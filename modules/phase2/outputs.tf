output aws_instance_ip{
    value = aws_instance.ha_proxy.*.public_ip
}

