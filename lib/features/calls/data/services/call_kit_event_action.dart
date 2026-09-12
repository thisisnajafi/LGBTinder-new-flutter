import 'package:flutter_callkit_incoming/entities/entities.dart';

/// What Flutter should do with a native CallKit event.
enum CallKitEventAction {
  accept,
  decline,
  timeout,
  callback,
  dismissOnly,
  ignore,
}

/// Maps plugin events.
///
/// [Event.actionCallEnded] must not reject — cold-start Accept often
/// dismisses the native UI and emits ended.
/// [Event.actionCallTimeout] must not reject (missed is CALL-FEAT-003).
CallKitEventAction classifyCallKitEvent(Event event) {
  switch (event) {
    case Event.actionCallAccept:
      return CallKitEventAction.accept;
    case Event.actionCallDecline:
      return CallKitEventAction.decline;
    case Event.actionCallTimeout:
      return CallKitEventAction.timeout;
    case Event.actionCallCallback:
      return CallKitEventAction.callback;
    case Event.actionCallEnded:
      return CallKitEventAction.dismissOnly;
    default:
      return CallKitEventAction.ignore;
  }
}
