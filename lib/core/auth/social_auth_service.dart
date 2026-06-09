import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:stopandgo/core/auth/social_auth_exceptions.dart';
import 'package:stopandgo/core/auth/social_auth_result.dart';

class SocialAuthService {
  SocialAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ?? GoogleSignIn(scopes: const <String>['email']);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const SocialAuthCancelledException();
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const SocialAuthConfigurationException(
          'Google Sign-In no regresó un idToken válido. Revisa la configuración OAuth de Firebase.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await userCredential.user?.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const SocialAuthConfigurationException(
          'Firebase no pudo generar el token para Google Sign-In.',
        );
      }

      return SocialAuthResult(
        provider: SocialAuthProvider.google,
        firebaseIdToken: firebaseIdToken,
        email: googleUser.email.trim(),
        displayName: userCredential.user?.displayName?.trim() ?? '',
      );
    } on FirebaseAuthException catch (error) {
      throw SocialAuthConfigurationException(_firebaseAuthErrorMessage(error));
    } on PlatformException catch (error) {
      final message = error.message ?? '';
      if (message.contains('canceled') || message.contains('cancelled')) {
        throw const SocialAuthCancelledException();
      }
      throw SocialAuthConfigurationException(
        message.isNotEmpty
            ? message
            : 'No fue posible completar Google Sign-In en este dispositivo.',
      );
    }
  }

  Future<SocialAuthResult> signInWithApple() async {
    if (!Platform.isIOS) {
      throw const SocialAuthConfigurationException(
        'Apple Sign-In solo está disponible en iOS.',
      );
    }

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw const SocialAuthConfigurationException(
          'Sign in with Apple no está disponible en este dispositivo.',
        );
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const SocialAuthConfigurationException(
          'Apple Sign-In no regresó identityToken. Revisa la configuración del capability en iOS.',
        );
      }

      final firebaseCredential = AppleAuthProvider.credentialWithIDToken(
        identityToken,
        rawNonce,
        AppleFullPersonName(
          givenName: appleCredential.givenName,
          familyName: appleCredential.familyName,
        ),
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        firebaseCredential,
      );
      final firebaseIdToken = await userCredential.user?.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const SocialAuthConfigurationException(
          'Firebase no pudo generar el token para Apple Sign-In.',
        );
      }

      final fullName = <String>[
        appleCredential.givenName?.trim() ?? '',
        appleCredential.familyName?.trim() ?? '',
      ].where((String value) => value.isNotEmpty).join(' ');

      return SocialAuthResult(
        provider: SocialAuthProvider.apple,
        firebaseIdToken: firebaseIdToken,
        email:
            userCredential.user?.email?.trim() ?? appleCredential.email ?? '',
        displayName: fullName.isNotEmpty
            ? fullName
            : userCredential.user?.displayName?.trim() ?? '',
        authorizationCode: appleCredential.authorizationCode,
      );
    } on FirebaseAuthException catch (error) {
      throw SocialAuthConfigurationException(_firebaseAuthErrorMessage(error));
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const SocialAuthCancelledException();
      }
      throw SocialAuthConfigurationException(
        error.message.isNotEmpty
            ? error.message
            : 'No fue posible completar Apple Sign-In.',
      );
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Si Google no estaba activo, seguimos con el logout local.
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException error) {
    final message = (error.message ?? '').trim();
    if (message.isNotEmpty) {
      return message;
    }

    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese correo usando otro método de acceso.';
      case 'invalid-credential':
        return 'La credencial social no es válida o expiró. Intenta de nuevo.';
      case 'network-request-failed':
        return 'No se pudo conectar con el servicio de autenticación.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'operation-not-allowed':
        return 'El proveedor social no está habilitado en Firebase.';
      default:
        return 'No fue posible completar la autenticación social.';
    }
  }
}
