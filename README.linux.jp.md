# Linuxで `antigravity-oauth-token` を生成する

[English](./README.linux.md) · [メインREADMEに戻る](./README.ja.md)

`agy` は、D-Bus Secret Service(GNOME Keyring / KWallet)に到達できない場合、
自動的にサインイン情報を単純なJSONファイルへ保存します。ほとんどのLinuxデスクトップには
これらが動いているため、確実にファイルフォールバックを発生させる一番安全な方法は、
キーリングが一切存在しない最小構成のコンテナを使うことです——これは本skillが
Claude自身のサンドボックス内で使っているのと同じ環境です。

## 方法A — Docker(推奨・動作確認済み)

```bash
docker run --rm -it -v "$PWD":/out debian:bookworm-slim bash
```

コンテナの中で:

```bash
apt-get update && apt-get install -y curl ca-certificates
curl -fsSL https://antigravity.google/cli/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
agy
```

`agy` の初回起動画面が表示され、サインイン方法を選ぶよう求められます。
**1. Google OAuth** を選んでください。認可URLが表示されるので、それを
(手元のPC、スマホなど)好きなブラウザで開き、Googleアカウントでログインすると、
表示先のページに短いコードが出てきます。それを `agy` のプロンプトに貼り戻してください。

サインインが完了したら("Welcome to Antigravity CLI!" が見えた時点でトークンは
すでに書き込まれているので、そこでCtrl+Cで抜けて問題ありません)、マウントした
フォルダにファイルをコピーします:

```bash
cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
```

ホスト側に戻ると、`docker run` を実行したディレクトリに
`antigravity-oauth-token` ができています。

## 方法B — キーリングの無い素のLinux環境

ヘッドレスサーバーや、GNOME Keyring/KWalletの無い最小構成のウィンドウマネージャ環境、
あるいは一時的にセッションバスを外すことに抵抗が無ければ、Dockerを使わずに済ませられます:

```bash
env -u DBUS_SESSION_BUS_ADDRESS bash -c '
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  agy
'
```

ディストリビューションによっては別経路でセッションバスを再検出することがあるため、
確実とは限りません。実行後に `agy -p "hi"` が再びサインインを求めてくる場合は、
方法Aに切り替えてください。

## うまくいったか確認する

ファイルをどこかにコピーする前に、その場でヘッドレスモードが動くか確認してください:

```bash
agy -p "reply with just the word ok"
```

再度のサインイン要求なしに `ok` とだけ返ってくれば成功です。

## このファイルの使い道

自分だけの非公開なこのskillのコピーの中の、以下の場所に配置してください:

```
skills/antigravity-bridge-skill/auth/antigravity-oauth-token
```

