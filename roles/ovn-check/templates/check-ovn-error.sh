#!/bin/bash

# This script is used at deploy time to check for errors in OVN logs
# The first arg is the deployment start time
check_time=$1
error_logs=("ovn-northd" "ovsdb-server-nb" "ovsdb-server-sb" "ovn-controller")
for i in $error_logs; do
    if [ -e "/var/log/openvswitch/$i.log" ]; then
        IFS=$'\n'
        errors_found=($(grep ERR /var/log/openvswitch/$i.log))
        last_error=`expr {{ '${#errors_found[@]}' }}  - 1`
        err_time=$(echo ${errors_found[last_error]:0:19} | xargs date +%s -d)
        if [ $err_time -gt $check_time ]; then
            echo "error found: ${errors_found[num_arrays]}"
            exit 1
        fi
    fi
done
exit 0
