import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/helpers/wav.dart';

void main() {
  test('writes a 44-byte PCM header in front of the samples', () {
    final pcm = Uint8List.fromList([1, 0, 2, 0, 3, 0]);
    final wav = wavFromPcm16(pcm, sampleRate: 16000);
    final data = ByteData.sublistView(wav);

    expect(wav.length, 44 + 6);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(data.getUint32(4, Endian.little), 36 + 6);
    expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(data.getUint16(20, Endian.little), 1); // PCM
    expect(data.getUint16(22, Endian.little), 1); // mono
    expect(data.getUint32(24, Endian.little), 16000);
    expect(data.getUint32(28, Endian.little), 32000); // bytes per second
    expect(data.getUint16(32, Endian.little), 2); // block align
    expect(data.getUint16(34, Endian.little), 16);
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(data.getUint32(40, Endian.little), 6);
    expect(wav.sublist(44), pcm);
  });
}
