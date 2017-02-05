#!/bin/bash

if [ "$#" -ne 0 ]; then
    echo "This script install mlmmj-light-web with necessary dependencies."
    exit 1
fi

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "I strongly recommend to run this sctipt only on a clean Debian with only standard system utilities installed (netinst iso)."
read -p "Are you sure to install mlmmj-light-web? [Y/n]: " reply
reply=${reply:-y}
if [[ ! $reply =~ ^[yY][eE][sS]|[yY]$ ]]
then
    echo "Aborted."
    exit 1
fi

read -p "What language are you want mlmmj-light-web to use? [EN/ru]: " reply
reply=${reply:-en}
while :
do
    case "${reply}" in 
    [eE][nN] )
        lang="en"
        break
        ;;
    [rR][uU] )
        lang="ru"
        break
        ;;
    * )
        read -p "Please, write, 'en' or 'ru': " reply
        ;;
    esac
done

sed -i '/language/d' config.txt
echo "language = ${lang}" >> config.txt

read -p "Please enter URL which you will use for mlmmj-light-web. [http://example.com/] : " url
url=${url:-http://example.com/}

sed -i '/web_url/d' config.txt
echo "web_url = ${url}" >> config.txt

echo
echo "Updating package list..."
echo
apt-get update
echo
echo "Installing software..."
echo
apt-get install -y mlmmj apg apache2 libapache2-mod-php5 gcc make
echo
echo "Creating mlmmj user..."
echo
useradd -r -s /bin/false mlmmj
echo "Replacing apache user..."
echo
sed -i 's/www-data/mlmmj/g' /etc/apache2/envvars
echo "Replacing cron task..."
echo '0 */2 * * * /usr/bin/find /var/spool/mlmmj/ -maxdepth 1 -mindepth 1 -type d -exec /usr/bin/mlmmj-maintd -F -d "{}" \' > /etc/cron.d/mlmmj
echo
echo "Updating apache.conf..."
echo
# Replace the third occurence of "AllowOverride None" with "AllowOverride All"
awk '/AllowOverride None/{c++;if(c==3){sub("AllowOverride None","AllowOverride All");c=0}}1' /etc/apache2/apache2.conf > /etc/apache2/apache2_.conf
mv /etc/apache2/apache2_.conf /etc/apache2/apache2.conf
echo "Restarting apache..."
echo
/etc/init.d/apache2 restart
echo
echo "Moving files..."
echo
mv move/exim4.conf /etc/exim4/
mv move/exim4.filter /etc/exim4/
mv move/mlmmj-footer-receive /usr/bin/
cd move/foot_filter
echo "Compiling foot_filter..."
echo
make
echo
echo "Moving files..."
echo
mv foot_filter /usr/bin/
cd ../..
rm -rf move
cd ..
rm -rf /var/www/html/*
cp -rp * /var/www/html/
cd ..
echo "Removing installation files..."
echo
rm -rf mlmmj-light-web
echo "Setting ownership of files..."
echo
chown mlmmj:mlmmj -R /var/www/html
chown mlmmj:mlmmj -R /var/spool/mlmmj
echo "Installation of mlmmj-light-web completed. Please, specify the fully qualified domain name (FQDN) in /etc/hostname and /etc/mailname if you have not done this already. Currently these files contain:"
echo "/etc/hostname: " $(cat /etc/hostname)
echo "/etc/mailname: " $(cat /etc/mailname)
echo
echo "Now visit ${url} in your browser."