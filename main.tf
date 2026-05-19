# VPCを作る
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "standard-3tier-vpc"
    }
}

resource "aws_subnet" "public_1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "standard-public_1a"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "standard-igw"
    }
}

# Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    # デフォルトルート
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "standard-public-rt"
    }
}

# Route Table Association
resource "aws_route_table_association" "public_1a" {
    subnet_id = aws_subnet.public_1a.id
    route_table_id = aws_route_table.public.id
}