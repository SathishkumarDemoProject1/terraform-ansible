# terraform-ansible

Steps to setup the ansible terraform-control server
1.  `git clone https://github.com/SathishkumarDemoProject1/terraform-ansible.git`
2.  `cd terraform-ansible`
3.  `sh install-ansible-terraform.sh`

Create infra with terraform.
Prerequsites:
1. get access_key and secret_key from aws.
2. create a key-pair "demo" in aws and download the private key file "demo.pem"
update access_key and secret_key in main.tf

1. `cd terraform`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`
5. `cd ../`

Note down the Ip list

Configure your application with ansible
1. update inventory file with above IP.
2. update demo.pem with your demo.pem.
3. `chmod 400 demo.pem`
4. `ansible-playbook main.yaml`
