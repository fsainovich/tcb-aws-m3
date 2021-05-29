tcb-aws-m3

BootCamp AWS - Module 3 Project

Steps:

    1 - Insert AWS credentials in PARAMETERS.TF (if you changed region, uptade AZ1 and AZ2 in TFVARS.TF)

    2 - Generate your keypair in linux or gitbash (with no passphrase)

    3 - Remove the hostname at end of your public key (after "=" in end off line)

    4 -  Insert path/name of your public key in MAIN.TF:

        public_key = file(CHANGE_IT")

    5 - Run: terraform validate

    6 - If validate is ok, then run: terraform plan

    7 - If plan is ok, then run: terraform apply --auto-approve

    8 - Wait