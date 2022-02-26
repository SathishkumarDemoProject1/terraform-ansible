provider "aws" {
    region = "us-east-1"
	version = "3.61.0"
	access_key = "AKIASQEYJANO65ZJJJXM"
    secret_key = "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"
}

resource "aws_instance" "webservers" {
	count = 2
    ami = "ami-033b95fb8079dc481"
    instance_type = "t3.nano"
    key_name = "demo"
	subnet_id  = "subnet-7a55f41c"
	security_groups =  [ "sg-0b5677b7dca4a0f57" ]
	tags = {
            Name = "webserver${count.index}"
    }
}

resource "local_file" "ip" {
    content  = "${aws_instance.webservers[0].public_ip} \n ${aws_instance.webservers[1].public_ip}"
    filename = "ip.txt"
}


data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = ["vpc-c026dbbd"]
  }
}


####################################################
# Target Group Creation
####################################################

resource "aws_lb_target_group" "tg" {
  name        = "TargetGroup"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = "vpc-c026dbbd"
}

####################################################
# Target Group Attachment with Instance
####################################################

resource "aws_alb_target_group_attachment" "tgattachment" {
  count            = length(aws_instance.webservers.*.id)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(aws_instance.webservers.*.id, count.index)
}


####################################################
# Application Load balancer
####################################################

resource "aws_lb" "lb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = data.aws_subnets.subnets.ids
}

####################################################
# Listner
####################################################

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  
  
}


####################################################
# Listener Rule
####################################################

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn

  }
  condition {
    host_header {
      values = ["*.com"]
    }
  }
}



#Create security_group.tf and put below codes:
locals {
  ingress_rules = [{
    name        = "HTTPS"
    port        = 443
    description = "Ingress rules for port 443"
    },
    {
      name        = "HTTP"
      port        = 80
      description = "Ingress rules for port 80"
    },
    {
      name        = "SSH"
      port        = 22
      description = "Ingress rules for port 22"
  }]

}

resource "aws_security_group" "sg" {

  name        = "CustomSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-c026dbbd"
  egress = [
    {
      description      = "for all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  dynamic "ingress" {
    for_each = local.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    Name = "AWS security group dynamic block"
  }

}