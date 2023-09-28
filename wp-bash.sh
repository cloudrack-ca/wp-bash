#!/bin/bash
# This script is meant to be run on a fresh install of Ubuntu 18.04 LTS
# This script is meant to be run as root

# Define colors
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Prompt user to define PHP version
echo -e "${YELLOW}Enter PHP version (e.g. 8.1): ${NC}"
read php_version

# Prompt user to define WordPress version
echo -e "${YELLOW}Enter WordPress version (e.g. latest): ${NC}"
read wp_version

# Prompt user to define WordPress directory
echo -e "${YELLOW}Enter WordPress directory (e.g. /var/www/html/wordpress): ${NC}"
read wp_dir

# Add PHP repository
echo -e "${BLUE}Adding PHP $php_version repository...${NC}"
add-apt-repository -y ppa:ondrej/php &>> install.log

# Update apt
echo -e "${GREEN}Updating apt...${NC}"
apt-get update &>> install.log

# Install required packages
echo -e "${BLUE}Installing required packages...${NC}"
apt-get install -y apache2 mysql-server php$php_version libapache2-mod-php$php_version php$php_version-mysql php$php_version-curl php$php_version-gd php$php_version-mbstring php$php_version-xml php$php_version-xmlrpc php$php_version-soap php$php_version-intl php$php_version-zip curl &>> install.log

# Download and extract WordPress
echo -e "${BLUE}Downloading and extracting WordPress $wp_version...${NC}"
wget -q https://wordpress.org/$wp_version.tar.gz -O - | tar -xz -C /tmp &>> install.log
mv /tmp/wordpress $wp_dir
chown -R www-data:www-data $wp_dir
chmod -R 755 $wp_dir

# Configure Apache to serve WordPress
echo -e "${BLUE}Configuring Apache to serve WordPress...${NC}"
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf
sed -i "s|DocumentRoot /var/www/html|DocumentRoot $wp_dir|" /etc/apache2/sites-available/wordpress.conf
sed -i "s|<Directory /var/www/html>|<Directory $wp_dir>|" /etc/apache2/sites-available/wordpress.conf
a2dissite 000-default.conf &>> install.log
a2ensite wordpress.conf &>> install.log
systemctl reload apache2 &>> install.log

# Install WordPress CLI
echo -e "${BLUE}Installing WordPress CLI...${NC}"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &>> install.log
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Set PHP.ini settings
echo -e "${BLUE}Setting PHP.ini settings...${NC}"
mkdir -p /etc/php/$php_version/apache2/
touch /etc/php/$php_version/apache2/php.ini
sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/$php_version/apache2/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php/$php_version/apache2/php.ini
sed -i 's/post_max_size = .*/post_max_size = 64M/' /etc/php/$php_version/apache2/php.ini

# Restart Apache
echo -e "${GREEN}Restarting Apache...${NC}"
systemctl restart apache2 &>> install.log
