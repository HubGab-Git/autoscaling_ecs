
variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "default region"
}

variable "ami" {
  type        = string
  default     = "ami-0b752bf1df193a6c4"
  description = "default ami"
}

variable "instance" {
  type        = string
  default     = "t2.micro"
  description = "default instance type"
}

variable "az" {
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  description = "default instance type"
}
variable "subnets" {
  type        = list(string)
  default     = ["subnet-0ca31973b1de89bad", "subnet-0bd22b6dfb851cdbe", "subnet-01a5bb829e4355408"]
  description = "default subnets ids"
}
variable "vpc" {
  type        = string
  default     = "vpc-028137a4cde36edc8"
  description = "default vpc id"
}