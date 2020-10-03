output application_lb_dns{
    value = module.alb_nginx.this_lb_dns_name
}
output ha_lb_dns{
    value = module.ha_alb.this_lb_dns_name
}