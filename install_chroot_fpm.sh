#!/usr/bin

#User create by "webserver add user"
read -p 'User :' user
read -p 'php version [8.2] : ' -i '8.2' version 

mount -B /dev /var/www/vhosts/$user/dev
mount -B /dev/pts /var/www/vhosts/$user/dev/pts

#For start systemd racine -> chroot
mkdir /var/www/vhosts/$user/run/systemd/
mkdir /var/www/vhosts/$user/run/systemd/notify/
mount -B /run/systemd/notify /var/www/vhosts/$user/run/systemd/notify

#Visibly during my last tests the tmp folder had no rights...
chmod 1777 /var/www/vhosts/$user/tmp

chroot /var/www/vhosts/$user apt install curl wget sudo gnupg2 ca-certificates lsb-release apt-transport-https -y
chroot /var/www/vhosts/$user curl -sSL https://packages.sury.org/php/README.txt | sudo bash -x

#install php & fpm
chroot /var/www/vhosts/$user apt install libapache2-mod-fcgid
chroot /var/www/vhosts/$user apt install libapache2-mod-php$version php$version -y
chroot /var/www/vhosts/$user apt install php$version-{curl,gd,intl,memcache,xml,zip,mbstring} -y
chroot /var/www/vhosts/$user apt install php$version-fpm php$version-mysql -y

cat << EOF > /etc/systemd/system/php$version-fpm-$user.service
[Unit]
Description=The PHP $version FastCGI Process Manager of $user
Documentation=man:php-fpm$version(8)
After=network.target

[Service]
Type=notify
RootDirectory=/var/www/vhosts/$user
ExecStart=/usr/sbin/php-fpm$version --nodaemonize --fpm-config /etc/php/$version/fpm/php-fpm.conf
ExecStartPost=-/usr/lib/php/php-fpm-socket-helper install /run/php/php-fpm.sock /etc/php/$version/fpm/pool.d/www.conf 81
ExecStopPost=-/usr/lib/php/php-fpm-socket-helper remove /run/php/php-fpm.sock /etc/php/$version/fpm/pool.d/www.conf 81
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

mkdir /var/www/vhosts/$user/run/php/
echo ''> /var/www/vhosts/$user/var/log/php-fpm$version.log
chmod 777 /var/www/vhosts/$user/var/log/php-fpm$version.log

systemctl daemon-reload
systemctl enable php$version-fpm-$user.service
systemctl start php$version-fpm-$user.service
