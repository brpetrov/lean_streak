import 'dart:typed_data';

/// Wraps raw 16-bit little-endian PCM in a WAV container (44-byte header).
Uint8List wavFromPcm16(
  Uint8List pcm, {
  required int sampleRate,
  int channels = 1,
}) {
  const bitsPerSample = 16;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final header = ByteData(44);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // fmt chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * blockAlign, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  final wav = Uint8List(44 + pcm.length);
  wav.setRange(0, 44, header.buffer.asUint8List());
  wav.setRange(44, wav.length, pcm);
  return wav;
}
