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

