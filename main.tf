provider "aws" {
	region = "us-east-1"
	}

resource "aws_instance" "nginix" {
	ami = "ami-40d28157"
	instance_type = "t2.micro"

	tags {
		Name = "my_nginix"
	}
}
