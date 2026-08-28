require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'tmpdir'

require_relative '../../scripts/store_tool'

class StoreToolTest < Minitest::Test
  PROJECT_ROOT = File.expand_path('../..', __dir__)
  SOURCE_CONFIG = File.join(PROJECT_ROOT, 'branding/academiapuebla/store.json')

  def setup
    FileUtils.mkdir_p(File.join(PROJECT_ROOT, 'build'))
    @temporary_directory = Dir.mktmpdir('store-tool-', File.join(PROJECT_ROOT, 'build'))
    @config_path = File.join(@temporary_directory, 'store.json')
    @output_path = File.join(@temporary_directory, 'output')
    @config = JSON.parse(File.read(SOURCE_CONFIG))
    File.write(@config_path, JSON.pretty_generate(@config))
  end

  def teardown
    FileUtils.remove_entry(@temporary_directory) if Dir.exist?(@temporary_directory)
  end

  def test_generates_android_and_ios_metadata
    tool = StoreTool.new(config_path: @config_path, output_root: @output_path)

    assert tool.generate
    assert_equal "Academia Puebla FC MID\n", File.read(File.join(@output_path, 'android/metadata/es-419/title.txt'))
    assert_equal "Academia Puebla FC MID\n", File.read(File.join(@output_path, 'ios/metadata/es-MX/name.txt'))
    assert File.exist?(File.join(@output_path, 'ios/metadata/es-MX/keywords.txt'))
    assert File.exist?(File.join(@output_path, 'android/metadata/es-419/images/icon.png'))
    assert File.exist?(File.join(@output_path, 'android/metadata/es-419/images/featureGraphic.png'))
    assert File.exist?(File.join(@output_path, 'store-summary.json'))
    summary = JSON.parse(File.read(File.join(@output_path, 'store-summary.json')))
    refute summary.fetch('review').key?('password')
    assert_equal true, summary.dig('review', 'passwordConfigured')

    first_generation = generated_files
    assert tool.generate
    assert_equal first_generation, generated_files
  end

  def test_rejects_text_over_store_limit
    @config['store']['localizations'][0]['title'] = 'A' * 31
    File.write(@config_path, JSON.pretty_generate(@config))
    tool = StoreTool.new(config_path: @config_path, output_root: @output_path)

    refute tool.validate
    assert tool.errors.any? { |error| error.include?('title excede 30') }
  end

  def test_publish_validation_blocks_missing_external_requirements
    @config['store']['contact']['privacyPolicyUrl'] = nil
    @config['store']['screenshots']['androidPhoneDirectory'] = 'build/store-test/missing-android'
    @config['store']['screenshots']['iosIphoneDirectory'] = 'build/store-test/missing-ios'
    File.write(@config_path, JSON.pretty_generate(@config))
    tool = StoreTool.new(config_path: @config_path, output_root: @output_path)

    refute tool.validate(publish: true)
    assert_includes tool.errors, 'Falta store.contact.privacyPolicyUrl.'
    assert_includes tool.errors, 'store.status debe cambiar a approved después de la revisión humana.'
    assert tool.errors.any? { |error| error.include?('googleDataSafetyReviewed') }
    assert tool.errors.any? { |error| error.include?('screenshot') }
    refute tool.errors.any? { |error| error.include?('store.review') }
  end

  private

  def generated_files
    Dir.glob(File.join(@output_path, '**/*'))
       .select { |path| File.file?(path) }
       .to_h { |path| [path.delete_prefix("#{@output_path}/"), File.binread(path)] }
  end
end
