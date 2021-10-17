# Configure S3 resource

resource "aws_s3_bucket" "test_bucket_alias" {
    bucket = "my-test-tf-bucket"
    tags = {
        Name = "My test TF Bucket"
        Environment = "Dev"
    }
}