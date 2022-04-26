# Specifies your AWS credentials and region
provider "aws" {
    access_key = "YOUR_ACCESS_KEY"
    secret_key = "YOUR_SECRET_KEY"
    region = "AWS_REGION"
}

# OPTIONAL: Specify a user that will be able to upload stuff to bucket
resource "aws_iam_user" "prod_user" {
    name = "absolute-agent-svc-user"
    path = "/system/"
}

# OPTIONAL: Creates keys for that user
resource "aws_iam_access_key" "prod_user" {
    user = "${aws_iam_user.prod_user.name}"
}

# OPTIONAL: Policy for user that allows it to upload
resource "aws_iam_user_policy" "prod_user_ro" {
    name = "prod"
    user = "${aws_iam_user.prod_user.name}"
    policy= <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
            "arn:aws:s3:::absolute-agent-svc",
            "arn:aws:s3:::absolute-agent-svc/*"
        ]
     }]
}
EOF
}

# Here we specify the bucket
resource "aws_s3_bucket" "prod_bucket" {
    bucket = "absolute-agent-svc"
    acl = "public-read"

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT","POST"]
        allowed_origins = ["*"]
        expose_headers = ["ETag"]
        max_age_seconds = 3000
    }

    policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
    {
        "Sid": "PublicReadForGetBucketObjects",
        "Effect": "Allow",
        "Principal": {
            "AWS": "*"
         },
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::absolute-agent-svc/*"
    }, {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
            "AWS": "${aws_iam_user.prod_user.arn}"
        },
        "Action": "s3:*",
        "Resource": [
            "arn:aws:s3:::absolute-agent-svc",
            "arn:aws:s3:::absolute-agent-svc/*"
        ]
    }]
}
EOF }

# Create Cloudfront distribution
resource "aws_cloudfront_distribution" "prod_distribution" {
    origin {
        domain_name = "${aws_s3_bucket.prod.website_endpoint}"
        origin_id = "S3-${aws_s3_bucket.prod.bucket}"

        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    # By default, show index.html file
    default_root_object = "index.html"
    enabled = true

    # If there is a 404, return index.html with a HTTP 200 Response
    custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
    }

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-${aws_s3_bucket.prod.bucket}"

        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = true
        }

        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    # Distributes content to US and Europe
    price_class = "PriceClass_100"

    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}