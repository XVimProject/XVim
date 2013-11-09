# XVim
  XVimはXcode用Vimプラグインです。XVimはXcodeの機能を損なうことなく、Vimの操作感を提供することを目指しています。

#### アナウンス
  [XVim開発者向けGoogleグループ](https://groups.google.com/d/forum/xvim-developers) が作成されました。
  
  このグループはXVimの開発者とテスター、報告者向けのものです。
  XVimプロジェクトのお手伝いをしてみたいという方がいましたらご参加ください。
  新しいリリースのテストや、問題の報告だけでも非常に助かります。気軽にご参加ください。

## サポートしているXcodeバージョン
  - Xcode4.6
  - Xcode5

## インストール
 - ソースコードをダウンロードし、XVim.xcodeprojをXcodeで開きます。("ブランチとリリース"の節も参照)
 - 利用するXcodeバージョンに合ったスキームを選択します
    - XVim for Xcode4はXcode4.6でビルドしてください
    - XVim for Xcode5はXcode5でビルドしてください
 - "Edit Scheme"を選択し"Build Configuration"を"Release"に設定します
 - ビルドする。このとき自動的に正しいディレクトリにプラグインがインストールされます
 - Xcodeを再起動します。（Xcodeプロセスを完全に終了させてください。）

## ブランチとリリース
 XVimにはいくつかのブランチとリリースがあります。通常はリリースの一つをダウンロードし、利用してください。
 以下はそれぞれのリリースとブランチの説明です。

 - リリース(タグ) : リリースはマスターブランチ上のtagです。これらのtag上のコード、ドキュメント類はすべて整った状態になっています。通常のXVimユーザーであればリリースの一つをご利用ください。
 - masterブランチ : 最も安定したブランチです。致命的なバグや、'develop'ブランチで開発された機能が'master'ブランチにマージされます。リリースに致命的なバグがある場合には最新の'master'を試してみてください。
 - developブランチ: 新たな機能や致命的でないバグはこのブランチにマージされます。試験的な機能を利用したい場合にはこのブランチを人用してください。

 他のブランチは'develop'ブランチにマージされる一時的な開発やバグ修正用のものです。Pull Requestは'develop'ブランチにするようにしてください。


## アンインストール
  以下のディレクトリを削除してください

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim.xcplugin

## 機能一覧
  別ファイルを参照ください。[FeatureList.md](https://github.com/JugglerShu/XVim/blob/master/Documents/Users/FeatureList.md)

## バグ報告
  残念ながらXVim影響でXcodeがクラッシュしてしまうことがあります。すべてのバグを取り除こうとしていますが、非常に難しいのが現状です。
  以下の情報のバグレポートがあると非常に助かります。

   * クラッシュ情報( クラッシュ時にスタックトレースが表示されます。それをコピーしてください。)
   * クラッシュ時の操作(一連のキー操作やクリック)
   * 編集していたテキスト
   * Xcodeのバージョン
   * XVimのバージョン(リリースバージョンやコミットの番号)
  
  もし上記情報で問題の難しい場合には以下の動画に従ってデバッグログの取得をお願いするかもしれません。
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)


  テストケースを書いていただけるとさらに助かります。Documents/Developsers/PullRequest.md hの"Write test"セクションにテストケースの書き方が書かれています。ソースコードを修正する必要はなくここで説明されている7つの項目をIssueに書くだけです。

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

  Pull Requestしていただけると非常にありがたいです。Pull Requstを行う前に、[Make a Pull Request](https://github.com/JugglerShu/XVim/blob/master/Documents/Developers/PullRequest.md)
をご一読ください。

## 寄付
  もし、このプラグインを気に入っていただけたら寄付をしていただけると嬉しいです。
  もともとこのプロジェクトはお金を稼ぐために始めたものではないため、すべての寄付は2011年の東北大震災の被災者の方々へそのまま寄付することとしています。

  寄付は、以下のURLから直接お願いします。こちらを一度経由すると手数料がかかってしまうため、このようにしています。

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  上記Paypalリンクから寄付を行った場合、こちらにはなんのメッセージも送信されません。以下のメッセージボードに寄付した旨を書いていただけると、私を含めコントリビュータのモチベーションに繋がります。

  [Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim )

## コントリビュータ
  以下のコントリビュータのページを御覧ください

  https://github.com/JugglerShu/XVim/contributors

## ライセンス
  MIT License

