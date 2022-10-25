#!/bin/bash

#Скрипт удаления Bitrix проектов
#Реализовал Буров Денис

project=$1
route=$2

project_dev=dev$project
route_dev=$(echo $route | sed -re 's/\//\/dev/4')

#Удаление конфигов Apache
rm -f /etc/httpd/bx/conf/$project\.conf
rm -f /etc/httpd/bx/conf/$project_dev\.conf

#Удаление симлинков конфигов nginx
unlink /etc/nginx/bx/site_enabled/$project\.conf
unlink /etc/nginx/bx/site_enabled/$project-ssl.conf
unlink /etc/nginx/bx/site_enabled/$project_dev\.conf
unlink /etc/nginx/bx/site_enabled/$project_dev-ssl.conf

#Удаление конфигов nginx
rm -f /etc/nginx/bx/site_avaliable/$project\.conf
rm -f /etc/nginx/bx/site_avaliable/$project-ssl.conf
rm -f /etc/nginx/bx/site_avaliable/$project_dev\.conf
rm -f /etc/nginx/bx/site_avaliable/$project_dev-ssl.conf

#Удаление директорий проекта
rm -rf $route
rm -rf $route_dev

#Удаление БД проекта
project_mysql=$(echo $project | sed 's/\./_/g')
project_dev_mysql=$(echo $project_dev | sed 's/\./_/g')

mysql -u root -e "DROP DATABASE $project_mysql;"
mysql -u root -e "DROP DATABASE $project_dev_mysql;;"
mysql -u root -e "DROP USER $project_mysql@localhost"

