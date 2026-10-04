#!/usr/bin/env python3
"""
create_sounds.py
通知音（info.wav）および警告音（warning.wav）を生成するスクリプト。
外部ライブラリ不要（標準ライブラリ wave, struct, math のみ使用）。
"""

import math
import os
import struct
import sys
import wave

def generate_wav(filepath, tone_definitions, sample_rate=44100):
    """
    tone_definitions: list of (frequency_hz, duration_sec, volume 0.0-1.0)
    """
    os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)
    
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)     # モノラル
        wav_file.setsampwidth(2)     # 16-bit
        wav_file.setframerate(sample_rate)

        frames = bytearray()
        for freq, duration, volume in tone_definitions:
            total_samples = int(sample_rate * duration)
            fade_len = int(sample_rate * 0.01) # クリックノイズ防止のためのフェード処理

            if freq <= 0:
                # 無音（休符）
                for _ in range(total_samples):
                    frames.extend(struct.pack("<h", 0))
                continue

            for i in range(total_samples):
                env = 1.0
                if i < fade_len:
                    env = i / fade_len
                elif i > total_samples - fade_len:
                    env = (total_samples - i) / fade_len

                # 正弦波
                val = math.sin(2.0 * math.pi * freq * (i / sample_rate))
                sample = int(32767 * volume * env * val)
                # クランプ
                sample = max(-32768, min(32767, sample))
                frames.extend(struct.pack("<h", sample))

        wav_file.writeframes(frames)

def main():
    target_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "sounds")
    
    # 1. info.wav: 心地よい2音チャイム（D5 -> A5）
    info_path = os.path.join(target_dir, "info.wav")
    if not os.path.exists(info_path):
        generate_wav(info_path, [
            (587.33, 0.15, 0.5), # D5
            (880.00, 0.35, 0.5), # A5
        ])
        print(f"Generated: {info_path}")

    # 2. warning.wav: 警告ビープ音（ピピッ！ピピッ！）
    warning_path = os.path.join(target_dir, "warning.wav")
    if not os.path.exists(warning_path):
        generate_wav(warning_path, [
            (880.00, 0.12, 0.6), # ピッ
            (0,      0.06, 0.0), # 無音
            (880.00, 0.12, 0.6), # ピッ
            (0,      0.15, 0.0), # 無音
            (880.00, 0.12, 0.6), # ピッ
            (0,      0.06, 0.0), # 無音
            (880.00, 0.25, 0.6), # ピー
        ])
        print(f"Generated: {warning_path}")

if __name__ == "__main__":
    main()
