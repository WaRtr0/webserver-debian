#!/bin/bash

#default

#iRedMail_bug#iRedMailLink='https://github.com/iredmail/iRedMail/archive/refs/tags/1.6.2.tar.gz'
organisationName='virtualutiliy'
organisationDomain='virtualutiliy.net'
defaultUser='defaultuser'
passRootMysql=$(date +%S"webserverpassRootMysql" | sha256sum | base64 | head -c 32)
#iRedMail_bug#passFirstMail=$(date +%N"webserverpassFirstMail" | sha256sum | base64 | head -c 32)
#\default

read -p 'Organisation Name : ' -i $organisationName organisationName
read -p 'Organisation Domain : ' -i $organisationDomain organisationDomain
read -p 'Default username for all access outside the chroot : ' -i $defaultUser defaultUser
adduser "$defaultUser"
read -s -p 'STRONG Pass Mysql root : ' -i $passRootMysql passRootMysql
#iRedMail_bug#read -s -p 'STRONG Pass first mail : ' -i $passFirstMail passFirstMail

#uninstall VNC (For contabo)
#apt remove xfce4 xfce4-goodies tightvncserver dbus-x11 vncviewer xvnc4viewer -y

#see later...
apt install nginx -y
systemctl stop nginx
systemctl disable nginx

apt install apache2 neofetch -y

systemctl stop apache2
rm -r /var/www/html/

rm /etc/update-motd.d/*
cat << EOF > /etc/update-motd.d/0-neofetch
#!/bin/sh
/bin/neofetch
EOF

chmod +x /etc/update-motd.d/*

echo '' > /etc/motd

echo "$organisationDomain" > /etc/hostname #change hostname

varip=$(/bin/hostname -i)
varhostname=$(/bin/hostname)
grep -v $varhostname /etc/hosts > /etc/tempHost && mv /etc/tempHost /etc/hosts
echo "$varip webserver.$organisationDomain webserver $organisationName" >> /etc/hosts

hostnamectl set-hostname "webserver.$organisationDomain"

#basic lib/bin
apt install git imagemagick ffmpeg libvips libvips-tools libreoffice sudo -y

#install passenger
apt install dirmngr gcc gzip dialog gnupg apt-transport-https ca-certificates mariadb-server curl -y

curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/phusion.gpg >/dev/null

sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bullseye main > /etc/apt/sources.list.d/passenger.list'

apt update -y
apt upgrade -y

apt install -y passenger

apt install -y libapache2-mod-passenger

echo "PassengerDefaultUser www-data" > "/etc/apache2/mods-available/passenger-user.load"

a2enmod passenger
a2enmod passenger-user

apache2ctl restart
systemctl stop apache2

apt install binutils debootstrap -y

/sbin/groupadd chrootgrp

grep -v Subsystem /etc/ssh/sshd_config > /etc/ssh/tmpshhconf && mv /etc/ssh/tmpshhconf /etc/ssh/sshd_config


cat << EOF >> /etc/ssh/sshd_config
Match all

Subsystem sftp internal-sftp
Match user $defaultUser
	X11Forwarding no
    AllowTcpForwarding no
Match group chrootgrp
    ChrootDirectory /var/www/vhosts/%u
    X11Forwarding no
    AllowTcpForwarding no
Match all
EOF

systemctl restart ssh
systemctl restart sshd

mkdir /var/www/vhosts

/sbin/debootstrap --arch amd64 bullseye /var/www/vhosts/templateUser http://deb.debian.org/debian

/bin/mount --bind /dev/pts /var/www/vhosts/templateUser/dev/pts

mkdir /var/www/vhosts/templateUser/var/app
mkdir /var/www/vhosts/templateUser/var/app/{errors_docs,system,www}
mkdir /var/www/vhosts/templateUser/var/app/system/{cache,logs}

cp /etc/skel/.??* /var/www/vhosts/templateUser/var/app/

mount -B /dev/pts/ /var/www/vhosts/templateUser/dev/pts/

apt install software-properties-common -y

apt update -y
apt upgrade -y

apt install libapache2-mod-fcgid -y

a2enmod actions fcgid alias proxy_fcgi
systemctl restart apache2
systemctl stop apache2

cd /home/$defaultUser

#iRedMail_bug#wget $iRedMailLink

#iRedMail_bug#tar zxf *.tar.gz
#iRedMail_bug#rm *.tar.gz
#iRedMail_bug#cd */

