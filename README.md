# AWS Standard 3-tier Architecture (IaC)

## 概要
Terraformを活用したAWS 3層アーキテクチャをコンテナで再現するプロジェクト

## 技術スタック
- **Language**: HCL (Terraform)
- **Cloud**: AWS
- **Tool**: Git, Terraform CLI, AWS CLI

## アーキテクチャ図
```mermaid
graph TD
    %% コンポーネントの定義
    User[👤 User / Internet]
    IGW[Internet Gateway]
    ALB[Application Load Balancer]

    subgraph VPC [VPC]
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

        %% --- 共通エンドポイント ---
        subgraph VPCE [VPC Endpoints]
            ECR_API[ecr.api]
            ECR_DKR[ecr.dkr]
            LOGS[logs]
        end
    end

    AWS_ECR[(Amazon ECR)]
    AWS_CW[(Amazon CloudWatch)]
    AWS_S3[(Amazon S3)]

    %% --- 通信の流れ ---
    User -->|HTTP port 80| IGW
    IGW --> ALB
    
    ALB -->|HTTP port 8000| Fargate1
    ALB -->|HTTP port 8000| Fargate2

    %% アプリからDBへのセキュアな通信
    Fargate1 -->|MySQL port 3306| RDS_1a
    Fargate2 -->|MySQL port 3306| RDS_1c
    
    %% RDS間のマルチAZ同期（AWSが自動でやる裏側の通信）
    RDS_1a <.- "Multi-AZ Replication" -.> RDS_1c

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
    
    Fargate1 -.-> AWS_S3
    Fargate2 -.-> AWS_S3
```
