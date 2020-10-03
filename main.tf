data "aws_vpc" "default" {
  default = true
} 
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default.id
}
######################################################
#               PHASE1                               #
######################################################
module phase1_nginx_server{
    source                 = "./modules/nginx-server"
    service_name           = "blah-everc-tf"
    ami_id                 = "ami-0de12f76efe134f2f"
    instance_type          = "t2.micro"
    region                 = var.region
    key_name               = var.key_name
    asg_max_size           = 3
    vpc                    = data.aws_vpc.default
    target_group_arns      = module.alb_nginx.target_group_arns
    asg_desired_capacity   = 2
    additional_lb_rules    = [
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
module "alb_nginx" {
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
  listener_arn           = module.alb_nginx.http_tcp_listener_arns[1]
  action {
    type                 = "forward"
    target_group_arn     = module.alb_nginx.target_group_arns[1]
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

######################################################
#               PHASE2                               #
######################################################
module phase2_nginx_server{
    source                 = "./modules/nginx-server"
    service_name           = "blah-everc-tf"
    ami_id                 = "ami-0de12f76efe134f2f"
    instance_type          = "t2.micro"
    region                 = var.region
    key_name               = var.key_name
    asg_max_size           = 3
    vpc                    = data.aws_vpc.default
    target_group_arns      = module.alb_nginx.target_group_arns
    asg_desired_capacity   = 2

}
module "ha_lb_sg" {
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
module "ha_alb" {
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
module  haproxy{
    source                 = "./modules/ha-proxy"
    autoscaling_group      = module.phase2_nginx_server.autoscaling_group_name
    region                 =var.region
    ami_id                 = "ami-0de12f76efe134f2f"
    instance_type          = "t2.micro"
    key_name               = var.key_name
    number_of_instances    = 2
    target_group_arns      = module.ha_alb.target_group_arns
    additional_lb_rules    = [
    {
            source_security_group_id = "${module.ha_lb_sg.this_security_group_id}"
            from_port                = 80
            to_port                  = 80
            protocol                 = "TCP"
    }
  ]
}