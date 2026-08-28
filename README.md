# stopandgo

## Flavors

- [Proceso para crear y automatizar un nuevo flavor](docs/new_flavor_automation.md)
- [Automatización de fichas de Google Play y App Store](docs/store_automation.md)
- [Referencia histórica y flavors registrados](FLAVORS.md)

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


./scripts/make_module.sh home_pattaern




# ANALTYICS

setear eventos:


firebaseAnalytics = FirebaseAnalytics.instance;
firebaseObserver = FirebaseAnalyticsObserver(analytics: firebaseAnalytics);

await firebaseAnalytics.logEvent(
  name: 'payment_completed',
  parameters: {
    'amount': 1800,
    'category': 'juvenil',
    'role': 'parent',
  },
);
