#!/bin/bash

IFS=' ' read -r -a array <<< "$@"

export DOMAINS=="-d ${array[0]} -d www.${array[0]}"
export EMAIL="${array[1]}"

/usr/bin/certbot certonly --config cli.ini --email $EMAIL $DOMAINS
