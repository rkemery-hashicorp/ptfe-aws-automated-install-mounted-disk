# ptfe-aws-automated-install-mounted-disk
## Automates the install of Terraform Enterprise to AWS - mounted disk mode.
## Automates A record creation of TFE hostname with GoDaddy API.

### ~ Not for production ~

## Directories

### certs:
* server.crt - pem encoded server certificate
* server.key - pem encoded private key

### config:
* application-settings.json - application settings for terraform install
* replicated.conf - replicated conf to bootstrap installer

### scripts:
* checktfeready.sh - checks to see if tfe instance is read
* godaddy.sh - automatically sets A record in Go Daddy to VM public IP
* sshtoinstance.sh - automatically ssh to AWS VM.

### variables:
* my_ip - list of IPs allowed to access instance - e.g., 127.0.0.1/32
* subnet_cidr - vpc subnet cidr range
* key_name - name of ssh key

### terraform.tfvars
* edit my_ip to IP of choice.
* edit subnet cidr to desired subnet.
* edit key_name is desired.

### main.tf
* creates a vpc with cidr_block of 10.0.0.0/16
* creates a security group allowing SSH, ICMP, HTTPS, and TFE admin ui port to my_ip list
* creates internet gateway to route vpc publicly.
* creates tls_private_key for ssh key generation.
* creates aws_key_pair from tls_private_key.
* creates aws instances of t2.medium, root_block_device of 50gb, and sets the following:
* tfe home directory of /opt/ptfe
* moves tfe license to license directory /etc
* moves application-settings.json to /etc
* moves tls certs to /etc
* moves replicated.conf to /etc
* sets up godaddy script, runs it, then removes it.
* begins the online install of tfe passing parameters for automated install.
* creates elastic ip resource

### sets up several provisioner files to upload:
1. license file
2. tls cert and key
3. application-settings
4. replicated.conf
5. go-daddy script

## what to do
1. modify application-settings.json "hostname": {} and "enc_password": {"value": ""}
2. modify replicated.conf "DaemonAuthenticationPassword" and "TlsBootstrapHostname"
3. mkdir in main.tf working directory called certs and place server.crt and server.key there
4. edit hostname and domain variables in scripts/checktfeready.sh
5. add api secret/key to godaddy.sh
