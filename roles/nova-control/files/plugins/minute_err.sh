#!/bin/sh

grep '^'"$(date +"%F %R")" /var/log/nova/nova-api.log > /var/log/sensu/minute_log | grep 'status: 5' /var/log/sensu/minute_log | wc -l