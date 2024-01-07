variable "aws_region" {
  default     = "eu-west-1"
}

variable "aws_profile" {
  default     = "TAC-717188463772"
}

variable "bucket_name" {
  default     = "user-upload_packet"
}
variable "function_name" {
  default     = "logs_analysis"
}
variable "runtime" {
  default = "python3.7"
}