/*
import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraVideoWidget extends ConsumerStatefulWidget {
  final int auctionId;
  final bool isAdmin;
  final String agoraToken;
  final Function(RtcEngine)? onEngineInitialized;
  const AgoraVideoWidget({
    required this.agoraToken,
    required this.isAdmin,
    required this.auctionId,
    this.onEngineInitialized,
    super.key,
  });

  @override
  ConsumerState createState() => _AgoraVideoWidgetState();
}

const appId = "f89c312549cf41a4a89a503e7458f0fa";
const appCert = "f0e5b11629eb491bb80e79f4cf2a1616";

class _AgoraVideoWidgetState extends ConsumerState<AgoraVideoWidget> {
  late final String _channelName = "auction_${widget.auctionId}";
  int? _remoteUid; // The UID of the remote user
  bool _localUserJoined =
      false; // Indicates whether the local user has joined the channel
  late RtcEngine _engine; // The RtcEngine instances
  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    try {
      // Create the engine
      _engine = createAgoraRtcEngine();

      // Initialize the engine
      await _engine.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      // Leave any existing channel
      await _engine.leaveChannel();

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onPermissionError: (permissionType) {
            log(
              "onPermissionError: $permissionType",
              time: DateTime.now(),
              level: 1,
            );
          },
          onError: (err, msg) {
            log("onError: $err, $msg", time: DateTime.now(), level: 1);
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
            log(
              "onJoinChannelSuccess ------------------",
              time: DateTime.now(),
              level: 1,
            );
            debugPrint("Local user ${connection.localUid} joined");

            if (!_localUserJoined) {
              setState(() {
                _localUserJoined = true;
              });
            }
          },
          onUserJoined:
              (RtcConnection connection, int remoteUid, int elapsed) async {
                log(
                  "Remote user $remoteUid joined",
                  time: DateTime.now(),
                  level: 1,
                );

                if (_remoteUid == null) {
                  setState(() {
                    _remoteUid = remoteUid;
                  });
                }
              },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                log(
                  "Remote user $remoteUid left channel",
                  time: DateTime.now(),
                  level: 1,
                );
                if (_remoteUid != null) {
                  setState(() {
                    _remoteUid = null;
                  });
                }
              },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            log(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
              time: DateTime.now(),
              level: 1,
            );
          },
        ),
      );

      // Set client role and permissions logic
      if (widget.isAdmin) {
        // Broadcaster: Request Camera & Mic, Enable Video, Start Preview
        await [Permission.microphone, Permission.camera].request();
        await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine.enableVideo();
        await _engine.startPreview();
      } else {
        // Audience: No permissions needed to watch (usually), or just network.
        // We set role to Audience.
        await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
        await _engine.enableVideo(); // Enable video module to see remote video
        // Do NOT start preview for audience
      }

      // Join channel
      await _engine.joinChannel(
        token: widget.agoraToken,
        channelId: _channelName,
        uid: CachedVariables.userId ?? 0,
        options: const ChannelMediaOptions(),
      );

      // Callback the engine to parent widget after successful initialization
      if (widget.onEngineInitialized != null) {
        widget.onEngineInitialized!(_engine);
      }
    } catch (e, st) {
      // Handle errors
      log("Error initializing Agora: $e $st", time: DateTime.now(), level: 1);
      // Add error handling logic here
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    // Leave the channel
    await _engine.leaveChannel();
    // Release resources
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _channelName),
        ),
      );
    } else if (_localUserJoined && widget.isAdmin) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'في انتظار البث المباشر...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      );
    }
  }
}
*/
