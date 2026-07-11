import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show EventChannel, MethodChannel;
import 'package:lizzieyzy_mobile/application/kifu_repository.dart';

import 'gib_codec.dart';
import 'kifu_resource_limits.dart';
import 'kifu_text_decoder.dart';

enum PlatformInboundKifuFormat { sgf, gib }

enum PlatformInboundKifuAction { view, send, open }

final class PlatformInboundKifuFile {
  PlatformInboundKifuFile({
    required this.fileName,
    required this.format,
    required Uint8List bytes,
    required this.text,
    required this.textEncoding,
    required this.sha256,
    required this.action,
    required this.isInitial,
  }) : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final PlatformInboundKifuFormat format;
  final Uint8List bytes;
  final String text;
  final KifuTextEncoding textEncoding;
  final String sha256;
  final PlatformInboundKifuAction action;
  final bool isInitial;
}

sealed class PlatformInboundKifuException implements Exception {
  const PlatformInboundKifuException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class InvalidInboundKifuPayloadException
    extends PlatformInboundKifuException {
  const InvalidInboundKifuPayloadException(super.message);
}

final class NativeInboundKifuReadException
    extends PlatformInboundKifuException {
  const NativeInboundKifuReadException()
    : super('The operating system could not provide a readable kifu file.');
}

final class UnsupportedInboundKifuFormatException
    extends PlatformInboundKifuException {
  const UnsupportedInboundKifuFormatException(String fileName)
    : super('Only basename-only .sgf and .gib files are accepted: $fileName');
}

abstract interface class PlatformInboundKifuBridge {
  Future<Object?> takeInitial();

  Stream<Object?> get runtimeEvents;
}

final class MethodChannelInboundKifuBridge
    implements PlatformInboundKifuBridge {
  const MethodChannelInboundKifuBridge({
    MethodChannel methods = const MethodChannel(_methodChannelName),
    EventChannel events = const EventChannel(_eventChannelName),
  }) : _methods = methods,
       _events = events;

  static const _methodChannelName =
      'com.wimi321.lizzieyzy.mobile/inbound_kifu/methods';
  static const _eventChannelName =
      'com.wimi321.lizzieyzy.mobile/inbound_kifu/events';

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Future<Object?> takeInitial() =>
      _methods.invokeMethod<Object?>('takeInitialKifu');

  @override
  Stream<Object?> get runtimeEvents =>
      _events.receiveBroadcastStream().cast<Object?>();
}

/// Validates kifu files delivered by native document intents.
///
/// Native code never passes a URI or absolute path through the channel. This
/// service nevertheless treats every message as untrusted and repeats format,
/// byte, text-decoding, and character checks before exposing it to application
/// code. Every explicit open is delivered, even when its content matches an
/// earlier open; repository-level content addressing resolves it to the
/// existing document without swallowing the user's action.
final class PlatformInboundKifuService {
  PlatformInboundKifuService({
    PlatformInboundKifuBridge bridge = const MethodChannelInboundKifuBridge(),
    this.limits = const KifuResourceLimits(),
    this.initialReadTimeout = const Duration(seconds: 2),
    KifuTextDecoder? textDecoder,
  }) : assert(initialReadTimeout > Duration.zero),
       _bridge = bridge,
       _textDecoder =
           textDecoder ??
           KifuTextDecoder(
             limits: limits,
             gibCodec: GibCodec(limits: limits),
           );

  final PlatformInboundKifuBridge _bridge;
  final KifuResourceLimits limits;
  final Duration initialReadTimeout;
  final KifuTextDecoder _textDecoder;

  Future<PlatformInboundKifuFile?>? _initialFuture;
  Stream<PlatformInboundKifuFile>? _runtimeEvents;

  Future<PlatformInboundKifuFile?> takeInitial() =>
      _initialFuture ??= _takeInitial();

  Stream<PlatformInboundKifuFile> get runtimeEvents => _runtimeEvents ??=
      _bridge.runtimeEvents.transform<PlatformInboundKifuFile>(
        StreamTransformer<Object?, PlatformInboundKifuFile>.fromHandlers(
          handleData: (raw, sink) {
            try {
              final file = _decode(raw, isInitial: false);
              if (file != null) sink.add(file);
            } on Object catch (error, stackTrace) {
              sink.addError(error, stackTrace);
            }
          },
        ),
      );

  Future<PlatformInboundKifuFile?> _takeInitial() async {
    final raw = await _bridge.takeInitial().timeout(
      initialReadTimeout,
      onTimeout: () => throw const NativeInboundKifuReadException(),
    );
    if (raw == null) return null;
    return _decode(raw, isInitial: true);
  }

  PlatformInboundKifuFile? _decode(Object? raw, {required bool isInitial}) {
    if (raw is! Map<Object?, Object?>) {
      throw const InvalidInboundKifuPayloadException(
        'The native payload must be a map.',
      );
    }
    if (raw.containsKey('error')) {
      if (raw.length != 1 || raw['error'] != 'unreadable') {
        throw const InvalidInboundKifuPayloadException(
          'The native error payload is invalid.',
        );
      }
      throw const NativeInboundKifuReadException();
    }
    final fileName = raw['name'];
    final rawBytes = raw['bytes'];
    final rawAction = raw['action'];
    if (fileName is! String || rawBytes is! Uint8List || rawAction is! String) {
      throw const InvalidInboundKifuPayloadException(
        'The native payload has invalid field types.',
      );
    }
    final format = _formatForSafeBasename(fileName);
    final action = switch (rawAction) {
      'view' => PlatformInboundKifuAction.view,
      'send' => PlatformInboundKifuAction.send,
      'open' => PlatformInboundKifuAction.open,
      _ => throw const InvalidInboundKifuPayloadException(
        'The native payload has an unsupported action.',
      ),
    };
    if (rawBytes.isEmpty) {
      throw const InvalidInboundKifuPayloadException(
        'An inbound kifu cannot be empty.',
      );
    }
    limits.enforceInputBytes(rawBytes.length);
    final decodedText = switch (format) {
      PlatformInboundKifuFormat.sgf => _textDecoder.decodeSgf(rawBytes),
      PlatformInboundKifuFormat.gib => _textDecoder.decodeGib(rawBytes),
    };

    final sha256 = KifuContentIdentity.sha256Bytes(rawBytes);
    return PlatformInboundKifuFile(
      fileName: fileName,
      format: format,
      bytes: rawBytes,
      text: decodedText.text,
      textEncoding: decodedText.encoding,
      sha256: sha256,
      action: action,
      isInitial: isInitial,
    );
  }

  PlatformInboundKifuFormat _formatForSafeBasename(String fileName) {
    if (fileName.isEmpty ||
        fileName.length > 255 ||
        fileName == '.' ||
        fileName == '..' ||
        fileName.contains('/') ||
        fileName.contains('\\') ||
        fileName.codeUnits.any((codeUnit) => codeUnit < 0x20)) {
      throw UnsupportedInboundKifuFormatException(fileName);
    }
    final separator = fileName.lastIndexOf('.');
    if (separator <= 0 || separator == fileName.length - 1) {
      throw UnsupportedInboundKifuFormatException(fileName);
    }
    return switch (fileName.substring(separator + 1).toLowerCase()) {
      'sgf' => PlatformInboundKifuFormat.sgf,
      'gib' => PlatformInboundKifuFormat.gib,
      _ => throw UnsupportedInboundKifuFormatException(fileName),
    };
  }
}
