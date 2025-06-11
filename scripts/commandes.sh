ssh -i id_rsa ubuntu@<IP_ADDRESS>
ssh -i "projet-c-local-key.pem" ubuntu@ec2-35-182-1-216.ca-central-1.compute.amazonaws.com
ansible-playbook -i inventory.ini playbook.yml --ask-vault-password -v 