#!/usr/bin/

IFS=' ' read -r -a array <<< "$@"

mysql << EOF
CREATE USER IF NOT EXISTS '${array[0]}'@'localhost' IDENTIFIED BY '${array[1]}';
CREATE DATABASE ${array[0]}_${array[2]};
GRANT ALL PRIVILEGES ON `${array[0]}_${array[2]}`.* TO `${array[0]}`@'localhost' WITH GRANT OPTION;
EOF
