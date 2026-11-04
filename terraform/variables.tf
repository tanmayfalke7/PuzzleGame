variable "aws_region" {
  type        = string
  default     = "ap-south-1"  # Keep set to your local AWS region (e.g., ap-south-1 for Mumbai)
  description = "AWS region for deployment"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"    # Updated to match your selection
  description = "EC2 instance type"
}

variable "ami_id" {
  type        = string
  default     = "ami-0f19324397f53458f" # Updated with your Amazon Linux 2023 AMI ID
  description = "Amazon Linux 2023 AMI ID"
}