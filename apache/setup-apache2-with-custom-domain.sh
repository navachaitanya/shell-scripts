#!/bin/bash
####################################################################################
# Author Name:
# Company Name (If Applicable):
# website Name:
# Follow below steps to run script to setup Apache with your custom domain name
# wget https://raw.githubusercontent.com/navachaitanya/shell-scripts/master/apache/setup-apache2-with-custom-domain.sh
# sudo chmod 755 setup-apache2-with-custom-domain.sh
# ./setup-apache2-custom-domain.sh
# Run script in single command
# wget https://raw.githubusercontent.com/navachaitanya/shell-scripts/master/apache/setup-apache2-with-custom-domain.sh; sudo chmod 755 setup-apache2-with-custom-domain.sh; ./setup-apache2-custom-domain.sh

####################################################################################
echo "Enter the root password if needed"
sudo -i
echo "hello... $USER !"
echo "This script made only for RPM based Linux like RHEL | CENTOS | Amazon Linux 2"
echo "Checking if Apache is already installed!"
if [[ -z $(apache2 -v 2>/dev/null) ]] && [[ -z $(httpd -v 2>/dev/null) ]];
then
    echo "Apache not found... Installing Apache"
    sudo yum install httpd -y
else
    echo "Apache already installed"
fi
echo "Restarting Apache...!"
service httpd restart
echo "Apache Restarted"
echo "---------------"
echo 'Initiliazing to create a subdomain folder in the Path "/etc/httpd/conf.d/'
cd /etc/httpd/conf/
echo 'Enter your custom domain name (Enter domain name without www and with .com only, example: google.com):'
read custom_domain_name
## Get dir name from command line args
# if $1 not passed, fall back to current directory
install_root_dir="${1:-${PWD}}"
apache_webroot="/var/www/html"
apache_user="www"
echo $install_root_dir
echo "printing pwd"
pwd
echo "above line is pwd"
#sudo mkdir ${custom_domain_name}
#echo "${custom_domain_name} has been created."
echo 'Changing user permission to webroot config'
#sudo chown $USER:$USER ${custom_domain_name}
sudo touch ${apache_webroot}/index.html
sudo chown $apache_user:$apache_user ${apache_webroot}/index.html
echo 'Creating Certbot SSL Certificate'
sudo certbot certonly -d ${custom_domain_name},${custom_domain_name}.com
sudo cat >>  ${apache_webroot}/index.html <<EOL
        <h1>Hello!</h1>
        <h2> Welcome to your ${custom_domain_name} ...!</h2>
        <h3> Your ${custom_domain_name} is working!</h3>
        <h4>Start deploying your ${custom_domain_name} code...</h4>
        <h5>See you soon.....!</h5>
EOL
echo 'Creating virtualhost for ${custom_domain_name}'
sudo touch ${custom_domain_name}.conf
sudo chown $apache_user:$apache_user /${custom_domain_name}.conf
sudo cat >> ${custom_domain_name}.conf <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot "/var/www/html"
    ServerName ${custom_domain_name}
    ServerAlias www.${custom_domain_name}
    ProxyPassMatch "^/nes/(.*)$" "http://localhost:8080/nes/$1"
    ProxyPassMatch "^/manager/" "http://localhost:8080"
RewriteEngine on
RewriteCond %{SERVER_NAME} =www.${custom_domain_name} [OR]
RewriteCond %{SERVER_NAME} =${custom_domain_name}
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOL

sudo cat >>${custom_domain_name}.conf <<EOL
<VirtualHost *:443>
    ServerName ${custom_domain_name}
    ServerAlias "www.${custom_domain_name}"
    DocumentRoot "/var/www/html"
	ErrorLog \${APACHE_LOG_DIR}/${custom_domain_name}.error.log
	CustomLog \${APACHE_LOG_DIR}/${custom_domain_name}.access.log combined
	DirectoryIndex index.html index.cgi index.php
	<Directory $install_root_dir/${custom_domain_name}/public/>
		Options Indexes FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>
	# Example SSL configuration
	SSLEngine on
	SSLProtocol all -SSLv2
	SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5
	RewriteCond %{HTTP_HOST} !^www.${custom_domain_name}$
	RewriteRule ^(.*)$ https://www.${custom_domain_name}$1 [R=302,L]
    ProxyPassMatch "^/nes/(.*)$" "http://localhost:8080/nes/$1"
    ProxyPassMatch "^/manager/" "http://localhost:8080"
	Include /etc/letsencrypt/options-ssl-apache.conf
	SSLCertificateFile /etc/letsencrypt/live/${custom_domain_name}/fullchain.pem
	SSLCertificateKeyFile /etc/letsencrypt/live/${custom_domain_name}/privkey.pem
</VirtualHost>
EOL
sudo cat ${install_root_dir}/${custom_domain_name}.conf
sudo systemctl restart apache2
echo 'Install Apache and configured Apache with custom domain name'
echo 'Removing the ShellScript'
sudo rm -rf setup-apache2-with-custom-domain.sh
echo "Completed script"
