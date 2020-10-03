
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
  tags                        = {
       ServiceName = var.service_name
  }
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


resource "aws_lb_target_group_attachment" "test" {
  count                       = (length(var.target_group_arns)>0)?length(aws_instance.ha_proxy):0
  target_group_arn            =  var.target_group_arns[0]
  target_id                   = aws_instance.ha_proxy[count.index].id
  port                        = 80
}

module "ha_sg" {
  name                        = "ha-ec2-sg"
  source                      = "terraform-aws-modules/security-group/aws"
  vpc_id                      = var.vpc.id
  egress_rules                = ["all-all"]
  ingress_with_cidr_blocks    = [
    {
            from_port               = 22
            to_port                 = 22
            protocol                = "tcp"
            description             = "SSH Public access"
            cidr_blocks             = "0.0.0.0/0"
    },
    {
            from_port               = 80
            to_port                 = 80
            protocol                = "tcp"
            description             = "SSH Public access"
            cidr_blocks             = var.vpc.cidr_block

    }
  ]
  ingress_with_source_security_group_id =  var.additional_lb_rules

} 

