variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Service name"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags that override default tags"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS cluster endpoint"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = null
}

variable "ip_family" {
  description = "IP family for the cluster (ipv4 or ipv6)"
  type        = string
  default     = "ipv4"
}

variable "enable_secrets_encryption" {
  description = "Enable secrets encryption using KMS"
  type        = bool
  default     = true
}

variable "encryption_resources" {
  description = "Resources to encrypt with KMS"
  type        = list(string)
  default     = ["secrets"]
}

variable "kms_admin_arns" {
  description = "List of IAM ARNs that can administer the KMS key"
  type        = list(string)
  default     = []
}

variable "cluster_additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the cluster role"
  type        = list(string)
  default     = []
}

variable "outpost_config" {
  description = "Outpost configuration for the EKS cluster"
  type = object({
    outpost_arns                = list(string)
    control_plane_instance_type = string
  })
  default = null
}

variable "compute_config" {
  description = "Compute configuration for the EKS cluster"
  type = object({
    enabled    = bool
    node_roles = list(string)
    subnet_ids = list(string)
  })
  default = null
}

variable "create_node_group" {
  description = "Create a managed node group"
  type        = bool
  default     = true
}

variable "node_group_name" {
  description = "Name of the node group"
  type        = string
  default     = "managed-nodes"
}

variable "node_subnet_ids" {
  description = "Subnet IDs for the node group"
  type        = list(string)
  default     = []
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "ssh_key_name" {
  description = "SSH key name for node access"
  type        = string
  default     = null
}

variable "node_remote_access_sg_ids" {
  description = "Security group IDs for node remote access"
  type        = list(string)
  default     = []
}

variable "node_labels" {
  description = "Labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "node_taint_key" {
  description = "Taint key for nodes"
  type        = string
  default     = null
}

variable "node_taint_value" {
  description = "Taint value for nodes"
  type        = string
  default     = null
}

variable "node_taint_effect" {
  description = "Taint effect for nodes"
  type        = string
  default     = "NO_SCHEDULE"
}

variable "max_unavailable_percentage" {
  description = "Maximum unavailable percentage for node updates"
  type        = number
  default     = 33
}

variable "node_additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the node role"
  type        = list(string)
  default     = []
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "coredns_resolve_conflicts" {
  description = "Conflict resolution strategy for CoreDNS addon"
  type        = string
  default     = "OVERWRITE"
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "kube_proxy_resolve_conflicts" {
  description = "Conflict resolution strategy for kube-proxy addon"
  type        = string
  default     = "OVERWRITE"
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "vpc_cni_resolve_conflicts" {
  description = "Conflict resolution strategy for VPC CNI addon"
  type        = string
  default     = "OVERWRITE"
}

variable "enable_prefix_delegation" {
  description = "Enable prefix delegation for VPC CNI"
  type        = bool
  default     = true
}

variable "warm_prefix_target" {
  description = "Warm prefix target for VPC CNI"
  type        = string
  default     = "1"
}

variable "fargate_profiles" {
  description = "Fargate profiles configuration"
  type = map(object({
    pod_execution_role_arn = string
    subnet_ids             = list(string)
    namespace              = string
    labels                 = optional(map(string), {})
  }))
  default = {}
}

variable "enable_aws_lb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_lb_controller_chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.6.0"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
