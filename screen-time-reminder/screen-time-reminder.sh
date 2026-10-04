#!/usr/bin/env bash
#
# screen-time-reminder.sh
# Linux Mint向けスクリーンタイム通知＆自動シャットダウンスクリプト
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
DIALOG_SCRIPT="$SCRIPT_DIR/show_dialog.py"
CREATE_SOUNDS_SCRIPT="$SCRIPT_DIR/create_sounds.py"
LOCK_FILE="/tmp/screen-time-reminder.lock"

# 引数の判定（テストモード対応）
TEST_MODE=0
if [[ "${1:-}" == "--test" || "${1:-}" == "-t" ]]; then
    TEST_MODE=1
fi

# ロック確認と取得（二重起動防止）
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "既にスクリーンタイムリマインダーが起動しています。"
    exit 0
fi

# サウンドファイルが存在しない場合は自動生成
if [[ ! -f "$SOUNDS_DIR/info.wav" || ! -f "$SOUNDS_DIR/warning.wav" ]]; then
    if command -v python3 >/dev/null 2>&1 && [[ -f "$CREATE_SOUNDS_SCRIPT" ]]; then
        python3 "$CREATE_SOUNDS_SCRIPT" "$SOUNDS_DIR" >/dev/null 2>&1 || true
    fi
fi

# 待機時間の定義（通常モード: 分を秒に換算、テストモード: 秒単位で動作）
if [[ "$TEST_MODE" -eq 1 ]]; then
    echo "[TEST MODE] 1分を1秒に短縮して動作テストを行います。"
    TIME_30=30
    TIME_60=60
    TIME_75=75
    TIME_85=85
    TIME_95=95
    CHECK_INTERVAL=1
else
    TIME_30=$((30 * 60))
    TIME_60=$((60 * 60))
    TIME_75=$((75 * 60))
    TIME_85=$((85 * 60))
    TIME_95=$((95 * 60))
    CHECK_INTERVAL=5
fi

# サウンド再生関数
play_sound() {
    local sound_type="$1" # info or warning
    local wav_file="$SOUNDS_DIR/${sound_type}.wav"

    # バックグラウンドで再生を実行（メインタイマーを止めない）
    (
        local played=0

        # 1. paplay (PulseAudio - Linux Mint標準)
        if command -v paplay >/dev/null 2>&1 && [[ -f "$wav_file" ]]; then
            [[ "$TEST_MODE" -eq 1 ]] && echo "[TEST:SOUND] paplay で $wav_file を再生します..."
            if paplay "$wav_file" 2>/dev/null; then
                played=1
            fi
        fi

        # 2. pw-play (PipeWire - PipeWire環境)
        if [[ "$played" -eq 0 ]] && command -v pw-play >/dev/null 2>&1 && [[ -f "$wav_file" ]]; then
            [[ "$TEST_MODE" -eq 1 ]] && echo "[TEST:SOUND] pw-play で $wav_file を再生します..."
            if pw-play "$wav_file" 2>/dev/null; then
                played=1
            fi
        fi

        # 3. aplay (ALSA - 全Linux環境で標準搭載のWAV再生コマンド)
        if [[ "$played" -eq 0 ]] && command -v aplay >/dev/null 2>&1 && [[ -f "$wav_file" ]]; then
            [[ "$TEST_MODE" -eq 1 ]] && echo "[TEST:SOUND] aplay で $wav_file を再生します..."
            if aplay -q "$wav_file" 2>/dev/null; then
                played=1
            fi
        fi

        # 4. canberra-gtk-play (テーマ音フォールバック)
        if [[ "$played" -eq 0 ]] && command -v canberra-gtk-play >/dev/null 2>&1; then
            [[ "$TEST_MODE" -eq 1 ]] && echo "[TEST:SOUND] canberra-gtk-play でテーマ音を再生します..."
            if [[ "$sound_type" == "warning" ]]; then
                canberra-gtk-play -i "dialog-warning" 2>/dev/null || true
            else
                canberra-gtk-play -i "message" 2>/dev/null || true
            fi
            played=1
        fi

        # 5. システムベル（最終手段）
        if [[ "$played" -eq 0 ]]; then
            [[ "$TEST_MODE" -eq 1 ]] && echo "[TEST:SOUND] システムベルを鳴らします..."
            echo -e "\a"
        fi
    ) &
}

# ダイアログ表示関数（常に最前面＆バックグラウンドで起動し、タイマーを止めない）
show_dialog() {
    local dialog_type="$1" # info or warning
    local title="$2"
    local message="$3"

    # サウンドの再生
    play_sound "$dialog_type"

    # ダイアログ表示サブプロセス（バックグラウンド実行）
    (
        if [[ -f "$DIALOG_SCRIPT" ]] && command -v python3 >/dev/null 2>&1; then
            # GTKネイティブの最前面ダイアログ（set_keep_above(True)）
            python3 "$DIALOG_SCRIPT" "$dialog_type" "$title" "$message" 2>/dev/null || true
        else
            # zenity フォールバック
            zenity "--$dialog_type" \
                --title="$title" \
                --text="$message" \
                --ok-label="OK" \
                --modal \
                --width=360 2>/dev/null || true
        fi
    ) &
}

# シャットダウン処理関数
do_shutdown() {
    if [[ "$TEST_MODE" -eq 1 ]]; then
        echo "[TEST MODE] 95分到達。テストのためシャットダウンは行いません。"
        play_sound "info"
        if [[ -f "$DIALOG_SCRIPT" ]] && command -v python3 >/dev/null 2>&1; then
            python3 "$DIALOG_SCRIPT" "info" "テスト完了" "[テスト完了] ここで電源が自動で切れます。" 2>/dev/null || true
        else
            zenity --info \
                --title="テスト完了" \
                --text="[テスト完了] ここで電源が自動で切れます。" \
                --ok-label="OK" \
                --modal 2>/dev/null || true
        fi
    else
        echo "時間制限（95分）に達したためシャットダウンを実行します。"
        systemctl poweroff 2>/dev/null || shutdown -h now 2>/dev/null || true
    fi
}

START_TIME=$(date +%s)
FLAG_30=0
FLAG_60=0
FLAG_75=0
FLAG_85=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # 30分通知
    if [[ "$FLAG_30" -eq 0 && "$ELAPSED" -ge "$TIME_30" ]]; then
        FLAG_30=1
        show_dialog "info" "じかんのおしらせ" "30分たったよ。休憩時間（きゅうけいじかん）だよ。遠く（とおく）をみてね。"
    fi

    # 60分通知
    if [[ "$FLAG_60" -eq 0 && "$ELAPSED" -ge "$TIME_60" ]]; then
        FLAG_60=1
        show_dialog "info" "じかんのおしらせ" "1時間（じかん）たったよ。もうそろそろ、おわる時間（じかん）だよ。"
    fi

    # 75分通知
    if [[ "$FLAG_75" -eq 0 && "$ELAPSED" -ge "$TIME_75" ]]; then
        FLAG_75=1
        show_dialog "warning" "じかんのおしらせ" "まだおわらないの？自動（じどう）で電源（でんげん）けしちゃうよ！"
    fi

    # 85分通知
    if [[ "$FLAG_85" -eq 0 && "$ELAPSED" -ge "$TIME_85" ]]; then
        FLAG_85=1
        show_dialog "warning" "じかんのおしらせ" "早くおわって！！もうすぐけしちゃうからね！！"
    fi

    # 95分自動シャットダウン
    if [[ "$ELAPSED" -ge "$TIME_95" ]]; then
        do_shutdown
        break
    fi

    sleep "$CHECK_INTERVAL"
done
