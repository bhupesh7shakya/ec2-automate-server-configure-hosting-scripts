#!/bin/bash

echo "Executing WordPress setup script..."

source ./server_setup.sh

echo "Installing MySQL Server..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

echo "Configuring MySQL..."
sudo mysql_secure_installation <<EOF

n
y
y
y
y
EOF

echo "Enter the site name (without spaces):"
read site_name_input

# Removing leading and trailing spaces from user input
site_name=$(echo "$site_name_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Check if the input contains spaces and prompt again if it does
while [[ $site_name != "${site_name_input}" ]]; do
    echo "Site name should not contain spaces. Enter the site name again:"
    read site_name_input
    site_name=$(echo "$site_name_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
done

echo "Creating directory for the website..."
sudo mkdir "/usr/share/nginx/html/$site_name"

echo "Downloading WordPress..."
sudo wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz

echo "Extracting WordPress..."
sudo tar -xzf /tmp/wordpress.tar.gz -C "/usr/share/nginx/html/$site_name" --strip-components=1

echo "Setting permissions for WordPress..."
sudo chown -R www-data:www-data "/usr/share/nginx/html/$site_name"
sudo find "/usr/share/nginx/html/$site_name" -type d -exec chmod 755 {} \;
sudo find "/usr/share/nginx/html/$site_name" -type f -exec chmod 644 {} \;

echo "Setting up MySQL database and user for WordPress..."
sudo mysql -u root -e "CREATE DATABASE ${site_name}_db;"
sudo mysql -u root -e "CREATE USER '${site_name}_user'@'localhost' IDENTIFIED BY '${site_name}_password';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON ${site_name}_db.* TO '${site_name}_user'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

echo "Configuring WordPress..."
sudo mv "/usr/share/nginx/html/$site_name/wp-config-sample.php" "/usr/share/nginx/html/$site_name/wp-config.php"
sudo sed -i "s/database_name_here/${site_name}_db/g; s/username_here/${site_name}_user/g; s/password_here/${site_name}_password/g" "/usr/share/nginx/html/$site_name/wp-config.php"

echo "Configuring Nginx for WordPress..."
sudo touch "/etc/nginx/conf.d/${site_name}_wordpress.conf"

nginx_wordpress_configuration="
server {
    listen 80;
    server_name $site_name;
    
    root /usr/share/nginx/html/$site_name;
    index index.php;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock; # Update this path if needed
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
"

echo "Writing Nginx configuration..."
echo "$nginx_wordpress_configuration" | sudo tee -a "/etc/nginx/conf.d/${site_name}_wordpress.conf" > /dev/null

echo "Reloading Nginx configuration..."
sudo systemctl reload nginx

echo "WordPress setup completed."
