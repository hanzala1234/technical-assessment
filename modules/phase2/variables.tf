
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
variable autoscaling_group{
    type             = string
    description      = "Autoscaling group name for haproxy backend servers"
}
variable number_of_instances{
    type             = number
    description      = "Number of instances for ha proxy"
}