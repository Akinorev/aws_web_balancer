provider "aws" {
  region     = "us-east-1"
}

data "aws_availability_zones" "all" {}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "instance_number" {
  description = "The number of instances"
  default = 2
}


/* Dns name from the Loadbalancer, it will be easier to access to web page */
output "elb_dns_name" {
  value = "${aws_elb.webbalancer.dns_name}"
}

/* To allow access for the port defined on server_port variable */
resource "aws_security_group" "instance" {
  name = "instance-sec"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}


/* To allow HTTP requests and route them to the port used by the instances in the ASG */
resource "aws_security_group" "elb" {
  name = "elb-sec"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* Initial configuration for all instances */
resource "aws_launch_configuration" "web" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hi! This is working nice." > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

/* Autoescaling, this is what will be used to select how many instances, 
   the load balancer they connect to and the available zones. */
resource "aws_autoscaling_group" "scaler" {
  launch_configuration = "${aws_launch_configuration.web.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = "${var.instance_number}"
  max_size = "${var.instance_number}"

  load_balancers = ["${aws_elb.webbalancer.name}"]
  health_check_type = "ELB"
  
  tag {
    key = "Name"
    value = "web-instance"
    propagate_at_launch = true
  }
}

/* Loadbalancer configuration, for simplicity it points directly to port 80
   and 8080 for internal instances */
resource "aws_elb" "webbalancer" {
  name = "web-balancer"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}