# antigravity-bridge-skill

[English README](./README.md)

Claude(モバイル版・Web版・その他サンドボックス環境で動くClaude全般)から、
Google の **Antigravity CLI**(`agy`)を自分自身の **Antigravityサブスクリプションのサインイン**
経由で呼び出せるようにする Claude Agent Skill です。APIキーは一切使用しません。

[`codex-bridge-skill`](https://github.com/mokouliszt/codex-bridge-skill) と同じ設計思想を、
`agy` の OAuthフロー・ファイルベースの認証情報保存方式に合わせて作り直したものです。

## できること

- Claudeのサンドボックス内に、必要なタイミングで公式の `agy` バイナリをインストールします。
- 自分のマシンで一度だけ生成した小さなJSONトークンファイル(下記のOS別ガイド参照)から、
  Antigravityへのサインイン状態を復元します。
- `agy` を非対話モード(`agy -p "..."`)で実行し、Claudeが質問を投げたり作業を任せたりして、
  結果を受け取れるようにします。
- 長時間かかるタスク向けに、バックグラウンドジョブの仕組みを提供します。Claudeのサンドボックスは
  会話のターンをまたいでプロセスを生かし続けられないためです。

## 意図的にやらないこと

- Antigravity/Gemini の **APIキーは一切使用しません**。認証は常に、`agy` CLI自身が使うのと
  同じ、個人のサブスクリプションのサインイン(OAuth)経由です。
- 自動的には発動しません。ユーザーが明示的にAntigravity/`agy`/このブリッジの利用を指示した
  場合にのみ、Claudeはこのskillを使用します。

## 初回セットアップ:トークンの生成

`agy` は通常、サインイン情報をOSのセキュアなキーリング(Windows資格情報マネージャー、
macOSキーチェーン、LinuxのSecret Service)に保存します。Claudeのサンドボックスにはこれらが
存在しないため、`agy` は自動的に、単純で持ち運び可能なJSONファイルへのフォールバック保存に
切り替わります——ただしこれは、キーリングに到達できない環境でのみ発動します。普段のデスクトップ
環境ではこのフォールバックは基本的に発生しないため、意図的にキーリングが存在しない環境で
トークンファイルを生成する必要があります。

自分のOSに応じたガイドを選んでください:

- [Windows](./README.win.jp.md)
- [macOS](./README.mac.jp.md)
- [Linux](./README.linux.jp.md)

各ガイドの最後に `antigravity-oauth-token` というファイルができます。これを、
**自分だけの非公開な** このskillのコピーの中の
`skills/antigravity-bridge-skill/auth/antigravity-oauth-token` に配置してください

## skillの導入手順

1. このリポジトリをダウンロードまたはクローンします。
2. `skills/antigravity-bridge-skill/` を、自分のClaude環境がskillを読み込む場所に配置します。
3. 生成した `antigravity-oauth-token` ファイルを、そのskillの `auth/` フォルダに
   (プレースホルダーを置き換える形で)配置します。
4. 会話の中で、Antigravity CLI / `agy` / このブリッジの利用を明示的にClaudeへ指示します。

## セキュリティに関する注意

- このskillは、シェルコマンドを含むすべてのツール呼び出しを、一件ごとの確認なしに
  自動承認するよう `agy` を設定します(`--dangerously-skip-permissions`)。これは本skillの
  ために意図的に選んだ設定です——使う前に意味を理解してください。`agy` は、自分が実行すべきと
  判断したコマンドを、人の確認なしにClaudeのサンドボックス内で実行します。
- `antigravity-oauth-token` ファイルは、あなたのGoogleアカウントに対する
  生きた認証情報です(Antigravityのconsumer OAuthスコープ。`cloud-platform` を含みます)。
  パスワードと同じように扱ってください。`.gitignore` によりバージョン管理からは除外されて
  いますが、それを維持してください。
- このトークンにはリフレッシュトークンが含まれるため、Googleアカウントのサードパーティ
  アクセス設定からアクセスを取り消すまで、アクセストークン自体の短い有効期限を超えて
  使い続けられます。

## ライセンス

MIT — [LICENSE](./LICENSE) を参照してください。
