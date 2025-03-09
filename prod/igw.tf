resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.environment}-igw"
    environment = "${local.environment}"
  }
}

resource "aws_nat_gateway" "aws_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_zone1.id

  tags = {
    "Name" = "${local.environment}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}
