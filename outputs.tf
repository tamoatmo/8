# EKS 集群输出
output "cluster_id" {
  description = "EKS 集群 ID"
  value       = aws_eks_cluster.eks_cluster.id
}

output "cluster_arn" {
  description = "EKS 集群 ARN"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_endpoint" {
  description = "EKS 集群端点"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_version" {
  description = "EKS 集群 Kubernetes 版本"
  value       = aws_eks_cluster.eks_cluster.version
}

output "cluster_platform_version" {
  description = "EKS 集群平台版本"
  value       = aws_eks_cluster.eks_cluster.platform_version
}

output "cluster_status" {
  description = "EKS 集群状态"
  value       = aws_eks_cluster.eks_cluster.status
}

output "cluster_security_group_id" {
  description = "EKS 集群安全组 ID"
  value       = aws_security_group.eks_cluster_sg.id
}

# OIDC 输出
output "cluster_oidc_issuer_url" {
  description = "EKS 集群的 OIDC 发行者 URL"
  value       = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# 节点组输出
output "node_group_arn" {
  description = "EKS 节点组 ARN"
  value       = aws_eks_node_group.eks_nodes.arn
}

output "node_group_status" {
  description = "EKS 节点组状态"
  value       = aws_eks_node_group.eks_nodes.status
}

output "node_security_group_id" {
  description = "EKS 节点安全组 ID"
  value       = aws_security_group.eks_nodes_sg.id
}

# VPC 输出
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 块"
  value       = aws_vpc.eks_vpc.cidr_block
}

output "internet_gateway_id" {
  description = "互联网网关 ID"
  value       = aws_internet_gateway.eks_igw.id
}

# 子网输出
output "private_subnet_ids" {
  description = "私有子网 ID 列表"
  value       = aws_subnet.private_subnets[*].id
}

output "public_subnet_ids" {
  description = "公共子网 ID 列表"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_cidrs" {
  description = "私有子网 CIDR 块列表"
  value       = aws_subnet.private_subnets[*].cidr_block
}

output "public_subnet_cidrs" {
  description = "公共子网 CIDR 块列表"
  value       = aws_subnet.public_subnets[*].cidr_block
}

# NAT 网关输出
output "nat_gateway_ids" {
  description = "NAT 网关 ID 列表"
  value       = aws_nat_gateway.nat_gw[*].id
}

output "nat_gateway_public_ips" {
  description = "NAT 网关公共 IP 列表"
  value       = aws_eip.nat_eip[*].public_ip
}

# IAM 角色输出
output "cluster_iam_role_arn" {
  description = "EKS 集群 IAM 角色 ARN"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_group_iam_role_arn" {
  description = "EKS 节点组 IAM 角色 ARN"
  value       = aws_iam_role.eks_node_group_role.arn
}

# 配置输出 - 用于 kubectl 配置
output "kubectl_config" {
  description = "kubectl 配置命令"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks_cluster.name}"
}

# 区域和可用区输出
output "aws_region" {
  description = "AWS 区域"
  value       = var.aws_region
}

output "availability_zones" {
  description = "使用的可用区"
  value       = data.aws_availability_zones.available.names
}