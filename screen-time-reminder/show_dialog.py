#!/usr/bin/env python3
"""
show_dialog.py
Linux Mint (GTK3) 環境で確実に「常に最前面（Keep on Top）」でダイアログを表示するスクリプト。
追加パッケージ不要（Linux Mint標準搭載の python3-gi / GTK3 を使用）。
"""

import sys

def show_gtk_dialog(dialog_type, title, message):
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk

    msg_type = Gtk.MessageType.WARNING if dialog_type == "warning" else Gtk.MessageType.INFO

    dialog = Gtk.MessageDialog(
        flags=Gtk.DialogFlags.MODAL,
        type=msg_type,
        buttons=Gtk.ButtonsType.OK,
        message_format=title
    )
    dialog.format_secondary_text(message)

    # 1. 常に最前面（他のウィンドウをクリックしても背面に隠れない）
    dialog.set_keep_above(True)

    # 2. 画面中央に配置
    dialog.set_position(Gtk.WindowPosition.CENTER_ALWAYS)

    # 3. 仮想デスクトップを切り替えても追従
    dialog.stick()

    # 4. 最前面にアクティブ化
    dialog.present()

    dialog.run()
    dialog.destroy()

def main():
    dialog_type = sys.argv[1] if len(sys.argv) > 1 else "info"
    title = sys.argv[2] if len(sys.argv) > 2 else "じかんのおしらせ"
    message = sys.argv[3] if len(sys.argv) > 3 else ""

    try:
        show_gtk_dialog(dialog_type, title, message)
    except Exception as e:
        # 万が一GTK呼び出しで失敗した場合は zenity にフォールバック
        import subprocess
        cmd = [
            "zenity",
            f"--{dialog_type}",
            f"--title={title}",
            f"--text={message}",
            "--ok-label=OK",
            "--width=360"
        ]
        subprocess.run(cmd)

if __name__ == "__main__":
    main()
