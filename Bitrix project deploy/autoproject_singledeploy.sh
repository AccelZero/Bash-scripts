#!/bin/bash

#Скрипт автоматической развертки Bitrix проекта (без dev версии)
#Реализовал Буров Денис

project=$1
route=$2
port=$3
replace=$4

#Проверка введенных данных
project_check=$(echo $project | cut -d "." -f 2,3)
if [[ $replace != "replace" ]] && find /etc/nginx/bx/site_avaliable/$project\.conf > /dev/null 2> /dev/null
then  
  echo "Конфиг nginx ${project}.conf уже существует"
  check="false"
fi

if [[ $replace != "replace" ]] && find /etc/nginx/bx/site_avaliable/$project\-ssl.conf > /dev/null 2> /dev/null
then
  echo "Конфиг nginx ${project}-ssl.conf уже существует"
  check="false"
fi

if [[ $replace != "replace" ]] && find /etc/httpd/bx/conf/${project}.conf > /dev/null 2> /dev/null
then
  echo "Конфиг apache ${project}.conf уже существует"
  check="false"
fi

route_check=$(echo $route | cut -d "/" -f 1,2,3)
if [[ "$route_check" != "/home/bitrix" ]]
then
  echo "Путь указан неверно"
  check="false"
fi

route_projeckt_check=$(echo $route | cut -d "/" -f 5)
if [[ $project != $route_projeckt_check ]]
then
  echo "Имя проекта, указанное в переменной 'Путь' не совпадает с именем проекта"
  check="false"
fi

if [ -d $route ]
then
  echo "Директория $route уже существует"
  check="false"
fi

if lsof -i -P -n | grep LISTEN | grep $port > /dev/null 
then
 echo "Указанный порт Занят"
 check="false"
fi

if [[ $check = "false" ]]
then
  echo "-----------------------------------------------------------"
  echo Проверка введенных данных не пройдена, проект не был создан
  exit 1
fi

#Бэкап старых конфигов проекта и удаление символьных ссылок
#Данная часть скрипта отрабатывает только если была задана 4 переменная "replace"
if [[ $replace = "replace" ]]
then
current_year=$(date +"%Y")
unlink /etc/nginx/bx/site_enabled/${project}.conf
unlink /etc/nginx/bx/site_enabled/${project}-ssl.conf
mv -f /etc/nginx/bx/site_avaliable/$project\.conf /etc/nginx/bx/site_avaliable/$project\.conf.back-${current_year} 
mv -f /etc/nginx/bx/site_avaliable/$project\-ssl.conf /etc/nginx/bx/site_avaliable/$project\-ssl.conf.back-${current_year} 
mv -f /etc/httpd/bx/conf/${project}.conf /etc/httpd/bx/conf/${project}.conf.back-${current_year} 
echo "Старые конфиги nginx и apache проекта забекаплены, старые символьные ссылки конфигов nginx удалены"
fi

#Создание переменных для каталогов формата /home/bitrix/ИМЯ_ПОДКAТАЛОГА и /home/bitrix/ИМЯ_ПОДКAТАЛОГА/devИМЯ_КАТАЛОГА
route_main=$(echo $route | cut -d "/" -f 1,2,3,4)
route_dev=$(echo $route | sed -re 's/\//\/dev/4')
port_dev=$(($port+1))

#Создание подкаталога и каталогов для проекта
if ! [ -d $route_main ]
then
  mkdir $route_main 
  chown bitrix:bitrix $route_main
fi

mkdir $route
chown bitrix:bitrix $route
echo "<?php phpinfo(); ?>" >> $route/index.php
touch $route/.htsecure

echo "Директории под проект созданы"

