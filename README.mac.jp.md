# macOSで `antigravity-oauth-token` を生成する

[English](./README.mac.md) · [メインREADMEに戻る](./README.ja.md)

macOSネイティブ環境では、`agy` はサインイン情報を **キーチェーン** に保存します。
これは持ち運び可能なファイルではなく、そのMac・macOSアカウントに紐付いているため、
他の環境にコピーして使うことはできません。本skillが必要とする素のJSONファイルを得るには、
Claude自身のサンドボックスと同じように、キーリングに到達できないLinuxコンテナの中で
`agy` を動かす必要があります。

## Docker Desktop(推奨・動作確認済み)

1. [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
   (軽量なCLIのみの構成が良ければColimaでも可)をインストールし、起動しておきます。
2. ターミナルを、ファイルが置かれても構わないフォルダで開き、次を実行します:

   ```bash
   docker run --rm -it -v "$PWD":/out debian:bookworm-slim bash
   ```

3. 開いたコンテナの中で:

   ```bash
   apt-get update && apt-get install -y curl ca-certificates
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   export PATH="$HOME/.local/bin:$PATH"
   agy
   ```

4. `agy` の初回起動画面が出ます。**1. Google OAuth** を選んでください。認可URLが
   表示されるので、Mac側のブラウザで開いてGoogleアカウントでログインし、表示先の
   ページに出る短いコードを `agy` のプロンプトに貼り戻します。

5. "Welcome to Antigravity CLI!" が表示された時点で、トークンファイルはすでに
   存在しています。マウントしたフォルダにコピーします:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
   ```

6. macOS側に戻ると、`docker run` を実行したフォルダ(ターミナルの作業ディレクトリ)に
   `antigravity-oauth-token` ができています。

WindowsにおけるWSLのような、キーリング無しの軽量な代替経路は素のmacOSには
ありません——キーチェーンへのアクセスは、macOSネイティブなプロセスからは事実上
常に可能なためです。そのためここではLinuxコンテナが確実な方法になります。

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
