#!/bin/bash

#Скрипт проверки конфигов nginx и apache
#Реализовал Буров Денис

echo "----------------------------------------------------------------------------------------------------------"
echo "nginx -t:"
nginx -t
echo ""
echo "apachectl -t:"
apachectl -t
echo "----------------------------------------------------------------------------------------------------------"

