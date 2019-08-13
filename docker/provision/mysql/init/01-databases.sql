# create databases
CREATE DATABASE IF NOT EXISTS `content`;
CREATE DATABASE IF NOT EXISTS `checkout`;
CREATE DATABASE IF NOT EXISTS `oms`;

# create magento2 user and grant rights
CREATE USER 'magento2'@'%' IDENTIFIED BY 'magento2';
GRANT ALL PRIVILEGES ON *.* TO 'magento2'@'%';