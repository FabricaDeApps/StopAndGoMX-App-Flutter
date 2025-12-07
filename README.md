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


./scripts/make_module.sh home    




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
