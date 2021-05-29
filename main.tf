# Create a VPC
resource "aws_vpc" "VPC_BOOTCAMP" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "VPC_BOOTCAMP"
  }
}

# Public subnet 
resource "aws_subnet" "PUBLIC_SUBNET" {
  vpc_id                  = aws_vpc.VPC_BOOTCAMP.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.AZ1
  map_public_ip_on_launch = true  

  tags = {
    Name = "Public_Subnet"
  }
}

# Private subnet 1
resource "aws_subnet" "PRIVATE_SUBNET1" {
  vpc_id                  = aws_vpc.VPC_BOOTCAMP.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.AZ1
  map_public_ip_on_launch = false  

  tags = {
    Name = "Private_Subnet1"
  }
}

# Private subnet 2
resource "aws_subnet" "PRIVATE_SUBNET2" {
  vpc_id                  = aws_vpc.VPC_BOOTCAMP.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.AZ2
  map_public_ip_on_launch = false  

  tags = {
    Name = "Private_Subnet2"
  }
}

# Internet gateway for public subnet
resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.VPC_BOOTCAMP.id

  tags = {
    Name = "Internet_Gateway"
  }
}

# routing table for VPC
resource "aws_route_table" "ROUTE_TABLE" {
  vpc_id = aws_vpc.VPC_BOOTCAMP.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }

  tags = {
    Name = "Routing_Table"
  }
}

# Assign Public_Subnet to routing table
resource "aws_route_table_association" "RT_PUBLIC" {
  subnet_id      = aws_subnet.PUBLIC_SUBNET.id
  route_table_id = aws_route_table.ROUTE_TABLE.id
}

# Security group allow WebServer Public Access (22 and 8080)
resource "aws_security_group" "WEBSERVER_ACCESS" {
  name        = "Allow WEBSERVER_ACCESS"
  description = "Allow 22 and 8080 inbound traffic"
  vpc_id      = aws_vpc.VPC_BOOTCAMP.id

  ingress {
    description      = "SSH ACCESS"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
  }

  ingress {
    description      = "HTTP ACCESS"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]    
  }  

  tags = {
    Name = "SG_Public_Access"
  }
}

# Security group allow DB access from VPC
resource "aws_security_group" "DB_ACCESS" {
  name        = "Allow DB_ACCESS"
  description = "Allow MYSQL PORT 3306 inbound traffic"
  vpc_id      = aws_vpc.VPC_BOOTCAMP.id

  ingress {
    description      = "MYSQL ACCESS"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.VPC_BOOTCAMP.cidr_block]
  } 

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]    
  }  

  tags = {
    Name = "SG_Private_BD_Access"
  }
}

# Registering Public Key generated localy
resource "aws_key_pair" "M3KEY_PUB" {
  key_name   = "M3KEY_PUB"
  public_key = file("M3KEY.pub")

  tags = {
    Name = "Public_KEY_M3"
  }
}

#Create DB subnet group aws_db_instance requirement 
resource "aws_db_subnet_group" "DB_SUBNET_PRIVATE_GROUP" {
  name       = "private_group"
  subnet_ids = [aws_subnet.PRIVATE_SUBNET1.id, aws_subnet.PRIVATE_SUBNET2.id]

   tags = {
    Name = "DB_Subnet_Group"
  }
}

#Create DB RDS instance
resource "aws_db_instance" "AWS-DB-MYSQL-1" {
 
  allocated_storage         = 20
  max_allocated_storage     = 25
  engine                    = "mysql"  
  engine_version            = "5.7.30"  
  instance_class            = "db.t2.micro"
  name                      = "AWSDBMYSQL1"
  username                  = "admin"
  password                  = "admin123456"
  parameter_group_name      = "default.mysql5.7"
  skip_final_snapshot       = true
  apply_immediately         = true
  availability_zone         = var.AZ1
  backup_retention_period   = 0  
  deletion_protection       = false
  vpc_security_group_ids    = [aws_security_group.DB_ACCESS.id]
  db_subnet_group_name      = aws_db_subnet_group.DB_SUBNET_PRIVATE_GROUP.name

  tags = {
    Name = "RDS_MYSQL_DB"
  }
}

#Create EC2 instante
resource "aws_instance" "WEBSERVER" {

   depends_on = [
    aws_db_instance.AWS-DB-MYSQL-1
  ]

  key_name                = aws_key_pair.M3KEY_PUB.key_name
  ami                     = "ami-0747bdcabd34c712a"
  instance_type           = "t2.micro"  
  subnet_id               = aws_subnet.PUBLIC_SUBNET.id
  disable_api_termination = false
  ebs_optimized           = false
  hibernation             = false
  monitoring              = false
  vpc_security_group_ids  = [aws_security_group.WEBSERVER_ACCESS.id]

  root_block_device {
    volume_size           = "20"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }

  credit_specification {
          cpu_credits = "standard"
  }  
  
  provisioner "file" {
    content     = "sudo mysql -u ${aws_db_instance.AWS-DB-MYSQL-1.username} -p${aws_db_instance.AWS-DB-MYSQL-1.password} -h ${aws_db_instance.AWS-DB-MYSQL-1.address} < /tmp/db_init.sql"
    destination = "/tmp/config_db_init.sh"
  }

  provisioner "file" {
    content     = "sudo mysql -u ${aws_db_instance.AWS-DB-MYSQL-1.username} -p${aws_db_instance.AWS-DB-MYSQL-1.password} -h ${aws_db_instance.AWS-DB-MYSQL-1.address} < /tmp/dump.sql"
    destination = "/tmp/config_db_load.sh"
  }
  
  provisioner "file" {
    source = "conf/db_init.sql"
    destination = "/tmp/db_init.sql"
  }

  provisioner "file" {
    source = "conf/dump.sql"
    destination = "/tmp/dump.sql"
  }
  
  provisioner "file" {
    source = "conf/config_db.sh"
    destination = "/tmp/config_db.sh"
  }

  provisioner "file" {
    source = "conf/config_app.sh"
    destination = "/tmp/config_app.sh"
  }

  provisioner "file" {
    source = "conf/sequence.sh"
    destination = "/tmp/sequence.sh"
  }

  provisioner "file" {
    source = "conf/startapp.sh"
    destination = "/tmp/startapp.sh"  
  }

  provisioner "file" {
    source = "conf/wikiapp.zip"
    destination = "/tmp/wikiapp.zip"
  }  

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/*.sh",       
      "sudo cp /tmp/*.sh /usr/local/bin/", 
      "sudo bash /usr/local/bin/sequence.sh", 
      "sudo sed -i 's/'dbserver01'/'${aws_db_instance.AWS-DB-MYSQL-1.address}'/g' /opt/wikiapp/wiki.py", 
      "sudo nohup python3 /opt/wikiapp/wiki.py & ",
      "sudo ps aux | grep wiki "
    ]
    
  }

  connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file("M3KEY")
  }

  tags = {
    Name = "EC2_WEBSERVER"
  }
}

#Create EC2 root EBS snapshot
resource "aws_ebs_snapshot" "EC2_SNAPSHOT" {
 depends_on = [
    aws_instance.WEBSERVER
  ]

  volume_id = aws_instance.WEBSERVER.root_block_device[0].volume_id

  timeouts {
    create = "15m"  
  }
  
  tags = {
    Name = "EC2 SnapShot"
  }
}