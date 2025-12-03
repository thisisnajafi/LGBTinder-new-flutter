import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/incoming_call_overlay.dart';

/// Service for handling incoming call notifications and navigation
class IncomingCallHandler {
  static const String CALL_TYPE_VIDEO = 'video';
  static const String CALL_TYPE_VOICE = 'voice';

  // Store pending call data
  static Map<String, dynamic>? _pendingCallData;


  /// Store pending call data for later processing
  static void storePendingCallData(Map<String, dynamic> notificationData) {
    _pendingCallData = notificationData;
  }

  /// Process any pending incoming call (call this when app comes to foreground)
  static void processPendingCallIfAvailable(BuildContext context) {
    if (_pendingCallData != null) {
      handleIncomingCallNotification(_pendingCallData!, context);
      _pendingCallData = null;
    }
  }

  /// Handle incoming call notification
  static void handleIncomingCallNotification(
    Map<String, dynamic> notificationData,
    BuildContext context,
  ) {
    try {
      final callData = _parseCallNotification(notificationData);
      if (callData != null) {
        _pendingCallData = callData;
        _showIncomingCallOverlay(context, callData);
      }
    } catch (e) {
      print('Error handling incoming call notification: $e');
    }
  }

  /// Parse call notification data
  static Map<String, dynamic>? _parseCallNotification(Map<String, dynamic> data) {
    try {
      // Handle different notification formats (FCM, OneSignal, etc.)
      final customData = data['data'] ?? data['custom'] ?? data;

      if (customData is String) {
        // Parse JSON string
        final parsed = jsonDecode(customData);
        return _extractCallData(parsed);
      } else if (customData is Map<String, dynamic>) {
        return _extractCallData(customData);
      }

      return null;
    } catch (e) {
      print('Error parsing call notification: $e');
      return null;
    }
  }

  /// Extract call data from notification payload
  static Map<String, dynamic>? _extractCallData(Map<String, dynamic> data) {
    final callType = data['call_type'];
    final callerId = data['caller_id'];
    final callerName = data['caller_name'];
    final callerAvatar = data['caller_avatar'];
    final callId = data['call_id'];
    final channelName = data['channel_name'];
    final token = data['token'];

    if (callType != null && callerId != null && callId != null) {
      return {
        'callType': callType,
        'callerId': callerId,
        'callerName': callerName ?? 'Unknown User',
        'callerAvatar': callerAvatar,
        'callId': callId,
        'channelName': channelName,
        'token': token,
      };
    }

    return null;
  }

  /// Show incoming call overlay
  static void _showIncomingCallOverlay(BuildContext context, Map<String, dynamic> callData) {
    final incomingCallData = IncomingCallData(
      callId: callData['callId'].toString(),
      callType: callData['callType'],
      callerId: callData['callerId'],
      callerName: callData['callerName'],
      callerAvatar: callData['callerAvatar'],
      channelName: callData['channelName'],
      token: callData['token'],
    );

    // Show the overlay - it handles accept/reject logic internally
    IncomingCallManager.showIncomingCall(context, incomingCallData);
  }

  /// Get pending call data (for call screens to access)
  static Map<String, dynamic>? getPendingCallData() {
    final data = _pendingCallData;
    _pendingCallData = null; // Clear after access
    return data;
  }

  /// Clear pending call data
  static void clearPendingCallData() {
    _pendingCallData = null;
  }

  /// Check if there's a pending incoming call
  static bool hasPendingCall() {
    return _pendingCallData != null;
  }
}

