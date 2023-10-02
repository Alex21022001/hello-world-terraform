variable "aws_region" {
  default = "us-east-1"
  type = string
}

variable "function_zip_path" {
  default = "/target/function.zip"
  type = string
}