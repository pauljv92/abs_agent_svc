resource "aws_storagegateway_gateway" "absolute-nfs-gw" {
  gateway_ip_address = "1.2.3.4"
  gateway_name       = "absolute-nfs-gw"
  gateway_timezone   = "GMT"
  gateway_type       = "FILE_S3"
}

resource "aws_storagegateway_nfs_file_share" "absolute-nfs-gw" {
  client_list  = ["0.0.0.0/0"]
  gateway_arn  = aws_storagegateway_gateway.absolute-nfs-gw.arn
  location_arn = aws_s3_bucket.absolute-nfs-gw.arn
  role_arn     = aws_iam_role.absolute-nfs-gw.arn
}