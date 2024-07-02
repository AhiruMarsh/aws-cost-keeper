# notify-aws-cost
AWSの使用料金を日次でDiscordに送信
![動作例](docs/image.png)

## 依存関係
* AWS側でOpenID Connect設定を事前実施  
  https://docs.github.com/ja/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## フォルダ・ファイル構成
* `.github/workflows/` GitHub Actionsのワークフロー設定
* `app/` アプリ本体
* `tests/` ワークフロー中のテストシナリオ

## 処理の流れ (ワークフロー設定)
1. `main`ブランチへのプッシュをトリガーにGitHub Actionsのワークフローが起動
2. 初期設定 (Python/AWS CLI/AWS資格情報取得)
3. テスト実行
4. (テストが成功した場合) ビルド実行 (SAM)
5. (ビルドが成功した場合) デプロイ実行 (SAM)
