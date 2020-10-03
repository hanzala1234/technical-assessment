variable service_name{
    type            = string
    description     = "Name of service"
}
variable ami_id{
    type            = string
    description     = "ami id to be used for instances"
}
variable instance_type{
    type            = string
    description     = "Instance type for ec2"
}
variable region{
    type            = string
    description     = "Region for terraform resources"
}
variable key_name{
     type           = string
     description    = "Key value pair for ssh access to ec2 instances"
}
variable asg_max_size{
    type            = number
    description     = "Max number of instances for asg"
}
variable asg_desired_capacity{
    type           = number
    description    = "Desired number of instances for asg"
}
variable additional_lb_rules{
    description  = "security gropu rules for granting access to loadbalancer"
    default      = []
}
variable target_group_arns{
    type        = list(string)
    description = "Target groups to attach ec2 instances"
    default     = []
}
variable vpc{
    description = "VPC for ec2 instances"
}