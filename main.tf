# Create a VPC 
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
  }
# Create subnet1 
  resource "aws_subnet" "mysubnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    
  }
# Create subnet2
  resource "aws_subnet" "mysubnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b" 
    map_public_ip_on_launch = true
  }

#Create Interget gateway
  resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
  }

  resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  }

  resource "aws_route_table_association" "RTA" {
  subnet_id      = aws_subnet.mysubnet1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.mysubnet2.id
  route_table_id = aws_route_table.RT.id
}
#Create security group
resource "aws_security_group" "mysg" {
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
# ingress = inbound rule
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
# egress = outbound rule
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  }
# Create a S3 bucket and allow EC2 to access the S3 bucket via IAM role
  resource "aws_s3_bucket" "mys3" {
  bucket = "saifterraformfirstproject"

  tags = {
    Name        = "My bucket"
  }
}
# Create a First EC2 Instance 
  resource "aws_instance" "webserver1" {
  ami          = "ami-0287a05f0ef0e9d9a"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id = aws_subnet.mysubnet1.id
  user_data = base64encode(file("userdata.sh"))
  

  tags = {
    Name = "HellopROject1"
  }
    }
# Create a Second EC2 Instance
resource "aws_instance" "webserver2" {
    ami = "ami-0287a05f0ef0e9d9a"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.mysubnet2.id
    user_data = base64encode(file("userdata1.sh"))
  
} 
# Create a Application loadbalancer 
resource "aws_lb" "webLB" {
    name = "MyfirstLB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.mysg.id]
    subnets = [aws_subnet.mysubnet1.id ,aws_subnet.mysubnet2.id]
  }
# Create a Target group
  resource "aws_lb_target_group" "LBTG" {
    name = "MyfirstTG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    
    health_check {
      protocol = "HTTP"
      path = "/"
      port = "traffic-port"
    }
  }
# Target Group attach with each instances 
   resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.LBTG.arn
    target_id = aws_instance.webserver1.id
    port = 80
     }

      resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.LBTG.arn
    target_id = aws_instance.webserver2.id
    port = 80
     }
# Create a loadbalancer lister to forward the traffic 
     resource "aws_lb_listener" "ALBI" {
        load_balancer_arn = aws_lb.webLB.arn
        port = 80
        protocol = "HTTP"

        default_action {
          type = "forward"
          target_group_arn = aws_lb_target_group.LBTG.arn
        }
       }
# Output loadbalancer with the dns name 
    output "loadbalancerdns" {
        value = aws_lb.webLB.dns_name
    }

