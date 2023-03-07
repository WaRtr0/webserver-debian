#!/bin/bash

username=false
firstname=false
surname=false
mail=false
password=false
tel=false

options=$(getopt -l "help,ui,user:,firstname:,surname:,mail:,password:,tel:" -o "hu:f:s:m:p:t:" -a -- "$@")

fin(){
if [ $username != false ] && [ $mail != false ] && [ $password != false ]
then
    if [[ ! -d /var/www/vhosts/$username ]];
    then
        cp -r /var/www/vhosts/templateUser /var/www/vhosts/$username
        /sbin/useradd $username --home /var/app/ --groups chrootgrp -s /bin/bash
        echo "$username:$password" | chpasswd --crypt-method SHA512
        chmod -R 751 /var/www/vhosts/$username/var/app/
        chown -R $username:$username /var/www/vhosts/$username/var/app/

        echo $(grep "$username:x:" /etc/passwd) >> /var/www/vhosts/$username/etc/passwd
        echo $(grep "$username:\$6\$" /etc/shadow) >> /var/www/vhosts/$username/etc/shadow

        echo "User $username has been successfully created"
        cd ../
    else
        echo -e "\033[0;31m---Exist User!---\033[0m"
        initUI
    fi
else
    echo -e "\033[0;31m---Please enter the required information (username, mail, password)---\033[0m"
    initUI
fi
exit 0
}

showHelp() {
cat << EOF  
-h, --help          Display help

--ui                Allows you to initialize the values one by one

-u, --user          set username

-f, --firstname     set firstname

-s, --surname       set surname

-m, --mail          set mail

-p, --password      set password

-t, --tel           set telephone
EOF
}

conti(){

echo -e "\033[0;33m#############     INFO       #############"
echo "USERNAME  : $username"
echo "FIRSTNAME : $firstname"
echo "SURNAME   : $surname"
echo "MAIL      : $mail"
echo "PHONE     : $tel"
echo -e "##########################################\033[0m"

response=false


while ! $response 
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

fin
}

initUI(){

    confirmPassword=false

    echo -e "\033[1;97m\"Enter\"\033[0m to pass"
    
    read -p "username - (Required) : " -i "$username" username
    if [[ ! $username ]]
    then
        echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
    fi
    while [ ! $username ]
    do
        read -p "username - (Required) : " -i "$username" username
        if [[ $username ]]
        then
            break;
        else
            echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
        fi
    done

    echo "> $username"


    read -p "mail - (Required) : " -i "$mail" mail
    if [[ ! $mail ]]
    then
        echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
    fi
    while [ ! $mail ]
    do
        read -p "mail - (Required) : " -i "$mail" mail
        if [[ $mail ]]
        then
            break;
        else
            echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
        fi
    done

    echo "> $mail"

    read -p "password - (Required) : "$'\n' -s -i "$password" password
    if [[ ! $password ]]
    then
        echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
    fi
    while [ ! $password ]
    do
        read -p "password - (Required) : "$'\n' -s -i "$password" password
        if [[ $password ]]
        then
            break;
        else
            echo -e "\033[0;31m---Please enter a correct answer---\033[0m"
        fi
    done

    while [ ! "$password" == "$confirmPassword" ]
    do
        read -p "Confirm password - (Required) : "$'\n' -s -i "$confirmPassword" confirmPassword

        if [ "$confirmPassword" == "$password" ]
        then
            break;
        else
            echo -e "\033[0;31m---Please enter a password or restart the script---\033[0m"
        fi
    done

    read -p "Firstname : " -i "$firstname" firstname
    echo "> $firstname"

    read -p "Surname : " -i "$surname" surname
    echo "> $surname"

    read -p "Phone : " -i "$tel" tel
    echo "> $tel"

    conti
}


eval set -- "$options"
options=$(getopt -l "help,ui,user:,firstname:,surname:,mail:,password:,tel:" -o "hu:f:s:m:p:t:" -a -- "$@")
if [ $1 ]
then
    ok=false
    while true
    do
    case "$1" in
    -h|--help) 
        showHelp
        exit 0
        ;;
    --ui) 
        ok=false
        initUI
        shift
        break;;
    -u|--user)
        ok=true
        username=$2
        ;;
    -f|--firstname)
        ok=true
        firstname=$2
        ;;
    -s|--surname) 
        ok=true
        surname=$2
        ;;
    -m|--mail)
        ok=true
        mail=$2
        ;;
    -p|--password)
        ok=true
        password=$2
        ;;
    -t|--tel)
        ok=true
        tel=$2
        ;;
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

initUI
