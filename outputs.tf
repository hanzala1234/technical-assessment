output lb_dns{
    value = module.phase1.lb_dns
}
output ha_instances_ip{
    value = module.phase2.aws_instance_ip
}