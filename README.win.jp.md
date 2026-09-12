# Windowsで `antigravity-oauth-token` を生成する

[English](./README.win.md) · [メインREADMEに戻る](./README.ja.md)

Windowsネイティブ環境では、`agy` はサインイン情報を **Windows資格情報マネージャー**
に保存します。これは持ち運び可能なファイルではなく、そのPC・Windowsアカウントに
紐付いているため、他の環境にコピーして使うことはできません。本skillが必要とする
素のJSONファイルを得るには、Claude自身のサンドボックスと同じように、キーリングに
到達できないLinux環境の中で `agy` を動かす必要があります。

## 方法A — Docker Desktop(推奨・動作確認済み)

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   をまだ入れていなければインストールし、起動しておきます。
2. PowerShellまたはコマンドプロンプトを、ファイルが置かれても構わないフォルダで開き、
   次を実行します:

   ```powershell
   docker run --rm -it -v "${PWD}:/out" debian:bookworm-slim bash
   ```

3. 開いたコンテナの中で:

   ```bash
   apt-get update && apt-get install -y curl ca-certificates
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   export PATH="$HOME/.local/bin:$PATH"
   agy
   ```

4. `agy` の初回起動画面が出ます。**1. Google OAuth** を選んでください。認可URLが
   表示されるので、ブラウザで開いてGoogleアカウントでログインし、表示先のページに出る
   短いコードを `agy` のプロンプトに貼り戻します。

5. "Welcome to Antigravity CLI!" が表示された時点で、トークンファイルはすでに
   存在しています。マウントしたフォルダにコピーします:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
   ```

6. Windows側に戻ると、`docker run` を実行したフォルダに
   `antigravity-oauth-token` ができています。

## 方法B — WSL2(Ubuntu)、Dockerなし

すでにWSL2上に素のUbuntu(`wsl --install -d Ubuntu`)があり、
`/etc/wsl.conf` で `systemd=true` を有効にしていなければ、通常D-Busセッションは
動いておらず、同じファイルフォールバックが得られるはずです。この経路は方法Aほど
十分には検証していません——`agy -p "hi"` が実行後もサインインを求めてくる場合は、
Dockerの方法に切り替えてください。

1. Ubuntu WSLのターミナルを開きます。
2. 上と同じ `curl ... | bash` と `agy` の手順を実行します。
3. できたファイルをWindows側から見える場所にコピーします:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /mnt/c/Users/<あなたのユーザー名>/antigravity-oauth-token
   ```

## うまくいったか確認する

ファイルをどこかにコピーする前に、その場でヘッドレスモードが受け付けるか確認してください:

```bash
agy -p "reply with just the word ok"
```

再度のサインイン要求なしに `ok` とだけ返ってくれば成功です。

## このファイルの使い道

自分だけの非公開なこのskillのコピーの中の、以下の場所に配置してください:

```
skills/antigravity-bridge-skill/auth/antigravity-oauth-token
```

