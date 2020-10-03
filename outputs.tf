output application_lb_dns{
    value = module.phase1.lb_dns
}
output ha_lb_dns{
    value = module.phase2.lb_dns
}