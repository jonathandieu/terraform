# translates private machine IP addresses into public ones
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    "Name" = "${local.environment}-nat"
  }
}