#Создание конфигов nginx
cat <<EOF >> /etc/nginx/bx/site_avaliable/$project\.conf
# Default website
server {
	listen 80;
	server_name $project;
	#include /etc/nginx/ip_allow.list;
	server_name_in_redirect off;
	
	proxy_set_header	X-Real-IP        \$remote_addr;
	proxy_set_header	X-Forwarded-For  \$proxy_add_x_forwarded_for;
	proxy_set_header	Host \$host:80;

	set \$proxyserver	"http://127.0.0.1:$port";
	set \$docroot		"$route";

	index index.php;
	root $route;

	# Redirect to ssl if need
	if (-f $route/.htsecure) { rewrite ^(.*)$ https://\$host\$1 permanent; }

	# Include parameters common to all websites
	include bx/conf/bitrix.conf;

	# Include server monitoring locations
	include bx/server_monitor.conf;
}
EOF
cat <<EOF >> /etc/nginx/bx/site_avaliable/$project-ssl.conf
# Default SSL certificate enabled website
server {
	listen 443 ssl http2;
	server_name $project;

	#include /etc/nginx/ip_allow.list;

	access_log /var/log/nginx/$project.access.ssl.log main;
	error_log /var/log/nginx/$project.error.ssl.log;

	# Enable SSL connection
	include	bx/conf/ssl.conf;
	server_name_in_redirect	off;

	proxy_set_header	X-Real-IP	\$remote_addr;
	proxy_set_header	X-Forwarded-For	\$proxy_add_x_forwarded_for;
	proxy_set_header	Host		\$host:443;
	proxy_set_header	HTTPS 		YES;

	set \$proxyserver	"http://127.0.0.1:$port";
	set \$docroot		"$route";

	index index.php;
	root $route;

	# Include parameters common to all websites
	include bx/conf/bitrix.conf;

	# Include server monitoring API's
	include bx/server_monitor.conf;

}
EOF

echo "Конфиги nginx созданы"

#Создание символьных ссылок
ln -s /etc/nginx/bx/site_avaliable/$project\.conf /etc/nginx/bx/site_enabled/$project\.conf
ln -s /etc/nginx/bx/site_avaliable/$project-ssl.conf /etc/nginx/bx/site_enabled/$project-ssl.conf
echo "Символьные ссылки для конфигов nginx созданы"

#Создание конфигов Apache
cat <<EOF >> /etc/httpd/bx/conf/$project\.conf
Listen 127.0.0.1:$port
<VirtualHost 127.0.0.1:$port>
	ServerAdmin webmaster@localhost
	ServerName $project
	DocumentRoot $route
	php_admin_value mbstring.func_overload 0

	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>

	<DirectoryMatch .*\.svn/.*>
		 Require all denied
	</DirectoryMatch>

	<DirectoryMatch .*\.git/.*>
		 Require all denied
	</DirectoryMatch>

	<DirectoryMatch .*\.hg/.*>
		 Require all denied
	</DirectoryMatch>

	<Directory $route>
		Options FollowSymLinks MultiViews
		AllowOverride All
		DirectoryIndex index.php index.html index.htm
		php_admin_value session.save_path /tmp/php_sessions/www
		php_admin_value upload_tmp_dir /tmp/php_upload/www
        Require all granted
	</Directory>

	<Directory $route/bitrix/cache>
		AllowOverride none
        Require all denied
	</Directory>

	<Directory $route/bitrix/managed_cache>
		AllowOverride none
        Require all denied
	</Directory>

	<Directory $route/bitrix/local_cache>
		AllowOverride none
        Require all denied
	</Directory>

	<Directory $route/bitrix/stack_cache>
		AllowOverride none
        Require all denied
	</Directory>

	<Directory $route/upload>
		AllowOverride none
		AddType text/plain php,php3,php4,php5,php6,phtml,pl,asp,aspx,cgi,dll,exe,ico,shtm,shtml,fcg,fcgi,fpl,asmx,pht
		php_value engine off
	</Directory>

	<Directory $route/upload/support/not_image>
		AllowOverride none
        Require all denied
	</Directory>

	<Directory $route/bitrix/images>
		AllowOverride none
		AddType text/plain php,php3,php4,php5,php6,phtml,pl,asp,aspx,cgi,dll,exe,ico,shtm,shtml,fcg,fcgi,fpl,asmx,pht
		php_value engine off
	</Directory>

	<Directory $route/bitrix/tmp>
		AllowOverride none
		AddType text/plain php,php3,php4,php5,php6,phtml,pl,asp,aspx,cgi,dll,exe,ico,shtm,shtml,fcg,fcgi,fpl,asmx,pht
		php_value engine off
	</Directory>

	ErrorLog logs/${project}_error.log
	# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
	LogLevel warn

	CustomLog logs/${project}_access.log combined

	<IfModule mod_rewrite.c>
		#Nginx should have "proxy_set_header HTTPS YES;" in location
		RewriteEngine On
		RewriteCond %{HTTP:HTTPS} =YES
		RewriteRule .* - [E=HTTPS:on,L]
	</IfModule>

</VirtualHost>
EOF

echo "Конфиги apache созданы"

#Проверка запуска скрипта с 4-ой переменной "replace", если да, то БД будет названа формата ИМЯ_БД_ТЕКУЩИЙ_ГОД
if [[ $replace != "replace" ]]
then
project_mysql=$(echo $project | sed 's/\./_/g')
else
project_mysql="$(echo $project | sed 's/\./_/g')_${current_year}"
fi

#Создание пользователя и БД
password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)
mysql -u root -e "create user '$project_mysql'@'localhost' identified by '$password';"
mysql -u root -e "create database $project_mysql DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -u root -e "grant all privileges on $project_mysql.* to $project_mysql@localhost;"
echo "БД $project_mysql создана"

#Запись в файл доступы от созданных БД
cat <<EOF >> /root/autoproject/.db_pass
--------------------------------------

user: $project_mysql
password: $password
db: $project_mysql

--------------------------------------
EOF

echo Пароли от созданных БД лежат в файле .db_pass

#Оповещение об успешном выполнение скрипта
echo ""
cat <<EOF 
-----------------------------------------------------------
Проект ${project} успешно создан
-----------------------------------------------------------
EOF

#Выдача прав на директории проекта допольнительным пользователям
echo ""
read -r -p "Нужно ли выдать права на директории проекта допольнительному пользователю? (Y/N) " answer
answer_check="true"
answer_check_user="true"
while [[ $answer_check = "true" ]]
do
  if [[ $answer = "Y" ]]
  then
   while [[ $answer_check_user = "true" ]]
   do
     if [[ $user = "" ]]
     then
       read -r -p "Введите имя пользователя, которому нужно выдать права (введите 'N' для выхода): " user
     elif [[ $user = "N" ]]
     then
       answer_check="false"
       answer_check_user="false"
     else
       setfacl -R -m u:${user}:rwx $route
       setfacl -R -m d:u:${user}:rwx $route
       echo "Права на директорию $route пользователю $user выданы"
       read -r -p "Введите имя пользователя, которому нужно выдать права (введите 'N' для выхода): " user
     fi
   done
  elif [[ $answer = "N" ]]
  then
    answer_check="false"
  else
    read -r -p "Нужно ли выдать права на директории с проектом допольнительному пользователю? (Y/N) " answer
  fi
done

