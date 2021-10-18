# Configure S3 resource

variable "env" {
    type = string
    default = "dev"
    sensitive = true
    description = "Environment variable relating to infrastructure code. Can be prod, dev or stg"
    validation {
        condition = length(var.env) <= 4 && contains(["prod","stg","dev"], var.env)
        error_message = "Invalid 'env' input: env variable must be one of the following: prod, stg, dev."
    }
}

resource "aws_s3_bucket" "test_bucket_alias" {
    bucket = "my-test-tf-bucket-${var.env}"
    tags = {
        Name = "My test TF Bucket"
        Environment = var.env
    }
}