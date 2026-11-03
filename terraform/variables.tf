variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for deployment"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance size"
}

variable "ami_id" {
  type        = string
  default     = "ami-0c7217cdde317cfec" # Amazon Linux 2023 AMI (update for your region)
  description = "AMI ID for EC2 instance"
}