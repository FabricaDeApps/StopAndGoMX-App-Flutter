# stopandgo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Imoportante correr esto para los logos:
./scripts/use_logo.sh 


./scripts/make_module.sh home     

flutter build apk --flavor zorros -t lib/main_zorros.dart




Flavors Android:
flutter build aab --flavor zorros -t lib/main_zorros.dart
flutter build aab --flavor mainapp -t lib/main_stopandgo.dart


Flavors iOS
flutter build ios --flavor zorros -t lib/main_zorros.dart
flutter build ios --flavor mainapp -t lib/main_stopandgo.dart


FASTLANE:

ZORROS
./scripts/use_logo.sh zorros
fastlane android deploy \
  flavor:zorros \
  target:lib/main_zorros.dart \
  track:internal \
  package_name:app.stopandgomx.zorros

fastlane android deploy flavor:zorros target:lib/main_zorros.dart track:production package_name:app.stopandgomx.zorros


STOPANDGO
./scripts/use_logo.sh stopandgo
fastlane android deploy \
  flavor:mainapp \
  target:lib/main_stopandgo.dart \
  track:internal || internal \
  package_name:app.stopandgomx.mainapp

# mainapp
fastlane deploy_mainapp

# zorros
fastlane deploy_zorros