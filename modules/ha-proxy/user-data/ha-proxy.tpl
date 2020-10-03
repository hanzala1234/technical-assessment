#!/bin/bash
yum install -y haproxy

echo "
global
   log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats


defaults
     log global
     mode http
     option httplog
     option dontlognull
     timeout connect 5000
     timeout client 50000
     timeout server 50000

frontend http_front
     bind *:80
     acl health path_end -i /health.html
     stats uri /haproxy?stats
     use_backend health_back  if health
     default_backend http_back

backend http_back" > /etc/haproxy/haproxy.cfg

echo -e "\t balance roundrobin
\t option httpchk GET /health.html
\t http-check expect status 200" >> /etc/haproxy/haproxy.cfg
for i in `aws autoscaling describe-auto-scaling-groups --region ${region} --auto-scaling-group-name ${auto_scaling_group} | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`; 
do
 echo -e "\t server myserver $(aws ec2 describe-instances --instance-ids $i --region eu-west-3 | grep -i PrivateIpAddress | awk '{ print $2 }' | head -1 | cut -d"," -f1| tr -d '"' ):5000  check port 6000" >> /etc/haproxy/haproxy.cfg ; 
done;
echo "backend health_back" >> /etc/haproxy/haproxy.cfg
echo -e "\t balance roundrobin
\t option httpchk GET /health.html
\t http-check expect status 200" >> /etc/haproxy/haproxy.cfg
for i in `aws autoscaling describe-auto-scaling-groups --region ${region} --auto-scaling-group-name ${auto_scaling_group} | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`; 
do
 echo -e "\t server myserver $(aws ec2 describe-instances --instance-ids $i --region eu-west-3 | grep -i PrivateIpAddress | awk '{ print $2 }' | head -1 | cut -d"," -f1| tr -d '"' ):6000  check port 6000" >> /etc/haproxy/haproxy.cfg ; 
done;
systemctl restart haproxy
systemctl enable haproxy