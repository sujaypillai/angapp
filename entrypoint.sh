#!/bin/sh
echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p
echo fs.inotify.max_user_instances=524288 | tee -a /etc/sysctl.conf && sysctl -p
exec yarn start:dev