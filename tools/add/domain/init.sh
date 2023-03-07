#!/bin/bash

#clear

user=false
ip=$(hostname -i)
domain=false
tech='php'
version='8.2'
ssl=false
cdn=false

install(){

if [ ! $user ] && [ -z $user ]
then
    initUI
fi

if [ ! $domain ] && [ -z $domain ]
then
    initUI
fi

echo " - START CREATION -"
echo -e "\n\n\n"

echo -ne '\033[1;97m[\033[0;30m▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m0%\033[0m)\r - \033[1;97mStarting creation\033[0m\r'
echo -ne '\033[1;97m[\033[0;32m▇▇\033[0;30m▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m10%\033[0m)\r - \033[1;97mAdding a domain\033[0m\r'

#reglage dns...

echo -ne '\033[1;97m[\033[0;32m▇▇▇▇▇\033[0;30m▇▇▇▇▇▇▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m25%\033[0m)\r - \033[1;97mCreating Virtual Hosting\033[0m\r'

if [[ ! -d /var/www/vhosts/$user ]]
then
    echo -e "\033[0;31m---Error not user---\033[0m"
    exit 0;
fi

if [[ ! -d /var/www/vhosts/$user/var/app/www/$domain ]];
then
    mkdir "/var/www/vhosts/$user/var/app/www/$domain"
    mkdir "/var/www/vhosts/$user/var/app/www/$domain/httpdocs"

    mkdir "/var/www/vhosts/$user/var/app/system/cache/$domain"
    mkdir "/var/www/vhosts/$user/var/app/system/logs/$domain"

cat << EOF > "/var/www/vhosts/$user/var/app/www/$domain/httpdocs/index.html"
<html>
    <head>
        <title>Welcome on $domain</title>
    </head>
    <body>
        <h1>Welcome on $domain</h1>
    </body>
</html>
EOF
    
    chown -R $user:www-data "/var/www/vhosts/$user/var/app/www/$domain"
    chmod -R 755 "/var/www/vhosts/$user/var/app/www/$domain"

    chown -R $user:www-data "/var/www/vhosts/$user/var/app/system/"
    chmod -R 755 "/var/www/vhosts/$user/var/app/system/"
fi

echo -ne "\033[1;97m[\033[0;32m▇▇▇▇▇▇▇▇\033[0;30m▇▇▇▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m40%\033[0m)\r - \033[1;97mConfiguring $tech\033[0m\r"

echo -ne '\033[1;97m[\033[0;32m▇▇▇▇▇▇▇▇▇▇▇\033[0;30m▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m55%\033[0m)\r - \033[1;97mConfiguring Apache\033[0m\r'

if [[ -e "/etc/apache2/sites-enabled/$domain.conf" ]];
then
    a2dissite $domain > /dev/null 2>&1
fi

if [[ -e "/etc/apache2/sites-available/$domain.conf" ]];
then
    rm /etc/apache2/sites-available/$domain.conf
fi

if [ "$tech" == "php" ]
then

    if $ssl
    then
        source php/vhost_ssl.sh $ip $domain "$tech$version" $user
    else
        source php/vhost.sh $ip $domain "$tech$version" $user
    fi

elif [ "$tech" == "node" ]
then
    if $ssl
    then
        source node/vhost_ssl.sh $ip $domain "$tech$version" $user
    else
        source node/vhost.sh $ip $domain "$tech$version" $user
    fi
#elif [ "$tech" == "ruby" ]
#then
#    if $ssl
#    then
#        source ruby/vhost_ssl.sh $ip $domain "$tech$version" $user
#    else
#        source ruby/vhost.sh $ip $domain "$tech$version" $user
#    fi
#elif [ "$tech" == "python" ]
#then
#    if $ssl
#    then
#        source python/vhost_ssl.sh $ip $domain "$tech$version" $user
#    else
#        source python/vhost.sh $ip $domain "$tech$version" $user
#    fi
else
    echo -e "\033[0;31m---Error not langage exist \"$tech\"---\033[0m"
    exit 0
fi

a2ensite $domain > /dev/null 2>&1

test=$(apache2ctl configtest 2>&1)
if [ "$test" != "Syntax OK" ]
then
   echo -e '\033[0;31m---Error apache2ctl configtest---\033[0m'
   echo $test
   exit 0
fi

systemctl reload apache2 > /dev/null 2>&1

echo -ne '\033[1;97m[\033[0;32m▇▇▇▇▇▇▇▇▇▇▇▇▇▇\033[0;30m▇▇▇▇\033[1;97m]\033[0m (\033[1;97m70%\033[0m)\r - \033[1;97mConfiguring Mail\033[0m\r'

#see later

echo -ne '\033[1;97m[\033[0;32m▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇\033[1;97m]\033[0m (\033[1;97m100%\033[0m)\r - \033[1;97mDone !\033[0m\r'

echo -ne '\n'

}