cat << EOF > config
export STORAGE_BASE_DIR='/var/vmail'
export DISABLE_WEB_SERVER='YES'
export WEB_SERVER=''
export BACKEND_ORIG='MARIADB'
export BACKEND='MYSQL'
export USE_FAIL2BAN='YES'
export DOMAIN_ADMIN_PASSWD_PLAIN='$passFirstMail'
export MYSQL_ROOT_PASSWD='$passRootMysql'
export FIRST_DOMAIN='$organisationDomain'
export VMAIL_DB_BIND_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export VMAIL_DB_ADMIN_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export MLMMJADMIN_API_AUTH_TOKEN='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export NETDATA_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export AMAVISD_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export IREDADMIN_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export RCM_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export SOGO_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export SOGO_SIEVE_MASTER_PASSWD='$(date +%s"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export IREDAPD_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
export FAIL2BAN_DB_PASSWD='$(date +%N"$passRootMysql$organisationName" | sha256sum | base64 | head -c 32)'
#EOF
EOF

apt install expect -y

#iRedMail_bug#cat << EOF > execScript.sh
#iRedMail_bug##!/usr/bin/expect -f
#iRedMail_bug#set timeout -1
#iRedMail_bug#spawn bash iRedMail.sh
#iRedMail_bug#expect {< Question > Use it for mail server setting? \[y|N\]}
#iRedMail_bug#send -- "y\r"
#iRedMail_bug#expect {< Question > File: /etc/nftables.conf, with SSHD ports: 22. \[Y|n\]}
#iRedMail_bug#send -- "y\r"
#iRedMail_bug#expect {< Question > Restart firewall now (with ssh ports: 22)? \[y|N\]}
#iRedMail_bug#send -- "y\r"
#iRedMail_bug#expect eof
#iRedMail_bug#EOF

#iRedMail_bug#chmod u+x execScript.sh

#iRedMail_bug#./execScript.sh

##conf apache

a2dissite 000-default.conf

cp -r /var/www/vhosts/templateUser /var/www/vhosts/default

mkdir /var/www/vhosts/default/var/app/www/{default,cgi-bin}
mkdir /var/www/vhosts/default/var/app/www/default
mkdir /var/www/vhosts/default/var/app/www/default
chown -R www-data:www-data /var/www/vhosts/default/var/app

rm /etc/apache2/sites-available/*

cat << EOF > /etc/apache2/sites-available/default.conf
<VirtualHost $varip:80>
	ServerName "default"
	UseCanonicalName Off
	DocumentRoot "/var/www/vhosts/default/var/app/www/default"
	ScriptAlias /cgi-bin/ "/var/www/vhosts/default/var/app/www/cgi-bin"

	<Directory "/var/www/vhosts/default/var/app/www/cgi-bin">
		AllowOverride None
		Options None
		Order allow,deny
		Allow from all
	</Directory>

	<Directory /var/www/vhosts/default/var/app/www/default>
		<IfModule mod_php4.c>
			php_admin_flag engine on
		</IfModule>
		<IfModule mod_php5.c>
			php_admin_flag engine on
		</IfModule>
		<IfModule mod_php7.c>
			php_admin_flag engine on
		</IfModule>
	</Directory>
</VirtualHost>

<IfModule mod_ssl.c>
	<VirtualHost $varip:443>
		ServerName "default"
		UseCanonicalName Off
		DocumentRoot "/var/www/vhosts/default/var/app/www/default"
		ScriptAlias /cgi-bin/ "/var/www/vhosts/default/var/app/www/cgi-bin"

		SSLEngine on

		SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
        	SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

		<Directory "/var/www/vhosts/default/var/app/www/cgi-bin">
			AllowOverride None
			Options None
			Order allow,deny
			Allow from all
		</Directory>

		<Directory /default/var/app/www/default>
			<IfModule mod_php4.c>
				php_admin_flag engine on
			</IfModule>
			<IfModule mod_php5.c>
				php_admin_flag engine on
			</IfModule>
			<IfModule mod_php7.c>
				php_admin_flag engine on
			</IfModule>
		</Directory>
	</VirtualHost>
</IfModule>
EOF

curl -sSL https://packages.sury.org/php/README.txt | bash -x
apt update -y
apt upgrade -y

#echo 'ChrootDir "/var/www/vhosts"' > /etc/apache2/apache2.conf

curl -sSL https://packages.sury.org/php/README.txt | sudo bash -x
sudo apt update

#install cerbot = certificate ssl

apt install snapd -y

snap install core
snap refresh core

snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot

#install tools 
mkdir /etc/webserver
cd /etc/webserver
git clone https://github.com/WaRtrO89/webserver-debian.git
mv webserver-debian/tools/ tools/
rm -r webserver-debian
mkdir certificate

ln -s /etc/webserver/tools/init.sh /bin/webserver


apt install php-pear apache2-dev gcc make zlib1g zlib1g-dev libpcre2-posix2 libpcre2-dev -y


#install memcached

apt install memcached libmemcached-tools -y
apt install python3-pymemcache libcache-memcached-libmemcached-perl -y
systemctl start memcached
systemctl enable memcached

cat << EOF > /etc/memcached.conf
-l 127.0.0.1
-U 0
-p 11211
-u memcache
-m 500
EOF

#apt install php-redis php-opcache php-memcache php-memcached -y

#install xcachce

#apt install php-xcache -y

#cd /home/$defaultUser
#mkdir xcache
#cd xcache

#git clone https://git.lighttpd.net/xcache/xcache.git

#cd xcache

#phpize && ./configure --with-php-config=/usr/bin/php-config8.2 --enable-xcache --enable-xcache-optimizer --enable-xcache-coverager
#make && make install

#install suhosin / snuffleupagus (security for php)

#apt install php8.2-dev -y
#git clone https://github.com/jvoisin/snuffleupagus
#phpize
#./configure --enable-snuffleupagus
#make
#make install
#cat << EOF > /etc/php/8.2/mods-available/snuffleupagus.ini
#extension=snuffleupagus.so
#sp.allow_broken_configuration=on
#sp.configuration_file=/dev/null
#EOF
#ln -s /etc/php/8.2/mods-available/snuffleupagus.ini /etc/php/8.2/fpm/conf.d/30-snuffleupagus.ini


#to be continued...
