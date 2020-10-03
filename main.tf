module phase1{
    source                 = "./modules/phase1"
    service_name           = "blah-everc-tf"
    ami_id                 = "ami-0de12f76efe134f2f"
    instance_type          = "t2.micro"
    region                 = var.region
    key_name               = var.key_name
    asg_max_size           = 3
    asg_desired_capacity   = 2
}
module phase2{
    source                 = "./modules/phase2"
    autoscaling_group      = module.phase1.autoscaling_group_name
    region                 =var.region
    ami_id                 = "ami-0de12f76efe134f2f"
    instance_type          = "t2.micro"
    key_name               = var.key_name
    number_of_instances    = 2
}