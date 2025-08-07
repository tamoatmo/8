# EKS Terraform 部署脚本

这个 Terraform 脚本用于在 AWS 上部署一个完整的 EKS (Elastic Kubernetes Service) 集群，包括所有必要的网络基础设施、IAM 角色和安全组。

## 功能特性

- 🌐 **完整的 VPC 基础设施**: 自动创建 VPC、子网、NAT 网关、路由表等
- 🔐 **安全配置**: 预配置的安全组和 IAM 角色
- ⚡ **EKS 集群**: 自动创建和配置 EKS 集群和工作节点组
- 🔧 **高度可配置**: 通过变量文件轻松自定义配置
- 📊 **丰富的输出**: 提供集群连接和管理所需的所有信息
- 🛡️ **最佳实践**: 遵循 AWS 和 EKS 的安全最佳实践

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                          VPC                                │
│  ┌─────────────────┐              ┌─────────────────┐       │
│  │  Public Subnet  │              │  Public Subnet  │       │
│  │   (AZ-1)        │              │   (AZ-2)        │       │
│  │                 │              │                 │       │
│  │   NAT Gateway   │              │   NAT Gateway   │       │
│  └─────────────────┘              └─────────────────┘       │
│           │                                 │               │
│  ┌─────────────────┐              ┌─────────────────┐       │
│  │ Private Subnet  │              │ Private Subnet  │       │
│  │   (AZ-1)        │              │   (AZ-2)        │       │
│  │                 │              │                 │       │
│  │  EKS Worker     │              │  EKS Worker     │       │
│  │    Nodes        │              │    Nodes        │       │
│  └─────────────────┘              └─────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## 先决条件

### 1. 工具安装

- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **kubectl** (用于管理 Kubernetes 集群)

```bash
# 安装 Terraform (macOS)
brew install terraform

# 安装 AWS CLI (macOS)
brew install awscli

# 安装 kubectl (macOS)
brew install kubectl
```

### 2. AWS 配置

配置 AWS 凭证和默认区域：

```bash
aws configure
```

或者设置环境变量：

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 3. IAM 权限

确保您的 AWS 用户/角色具有以下权限：

- EC2 完全访问权限
- EKS 完全访问权限
- IAM 创建角色和策略的权限
- VPC 管理权限

## 快速开始

### 1. 克隆并准备配置

```bash
# 进入项目目录
cd eks-terraform

# 复制示例配置文件
cp terraform.tfvars.example terraform.tfvars

# 编辑配置文件
nano terraform.tfvars
```

### 2. 自定义配置

编辑 `terraform.tfvars` 文件，至少修改以下配置：

```hcl
# 基本配置
cluster_name = "your-cluster-name"
aws_region   = "your-preferred-region"

# 安全配置 - 限制访问来源
public_access_cidrs = ["your-ip-address/32"]

# 标签配置
tags = {
  Environment = "production"
  Project     = "your-project-name"
  Owner       = "your-name"
}
```

### 3. 部署集群

```bash
# 初始化 Terraform
terraform init

# 查看执行计划
terraform plan

# 应用配置
terraform apply
```

### 4. 配置 kubectl

部署完成后，配置 kubectl 以连接到新创建的 EKS 集群：

```bash
# 获取 kubectl 配置命令（从 Terraform 输出）
terraform output kubectl_config

# 执行配置命令
aws eks update-kubeconfig --region <region> --name <cluster-name>

# 验证连接
kubectl get nodes
```

## 配置选项

### 网络配置

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `vpc_cidr` | VPC CIDR 块 | `10.0.0.0/16` |
| `public_subnet_cidrs` | 公共子网 CIDR 列表 | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | 私有子网 CIDR 列表 | `["10.0.10.0/24", "10.0.20.0/24"]` |

### 集群配置

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `cluster_name` | EKS 集群名称 | `my-eks-cluster` |
| `kubernetes_version` | Kubernetes 版本 | `1.28` |
| `node_instance_types` | 节点实例类型 | `["t3.medium"]` |
| `desired_capacity` | 期望节点数 | `2` |
| `min_capacity` | 最小节点数 | `1` |
| `max_capacity` | 最大节点数 | `5` |

### 安全配置

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `endpoint_private_access` | 启用私有端点访问 | `true` |
| `endpoint_public_access` | 启用公共端点访问 | `true` |
| `public_access_cidrs` | 允许访问的 CIDR 块 | `["0.0.0.0/0"]` |

## 输出信息

部署完成后，Terraform 将输出以下重要信息：

```bash
# 查看所有输出
terraform output

# 查看特定输出
terraform output cluster_endpoint
terraform output vpc_id
```

主要输出包括：

- `cluster_endpoint`: EKS 集群 API 端点
- `cluster_id`: 集群 ID
- `vpc_id`: VPC ID
- `kubectl_config`: kubectl 配置命令

## 成本优化

### 节点组配置

```hcl
# 使用 Spot 实例降低成本
capacity_type = "SPOT"
node_instance_types = ["t3.medium", "t3.large"]

# 调整节点数量
desired_capacity = 1
min_capacity     = 1
max_capacity     = 3
```

### 日志配置

```hcl
# 减少日志类型以降低 CloudWatch 成本
cluster_log_types = ["api", "audit"]
```

## 故障排除

### 常见问题

#### 1. 权限不足错误

```
Error: insufficient permissions
```

**解决方案**: 确保 AWS 用户具有必要的 IAM 权限。

#### 2. 可用区不支持 EKS

```
Error: InvalidParameterException: Subnets specified must span at least two availability zones
```

**解决方案**: 确保在 `variables.tf` 中配置了至少两个不同可用区的子网。

#### 3. 实例类型不可用

```
Error: InvalidParameterValue: Unsupported instance type
```

**解决方案**: 检查选择的实例类型在目标区域是否可用，考虑使用 `t3.medium` 或 `m5.large`。

#### 4. kubectl 连接失败

```
error: You must be logged in to the server (Unauthorized)
```

**解决方案**: 
```bash
# 重新配置 kubectl
aws eks update-kubeconfig --region <region> --name <cluster-name>

# 检查 AWS 凭证
aws sts get-caller-identity
```

### 调试技巧

```bash
# 查看 Terraform 状态
terraform state list

# 查看特定资源
terraform state show aws_eks_cluster.eks_cluster

# 强制刷新状态
terraform refresh

# 查看详细日志
TF_LOG=DEBUG terraform apply
```

## 清理资源

```bash
# 删除所有创建的资源
terraform destroy

# 确认删除
# 输入 "yes" 确认
```

**⚠️ 警告**: 此操作将删除所有创建的资源，包括 EKS 集群、VPC 和相关的所有资源。请确保您已备份重要数据。

## 安全最佳实践

1. **限制公共访问**: 将 `public_access_cidrs` 限制为您的 IP 地址或公司网络
2. **使用私有子网**: 工作节点部署在私有子网中
3. **启用日志记录**: 保持集群日志记录以便审计
4. **定期更新**: 定期更新 Kubernetes 版本和节点 AMI
5. **最小权限原则**: 为应用程序使用最小必要权限的 IAM 角色

## 支持和贡献

如果您遇到问题或有改进建议，请：

1. 检查本文档的故障排除部分
2. 查看 [Terraform AWS EKS 文档](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
3. 查看 [AWS EKS 官方文档](https://docs.aws.amazon.com/eks/)

## 许可证

此项目使用 MIT 许可证。有关详细信息，请参阅 LICENSE 文件。