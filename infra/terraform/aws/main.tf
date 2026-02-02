resource "aws_s3_bucket" "example" {
  bucket = "learning-repo-example-${random_id.suffix.hex}"

  tags = {
    project = "learning-repo"
    env     = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_id" "suffix" {
  byte_length = 4
}
