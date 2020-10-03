# Technical Assesment  Terraform Script

Before running terraform script , aws environment needs to be configured. Secret key and Secret access key is required. There are multiple options for configuring aws environment:

1) Configure CLI
type the following command in bash ; It will prompt you for keys

*) aws configure 

2) Configure Environment Variable

export AWS_ACCESS_KEY_ID = xxxxx
export AWS_SECRET_ACCESS_KEY =  xxxxxx


## To Run  Terraform Script

Before running terraform script, s3 bucket and key-value pair needs to be created in aws.

provide s3 details in provider.tf file in s3 section.

Multiple terraform variables needs to be configured.

Following is sample terraform.tfvars file

```
region   = "eu-west-3"
key_name = "blahblah" 
phase1_service_name = "blabla-tf-ever-com"
phase2_service_name = "blabla-tf.ever-io"
ami_id              = "ami-0de12f76efe134f2f"
instance_type       = "t2.micro"
```

Once all terraform variables are configured , terraform script needs to be run with following commands:

```
terraform init
terraform apply
```

Once above command runs successfully, it will generate loadbalalncer dns names; following is the sample output 


```
Apply complete! Resources: 44 added, 0 changed, 0 destroyed.

Outputs:

application_lb_dns = blabla-tf-ever-com-alb-1791928046.eu-west-3.elb.amazonaws.com
ha_lb_dns = haproxy-alb-1663253381.eu-west-3.elb.amazonaws.com
````

Add dns entires in /etc/hosts files  with appropirate service dns:

check the endpoints by:

curl <dns-name>/              --- For default page
curl <dns-name>/health.html   --- For Hostname