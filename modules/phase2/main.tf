# Fetching default vpc
data "aws_vpc" "default" {
  default = true
} 
# Fetching subnet details
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
}
data "template_file" "user_data" {
  template                    = "${file("${path.module}/user-data/ha-proxy.tpl")}"
  vars                        = {
    auto_scaling_group   = var.autoscaling_group
    region               = var.region
  }
}
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions             = ["sts:AssumeRole"]

    principals {
           type        = "Service"
           identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy" "ec2_readonly" {
  arn                         = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_instance" "ha_proxy" {
  count                       = var.number_of_instances
  ami                         = var.ami_id
  instance_type               =  var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  key_name                    = var.key_name
  user_data                   = data.template_file.user_data.rendered
  security_groups             = [module.ha_sg.this_security_group_name]
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role                        = aws_iam_role.instance.name
  policy_arn                  = data.aws_iam_policy.ec2_readonly.arn
}
resource "aws_iam_role" "instance" {
  name                        = "instance_role"
  assume_role_policy          = data.aws_iam_policy_document.instance_assume_role_policy.json
}
resource "aws_iam_instance_profile" "instance_profile" {
  name                        = "instance_profile"
  role                        = aws_iam_role.instance.name
}

module "alb" {
  source                    = "terraform-aws-modules/alb/aws"
  version                   = "~> 5.0"
  name                      = "haproxy-alb"
  load_balancer_type        = "application"
  vpc_id                    = data.aws_vpc.default.id
  subnets                   = data.aws_subnet_ids.subnets.ids
  security_groups           = [module.lb_sg.this_security_group_id]
  target_groups = [
    {
      name                = "haproxy-target-group"
      backend_protocol    = "HTTP"
      backend_port        = 80
      target_type         = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Terraform"
  }
}
resource "aws_lb_target_group_attachment" "test" {
  count            = length(aws_instance.ha_proxy)
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = aws_instance.ha_proxy[count.index].id
  port             = 80
}
module "lb_sg" {
  source = "terraform-aws-modules/security-group/aws"
  egress_rules = ["all-all"]
  
  name                     = "haproxy-alb-sg"
  description              = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id                   = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
           from_port               = 80
           to_port                 = 80
           protocol                = "TCP"
           description             = "HTTP port"
           cidr_blocks             = "0.0.0.0/0"
    }
    
    ]
}
module "ha_sg" {
  name                                  = "ha-ec2-sg"
  source                                = "terraform-aws-modules/security-group/aws"
  vpc_id                                = data.aws_vpc.default.id
  egress_rules                          = ["all-all"]
  ingress_with_cidr_blocks = [
    {
            from_port               = 22
            to_port                 = 22
            protocol                = "tcp"
            description             = "SSH Public access"
            cidr_blocks             = "0.0.0.0/0"
    }
  ]
  ingress_with_source_security_group_id = [
    {
            source_security_group_id = "${module.lb_sg.this_security_group_id}"
            from_port                = 80
            to_port                  = 80
            protocol                 = "TCP"
    }
  ]

} 

