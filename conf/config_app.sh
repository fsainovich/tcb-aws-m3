sudo apt-get update

sudo apt install -y python3-dev libmysqlclient-dev unzip libpq-dev python-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libffi-dev mysql-client python3-pip

sudo pip3 install flask wtforms flask_mysqldb passlib

cd /tmp

sudo cp wikiapp.zip /opt

cd /opt

sudo unzip wikiapp.zip