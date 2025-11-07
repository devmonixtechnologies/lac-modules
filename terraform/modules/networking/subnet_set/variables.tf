variable "vpc_id" {
  description = "ID of the VPC to attach subnets"
  type        = string
}

variable "environment" {
  description = "Environment identifier"
  type        = string
}

variable "service" {
  description = "Service name for tagging"
  type        = string
  default     = "network"
}

variable "component" {
  description = "Component identifier"
  type        = string
  default     = "subnet"
}

variable "subnet_group" {
  description = "Label applied to all subnets (e.g., public, private)"
  type        = string
}

variable "subnets" {
  description = "List of subnet definitions"
  type = list(object({
    name                  = string
    cidr_block            = string
    az                    = string
    tier                  = optional(string)
    map_public_ip_on_launch = optional(bool)
  }))
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags overriding defaults"
  type        = map(string)
  default     = {}
}
