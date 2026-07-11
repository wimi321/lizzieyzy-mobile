import 'dart:async';

import 'package:lizzieyzy_mobile/application/settings/settings.dart';

import 'analysis_provider_factory.dart';

/// Coordinates provider ownership across every app-owned analysis session.
///
/// The desktop bridge intentionally defaults to one connection. A session must
/// therefore obtain a lease before it creates a provider, and it keeps that
/// lease until the provider has been fully released. Factories backed by a
/// multi-connection service can opt into a larger capacity through
/// [AnalysisProviderSchedulingPolicy].
final class AnalysisProviderScheduler {
  AnalysisProviderScheduler(this._factory);

  final AnalysisProviderFactory _factory;
  final Map<Object, _ProviderLane> _lanes = <Object, _ProviderLane>{};

  AnalysisProviderLeaseRequest acquire(
    AnalysisServiceProfile profile, {
    required void Function(int position) onQueuePositionChanged,
  }) {
    final schedulingPolicy = _factory is AnalysisProviderSchedulingPolicy
        ? _factory as AnalysisProviderSchedulingPolicy
        : null;
    final group =
        schedulingPolicy?.concurrencyGroup(profile) ??
        profile.endpoint.toString();
    final requestedCapacity =
        schedulingPolicy?.maximumConcurrentProviders(profile) ?? 1;
    if (requestedCapacity < 1) {
      throw StateError('Analysis provider capacity must be positive.');
    }

    final lane = _lanes.putIfAbsent(
      group,
      () => _ProviderLane(group: group, capacity: requestedCapacity),
    );
    // A concurrency group must never become less restrictive because a later
    // profile reports a different value. This is fail-safe for a shared bridge
    // while still allowing a stable multi-connection factory to opt in.
    if (requestedCapacity < lane.capacity) lane.capacity = requestedCapacity;

    if (lane.active < lane.capacity && lane.pending.isEmpty) {
      lane.active += 1;
      return AnalysisProviderLeaseRequest._immediate(
        AnalysisProviderLease._(this, group),
      );
    }

    final request = AnalysisProviderLeaseRequest._queued(
      this,
      group,
      onQueuePositionChanged,
      lane.pending.length + 1,
    );
    lane.pending.add(request);
    return request;
  }

  void _cancel(AnalysisProviderLeaseRequest request) {
    final lane = _lanes[request._group];
    if (lane == null || !lane.pending.remove(request)) return;
    request._completeCancelled();
    _renumber(lane);
    _removeLaneIfIdle(lane);
  }

  void _release(Object group) {
    final lane = _lanes[group];
    if (lane == null || lane.active < 1) {
      throw StateError('Analysis provider lease was released more than once.');
    }
    lane.active -= 1;
    while (lane.active < lane.capacity && lane.pending.isNotEmpty) {
      final request = lane.pending.removeAt(0);
      if (request._isResolved) continue;
      lane.active += 1;
      request._completeGranted(AnalysisProviderLease._(this, group));
    }
    _renumber(lane);
    _removeLaneIfIdle(lane);
  }

  void _renumber(_ProviderLane lane) {
    for (var index = 0; index < lane.pending.length; index++) {
      lane.pending[index]._updateQueuePosition(index + 1);
    }
  }

  void _removeLaneIfIdle(_ProviderLane lane) {
    if (lane.active == 0 && lane.pending.isEmpty) {
      _lanes.remove(lane.group);
    }
  }
}

/// Optional factory policy for safe future multi-connection or multiplexed
/// implementations. Factories that do not implement it are conservatively
/// serialized to one provider per endpoint.
abstract interface class AnalysisProviderSchedulingPolicy {
  Object concurrencyGroup(AnalysisServiceProfile profile);

  int maximumConcurrentProviders(AnalysisServiceProfile profile);
}

final class AnalysisProviderLeaseRequest {
  AnalysisProviderLeaseRequest._immediate(AnalysisProviderLease lease)
    : immediateLease = lease,
      initialQueuePosition = null,
      _scheduler = null,
      _group = lease._group,
      _onQueuePositionChanged = null,
      _completer = null;

  AnalysisProviderLeaseRequest._queued(
    this._scheduler,
    this._group,
    this._onQueuePositionChanged,
    this.initialQueuePosition,
  ) : immediateLease = null,
      _completer = Completer<AnalysisProviderLease?>();

  final AnalysisProviderLease? immediateLease;
  final int? initialQueuePosition;
  final AnalysisProviderScheduler? _scheduler;
  final Object _group;
  final void Function(int position)? _onQueuePositionChanged;
  final Completer<AnalysisProviderLease?>? _completer;
  var _isResolved = false;
  int? _queuePosition;

  bool get isQueued => immediateLease == null;

  Future<AnalysisProviderLease?> get granted {
    final completer = _completer;
    if (completer == null) {
      return Future<AnalysisProviderLease?>.value(immediateLease);
    }
    return completer.future;
  }

  void cancel() {
    if (!isQueued || _isResolved) return;
    _scheduler!._cancel(this);
  }

  void _completeGranted(AnalysisProviderLease lease) {
    if (_isResolved) {
      lease.release();
      return;
    }
    _isResolved = true;
    _completer!.complete(lease);
  }

  void _completeCancelled() {
    if (_isResolved) return;
    _isResolved = true;
    _completer!.complete(null);
  }

  void _updateQueuePosition(int position) {
    if (_isResolved || position == _queuePosition) return;
    _queuePosition = position;
    _onQueuePositionChanged?.call(position);
  }
}

final class AnalysisProviderLease {
  AnalysisProviderLease._(this._scheduler, this._group);

  final AnalysisProviderScheduler _scheduler;
  final Object _group;
  var _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _scheduler._release(_group);
  }
}

final class _ProviderLane {
  _ProviderLane({required this.group, required this.capacity});

  final Object group;
  int capacity;
  int active = 0;
  final List<AnalysisProviderLeaseRequest> pending =
      <AnalysisProviderLeaseRequest>[];
}
