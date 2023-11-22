
# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Subnet
resource "aws_subnet" "sn_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

# Route Table
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Subnet Association
resource "aws_route_table_association" "rt_public_To_sn_public" {
  subnet_id      = aws_subnet.sn_public.id
  route_table_id = aws_route_table.rt_public.id
}

# Security Group
resource "aws_security_group" "sg_public" {
  name   = "sg_public"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for index.html
resource "aws_instance" "instance_index" {
  ami                    = "ami-02e136e904f3da870"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_public.id
  vpc_security_group_ids = [aws_security_group.sg_public.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo '<html><body><h1>Index Page</h1></body></html>' | sudo tee /var/www/html/index.html
              EOF
}

# EC2 Instance for error.html
resource "aws_instance" "instance_error" {
  ami                    = "ami-02e136e904f3da870"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_public.id
  vpc_security_group_ids = [aws_security_group.sg_public.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo '<html><body><h1>Error Page</h1></body></html>' | sudo tee /var/www/html/error.html
              EOF
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "meu-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_public.id]
  subnets            = [aws_subnet.sn_public.id]
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "meu-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Target Group Attachment for Index Instance
resource "aws_lb_target_group_attachment" "tga_index" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance_index.id
  port             = 80
}

# Target Group Attachment for Error Instance
resource "aws_lb_target_group_attachment" "tga_error" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance_error.id
  port             = 80
}
