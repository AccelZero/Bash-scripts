#!/bin/bash

username=$1

useradd $username
mkdir /home/$username/.ssh
chown $username:$username /home/$username/.ssh
chmod 700 /home/$username/.ssh
touch /home/$username/.ssh/authorized_keys
chown $username:$username /home/$username/.ssh/authorized_keys
chmod 600 /home/$username/.ssh/authorized_keys 
