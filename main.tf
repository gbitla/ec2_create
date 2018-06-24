provider "aws" {
	region = "us-east-1"
	}

resource "aws_instance" "nginix" {
	ami = "ami-40d28157"
	instance_type = "t2.micro"

	tags {
		Name = "my_nginix"
	}

	user_data = <<-EOF
		echo "Hello, World" > index.html
		nohup busybox httpd -f -p 8080 &
		EOF
}
resource "aws_security_group" "nginix_sg" {
	name = "nginix_sg"
	
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		}

}
