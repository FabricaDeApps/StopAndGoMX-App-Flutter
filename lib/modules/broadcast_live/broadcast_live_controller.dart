import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class BroadcastLiveController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final isLive = false.obs;
  final error = RxnString();

  final isStarting = false.obs;
  final isStopping = false.obs;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _pc;

  // args
  late final int liveEventId;
  late final String webrtcPublishUrl;

  @override
  void onInit() {
    super.onInit();
    final args = Map<String, dynamic>.from(Get.arguments ?? {});

    liveEventId = (args['liveEventId'] ?? args['id'] ?? 0) as int;

    webrtcPublishUrl =
        (args['webrtcPublishUrl'] ??
                args['webrtc_publish_url'] ??
                args['publishUrl'] ??
                '')
            .toString()
            .trim();

    _boot();
  }

  Future<void> _boot() async {
    try {
      isLoading.value = true;
      error.value = null;

      if (liveEventId <= 0 || webrtcPublishUrl.isEmpty) {
        throw Exception(
          'Faltan datos para transmitir (liveEventId / webrtcPublishUrl).',
        );
      }

      // (Opcional) Si quieres mantener permission_handler:
      // final ok = await _requestPermissions();
      // if (!ok) throw Exception('Permisos de cámara y micrófono requeridos.');

      await localRenderer.initialize();
      await WakelockPlus.enable();

      _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30},
        },
      });

      localRenderer.srcObject = _localStream;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _requestPermissions() async {
    final camStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    final ok = camStatus.isGranted && micStatus.isGranted;
    if (ok) return true;

    final blocked =
        camStatus.isPermanentlyDenied ||
        micStatus.isPermanentlyDenied ||
        camStatus.isRestricted ||
        micStatus.isRestricted;

    if (blocked) {
      await openAppSettings();
    }

    return false;
  }

  Future<void> start() async {
    if (isStarting.value) return;

    try {
      isStarting.value = true;
      error.value = null;

      if (_localStream == null) {
        throw Exception('Local stream no inicializado.');
      }

      // 0) Notifica backend: START
      // Esto debe cambiar status a "live" y guardar started_at, etc.
      await _api.startLiveEvent(liveEventId);

      // 1) Crea PeerConnection
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      });

      // 2) Agrega tracks
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // 3) Crea Offer
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await _pc!.setLocalDescription(offer);

      // 4) Publica por WHIP
      final resp = await http.post(
        Uri.parse(webrtcPublishUrl),
        headers: {
          'Content-Type': 'application/sdp',
          'Accept': 'application/sdp',
        },
        body: offer.sdp ?? '',
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        // Si WHIP falla, pausamos backend para no dejarlo en "live"
        await _safePauseBackend();
        throw Exception('WHIP failed: HTTP ${resp.statusCode} ${resp.body}');
      }

      // 5) Aplica Answer
      final answerSdp = resp.body;
      await _pc!.setRemoteDescription(
        RTCSessionDescription(answerSdp, 'answer'),
      );

      isLive.value = true;
    } catch (e) {
      error.value = e.toString();
      // si ya quedó algo abierto, lo cerramos local
      await _stopLocalOnly();
    } finally {
      isStarting.value = false;
    }
  }

  /// Pausar transmisión (sin destruir UI/cámara si tú quieres)
  /// Útil si vas a reanudar en la misma pantalla.
  Future<void> pause() async {
    try {
      error.value = null;
      await _api.pauseLiveEvent(liveEventId);
      isLive.value = false;

      // opcional: detener tracks o mantenerlos
      // aquí lo dejo "light": cerramos peer pero mantenemos cámara lista
      await _pc?.close();
      _pc = null;
    } catch (e) {
      error.value = e.toString();
    }
  }

  /// Stop = terminar definitivamente (backend finish + cerrar todo)
  Future<void> stop() async {
    if (isStopping.value) return;

    try {
      isStopping.value = true;
      error.value = null;

      // 1) backend finish
      await _safeFinishBackend();

      // 2) cerrar local completo
      await _stopLocalOnly();
    } catch (e) {
      error.value = e.toString();
      // aún si falla backend, no dejes recursos colgados
      await _stopLocalOnly();
    } finally {
      isStopping.value = false;
    }
  }

  Future<void> _safePauseBackend() async {
    try {
      await _api.pauseLiveEvent(liveEventId);
    } catch (_) {}
  }

  Future<void> _safeFinishBackend() async {
    try {
      await _api.finishLiveEvent(liveEventId);
    } catch (_) {}
  }

  Future<void> _stopLocalOnly() async {
    try {
      isLive.value = false;

      await _pc?.close();
      _pc = null;

      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream = null;

      localRenderer.srcObject = null;
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    final stream = _localStream;
    if (stream == null) return;

    final videoTracks = stream.getVideoTracks();
    if (videoTracks.isEmpty) return;

    await Helper.switchCamera(videoTracks.first);
  }

  Future<void> toggleMute() async {
    final stream = _localStream;
    if (stream == null) return;

    final audioTracks = stream.getAudioTracks();
    if (audioTracks.isEmpty) return;

    final t = audioTracks.first;
    t.enabled = !t.enabled;
    update();
  }

  @override
  void onClose() {
    WakelockPlus.disable();
    localRenderer.dispose();
    super.onClose();
  }
}
