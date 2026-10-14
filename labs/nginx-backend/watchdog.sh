#!/bin/bash

while true
do
	curl http://localhost:9090

	if [ $? -eq 0 ]
	then
		echo "server up"
	else
		echo "server down"

	fi

	sleep 5

done
