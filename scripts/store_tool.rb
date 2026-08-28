#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'optparse'
require 'pathname'
require 'uri'

class StoreTool
  TEXT_LIMITS = {
    'title' => 30,
    'subtitle' => 30,
    'shortDescription' => 80,
    'description' => 4_000,
    'promotionalText' => 170,
    'releaseNotes' => 4_000
  }.freeze

  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg].freeze

  attr_reader :config_path, :output_root, :errors, :warnings

  def initialize(config_path:, output_root: nil)
    @config_path = File.expand_path(config_path)
    @root = find_project_root(File.dirname(@config_path))
    @config = JSON.parse(File.read(@config_path))
    flavor = required_string(@config, 'flavor')
    @output_root = File.expand_path(output_root || File.join(@root, 'build/store', flavor))
    @errors = []
    @warnings = []
  rescue JSON::ParserError => e
    abort "JSON inválido en #{config_path}: #{e.message}"
  rescue Errno::ENOENT
    abort "No existe el manifiesto: #{config_path}"
  end

  def generate
    validate(publish: false)
    return false unless errors.empty?

    localizations.each do |localization|
      write_android_metadata(localization)
      write_ios_metadata(localization)
    end
    copy_store_assets
    write_store_summary
    write_report('generated')
    true
  end

  def validate(publish: false)
    errors.clear
    warnings.clear
    validate_identity
    validate_status(publish: publish)
    validate_localizations
    validate_contact(publish: publish)
    validate_review_access(publish: publish)
    validate_compliance(publish: publish)
    validate_assets(publish: publish)
    validate_screenshots(publish: publish)
    write_report(publish ? 'publish-validation' : 'validation') if valid_output_root?
    errors.empty?
  end

  def report
    {
      'flavor' => @config['flavor'],
      'config' => relative_to_root(config_path),
      'output' => relative_to_root(output_root),
      'errors' => errors,
      'warnings' => warnings,
      'valid' => errors.empty?,
      'ready' => errors.empty? && warnings.empty?
    }
  end

  private

  def store
    @config.fetch('store', {})
  end

  def localizations
    value = store['localizations']
    value.is_a?(Array) ? value : []
  end

  def validate_identity
    %w[name flavor organizationSlug androidApplicationId iosBundleId].each do |key|
      errors << "Falta #{key}." if @config[key].to_s.strip.empty?
    end
    errors << 'organizationId debe ser un entero positivo.' unless @config['organizationId'].is_a?(Integer) && @config['organizationId'].positive?
    errors << 'Falta store.localizations.' if localizations.empty?
  end

  def validate_status(publish:)
    status = store['status'].to_s
    unless %w[draft approved].include?(status)
      errors << 'store.status debe ser draft o approved.'
      return
    end
    errors << 'store.status debe cambiar a approved después de la revisión humana.' if publish && status != 'approved'
  end

  def validate_localizations
    localizations.each_with_index do |localization, index|
      prefix = "store.localizations[#{index}]"
      %w[locale androidLocale iosLocale title subtitle shortDescription description promotionalText releaseNotes].each do |key|
        value = localization[key].to_s.strip
        errors << "Falta #{prefix}.#{key}." if value.empty?
        limit = TEXT_LIMITS[key]
        errors << "#{prefix}.#{key} excede #{limit} caracteres (#{value.length})." if limit && value.length > limit
      end

      keywords = localization['keywords']
      unless keywords.is_a?(Array) && keywords.all? { |keyword| !keyword.to_s.strip.empty? }
        errors << "#{prefix}.keywords debe ser una lista de textos."
        next
      end
      joined_keywords = keywords.join(',')
      errors << "#{prefix}.keywords excede 100 caracteres (#{joined_keywords.length})." if joined_keywords.length > 100
    end
  end

  def validate_contact(publish:)
    contact = store.fetch('contact', {})
    %w[privacyPolicyUrl supportUrl].each do |key|
      value = contact[key].to_s.strip
      if value.empty?
        add_requirement("Falta store.contact.#{key}.", publish)
      elsif !https_url?(value)
        errors << "store.contact.#{key} debe ser una URL https válida."
      end
    end

    marketing_url = contact['marketingUrl'].to_s.strip
    errors << 'store.contact.marketingUrl debe ser una URL https válida.' unless marketing_url.empty? || https_url?(marketing_url)

    email = contact['supportEmail'].to_s.strip
    if email.empty?
      add_requirement('Falta store.contact.supportEmail.', publish)
    elsif email !~ /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/
      errors << 'store.contact.supportEmail no parece un correo válido.'
    end
  end

  def validate_review_access(publish:)
    review = store.fetch('review', {})
    return unless review['requiresLogin'] == true

    {
      'username' => 'usernameEnvironmentVariable',
      'password' => 'passwordEnvironmentVariable'
    }.each do |value_key, variable_key|
      next unless review[value_key].to_s.strip.empty?

      variable = review[variable_key].to_s.strip
      if variable.empty?
        add_requirement("Falta store.review.#{value_key} o store.review.#{variable_key}.", publish)
      elsif publish && ENV[variable].to_s.strip.empty?
        errors << "Falta store.review.#{value_key} o definir la variable de entorno #{variable}."
      end
    end
  end

  def validate_compliance(publish:)
    compliance = store.fetch('compliance', {})
    %w[
      googleDataSafetyReviewed
      applePrivacyReviewed
      contentRatingCompleted
      targetAudienceReviewed
      appAccessInstructionsReviewed
    ].each do |key|
      add_requirement("Falta confirmar store.compliance.#{key}.", publish) unless compliance[key] == true
    end
  end

  def validate_screenshots(publish:)
    screenshots = store.fetch('screenshots', {})
    minimum = screenshots.fetch('minimumRequired', 1).to_i
    recommended = screenshots.fetch('recommended', 5).to_i

    {
      'Android' => screenshots['androidPhoneDirectory'],
      'iOS' => screenshots['iosIphoneDirectory']
    }.each do |platform, directory|
      files = image_files(directory)
      count = files.length
      if count < minimum
        add_requirement("#{platform} necesita al menos #{minimum} screenshot(s); hay #{count}.", publish)
      elsif count < recommended
        warnings << "#{platform} tiene #{count} screenshot(s); se recomiendan #{recommended}."
      end

      files.each { |path| validate_screenshot_file(platform, path) }
    end
  end

  def validate_assets(publish:)
    assets = store.fetch('assets', {})
    validate_png_asset(
      assets['androidStoreIcon'],
      label: 'Icono de Google Play',
      width: 512,
      height: 512,
      alpha: true,
      publish: publish
    )
    validate_png_asset(
      assets['androidFeatureGraphic'],
      label: 'Gráfico promocional de Google Play',
      width: 1_024,
      height: 500,
      alpha: false,
      publish: publish
    )
  end

  def validate_png_asset(path, label:, width:, height:, alpha:, publish:)
    if path.to_s.strip.empty? || !File.exist?(absolute_from_root(path))
      add_requirement("Falta #{label}.", publish)
      return
    end

    info = png_info(absolute_from_root(path))
    unless info
      errors << "#{label} debe ser PNG."
      return
    end
    errors << "#{label} debe medir #{width}x#{height}; mide #{info[:width]}x#{info[:height]}." unless info[:width] == width && info[:height] == height
    errors << "#{label} #{alpha ? 'debe incluir' : 'no debe incluir'} canal alpha." unless info[:alpha] == alpha
  end

  def validate_screenshot_file(platform, path)
    info = png_info(path)
    return warnings << "No se validaron dimensiones/canales de #{relative_to_root(path)} porque no es PNG." unless info

    errors << "#{platform}: #{File.basename(path)} no debe incluir canal alpha." if info[:alpha]
    if platform == 'Android'
      short, long = [info[:width], info[:height]].minmax
      errors << "Android: #{File.basename(path)} debe medir entre 320 y 3840 px y no superar proporción 2:1." unless short >= 320 && long <= 3_840 && long <= short * 2
    else
      accepted = [[1_260, 2_736], [1_290, 2_796], [1_320, 2_868], [1_284, 2_778], [1_242, 2_688]]
      size = [info[:width], info[:height]]
      errors << "iOS: #{File.basename(path)} tiene tamaño no admitido (#{size.join('x')})." unless accepted.include?(size) || accepted.include?(size.reverse)
    end
  end

  def write_android_metadata(localization)
    locale_dir = File.join(output_root, 'android/metadata', localization.fetch('androidLocale'))
    write_text(File.join(locale_dir, 'title.txt'), localization.fetch('title'))
    write_text(File.join(locale_dir, 'short_description.txt'), localization.fetch('shortDescription'))
    write_text(File.join(locale_dir, 'full_description.txt'), localization.fetch('description'))
  end

  def write_ios_metadata(localization)
    locale_dir = File.join(output_root, 'ios/metadata', localization.fetch('iosLocale'))
    contact = store.fetch('contact', {})
    values = {
      'name.txt' => localization.fetch('title'),
      'subtitle.txt' => localization.fetch('subtitle'),
      'description.txt' => localization.fetch('description'),
      'keywords.txt' => localization.fetch('keywords').join(','),
      'promotional_text.txt' => localization.fetch('promotionalText'),
      'release_notes.txt' => localization.fetch('releaseNotes'),
      'privacy_url.txt' => contact['privacyPolicyUrl'],
      'support_url.txt' => contact['supportUrl'],
      'marketing_url.txt' => contact['marketingUrl']
    }
    values.each { |filename, value| write_text(File.join(locale_dir, filename), value) unless value.to_s.strip.empty? }
  end

  def copy_store_assets
    screenshots = store.fetch('screenshots', {})
    localizations.each do |localization|
      copy_images(
        screenshots['androidPhoneDirectory'],
        File.join(output_root, 'android/metadata', localization.fetch('androidLocale'), 'images/phoneScreenshots')
      )
      copy_file(
        store.dig('assets', 'androidStoreIcon'),
        File.join(output_root, 'android/metadata', localization.fetch('androidLocale'), 'images/icon.png')
      )
      copy_file(
        store.dig('assets', 'androidFeatureGraphic'),
        File.join(output_root, 'android/metadata', localization.fetch('androidLocale'), 'images/featureGraphic.png')
      )
      copy_images(
        screenshots['iosIphoneDirectory'],
        File.join(output_root, 'ios/screenshots', localization.fetch('iosLocale'))
      )
    end
  end

  def copy_images(source, destination)
    files = image_files(source)
    return if files.empty?

    FileUtils.mkdir_p(destination)
    files.each { |path| FileUtils.cp(path, File.join(destination, File.basename(path))) }
  end

  def copy_file(source, destination)
    return if source.to_s.strip.empty?

    absolute = absolute_from_root(source)
    return unless File.file?(absolute)

    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(absolute, destination)
  end

  def png_info(path)
    header = File.binread(path, 26)
    return nil unless header.start_with?("\x89PNG\r\n\x1A\n".b) && header.bytesize >= 26

    {
      width: header.byteslice(16, 4).unpack1('N'),
      height: header.byteslice(20, 4).unpack1('N'),
      alpha: [4, 6].include?(header.getbyte(25))
    }
  rescue Errno::ENOENT
    nil
  end

  def image_files(directory)
    return [] if directory.to_s.strip.empty?

    absolute = absolute_from_root(directory)
    return [] unless Dir.exist?(absolute)

    Dir.children(absolute)
       .map { |name| File.join(absolute, name) }
       .select { |path| File.file?(path) && IMAGE_EXTENSIONS.include?(File.extname(path).downcase) }
       .sort
  end

  def write_text(path, value)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "#{value.to_s.strip}\n")
  end

  def write_report(action)
    FileUtils.mkdir_p(output_root)
    payload = report.merge('action' => action)
    File.write(File.join(output_root, 'validation-report.json'), "#{JSON.pretty_generate(payload)}\n")
  end

  def write_store_summary
    summary = {
      'name' => @config['name'],
      'flavor' => @config['flavor'],
      'organizationId' => @config['organizationId'],
      'organizationSlug' => @config['organizationSlug'],
      'androidApplicationId' => @config['androidApplicationId'],
      'iosBundleId' => @config['iosBundleId'],
      'status' => store['status'],
      'category' => store['category'],
      'assets' => store['assets'],
      'contact' => store['contact'],
      'review' => redacted_review,
      'compliance' => store['compliance'],
      'publishing' => store['publishing']
    }
    FileUtils.mkdir_p(output_root)
    File.write(File.join(output_root, 'store-summary.json'), "#{JSON.pretty_generate(summary)}\n")
  end

  def add_requirement(message, publish)
    (publish ? errors : warnings) << message
  end

  def redacted_review
    review = store.fetch('review', {}).dup
    password_configured = !review.delete('password').to_s.empty?
    review.merge('passwordConfigured' => password_configured)
  end

  def https_url?(value)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?
  rescue URI::InvalidURIError
    false
  end

  def required_string(hash, key)
    value = hash[key].to_s.strip
    abort "Falta #{key} en #{config_path}" if value.empty?
    value
  end

  def absolute_from_root(path)
    pathname = Pathname.new(path)
    pathname.absolute? ? pathname.to_s : File.join(@root, path)
  end

  def relative_to_root(path)
    Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
  rescue ArgumentError
    path
  end

  def valid_output_root?
    output_root.start_with?(File.join(@root, 'build/store') + File::SEPARATOR)
  end

  def find_project_root(start)
    current = File.expand_path(start)
    loop do
      return current if File.exist?(File.join(current, 'pubspec.yaml'))
      parent = File.dirname(current)
      abort "No pude encontrar la raíz del proyecto desde #{start}" if parent == current
      current = parent
    end
  end
end

if $PROGRAM_NAME == __FILE__
  usage = lambda do
    warn 'Uso: ruby scripts/store_tool.rb <generate|validate> --config RUTA [--output RUTA] [--publish]'
    exit 64
  end

  action = ARGV.shift
  usage.call unless %w[generate validate].include?(action)

  options = { publish: false }
  OptionParser.new do |parser|
    parser.on('--config PATH') { |value| options[:config] = value }
    parser.on('--output PATH') { |value| options[:output] = value }
    parser.on('--publish') { options[:publish] = true }
  end.parse!(ARGV)
  usage.call if options[:config].to_s.strip.empty?

  tool = StoreTool.new(config_path: options[:config], output_root: options[:output])
  success = action == 'generate' ? tool.generate : tool.validate(publish: options[:publish])

  tool.warnings.each { |warning| warn "ADVERTENCIA: #{warning}" }
  tool.errors.each { |error| warn "ERROR: #{error}" }
  puts JSON.pretty_generate(tool.report)
  exit(success ? 0 : 1)
end
