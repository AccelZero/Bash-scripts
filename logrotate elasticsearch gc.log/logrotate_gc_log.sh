#!/bin/bash

do_gzip1() {
        if [[ -f "/var/log/elasticsearch/gc.log.0$1" ]]
        then
                gzip -f /var/log/elasticsearch/gc.log.0$1
        fi
}

do_gzip2() {
        if [[ -f "/var/log/elasticsearch/gc.log.$1" ]]
        then
                gzip -f /var/log/elasticsearch/gc.log.$1
        fi
}

for logrotate in {0..31}; do
        if [[ $logrotate -le 9 ]]
        then
                do_gzip1 $logrotate
        fi
        if [[ $logrotate -gt 9 ]]
        then
                do_gzip2 $logrotate
        fi
done

