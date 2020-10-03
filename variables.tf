variable region{
    type            = string
    description     = "Region for terraform resources"
}
variable key_name{
     type           = string
     description    = "Key value pair for ssh access to ec2 instances"
}
variable service_name{
    default = "tf-everc"
}