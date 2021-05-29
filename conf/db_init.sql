create database wikidb;
CREATE USER IF NOT EXISTS wiki@'%' IDENTIFIED BY 'admin123456';
GRANT ALL PRIVILEGES ON wikidb.* TO wiki@'%';
FLUSH PRIVILEGES;