import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_router.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/error_handler_service.dart';
import '../data/models/call.dart';
import '../pages/outgoing_call_page.dart';
import '../providers/call_provider.dart';

/// Initiates a call via API and navigates to [OutgoingCallPage].
Future<void> startOutgoingCall({
  required BuildContext context,
  required WidgetRef ref,
  required int recipientId,
  required String recipientName,
  String? recipientAvatarUrl,
  required OutgoingCallType type,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final apiType = type == OutgoingCallType.video ? 'video' : 'voice';
    final call = await ref.read(callProvider.notifier).initiateCall(
          InitiateCallRequest(
            receiverId: recipientId,
            callType: apiType,
          ),
        );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (call == null) {
      throw Exception('Failed to initiate call');
    }

    final callId = call.id > 0 ? call.id : int.tryParse(call.callId);
    if (callId == null || callId <= 0) {
      throw Exception('Invalid call ID from server');
    }

    if (!context.mounted) return;
    context.push(
      Uri(
        path: AppRoutes.outgoingCall,
        queryParameters: {
          'callId': callId.toString(),
          'recipientId': recipientId.toString(),
          'recipientName': recipientName,
          if (recipientAvatarUrl != null && recipientAvatarUrl.isNotEmpty)
            'avatarUrl': recipientAvatarUrl,
          'type': type == OutgoingCallType.video ? 'video' : 'voice',
        },
      ).toString(),
    );
  } on ApiError catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ErrorHandlerService.handleError(context, e);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Could not start call',
      );
    }
  }
}

/// Opens [OutgoingCallPage] for callee after accepting (call already active).
void openActiveCallPage({
  required BuildContext context,
  required int callId,
  required int recipientId,
  required String recipientName,
  String? recipientAvatarUrl,
  required OutgoingCallType type,
}) {
  context.push(
    Uri(
      path: AppRoutes.outgoingCall,
      queryParameters: {
        'callId': callId.toString(),
        'recipientId': recipientId.toString(),
        'recipientName': recipientName,
        if (recipientAvatarUrl != null && recipientAvatarUrl.isNotEmpty)
          'avatarUrl': recipientAvatarUrl,
        'type': type == OutgoingCallType.video ? 'video' : 'voice',
        'callee': '1',
      },
    ).toString(),
  );
}
