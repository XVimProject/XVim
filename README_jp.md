# !!!Xcode 9 は(まだ)サポートされていません!!!

# XVim [![Build Status](https://travis-ci.org/XVimProject/XVim.svg?branch=master)](https://travis-ci.org/XVimProject/XVim) [![Bountysource](https://www.bountysource.com/badge/team?team_id=918&style=bounties_posted)](https://www.bountysource.com/teams/xvim/bounties?utm_source=XVim&utm_medium=shield&utm_campaign=bounties_posted) [![Bountysource](https://www.bountysource.com/badge/team?team_id=918&style=raised)](https://www.bountysource.com/teams/xvim?utm_source=XVim&utm_medium=shield&utm_campaign=raised)

  XVimはXcode用Vimプラグインです。XVimはXcodeの機能を損なうことなく、Vimの操作感を提供することを目指しています。

#### アナウンス

  - Xcode 8 ユーザーは [INSTALL_Xcode8.md](INSTALL_Xcode8.md) をご覧ください。
  - Xcode 7 ユーザーは 809527b 以前のコミットを使ってください。
  - XVimではBountysourceを利用しはじめました。
  - [XVim開発者向けGoogleグループ]((https://groups.google.com/d/forum/xvim-developers) が作成されました。

## サポートしているXcodeバージョン
  - Xcode7  : 809527b 以前のコミットを使用してください。
  - Xcode8  : 最新のmasterブランチを使用してください。

## インストール
  Xcode 8 ユーザーは、まず [INSTALL_Xcode8.md](INSTALL_Xcode8.md) の説明書きに従ってください。

  ソースコードをダウンロード、あるいはリポジトリをクローンし、以下を実行します。

  1. `xcode-select` があなたのXcodeを示していることを確認してください。
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```

  Xcodeのアプリケーションパスが表示されない場合は、 `xcode-select -s` を使って設定してください。

  2. makeします。
  ```bash
  $ make
  ```

  以下のように表示されたら

  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk?
  ```
  あなたのXcodeバージョンでXVimを使用したい場合は、yを押します。(それが動作確認されていなくても)

  3. 必要であれば `.xvimrc` を作り、Xcodeを再起動します。

  4. Xcodeを起動します。 XVimを読み込むかどうか尋ねられます。「Yes」を選択してください。
     間違って「No」を押した場合、Xcodeを閉じてターミナルから次のコマンドを実行します。

    ```
    defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.X はXcodeのバージョンです)
    ```

     Xcodeを再度開いてください。

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

## コントリビューション
  分割された [CONTRIBUTING.md](.github/CONTRIBUTING.md) をご覧ください。

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
プロジェクトを手助けして拡張したいのであれば、 [BountySource](https：//www.bountysource.com/teams/xvim)を通じて直接支援することを検討してください。 チーム (プロジェクト全体) を支援したり、あるいは特定のIssueに賞金をかけることができます。(もし、修正して欲しいバグや実装して欲しい機能がIssueとして存在していなければ、新たにIssueを作成してください)。

## コントリビュータ
  以下のコントリビュータのページを御覧ください
  https://github.com/JugglerShu/XVim/contributors

## ライセンス
  MIT License

