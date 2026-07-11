import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' show XFile;

enum BoundedReadLimitKind { declaredLength, streamedLength }

/// A typed rejection raised before an untrusted file can allocate beyond its
/// configured byte budget.
final class BoundedReadLimitException implements Exception {
  const BoundedReadLimitException({
    required this.kind,
    required this.limit,
    required this.observed,
  });

  final BoundedReadLimitKind kind;
  final int limit;

  /// Exact for [BoundedReadLimitKind.declaredLength], and the number of bytes
  /// observed before cancellation for a streaming rejection.
  final int observed;

  @override
  String toString() =>
      'BoundedReadLimitException(${kind.name}: $observed > $limit)';
}

/// Small testable boundary around a user-selected file.
abstract interface class BoundedByteSource {
  Future<int> length();

  /// Implementations must honor [endExclusive] where the underlying API
  /// supports range reads. The reader still counts every returned byte and
  /// cancels a source that ignores the range.
  Stream<Uint8List> openRead(int start, int endExclusive);
}

final class XFileBoundedByteSource implements BoundedByteSource {
  const XFileBoundedByteSource(this.file);

  final XFile file;

  @override
  Future<int> length() => file.length();

  @override
  Stream<Uint8List> openRead(int start, int endExclusive) async* {
    var emittedBytes = false;
    try {
      await for (final chunk in file.openRead(start, endExclusive)) {
        emittedBytes = true;
        yield chunk;
      }
    } on RangeError {
      if (emittedBytes) rethrow;
      // cross_file's in-memory XFile implementation rejects an end offset
      // beyond EOF instead of clamping it like dart:io. Retrying as a stream
      // without an end remains bounded: readBoundedBytes counts every chunk
      // and cancels immediately upon receiving the limit-plus-one sentinel.
      yield* file.openRead(start);
    }
  }
}

final class FileBoundedByteSource implements BoundedByteSource {
  const FileBoundedByteSource(this.file);

  final File file;

  @override
  Future<int> length() => file.length();

  @override
  Stream<Uint8List> openRead(int start, int endExclusive) => file
      .openRead(start, endExclusive)
      .map((chunk) => Uint8List.fromList(chunk));
}

/// Reads at most [maximumBytes] from [source].
///
/// The range request is capped at `maximumBytes + 1`, so a file that grows
/// after `length()` (or a provider that lies about its size) cannot trigger an
/// unbounded `readAsBytes` allocation. Seeing the sentinel byte cancels the
/// stream and fails closed.
Future<Uint8List> readBoundedBytes(
  BoundedByteSource source, {
  required int maximumBytes,
}) async {
  if (maximumBytes <= 0 || maximumBytes >= 0x7FFFFFFFFFFFFFFF) {
    throw RangeError.range(maximumBytes, 1, 0x7FFFFFFFFFFFFFFE, 'maximumBytes');
  }

  final declaredLength = await source.length();
  if (declaredLength < 0) {
    throw StateError('An untrusted file reported a negative byte length.');
  }
  if (declaredLength > maximumBytes) {
    throw BoundedReadLimitException(
      kind: BoundedReadLimitKind.declaredLength,
      limit: maximumBytes,
      observed: declaredLength,
    );
  }

  final iterator = StreamIterator<Uint8List>(
    source.openRead(0, maximumBytes + 1),
  );
  final bytes = BytesBuilder(copy: false);
  var observed = 0;
  try {
    while (await iterator.moveNext()) {
      final chunk = iterator.current;
      if (chunk.isEmpty) continue;
      final remainingWithSentinel = maximumBytes + 1 - observed;
      if (remainingWithSentinel <= 0) {
        throw BoundedReadLimitException(
          kind: BoundedReadLimitKind.streamedLength,
          limit: maximumBytes,
          observed: observed,
        );
      }
      final accepted = chunk.length <= remainingWithSentinel
          ? chunk
          : Uint8List.sublistView(chunk, 0, remainingWithSentinel);
      bytes.add(accepted);
      observed += accepted.length;
      if (observed > maximumBytes) {
        throw BoundedReadLimitException(
          kind: BoundedReadLimitKind.streamedLength,
          limit: maximumBytes,
          observed: observed,
        );
      }
    }
  } finally {
    await iterator.cancel();
  }
  return bytes.takeBytes();
}

Future<Uint8List> readBoundedXFile(XFile file, {required int maximumBytes}) =>
    readBoundedBytes(XFileBoundedByteSource(file), maximumBytes: maximumBytes);

Future<Uint8List> readBoundedFile(File file, {required int maximumBytes}) =>
    readBoundedBytes(FileBoundedByteSource(file), maximumBytes: maximumBytes);
