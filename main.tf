provider "aws" {
	region = "us-east-1"
	}

variable "server_port" {
	description = "The port the server will use for HTTP requests"
	default = 8080
}

variable "server_protocol" {
	description = "The protocol the server will use for HTTP requests"
	default = "http"
}

resource "aws_launch_configuration" "nginx" {
	image_id = "ami-2d39803a"
	instance_type = "t2.micro"

	security_groups = ["${aws_security_group.nginx_sg.id}"]

	user_data = <<-EOF
		#!/bin/bash
		echo "Hello, World" > index.html
		nohup busybox httpd -f -p "${var.server_port}" &
		EOF

	lifecycle {
		create_before_destroy = true
	}
	
}

resource "aws_security_group" "nginx_sg" {
	name = "nginx_sg"
	
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

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "nginx_asg" {
        launch_configuration = "${aws_launch_configuration.nginx.id}"
        availability_zones = ["${data.aws_availability_zones.all.names}"]

	load_balancers = ["${aws_elb.nginx_elb.name}"]
	health_check_type = "ELB"	

        min_size=2
        max_size=10

        tag {
                key = "Name"
                value = "terraform-asg-my_nginx"
                propagate_at_launch = true
        }
}

resource "aws_elb" "nginx_elb" {
	name = "nginxelb"
	availability_zones = ["${data.aws_availability_zones.all.names}"]

	security_groups = ["${aws_security_group.nginx_elb_sg.id}"] 

	listener {
		lb_port = 80
		lb_protocol = "${var.server_protocol}"
		instance_port = "${var.server_port}"
		instance_protocol = "${var.server_protocol}"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "HTTP:${var.server_port}/"
	}

}

resource "aws_security_group" "nginx_elb_sg" {
	name = "terraform-nginx-elb-sg"
	
	ingress {
		from_port = 80 
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

}

output "all" {
	value = ["${data.aws_availability_zones.all.names}"]
} 

output "elb_dns_name" {
	value = "${aws_elb.nginx_elb.dns_name}"
}
