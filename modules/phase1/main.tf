# Fetching default vpc
data "aws_vpc" "default" {
  default = true
} 
# Fetching subnet details
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
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
  target_group_arns               = module.alb.target_group_arns
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
    }
  ]

}
# Creating LoadBalancer with listner and target group
module "alb" {
  source                    = "terraform-aws-modules/alb/aws"
  version                   = "~> 5.0"
  name                      = "${var.service_name}-alb"
  load_balancer_type        = "application"
  vpc_id                    = data.aws_vpc.default.id
  subnets                   = data.aws_subnet_ids.subnets.ids
  security_groups           = [module.lb_sg.this_security_group_id]
  target_groups = [
    {
      name                = "${var.service_name}-default-group"
      backend_protocol    = "HTTP"
      backend_port        = 5000
      target_type         = "instance"
      health_check        =  {
             enabled   = true
             port      = 6000
             path      = "/health.html"
             protocol  = "HTTP"
      }
    },
      {
      name                 = "${var.service_name}-health-group"
      backend_protocol     = "HTTP"
      backend_port         = 6000
      target_type          = "instance"
      health_check         =  {
           enabled     = true
           port        = 6000
           path        = "/health.html"
           protocol    = "HTTP"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 8080
      protocol           = "HTTP"
      action_type        = "redirect"
      redirect           = {
           port              = "80"
           protocol          = "HTTP"
           status_code       = "HTTP_301"
      }
    }
    ,
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

# listner rule for  /health.html endpoint

resource "aws_lb_listener_rule" "health" {
  listener_arn           = module.alb.http_tcp_listener_arns[1]
  action {
    type                 = "forward"
    target_group_arn     = module.alb.target_group_arns[1]
  }
  condition {
    path_pattern {
         values = ["/health.html"]
    }
  }
  
}
# Loadbalancer security group to allow traffic to port 80 and 8080 from public internet
module "lb_sg" {
  source = "terraform-aws-modules/security-group/aws"
  egress_rules = ["all-all"]
  
  name                     = "${var.service_name}-alb-sg"
  description              = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id                   = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
           from_port              = 8080
           to_port                = 8080
           protocol               = "TCP"
           description            = "HTTPs stimulation port"
           cidr_blocks            = "0.0.0.0/0"
    },
    {
           from_port               = 80
           to_port                 = 80
           protocol                = "TCP"
           description             = "HTTP port"
           cidr_blocks             = "0.0.0.0/0"
    }
    
    ]
}
# Autoscaling security group to allow traffic to port 5000 and 6000 from loadbalancer
module "asg_sg" {
  name                                  = "${var.service_name}-asg-sg"
  source                                = "terraform-aws-modules/security-group/aws"
  vpc_id                                = data.aws_vpc.default.id
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
      cidr_blocks = data.aws_vpc.default.cidr_block
    },
    {
      from_port   = 6000
      to_port     = 6000
      protocol    = "tcp"
      description = "Health check port"
      cidr_blocks = data.aws_vpc.default.cidr_block
    }

  ]
  ingress_with_source_security_group_id = [
    {
            source_security_group_id = "${module.lb_sg.this_security_group_id}"
            from_port                = 5000
            to_port                  = 5000
            protocol                 = "TCP"
    },
    {
            source_security_group_id = "${module.lb_sg.this_security_group_id}"
            from_port                = 6000
            to_port                  = 6000
            protocol                 = "TCP"
    }
  ]

} 

