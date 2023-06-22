variable "vpc_cidr" {
  type        = string
  description = "The CIDR block that should be assigned to the VPC. Must be a /16."

  validation {
    condition     = endswith(var.vpc_cidr, "/16")
    error_message = "The CIDR block must be a /16."
  }
}

variable "availability_zones" {
  type        = set(string)
  description = "The availability zones that should be assigned to the subnets in the VPC. Region is determined by the terraform provider configuration."
  default     = toset(["a", "b", "c"])

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Three availability zone names are required."
  }
}

variable "resource_tags" {
  type = map(string)
  description = "Tags to assign to all created resources."
  default = {}
}
