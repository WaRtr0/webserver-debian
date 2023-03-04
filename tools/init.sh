#!/bin/bash

if [[ -d /etc/webserver ]]
then
	cd /etc/webserver/tools
else
	exit 0;
fi

IFS='/' read -a chemin <<<$(pwd)
delete=(etc tools)

for del in ${delete[@]}
do
	chemin=("${chemin[@]/$del}")
done

chemin="${chemin[@]}"
array=(*/)
directory=false
parent=$0

command=($@)

empty(){
	read -p "$chemin > " command
	command=($command)
	cont
}

cont(){

	if [ "${command[0]}" == "help" ]
	then
		echo -e "\033[0;33m* * * * * * * * * * * * * * * * * * *"
		echo "$parent help" 
		echo "* * * * * * * * * * * * * * * * * * *"
		echo "List commands :" 
		for dir in "${array[@]}"
		do
			echo "- ${dir/\//""}"
		done
		echo -e "* * * * * * * * * * * * * * * * * * *\033[0m"
		empty
	fi

	if [ "${command[0]}" == "exit" ]
	then
		exit 0;
	fi

	for dir in "${array[@]}"
	do
	    if [ "$dir" == "${command[0]}/" ]
	    then
	        directory=${command[0]}
	        break;
	    fi
	done

	if [ $directory == false ]
	then
		if [ -z "${command[0]}" ]
		then
			empty
		else
			echo -e '\033[0;31mCommand not found'
		    echo -e '\033[0;36mDo \033[1;36m"help"\033[0;36m to see the available commands\033[0m'
		    empty
		fi
	    
	else
	    cd $directory
	    command=("${command[@]/${command[0]}}")
	    bash init.sh "${command[@]}"
	fi
}
cont
