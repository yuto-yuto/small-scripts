# スクリーンタイム通知＆自動シャットダウン (screen-time-reminder)

Linux Mint環境において、ログインからの経過時間を監視し、確認ダイアログ（OKボタンのみ）を表示して95分後に自動で電源を切るスクリプトです。

## 構成ファイル

- [screen-time-reminder.sh](file:///home/yuto/root/development/small-scripts/screen-time-reminder/screen-time-reminder.sh): 監視・通知・サウンド再生・シャットダウンを行う本体スクリプト
- [show_dialog.py](file:///home/yuto/root/development/small-scripts/screen-time-reminder/show_dialog.py): Linux Mint標準のGTK3ネイティブで「常に最前面（Keep on Top）」ダイアログを表示するスクリプト
- [install.sh](file:///home/yuto/root/development/small-scripts/screen-time-reminder/install.sh): 自動起動への登録／解除を行うインストーラースクリプト
- [create_sounds.py](file:///home/yuto/root/development/small-scripts/screen-time-reminder/create_sounds.py): 通知音（info.wav）および警告音（warning.wav）を生成する補助スクリプト

## 特徴

1. **確実に「常に最前面（Keep on Top）」に表示**:
   - Linux Mint標準の GTK3（`set_keep_above(True)`）を使用し、他のアプリをクリックしても絶対に背面に隠れないダイアログを表示します。
   - 画面中央への配置およびアクティブ化（フォーカス取得）も行われます。
2. **確実なサウンド通知**:
   - 専用の通知音（`info.wav`）および警告音（`warning.wav`）をスクリプト側で自動生成・保持。
   - デスクトップのテーマ効果音設定が無効化されていても、オーディオ出力（`paplay` / `pw-play` / `aplay`）へ直接音声を送るため確実に鳴ります。
   - 75分後・85分後の警告ダイアログでは注意を引くため警告音を再生します。
3. **タイマーの非同期化**:
   - ダイアログを閉じずに放置しても、経過時間通りに次のダイアログが表示され、95分後に確実にシャットダウンします。
4. **テストモード機能 (`--test`)**:
   - 1分を1秒に短縮して実際の挙動を安全に確認できます。テスト実行時には、どの音声再生コマンドが使われたかのログもターミナルに表示されます。

## 通知・動作スケジュール

| 経過時間 | 通知ダイアログの内容 | サウンド | 動作 |
|---|---|---|---|
| **30分後** | 30分たったよ。休憩時間（きゅうけいじかん）だよ。遠く（とおく）をみてね。 | 情報通知音（info.wav） | 常に最前面の情報ダイアログ |
| **60分後** | 1時間（じかん）たったよ。もうそろそろ、おわる時間（じかん）だよ。 | 情報通知音（info.wav） | 常に最前面の情報ダイアログ |
| **75分後** | まだおわらないの？自動（じどう）で電源（でんげん）けしちゃうよ！ | 警告音（warning.wav） | 常に最前面の警告ダイアログ |
| **85分後** | 早くおわって！！もうすぐけしちゃうからね！！ | 警告音（warning.wav） | 常に最前面の警告ダイアログ |
| **95分後** | - | - | 自動シャットダウン (`systemctl poweroff`) |

## 使い方

### 1. インストール（自動起動に登録）

本ディレクトリで以下を実行します：

```bash
chmod +x install.sh
./install.sh
```

これで `~/.config/autostart/screen-time-reminder.desktop` が作成され、次回ログイン時から自動的に開始されます。

### 2. 動作確認（テストモード）

短縮時間（1分＝1秒）で動作確認ができます。95秒到達時もテスト用のダイアログが表示され、実際の電源OFFは行われません。

```bash
./screen-time-reminder.sh --test
```

### 3. アンインストール（自動起動の解除）

自動起動を解除したい場合は、以下を実行してください：

```bash
./install.sh --uninstall
```
