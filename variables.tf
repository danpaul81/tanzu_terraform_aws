variable "access_key" {
	description 	=  "aws access key"
	type 			= string
	sensitive = true
}

variable "secret_access_key" {
	description 	=  "aws secret access key"
	type 			= string
	sensitive = true
}

variable "deploy_key" {
  description 	= "existing AWS SSH Keypair to use"
  type 			= string
}

variable "name_prefix" {
	description = "prefix to apply to name of ressources"
	type 		= string
}

variable "aws_region" {
	description ="AWS region"
	type		= string
	default 	= "eu-west-1"
}

variable "aws_az" {
	description ="AWS AZ"
	type		= string
	default 	= "eu-west-1a"
}

variable "aws_ami_image" {
	description ="AMI Image to use for k8s Server"
	type		= string
	#default 	= "ami-0d75513e7706cf2d9"  # Ubuntu 22.04 LTS image
	#default 	= "ami-0d2a4a5d69e46ea0b"  # Ubuntu 20.04 LTS image
	default = "ami-0d71ea30463e0ff8d" #amazon linux x64 eu-west
	//default = "ami-098e42ae54c764c35" #amazon linux x64 us-west
}

variable "aws_instance_type" {
	description ="AWS Instance Type for bootstrap server"
	type		= string
	default 	= "t2.large"
}


variable "aws_cidr_vpc" {
	description ="CIDR block for VPC"
	type		= string
	default 	= "172.30.0.0/16"
}

variable "aws_tag_vpc" {
	description ="VPC Name Tag"
	type		= string
	default 	= "dpaul_AWS_VPC"
}


variable "aws_cidr_sn_private" {
	description ="CIDR block for private Subnet"
	type		= string
	default 	= "172.30.2.0/24"
}

variable "aws_cidr_sn_public" {
	description ="CIDR block for public Subnet"
	type		= string
	default 	= "172.30.1.0/24"
}
