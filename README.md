# AWS Standard 3-tier Architecture (IaC)

## 概要
Terraformを活用したAWS 3層アーキテクチャをコンテナで再現するプロジェクト

## 技術スタック
- **Language**: HCL (Terraform)
- **Cloud**: AWS
- **Tool**: Git, Terraform CLI, AWS CLI

## アーキテクチャ図
```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffffff', 'edgeLabelBackground':'#ffffff', 'tertiaryColor': '#f3f4f6'}}}%%
graph TD
    %% クラウドの定義 %%
    subgraph cloud ["AWS Cloud (ap-northeast-1)"]
        
        %% インターネットゲートウェイ
        IGW["Internet Gateway"]:::network

        %% インターネット（外の世界）
        User[("👤 User / Internet")]:::client

        subgraph vpc ["VPC (10.0.0.0/16)"]
            
            %% ロードバランサー
            ALB["Application Load Balancer"]:::network

            subgraph az1 ["Availability Zone 1a"]
                subgraph pub1 ["Public Subnet (1a)"]
                end
                
                subgraph pri1 ["Private App Subnet (1a)"]
                    Fargate1["ECS Fargate Task"]:::compute
                end
            end

            subgraph az2 ["Availability Zone 1c"]
                subgraph pub2 ["Public Subnet (1c)"]
                end
                
                subgraph pri2 ["Private App Subnet (1c)"]
                    Fargate2["ECS Fargate Task"]:::compute
                end
            end
            
            %% VPCエンドポイント %%
            subgraph endpoints ["VPC Endpoints (Security Group: vpc_endpoint_sg)"]
                VPCE_ECR_API["com.amazonaws.ap-northeast-1.ecr.api"]:::endpoint
                VPCE_ECR_DKR["com.amazonaws.ap-northeast-1.ecr.dkr"]:::endpoint
                VPCE_LOGS["com.amazonaws.ap-northeast-1.logs"]:::endpoint
            end

        end
        
        %% AWSサービス（VPCの外） %%
        ECR[("Amazon ECR (Image Registry)")]:::storage
        CloudWatch[("Amazon CloudWatch (Logs)")]:::storage
        S3[("Amazon S3 (for ECR layers)")]:::storage
    end

    %% --- 通信の流れ（修正部分） --- %%
    User -- "HTTP (port 80)" --> IGW
    IGW --> ALB
    
    ALB -- "HTTP (port 8000)" --> Fargate1
    ALB -- "HTTP (port 8000)" --> Fargate2
    
    Fargate1 -- "port 443 (HTTPS)" --> VPCE_ECR_API
    Fargate1 -- "port 443 (HTTPS)" --> VPCE_ECR_DKR
    Fargate1 -- "port 443 (HTTPS)" --> VPCE_LOGS

    Fargate2 -- "port 443 (HTTPS)" --> VPCE_ECR_API
    Fargate2 -- "port 443 (HTTPS)" --> VPCE_ECR_DKR
    Fargate2 -- "port 443 (HTTPS)" --> VPCE_LOGS

    VPCE_ECR_API -.-> ECR
    VPCE_ECR_DKR -.-> ECR
    VPCE_LOGS -.-> CloudWatch
    
    Fargate1 -.-> S3
    Fargate2 -.-> S3
    S3 -.-> ECR

    %% --- スタイルの定義 --- %%
    classDef client fill:#000000,stroke:#333,stroke-width:2px,color:#ffffff;
    classDef network fill:#f3f4f6,stroke:#333,stroke-width:1px,rx:10,ry:10,color:#000000;
    classDef compute fill:#ff9900,stroke:#000,stroke-width:1px,color:#ffffff,font-weight:bold,rx:5,ry:5;
    classDef storage fill:#ffffff,stroke:#333,stroke-width:1px,rx:5,ry:5,stroke-dasharray: 5 5,color:#000000;
    classDef endpoint fill:#e1f5fe,stroke:#0277bd,stroke-width:1px,color:#000000;
    linkStyle default stroke-width:1.5px,fill:none,stroke:#000000;
```
