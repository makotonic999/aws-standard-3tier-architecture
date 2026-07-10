# AWS Standard 3-tier Architecture (IaC)

## 目的・背景
Terraform（IaC）の実務スキルを習得するためのトレーニングプロジェクト。
最終的には「実務で評価される、堅牢なポートフォリオ」として機能する作品にすることを目指している。

ただインフラを構築するだけでなく、ユーザー視点でインフラの仕組み（マルチAZや3層構造）を体感できる
**「リアルタイム・サーバー生存確認掲示板」** というアプリ（FastAPI）を載せて完成させる。

## アプリ仕様
1. 画面トップに、現在アクセスしているECSコンテナのAZ（`ap-northeast-1a` または `1c`）をデカデカと表示する
   - リロードするとALBによって1aと1cが切り替わるのが目に見える
2. フォームからメッセージを入力すると、プライベートサブネットのRDS（MySQL）にデータが保存され、一覧表示される

## 技術スタック
- **IaC**: Terraform (HCL)
- **Cloud**: AWS
- **App**: Python / FastAPI / SQLAlchemy / PyMySQL
- **Container**: Docker / Amazon ECS Fargate / Amazon ECR
- **DB**: Amazon RDS MySQL 8.0
- **CI/CD**: GitHub Actions (OIDC認証)
- **Tool**: Git, Terraform CLI, AWS CLI

## モジュール構成
```
modules/
├── vpc/   # VPC, サブネット, SG, VPCエンドポイント
├── alb/   # Application Load Balancer
├── ecs/   # ECS Fargate, ECR, タスク定義
├── rds/   # RDS MySQL (Multi-AZ)
└── ec2/   # Bastionサーバー
```

## Git運用方針
- `feature/*` ブランチで作業し、節目ごとにGitHubへPush
- 現在のブランチ: `feature/ecs-fargate`

## Amazon Q 引き継ぎ用コンテキスト
次回セッション開始時に以下を伝えると作業をスムーズに再開できる。

- このREADMEを `@README.md` で読み込ませる
- 現在の作業ブランチ・直前の作業内容を伝える
- エラーが出ている場合はターミナルの出力をそのまま貼る

## アーキテクチャ図
```mermaid
graph TD
    %% コンポーネントの定義
    User[👤 User / Internet]
    IGW[Internet Gateway]
    ALB[Application Load Balancer]

    subgraph VPC [VPC]
        %% VPCエンドポイントを中央に配置するためのサブグラフ
        subgraph VPCE [VPC Endpoints]
            ECR_API[ecr.api]
            ECR_DKR[ecr.dkr]
            LOGS[logs]
        end

        %% S3をVPCEの直下に配置
        AWS_S3[(Amazon S3)]

        %% --- 1aのエリア ---
        subgraph AZ_1a [Availability Zone 1a]
            Fargate1[ECS Fargate Task - 1a]
            RDS_1a[(Amazon RDS MySQL - 1a)]
        end
        
        %% --- 1cのエリア ---
        subgraph AZ_1c [Availability Zone 1c]
            Fargate2[ECS Fargate Task - 1c]
            RDS_1c[(Amazon RDS MySQL - 1c)]
        end
    end

    AWS_ECR[(Amazon ECR)]
    AWS_CW[(Amazon CloudWatch)]

    %% --- 通信の流れ ---
    User -->|HTTP port 80| IGW
    IGW --> ALB
    
    ALB -->|HTTP port 8000| Fargate1
    ALB -->|HTTP port 8000| Fargate2

    %% アプリからDBへのセキュアな通信
    Fargate1 -->|MySQL port 3306| RDS_1a
    Fargate2 -->|MySQL port 3306| RDS_1c
    
    %% RDS間のマルチAZ同期
    RDS_1a -. Multi-AZ Replication .-> RDS_1c

    %% 1a, 1c両方からエンドポイントを経由する流れ
    Fargate1 -->|HTTPS port 443| ECR_API
    Fargate1 -->|HTTPS port 443| ECR_DKR
    Fargate1 -->|HTTPS port 443| LOGS

    Fargate2 -->|HTTPS port 443| ECR_API
    Fargate2 -->|HTTPS port 443| ECR_DKR
    Fargate2 -->|HTTPS port 443| LOGS

    %% エンドポイントからAWS各サービスへ
    ECR_API -.-> AWS_ECR
    ECR_DKR -.-> AWS_ECR
    LOGS -.-> AWS_CW
    
    %% FargateからS3へ（点線で表現）
    Fargate1 -.-> AWS_S3
    Fargate2 -.-> AWS_S3

    %% --- レイアウト調整用の不可視リンク ---
    %% S3をVPCEの直下に強制配置
    VPCE ~~~ AWS_S3
    %% AZ_1aとAZ_1cをVPCEの両脇に配置
    AZ_1a ~~~ VPCE
    VPCE ~~~ AZ_1c
```
