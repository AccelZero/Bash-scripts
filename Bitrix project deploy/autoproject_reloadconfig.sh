#!/bin/bash

#Скрипт релоада nginx и apache с проверкой конфигурации
#Реализовал Буров Денис

#Проверка конфигурации nginx и, если все ок, выполняется его релоад
nginx -t 2> /root/autoproject/.nginx_check
if grep -q 'nginx: the configuration file /etc/nginx/nginx.conf syntax is ok' "/root/autoproject/.nginx_check" && grep -q 'nginx: configuration file /etc/nginx/nginx.conf test is successful'  "/root/autoproject/.nginx_check"
then
  nginx -s reload
  echo "nginx успешно выполнил релоад"
  echo "Состояние nginx:"
  systemctl status nginx.service  | grep Active:
else
 echo "nginx не был перезапущен, т.к. при проверке конфигурации была обнаружена ошибка:"
 nginx -t
fi

echo ""

#Проверка конфигурации Apache и, если все ок, выполняется его релоад
apachectl -t 2> /root/autoproject/.apache_check
if grep -q 'Syntax OK' "/root/autoproject/.apache_check"
then
  systemctl reload httpd
  echo "Apache успешно выполнил релоад"
  echo "Состояние apache:"
  systemctl status httpd.service | grep Active:
else
 echo "Apache не был перезапущен, т.к. при проверке конфигурации была обнаружена ошибка:"
 apachectl -t
fi

