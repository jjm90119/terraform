resource "aws_vpc" "mtv_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "mtv_public_subnet" {
  vpc_id                  = aws_vpc.mtv_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "mtv_internet_gateway" {
  vpc_id = aws_vpc.mtv_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mtv_public_rt" {
  vpc_id = aws_vpc.mtv_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtv_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtv_internet_gateway.id
}

resource "aws_route_table_association" "mtv_public_assoc" {
  subnet_id      = aws_subnet.mtv_public_subnet.id
  route_table_id = aws_route_table.mtv_public_rt.id
}

resource "aws_security_group" "mtv_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.mtv_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["3.144.129.88/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "mtv_auth" {
  key_name   = "mtvkey"
  public_key = file("~/.ssh/mtvkey.pub")
}

resource "aws_instance" "dev_node" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.mtv_auth.id
  vpc_security_group_ids = [aws_security_group.mtv_sg.id]
  subnet_id              = aws_subnet.mtv_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  // Provisioners are a last resort. Tools like Ansible are better suited for configurations. Using provisioners this time as we are handling 1 server and for learning purposes.
  provisioner "local-exec" {
    command = templatefile("linux-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/mtvkey"
    })
  }
}