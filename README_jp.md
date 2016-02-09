# XVim
  XVimはXcode用Vimプラグインです。XVimはXcodeの機能を損なうことなく、Vimの操作感を提供することを目指しています。

#### アナウンス
  - XVimのリポジトリはXVimProject organizationに移されました。リポジトリをクローンしている場合は、[こちら][github-transferring]にあるようにリモートリポジトリのURLを変更することをお勧めします (Github では、古いURLから新しいURLへ丁寧な転送が行われており、この対応は必須ではありません)。
  - XVimではBountysourceを利用しはじめしました。[![Bountysource][bountysource-bouties-badge]][bountysource-bouties] [![Bountysource][bountysource-raised-badge]][bountysource-raised]
  - [XVim開発者向けGoogleグループ][google-group] が作成されました。

[github-transferring]: https://help.github.com/articles/transferring-a-repository/
[bountysource-bouties-badge]: https://www.bountysource.com/badge/team?team_id=918&style=bounties_posted
[bountysource-bouties]: https://www.bountysource.com/teams/xvim/bounties?utm_source=XVim&utm_medium=shield&utm_campaign=bounties_posted
[bountysource-raised-badge]: https://www.bountysource.com/badge/team?team_id=918&style=raised
[bountysource-raised]: https://www.bountysource.com/teams/xvim?utm_source=XVim&utm_medium=shield&utm_campaign=raised
[google-group]: https://groups.google.com/d/forum/xvim-developers

## サポートしているXcodeバージョン
  - Xcode6
  - Xcode7

## インストール
  ソースコードをダウンロード、あるいはリポジトリをクローンし、以下を実行します。

  ```bash
  $ make
  ```

  必要に応じて `.xvimrc` を作成し、Xcodeを再起動します。

## ブランチとリリース
 XVimにはいくつかのブランチとリリースがあります。通常はリリースの一つをダウンロードし、利用してください。
 以下はそれぞれのリリースとブランチの説明です。

 - リリース(タグ) : リリースはマスターブランチ上のtagです。これらのtag上のコード、ドキュメント類はすべて整った状態になっています。通常のXVimユーザーであればリリースの一つをご利用ください。
 - masterブランチ : 最も安定したブランチです。致命的なバグの修正や、'develop'ブランチで開発された機能が'master'ブランチにマージされます。リリースに致命的なバグがある場合には最新の'master'を試してみてください。
 - developブランチ: 新たな機能や致命的でないバグの修正はこのブランチにマージされます。試験的な機能を利用したい場合にはこのブランチを使用してください。

 他のブランチは'develop'ブランチにマージされる一時的な開発やバグ修正用のものです。Pull Requestは'develop'ブランチにするようにしてください。


## アンインストール
  ```bash
  $ make uninstall
  ```

### 手動でのアンインストール
  以下のディレクトリを削除してください

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin

## 機能一覧
  別ファイルを参照ください。[FeatureList.md](Documents/Users/FeatureList.md)

## バグ報告
  残念ながらXVim影響でXcodeがクラッシュしてしまうことがあります。すべてのバグを取り除こうとしていますが、非常に難しいのが現状です。
  以下の情報のバグレポートがあると非常に助かります。

   * クラッシュ情報(クラッシュ時にスタックトレースが表示されます。それをコピーしてください。)
   * クラッシュ時の操作(一連のキー操作やクリック)
   * 編集していたテキスト
   * Xcodeのバージョン
   * XVimのバージョン(リリースバージョンやコミットの番号)
  
  もし上記情報で問題の難しい場合には以下の動画に従ってデバッグログの取得をお願いするかもしれません。
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)


  テストケースを書いていただけるとさらに助かります。Documents/Developsers/PullRequest.md hの"Write test"セクションにテストケースの書き方が書かれています。ソースコードを修正する必要はなくここで説明されている7つの項目をIssueに書くだけです。

## Bountysource
  XVimでは、Bountysourceを利用しています。
  Issue をなるべく早く解決したい場合、賞金をかけることは一つの選択肢になるでしょう。
  (必ずしも保障はされませんが) コントリビューターは賞金のかかったIssueに優先的に対応します。
  賞金をかけるには、以下のリンク先の"Issues"タブへ進み、対象のIssueを選択します。

  https://www.bountysource.com/teams/xvim

## バグIssueの取り扱い

  報告されたバグは以下の順で処理されます。

  1. バグの再現性が確認され、'Bug'というラベルが付けれらます。
  2. バグが'develop'ブランチで修正されます
  3. 報告者によってバグが修正されたことが確認されます。
  4. Issueに'Done'というラベルが付けられます。
  5. バグ修正が他に副作用がないことを確認します。
  6. 'master'ブランチにマージされます
  7. IssueがCloseされます。

  この手順は'Bug' issueにのみ適用されます。


## コントリビューション
  提案や、バグの報告、機能要望は遠慮無くお寄せください。

  もし、自分で機能追加やバグの修正をしたい場合には、以下の動画が参考になります。
  
 - [How to get debug log](http://www.youtube.com/watch?v=50Bhu8setlc)
 - [How to debug XVim](http://www.youtube.com/watch?v=AbC6f86VW9A)
 - [How to write a test case](http://www.youtube.com/watch?v=kn-kkRTtRcE)

  Pull Requestしていただけると非常にありがたいです。Pull Requstを行う前に、[Make a Pull Request](Documents/Developers/PullRequest.md)
をご一読ください。

## 寄付
  もし、このプラグインを気に入っていただけたら寄付をしていただけると嬉しいです。
  寄付方法は、「東北地方太平洋沖地震」からの復興支援もしくはXVimProjectへのBountySource経由での支援の二種類があります
  (もちろん両方も選択することもできます)。

### 東北地方太平洋沖地震

  もともとこのプロジェクトはお金を稼ぐために始めたものではないため、
  2011年の東北地方太平洋沖地震の被災者の方々へそのまま寄付しています。

  寄付は、以下のURLから直接お願いします。
  こちらを一度経由すると手数料がかかってしまうため、このようにしています。

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  上記Paypalリンクから寄付を行った場合、こちらにはなんのメッセージも送信されません。
  [メッセージボード][donation-messageboard]に寄付した旨を書いていただけると、
  私を含めコントリビュータのモチベーションに繋がります。

  [donation-messageboard]: https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim

### Bountysource
  BountySourceでは、チーム (プロジェクト全体) を支援したり、あるいは特定のIssueに賞金をかけることができます
  (もし、修正して欲しいバグや実装して欲しい機能がIssueとして存在していなければ、新たにIssueを作成してください)。

## コントリビュータ
  以下のコントリビュータのページを御覧ください

  https://github.com/JugglerShu/XVim/contributors

## ライセンス
  MIT License

