# Fetching subnet details
data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc.id
}
# Creating Auto Scaling Group For EC2 instnaces
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"
  
  name                            = var.service_name
  image_id                        = var.ami_id 
  instance_type                   = var.instance_type
  user_data                       = file("${path.module}/user-data/user-data.sh")
  security_groups                 = [module.asg_sg.this_security_group_id]
  key_name                        = var.key_name
  # Auto scaling group      
  target_group_arns               = var.target_group_arns 
  asg_name                        = "${var.service_name}-asg"
  vpc_zone_identifier             =  data.aws_subnet_ids.subnets.ids
  min_size                        = 0
  health_check_type               = "EC2"
  max_size                        = var.asg_max_size
  desired_capacity                = var.asg_desired_capacity
  wait_for_capacity_timeout       = 0
  tags                            =[
    {
      key                 = "Environment"
      value               = "Terraform"
      propagate_at_launch = true
    },
    {
      key                 = "ServiceName"
      value               = var.service_name
      propagate_at_launch = true

    }
  ]

}
# Creating LoadBalancer with listner and target group

# Autoscaling security group to allow traffic to port 5000 and 6000 from loadbalancer
module "asg_sg" {
  name                                  = "${var.service_name}-asg-sg"
  source                                = "terraform-aws-modules/security-group/aws"
  vpc_id                                = var.vpc.id
  egress_rules                          = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH Public access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      description = "Internal application port"
      cidr_blocks = var.vpc.cidr_block
    },
    {
      from_port   = 6000
      to_port     = 6000
      protocol    = "tcp"
      description = "Health check port"
      cidr_blocks = var.vpc.cidr_block
    }

  ]
  ingress_with_source_security_group_id =  var.additional_lb_rules

} 

