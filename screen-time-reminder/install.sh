#!/usr/bin/env bash
#
# install.sh
# スクリーンタイム通知スクリプトのインストーラー / アンインストーラー
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/screen-time-reminder.sh"
CREATE_SOUNDS_SCRIPT="$SCRIPT_DIR/create_sounds.py"
SHOW_DIALOG_SCRIPT="$SCRIPT_DIR/show_dialog.py"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/screen-time-reminder.desktop"

# アンインストール処理
if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
    echo "スクリーンタイムリマインダーをアンインストールしています..."
    if [[ -f "$DESKTOP_FILE" ]]; then
        rm -f "$DESKTOP_FILE"
        echo "自動起動エントリ ($DESKTOP_FILE) を削除しました。"
    else
        echo "自動起動エントリは登録されていませんでした。"
    fi

    # 実行中のプロセスがあれば終了
    if pgrep -f "$TARGET_SCRIPT" >/dev/null 2>&1; then
        echo "実行中のリマインダープロセスを停止しています..."
        pkill -f "$TARGET_SCRIPT" || true
    fi

    echo "アンインストールが完了しました。"
    exit 0
fi

# インストール処理
echo "スクリーンタイムリマインダーをインストール（自動起動に登録）します..."

# 実スクリプトの存在確認
if [[ ! -f "$TARGET_SCRIPT" ]]; then
    echo "エラー: 対象のスクリプト ($TARGET_SCRIPT) が見つかりません。" >&2
    exit 1
fi

# 実行権限の付与
chmod +x "$TARGET_SCRIPT"
if [[ -f "$CREATE_SOUNDS_SCRIPT" ]]; then
    chmod +x "$CREATE_SOUNDS_SCRIPT"
fi
if [[ -f "$SHOW_DIALOG_SCRIPT" ]]; then
    chmod +x "$SHOW_DIALOG_SCRIPT"
fi
echo "実スクリプトに実行権限を付与しました: $TARGET_SCRIPT"

# 音声ファイルの事前生成
if command -v python3 >/dev/null 2>&1 && [[ -f "$CREATE_SOUNDS_SCRIPT" ]]; then
    python3 "$CREATE_SOUNDS_SCRIPT" "$SOUNDS_DIR" >/dev/null 2>&1 || true
    echo "通知用サウンドファイルを準備しました。"
fi

# 自動起動ディレクトリの作成
mkdir -p "$AUTOSTART_DIR"

# .desktop ファイルの作成
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Screen Time Reminder
Comment=スクリーンタイム通知＆自動電源OFF
Exec=$TARGET_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Terminal=false
Categories=Utility;
EOF

chmod 644 "$DESKTOP_FILE"

echo "------------------------------------------------------------"
echo "インストールが完了しました！"
echo "Linux Mint に次回ログインした際、自動的にバックグラウンドで開始されます。"
echo "自動起動ファイル: $DESKTOP_FILE"
echo ""
echo "【動作確認方法（テストモード）】"
echo "1分を1秒に短縮して動作確認できます:"
echo "  $TARGET_SCRIPT --test"
echo ""
echo "【アンインストール方法】"
echo "自動起動を解除したい場合は以下を実行してください:"
echo "  $SCRIPT_DIR/install.sh --uninstall"
echo "------------------------------------------------------------"
