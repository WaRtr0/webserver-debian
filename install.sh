#!/bin/bash


organisationName='virtualutiliy'
organisationDomain='virtualutiliy.net'
defaultUser='defaultuser'


read -p 'Organisation Name : ' -i $organisationName organisationName
read -p 'Organisation Domain : ' -i $organisationDomain organisationDomain
read -p 'Default username for all access outside the chroot : ' -i $defaultUser defaultUser
adduser "$defaultUser"

apt install nginx -y
systemctl stop nginx
systemctl disable nginx

apt install apache2 openssh-server neofetch -y

systemctl enable ssh
systemctl start ssh

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

apt install expect -y

##conf apache

a2dissite 000-default.conf

cp -r /var/www/vhosts/templateUser /var/www/vhosts/default

mkdir /var/www/vhosts/default/var/app/www/{default,cgi-bin}
mkdir /var/www/vhosts/default/var/app/www/default
mkdir /var/www/vhosts/default/var/app/www/default
chown -R www-data:www-data /var/www/vhosts/default/var/app

rm /etc/apache2/sites-available/*

cat << EOF > /etc/apache2/ports.conf
Listen 127.0.0.1:7780
<IfModule ssl_module>
        Listen 127.0.0.1:7443
</IfModule>
<IfModule mod_gnutls.c>
        Listen 127.0.0.1:7443
</IfModule>
EOF

cat << EOF > /etc/apache2/sites-available/default.conf
<VirtualHost 127.0.0.1:7780>
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
	<VirtualHost 127.0.0.1:7443>
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

chmod +x /etc/webserver/tools/init.sh

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

echo "Installation MySQL : "

mysql_secure_installation

systemctl enable nginx.service
systemctl start nginx.service

rm /etc/nginx/sites-enabled/*
rm /etc/nginx/sites-available/*

cat << EOF > /etc/nginx/sites-available/1-apache
upstream apache{
    server 127.0.0.1:8080;
}

upstream apache_ssl{
    server 127.0.0.1:8443;
}
EOF

ln -s /etc/nginx/sites-available/1-apache /etc/nginx/sites-enabled/

apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow NginxFull

cat << EOF > execUFW.sh
#!/usr/bin/expect -f
set timeout -1
spawn ufw enable
expect {Command may disrupt existing ssh connections. Proceed with operation (y|n)?}
send -- "y\r"
expect eof
EOF

chmod u+x execUFW.sh
./execUFW.sh
rm execUFW.sh

#install mail server


apt install tree mailutils -y
apt install postfix postfix-mysql -y
apt install dovecot-mysql dovecot-pop3d dovecot-imapd dovecot-managesieved -y


groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/vmail -m

read -p "postfix mysql password" pmpassword
read -p "mailuser mysql password" mmpassword

mysql << EOF
CREATE USER IF NOT EXISTS 'postfix'@'localhost' IDENTIFIED BY '$pmpassword';
CREATE DATABASE postfix;
GRANT ALL PRIVILEGES ON \`postfix\`.* TO 'postfix'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

mysql << EOF
CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY '$mmpassword';
GRANT SELECT ON \`postfix\`.* TO 'mailuser'@'localhost';
FLUSH PRIVILEGES;
EOF

cd /srv/
wget -O postfixadmin.tgz https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.3.10.tar.gz
tar -zxvf postfixadmin.tgz
mv postfixadmin-postfixadmin-3.3* postfixadmin
rm postfixadmin.tgz

ln -s /srv/postfixadmin/public /var/www/postfixadmin

cat << EOF > /srv/postfixadmin/config.local.php
<?php
\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = 'localhost';
\$CONF['database_name'] = 'postfix';
\$CONF['database_user'] = 'postfix';
\$CONF['database_password'] = '$pmpassword';

\$CONF['setup_password'] =  '$(php -r "echo password_hash('$pmpassword', PASSWORD_DEFAULT);")';
\$CONF['configured'] = true;

EOF

mkdir -p /srv/postfixadmin/templates_c

mkdir -p /srv/postfixadmin/templates_c
chown -R www-data /srv/postfixadmin/templates_c

apt install libapache2-mod-php7.3 php7.3 -y
apt install php7.3-{curl,gd,intl,memcache,xml,zip,mbstring,redis,memcached,opcache,redis,mcrypt,xmlrpc,bcmath,mysql,fpm} -y


cat << EOF > /etc/php/7.3/fpm/pool.d/postfix_pool.conf
[postfix]
user = www-data
group = www-data

listen = /var/run/php/php7.3-postfix.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = ondemand
pm.max_children = 4

php_admin_value['date.timezone'] = Europe/Berlin
php_admin_value['session.save_path'] = /tmp
php_admin_value['open_basedir'] = /tmp/:/var/www/postfixadmin/:/srv/postfixadmin/:/usr/bin/doveadm:/var/cache/postfixadmin:/var/cache/postfixadmin/template_c
EOF

systemctl enable php7.3-fpm
systemctl start php7.3-fpm

ufw disable

cat << EOF > /etc/nginx/sites-available/postfix.$organisationDomain
server {
        listen 80;
        server_name www.postfix.$organisationDomain postfix.$organisationDomain;
        root /var/www/postfixadmin;
}
EOF

ln -s /etc/nginx/sites-available/postfix.$organisationDomain /etc/nginx/sites-enabled/

systemctl restart nginx

/bin/certbot --nginx -d postfix.$organisationDomain -d www.postfix.$organisationDomain

ufw enable

cat << EOF > /etc/nginx/sites-available/postfix.$organisationDomain
server {
        listen 80;
        server_name www.postfix.$organisationDomain postfix.$organisationDomain;
        root /var/www/postfixadmin;

        index index.php index.html;

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php{
                fastcgi_index index.php;
                fastcgi_pass unix:/run/php/php7.3-postfix.sock;

                include fastcgi_params;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
}

server {
        listen 443 ssl http2;
        server_name www.postfix.$organisationDomain postfix.$organisationDomain;

        include /etc/letsencrypt/options-ssl-nginx.conf;
        ssl_certificate /etc/letsencrypt/live/postfix.$organisationDomain/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/postfix.$organisationDomain/privkey.pem;

        root /var/www/postfixadmin;
        index index.php index.html;

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php{
                fastcgi_index index.php;
                fastcgi_pass unix:/run/php/php7.3-postfix.sock;

                include fastcgi_params;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
}
EOF

systemctl restart nginx

cat << EOF > /etc/postfix/mysql-virtual-mailbox-domains.cf
user = mailuser
password = $mmpassword
hosts = 127.0.0.1
dbname = postfix
query = SELECT 1 FROM domain where domain='%s'
EOF

postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf

cat << EOF > /etc/postfix/mysql-virtual-mailbox-maps.cf
user = mailuser
password = $mmpassword
hosts = 127.0.0.1
dbname = postfix
query = SELECT 1 FROM mailbox where username='%s'
EOF

postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf

grep -rl 'auth_mechanisms = plain' /etc/dovecot/conf.d/10-auth.conf | xargs sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g'
grep -rl '!include auth-system.conf.ext' /etc/dovecot/conf.d/10-auth.conf | xargs sed -i 's/!include auth-system.conf.ext/#!include auth-system.conf.ext/g'
grep -rl '#!include auth-sql.conf.ext' /etc/dovecot/conf.d/10-auth.conf | xargs sed -i 's/#!include auth-sql.conf.ext/!include auth-sql.conf.ext/g'
grep -rl 'mail_location = mbox:~/mail:INBOX=/var/mail/%u' /etc/dovecot/conf.d/10-mail.conf | xargs sed -i 's/mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/mail_location = maildir:\/var\/vmail\/%d\/%n\/Maildir/g'

cat << EOF > /etc/dovecot/conf.d/auth-sql.conf.ext
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/%d/%n
}
EOF

cat << EOF > /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
  }
  inet_listener imaps {
  }
}

service pop3-login {
  inet_listener pop3 {
  }
  inet_listener pop3s {
  }
}

service submission-login {
  inet_listener submission {
  }
}

service lmtp {
  unix_listener lmtp {
  }
}

service imap {
}

service pop3 {
}

service submission {
}

service auth {
  unix_listener auth-userdb {
  }

  # Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}

service auth-worker {
}

service dict {
  unix_listener dict {
  }
}
EOF

cat << EOF >> /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=127.0.0.1 dbname=postfix user=mailuser password=$mmpassword
password_query = SELECT username,domain,password FROM mailbox WHERE username='%u';
EOF

chgrp vmail /etc/dovecot/dovecot.conf
chmod g+r /etc/dovecot/dovecot.conf

service dovecot restart

cat << EOF >> /etc/postfix/master.cf
dovecot  unix  – n  n –  – pipe
  flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f ${sender} -d ${recipient}
EOF

service postfix restart

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1