showHelp() {
cat << EOF  
-h, --help      Display help

--ui            Allows you to initialize the values one by one

-u, --user      set User

-i, --ip        set IP

-d, --domain    set Domain

-t, --tech      set Technology used (Php, Node, Ruby, Python) | Default : php

-v, --version   set Version of technology | Default : 8.2

-s, --ssl       activate SSL parameter

-c, --cdn       activate cloudflare and others CDN parameter
EOF
}


conti(){

echo -e "\033[0;33m#############     INFO       #############"
echo "USER    : $user"
echo "IP      : $ip"
echo "DOMAINE : $domain"
echo "VERSION : $version"
echo "TECH    : $tech"
echo "SSL     : $ssl"
echo "CDN     : $cdn"
echo -e "##########################################\033[0m"

response=false


while ! $response -eq false
do
    read -p "Continue (yes, no, restart) : " resp
    if [ "$resp" == "yes" ] || [ "$resp" == "no" ] || [ "$resp" == "restart" ]
    then
        response="$resp";
        break;
    else
        echo -e '\033[0;31m---Please enter a correct answer---\033[0m'
    fi
done

echo $response

if [ "$response" == "restart" ]
then
    initUI
fi

if [ "$response" == "no" ]
then
    exit 0
fi

install
}

initUI(){

    #clear

    echo -e "\033[1;97m\"Enter\"\033[0m to pass"

    if [ $user ];
    then
        read -p "User - (default : $user) : " -i "$user" respUs
        if [[ $respUs ]]; then
            user=$respUs
        fi
    else
        while ! $user
        do
            read -p "User : " user
            if [[ $user ]]
            then
                break;
            else
                echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
            fi
        done
    fi
    echo "> $user"

    read -p "IP - (default : $ip) : " -i "$ip" respIp
    if [[ $respIp ]]; then
        ip=$respIp
    fi
    echo "> $ip"

    if [[ $domain ]];
    then
        read -p "Domain - (default : $domain) : " -i "$domain" respDo
        if [[ $respDo ]]; then
            domain=$respDo
        fi
    else
        while ! $domain
        do
            read -p "Domain : " domain
            if [[ $domain ]]
            then
                break;
            else
                echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
            fi
        done
    fi
    echo "> $domain"

    read -p "Technology used [ php, node, ruby, python ] - (default : $tech) : " -i "$tech" resptech
    if [[ $resptech ]]; then
        tech=$resptech
    fi
    echo "> $tech"
    read -p "Version of $tech - (default : $version) : " -i "$version" respversion
    if [[ $respversion ]]; then
        version=$respversion
    fi
    echo "> $version"
    read -p "Use SSL ? [true, false] - (default : $ssl) : " -i "$ssl" respssl
    if [ "$respssl" == "false" ]; then
        ssl=false
    elif [ $respssl ]; then
        ssl=true
    else
        ssl=false
    fi
    echo "> $ssl"
    read -p "Use CDN ? [true, false] - (default : $cdn) : " -i "$cdn" respcdn
    if [ "$respcdn" == "false" ]; then
        cdn=false
    elif [ $respcdn ]; then
        cdn=true
    else
        cdn=false
    fi
    echo "> $cdn"

    conti
}



options=$(getopt -l "help,ip:,user:domain:,tech:,version:,ssl,cdn,ui" -o "hi:u:d:t:v:sc" -a -- "$@")

eval set -- "$options"

echo "test : $1"
if [ -z $1 ]
then
    ok=false
    while true
    do
    case "$1" in
    -h|--help) 
        showHelp
        exit 0
        ;;
    -i|--ip) 
        ok=true
        ip=$2
        ;;
    -u|--user)
        ok=true
        user=$2
        ;;
    -d|--domain)
        ok=true
        domain=$2
        ;;
    -t|--tech)
        ok=true
        tech=$2
        ;;
    -v|--version) 
        ok=true
        version=$2
        ;;
    -s|--ssl)
        ok=true
        ssl=true
        ;;
    -c|--cdn)
        ok=true
        cdn=true
        ;;
    --ui)
        ok=false
        initUI
        shift
        break;;
    --)
        shift
        break;;
    esac
    shift
    done
    if $ok
    then
        conti
    fi
else
    initUI
fi

conti
cd ../
