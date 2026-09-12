import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/config/pusher_config.dart';

void main() {
  setUp(PusherConfig.resetRuntime);
  tearDown(PusherConfig.resetRuntime);

  test('applyRemote key+cluster is a persistable pair', () {
    PusherConfig.applyRemote(key: 'e1bc13af2989f44cc18a', cluster: 'ap2');

    expect(PusherConfig.appKey, 'e1bc13af2989f44cc18a');
    expect(PusherConfig.cluster, 'ap2');
    expect(PusherConfig.hasRemotePair, isTrue);
    expect(PusherConfig.isConfigured, isTrue);
  });

  test('key change without cluster clears the previous cluster', () {
    PusherConfig.applyRemote(key: 'd1e07f61aaaaaaaaaaaa', cluster: 'us3');
    PusherConfig.applyRemote(key: 'e1bc13af2989f44cc18a');

    expect(PusherConfig.appKey, 'e1bc13af2989f44cc18a');
    expect(PusherConfig.cluster, isEmpty);
    expect(PusherConfig.hasRemotePair, isFalse);
    expect(PusherConfig.isConfigured, isFalse);
  });

  test('same key without cluster keeps the existing cluster', () {
    PusherConfig.applyRemote(key: 'e1bc13af2989f44cc18a', cluster: 'ap2');
    PusherConfig.applyRemote(key: 'e1bc13af2989f44cc18a');

    expect(PusherConfig.cluster, 'ap2');
    expect(PusherConfig.hasRemotePair, isTrue);
  });
}
