
# file contains pre-defined TCE Guest Security Groups
# TCE would automatically create
# to include portworx ports all SG will be pre-provisioned and referenced in guest cluster yaml

# security group for guest bastion host
resource "aws_security_group" "sg_tce_guest_bastion" {
	name 		= 	format("%s-%s",var.name_prefix,"sg-guest-bastion")
	description = 	"TCE guest bastion"
	vpc_id = aws_vpc.main.id
	ingress {
		description = "SSH"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = format("%s-%s",var.name_prefix,"sg-guest-bastion")
		}
}

# security group for guest apiserver-lb
resource "aws_security_group" "sg_tce_guest_apiserver-lb" {
	name 		= 	format("%s-%s",var.name_prefix,"sg-guest-apiserver-lb")
	description = 	"TCE guest apiserver-lb"
	vpc_id = aws_vpc.main.id
	ingress {
		description = "Kubernetes API"
		from_port 	= 6443
		to_port 	= 6443
		protocol	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = format("%s-%s",var.name_prefix,"sg-guest-apiserver-lb")
		}
}

# security group for node
resource "aws_security_group" "sg_tce_guest_node" {
	name 		= 	format("%s-%s",var.name_prefix,"sg-guest-node")
	description = 	"TCE guest node"
	vpc_id = aws_vpc.main.id
    tags = {
		Name = format("%s-%s",var.name_prefix,"sg-guest-node")
		}
}

resource "aws_security_group_rule" "antrea1_cp" {
        type = "ingress" 
		description = "antrea1"
		from_port 	= 10349
		to_port 	= 10349
		protocol	= "tcp"
        source_security_group_id = aws_security_group.sg_tce_guest_controlplane.id
        security_group_id = aws_security_group.sg_tce_guest_node.id
}

resource "aws_security_group_rule" "antrea1_node" {
        type        = "ingress"
		description = "antrea1"
		from_port 	= 10349
		to_port 	= 10349
		protocol	= "tcp"
		self        = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
}

resource "aws_security_group_rule" "nodeport" {
        type        =  "ingress"
		description = "Node Port Services"
		from_port 	= 30000
		to_port 	= 32767
		protocol	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
        security_group_id = aws_security_group.sg_tce_guest_node.id
	}
    
resource "aws_security_group_rule" "geneve_node" {
        type = "ingress"
		description = "genev"
		from_port 	= 6081
		to_port 	= 6081
		protocol	= "udp"
		self = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
	}

resource "aws_security_group_rule" "ssh_bastion" {
        type = "ingress"
		description = "SSH"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		source_security_group_id = aws_security_group.sg_tce_guest_bastion.id
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "geneve_cp" {
        type = "ingress"
		description = "genev"
		from_port 	= 6081
		to_port 	= 6081
		protocol	= "udp"
		source_security_group_id = aws_security_group.sg_tce_guest_controlplane.id
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "kapp_cp" {
        type = "ingress"
		description = "kapp-controller"
		from_port 	= 10100
		to_port 	= 10100
		protocol	= "tcp"
		source_security_group_id = aws_security_group.sg_tce_guest_controlplane.id
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "kapp_node" {
        type = "ingress"
		description = "kapp-controller"
		from_port 	= 10100
		to_port 	= 10100
		protocol	= "tcp"
		self = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "kubet_api_cp" {
        type = "ingress"
		description = "kubelet API"
		from_port 	= 10250
		to_port 	= 10250
		protocol	= "tcp"
		source_security_group_id = aws_security_group.sg_tce_guest_controlplane.id
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "kubelet_api_node" {
        type ="ingress"
		description = "kubelet API"
		from_port 	= 10250
		to_port 	= 10250
		protocol	= "tcp"
		self = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "portworx_tcp" {
        type ="ingress"
		description = "portworx tcp"
		from_port 	= 9001
		to_port 	= 9022
		protocol	= "tcp"
		self = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "portworx_udp" {
        type ="ingress"
		description = "portworx udp"
		from_port 	= 9002
		to_port 	= 9002
		protocol	= "udp"
		self = true
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}

resource "aws_security_group_rule" "egress" {	
        type ="egress"
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
        security_group_id = aws_security_group.sg_tce_guest_node.id
		}
	


# security group for guest controlplane
resource "aws_security_group" "sg_tce_guest_controlplane" {
	name 		= 	format("%s-%s",var.name_prefix,"sg-guest-controlplane")
	description = 	"TCE guest controlplane"
	vpc_id = aws_vpc.main.id
    
    ingress {
		description = "genev"
		from_port 	= 6081
		to_port 	= 6081
		protocol	= "udp"
		self = true
		}
    ingress {
		description = "antrea1"
		from_port 	= 10349
		to_port 	= 10349
		protocol	= "tcp"
		security_groups = [aws_security_group.sg_tce_guest_node.id]
		}
   	ingress {
		description = "Kubernetes API"
		from_port 	= 6443
		to_port 	= 6443
		protocol	= "tcp"
		self = true
		}  
    ingress {
		description = "Kubernetes API"
		from_port 	= 6443
		to_port 	= 6443
		protocol	= "tcp"
		security_groups = [aws_security_group.sg_tce_guest_node.id]
		}  
    ingress {
		description = "etcd"
		from_port 	= 2379
		to_port 	= 2379
		protocol	= "tcp"
		self = true
		}
    ingress {
		description = "antrea1"
		from_port 	= 10349
		to_port 	= 10349
		protocol	= "tcp"
		self = true
		}
    ingress {
		description = "etcd peer"
		from_port 	= 2380
		to_port 	= 2380
		protocol	= "tcp"
		self = true
		}
    ingress {
		description = "Kubernetes API"
		from_port 	= 6443
		to_port 	= 6443
		protocol	= "tcp"
		security_groups = [aws_security_group.sg_tce_guest_apiserver-lb.id]
		}  
    ingress {
		description = "SSH"
		from_port 	= 22
		to_port 	= 22
		protocol	= "tcp"
		security_groups = [aws_security_group.sg_tce_guest_bastion.id]
		}
    ingress {
		description = "kapp-controller"
		from_port 	= 10100
		to_port 	= 10100
		protocol	= "tcp"
		security_groups = [aws_security_group.sg_tce_guest_node.id]
		}
    ingress {
		description = "genev"
		from_port 	= 6081
		to_port 	= 6081
		protocol	= "udp"
		security_groups = [aws_security_group.sg_tce_guest_node.id]
		}
    
    ingress {
		description = "kapp-controller"
		from_port 	= 10100
		to_port 	= 10100
		protocol	= "tcp"
		self = true
		}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
		}
	tags = {
		Name = format("%s-%s",var.name_prefix,"sg-guest-controlplane")
		}
}