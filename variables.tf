variable region{
    type            = string
    description     = "Region for terraform resources"
}
variable key_name{
     type           = string
     description    = "Key value pair for ssh access to ec2 instances"
}
variable service_name{
    default         = "tf-everc"
}
variable instance_type{
    type            = string
    description     = "Instance type to be used for ec2 instances"
}
variable ami_id{
    type             = string
    description      = "Ami id for ec2  instances"
}
variable phase1_service_name{
    type            = string
    description     = "Name of service for phase1"
}
variable phase2_service_name{
    type           = string
    description    = "Name of service for phase2"
}