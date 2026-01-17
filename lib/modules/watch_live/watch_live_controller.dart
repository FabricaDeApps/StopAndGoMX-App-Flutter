import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

enum WatchMode { none, hls, webrtc }

class WatchLiveController extends GetxController {
  final isLoading = true.obs;
  final error = RxnString();
  final mode = WatchMode.none.obs;

  // para evitar pintar RTCVideoView antes de inicializar renderer
  final webrtcReady = false.obs;

  late final int liveEventId;
  late final String playUrl;
  late final String title;

  // HLS
  VideoPlayerController? videoCtrl;

  // WebRTC
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _rendererInitialized = false;
  RTCPeerConnection? _pc;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments ?? {}) as Map;

    liveEventId = (args['liveEventId'] ?? 0) as int;
    playUrl = (args['playUrl'] ?? '').toString();
    title = (args['title'] ?? 'Live').toString();

    load();
  }

  bool _isHlsUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('.m3u8') ||
        u.contains('/hls/') ||
        u.contains('manifest.m3u8');
  }

  bool _isWebrtcPlayUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('/webrtc/play') || u.contains('webrtc/play');
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      if (liveEventId <= 0 || playUrl.isEmpty) {
        throw Exception(
          'Faltan datos para reproducir (liveEventId / playUrl).',
        );
      }

      // limpia sesiones anteriores
      await _disposeHls();
      await stopWebrtc(); // <- ahora NO dispone renderer

      // decide modo
      if (_isHlsUrl(playUrl)) {
        mode.value = WatchMode.hls;
        await _initHls(playUrl);
      } else if (_isWebrtcPlayUrl(playUrl)) {
        mode.value = WatchMode.webrtc;
        await _initWebrtc(playUrl);
      } else {
        // fallback: intenta HLS
        mode.value = WatchMode.hls;
        await _initHls(playUrl);
      }
    } catch (e) {
      error.value = e.toString();
      mode.value = WatchMode.none;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================
  // HLS
  // =======================
  Future<void> _initHls(String url) async {
    final vc = VideoPlayerController.networkUrl(Uri.parse(url));
    videoCtrl = vc;
    await vc.initialize();
    await vc.play();
  }

  void togglePlayPause() {
    final vc = videoCtrl;
    if (vc == null || !vc.value.isInitialized) return;
    vc.value.isPlaying ? vc.pause() : vc.play();
    update();
  }

  Future<void> _disposeHls() async {
    final vc = videoCtrl;
    videoCtrl = null;
    if (vc != null) {
      try {
        await vc.pause();
      } catch (_) {}
      await vc.dispose();
    }
  }

  // =======================
  // WebRTC
  // =======================
  Future<void> _initWebrtc(String url) async {
    // Inicializa renderer SOLO una vez
    if (!_rendererInitialized) {
      await remoteRenderer.initialize();
      _rendererInitialized = true;
    }

    webrtcReady.value = false;
    remoteRenderer.srcObject = null;

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    _pc!.onTrack = (RTCTrackEvent ev) {
      if (ev.track.kind == 'video') {
        remoteRenderer.srcObject = ev.streams.isNotEmpty
            ? ev.streams.first
            : null;
        webrtcReady.value = true;
      }
    };

    final offer = await _pc!.createOffer({});
    await _pc!.setLocalDescription(offer);

    final resp = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/sdp', 'Accept': 'application/sdp'},
      body: offer.sdp ?? '',
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'WebRTC play failed: HTTP ${resp.statusCode} ${resp.body}',
      );
    }

    await _pc!.setRemoteDescription(RTCSessionDescription(resp.body, 'answer'));
  }

  Future<void> stopWebrtc() async {
    webrtcReady.value = false;

    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;

    // IMPORTANTE: no dispose renderer aquí
    try {
      remoteRenderer.srcObject = null;
    } catch (_) {}
  }

  @override
  void onClose() {
    _disposeHls();
    stopWebrtc();

    // dispose renderer SOLO al cerrar el controller
    if (_rendererInitialized) {
      remoteRenderer.dispose();
      _rendererInitialized = false;
    }

    super.onClose();
  }
}
