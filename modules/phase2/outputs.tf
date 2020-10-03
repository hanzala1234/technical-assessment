output aws_instance_ip{
    value = aws_instance.ha_proxy.*.public_ip
}
output lb_dns{
    value = module.alb.this_lb_dns_name
}
