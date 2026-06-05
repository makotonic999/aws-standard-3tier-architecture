# AWS Standard 3-tier Architecture (IaC)

## 概要
Terraformを活用したAWS 3層アーキテクチャのプロビジョニングプロジェクトです。
本リポジトリでは、インフラのコード化（IaC）による再現性と、セキュアでスケーラブルな環境の構築を目指しています。

## 構成
- **VPC**: 3層（Public/Private）サブネット構成
- **Compute**: EC2インスタンス（Auto Scalingを考慮した設計）
- **Database**: RDS (MySQL) 8.0系
- **Security**: セキュリティグループによる最小権限アクセスの実装

## 技術スタック
- **Language**: HCL (Terraform)
- **Cloud**: AWS
- **Tool**: Git, Terraform CLI, AWS CLI

## 動作確認環境
- Local OS: Windows 11 (WSL2/Mingw64)
- Terraform version: 1.15.1
- AWS CLI version: 2.34.41

## アーキテクチャ図
graph TD
    subgraph VPC
        InternetGateway --> PublicSubnet[Public Subnet]
        PublicSubnet --> EC2[EC2 Instance]
        
        subgraph PrivateSubnet[Private Subnet]
            EC2 --> RDS[(RDS MySQL)]
        end
    end

    style RDS fill:#f9f,stroke:#333,stroke-width:2px
    style EC2 fill:#bbf,stroke:#333,stroke-width:2px
## 構築手順
1. `terraform init` を実行
2. `terraform apply` で環境構築
3. `terraform destroy` で環境削除

## 工夫した点
- 特定のマイナーバージョン指定による環境依存エラーを避けるため、メジャーバージョン指定へ最適化しました。
