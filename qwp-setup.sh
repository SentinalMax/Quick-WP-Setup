#!/bin/bash
# Copyright Alex Vergara 2022

if [ "$EUID" -ne 0 ]
	then echo "Program needs to be run as root!"
	exit
fi

echo " ->Installing Apache2" && sudo apt install apache2 -y

if [ ! -d "/var/www/html/wordpress" ] ; then
	echo " ->Wordpress DOES NOT exist, procceding to installation"
	echo " ->Downloading wordpress" && wget http://wordpress.org/latest.tar.gz && tar xfz latest.tar.gz
	echo " ->Moving wordpress to /var/www/html" && sudo mv wordpress/ /var/www/html && sudo rm -r latest.tar.gz
else
	echo " ->Wordpress already installed, continuing installation"
fi

echo " ->Installing PHP dependencies" && sudo apt install php libapache2-mod-php php-mysql php-curl php-dompdf php-imagick php-mbstring php-zip php-intl php-gd -y
echo " ->Installing MySQL Server" && sudo apt install mysql-server -y

# mysql configuration
echo -e "\n" && echo -e "Follow the prompts below to configure your MySQL database! \n"
echo -n "MySQL ROOT password: " && read -r ROOT_PASS
echo -n "wordpress user, name (what the wp user should be in your db): " && read -r WPUSER_NAME
echo -n "wordpress user, password: " && read -r WPUSER_PASS

sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by '$ROOT_PASS';";
sudo mysql -u root -p$ROOT_PASS -e "CREATE USER '$WPUSER_NAME'@localhost IDENTIFIED BY '$WPUSER_PASS';";
sudo mysql -u root -p$ROOT_PASS -e "CREATE DATABASE wp;";
sudo mysql -u root -p$ROOT_PASS -e "GRANT ALL PRIVILEGES ON wp.* TO '$WPUSER_NAME'@'localhost';";

echo -e "\n" && echo -e " ->MySQL is now setup, continuing... \n"
echo " ->Making a 'wp-config.php' file"
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

echo " ->Setting up wordpress (wp-config.php) with MySQL credentials"
FILE=/var/www/html/wordpress/wp-config.php

sudo sed -i 's/database_name_here/wp/' $FILE
sudo sed -i 's/username_here/'$WPUSER_NAME'/' $FILE
sudo sed -i 's/password_here/'$WPUSER_PASS'/' $FILE

echo " ->Configure wordpress communications"
echo "define( 'FS_METHOD', 'direct' );" >> $FILE

echo " ->Setting permissions"
cd /var/www/html/wordpress
sudo chown www-data:www-data  -R * # Let Apache be owner
sudo find . -type d -exec chmod 755 {} \;  # Change directory permissions rwxr-xr-x
sudo find . -type f -exec chmod 644 {} \;  # Change file permissions rw-r--r--

OUTPUT_1="$(who | awk '{print $1}')"

if [[ -n $OUTPUT_1 ]]
then
	echo " ->Setting owner of non critical WP files to $OUTPUT_1"
	sudo chown $OUTPUT_1:$OUTPUT_1  -R * # Let a useraccount be owner
else
	echo " ->Owner defaulting to current ROOT user (WARNING, BE SURE TO CHANGE THIS!)"
	sudo chown root:root  -R * # If this is overriden it's because the program couldn't find any other user accounts running, so perms were given to root. Be sure to change this!
fi
sudo chown www-data:www-data wp-content # Let apache be owner of wp-content

echo " ->Generating salts and appending them to wp-config.php"
#sudo apt install curl #curl is installed by default

OUTPUT_2="$(openssl version)"

if [[ -n $OUTPUT_2 ]]
then
    printf "%s\n" "$OUTPUT_2"
    echo " ->OpenSSL is already installed!"
else
    echo " -> Installing OpenSSL & dependencies" && sudo apt install build-essential checkinstall zlib1g-dev openssl -y
fi

A_AUTH_KEY=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
B_SEC_AUTH_KEY=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
C_LOG_KEY=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
D_N_KEY=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
E_AUTH_SALT=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
F_SEC_AUTH_SALT=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
G_LOG_SALT=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')
H_N_SALT=$(openssl rand -base64 32 | sed -e 's/[]\/$*.^[]/\\&/g')

sudo sed -i "s/AUTH_KEY',         .* $PARTITION_COLUMN.*/AUTH_KEY', '$A_AUTH_KEY');/" $FILE #SECURE AUTH SALT
sudo sed -i "s/SECURE_AUTH_KEY',  .* $PARTITION_COLUMN.*/SECURE_AUTH_KEY', '$B_SEC_AUTH_KEY');/" $FILE #SECURE AUTH KEY
sudo sed -i "s/LOGGED_IN_KEY',    .* $PARTITION_COLUMN.*/LOGGED_IN_KEY', '$C_LOG_KEY');/" $FILE #LOGGED IN SALT
sudo sed -i "s/NONCE_KEY',        .* $PARTITION_COLUMN.*/NONCE_KEY', '$D_N_KEY');/" $FILE #LOGGED IN KEY
sudo sed -i "s/AUTH_SALT',        .* $PARTITION_COLUMN.*/AUTH_SALT', '$E_AUTH_SALT');/" $FILE #NONCE SALT
sudo sed -i "s/SECURE_AUTH_SALT', .* $PARTITION_COLUMN.*/SECURE_AUTH_SALT', '$F_SEC_AUTH_SALT');/" $FILE #NONCE KEY
sudo sed -i "s/LOGGED_IN_SALT',   .* $PARTITION_COLUMN.*/LOGGED_IN_SALT', '$G_LOG_SALT');/" $FILE #AUTH SALT
sudo sed -i "s/NONCE_SALT',       .* $PARTITION_COLUMN.*/NONCE_SALT', '$H_N_SALT');/" $FILE #AUTH KEY