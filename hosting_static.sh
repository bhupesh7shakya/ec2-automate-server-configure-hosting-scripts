#!/bin/bash

echo "Executing server setup script..."

source ./server_setup.sh

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

echo "Enter the content for the HTML file:"
read -r html_content

html="
<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='UTF-8'>
<title>$site_name</title>
</head>
<body>
<h1>$html_content</h1>
</body>
</html>
"

echo "Writing HTML content to index.html..."
echo "$html" | sudo tee "/usr/share/nginx/html/$site_name/index.html" > /dev/null

echo "Creating Nginx configuration file..."
sudo touch "/etc/nginx/conf.d/${site_name}_website.conf"

nginx_file_configuration="
server {
    listen 80;
    server_name _;
    
    root /usr/share/nginx/html/$site_name;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
"

echo "Writing Nginx configuration..."
echo "$nginx_file_configuration" | sudo tee -a "/etc/nginx/conf.d/${site_name}_website.conf" > /dev/null

echo "Reloading Nginx configuration..."
sudo systemctl reload nginx

echo "Script execution complete."
