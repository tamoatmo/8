# AWS 区域
variable "aws_region" {
  description = "AWS 部署区域"
  type        = string
  default     = "us-west-2"
}

# EKS 集群名称
variable "cluster_name" {
  description = "EKS 集群名称"
  type        = string
  default     = "my-eks-cluster"
}

# Kubernetes 版本
variable "kubernetes_version" {
  description = "Kubernetes 版本"
  type        = string
  default     = "1.28"
}

# VPC CIDR 块
variable "vpc_cidr" {
  description = "VPC 的 CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

# 公共子网 CIDR 块
variable "public_subnet_cidrs" {
  description = "公共子网的 CIDR 块列表"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# 私有子网 CIDR 块
variable "private_subnet_cidrs" {
  description = "私有子网的 CIDR 块列表"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# 节点实例类型
variable "node_instance_types" {
  description = "EKS 节点的 EC2 实例类型"
  type        = list(string)
  default     = ["t3.medium"]
}

# AMI 类型
variable "ami_type" {
  description = "EKS 节点的 AMI 类型"
  type        = string
  default     = "AL2_x86_64"
  validation {
    condition = contains([
      "AL2_x86_64",
      "AL2_x86_64_GPU",
      "AL2_ARM_64",
      "CUSTOM",
      "BOTTLEROCKET_ARM_64",
      "BOTTLEROCKET_x86_64"
    ], var.ami_type)
    error_message = "AMI 类型必须是有效的 EKS AMI 类型之一。"
  }
}

# 容量类型
variable "capacity_type" {
  description = "节点组的容量类型"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "容量类型必须是 ON_DEMAND 或 SPOT。"
  }
}

# 磁盘大小
variable "disk_size" {
  description = "EKS 节点的磁盘大小 (GB)"
  type        = number
  default     = 20
}

# 期望容量
variable "desired_capacity" {
  description = "节点组的期望容量"
  type        = number
  default     = 2
}

# 最小容量
variable "min_capacity" {
  description = "节点组的最小容量"
  type        = number
  default     = 1
}

# 最大容量
variable "max_capacity" {
  description = "节点组的最大容量"
  type        = number
  default     = 5
}

# 最大不可用节点数
variable "max_unavailable" {
  description = "更新期间最大不可用节点数"
  type        = number
  default     = 1
}

# 端点私有访问
variable "endpoint_private_access" {
  description = "启用 EKS 集群端点私有访问"
  type        = bool
  default     = true
}

# 端点公共访问
variable "endpoint_public_access" {
  description = "启用 EKS 集群端点公共访问"
  type        = bool
  default     = true
}

# 公共访问 CIDR
variable "public_access_cidrs" {
  description = "允许访问公共 EKS 端点的 CIDR 块列表"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# 集群日志类型
variable "cluster_log_types" {
  description = "要启用的 EKS 集群日志类型"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# 标签
variable "tags" {
  description = "应用于所有资源的标签"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "eks-cluster"
    ManagedBy   = "terraform"
  }
}