#! /bin/bash
tfehostname=
tfedomain=

while ! curl -ksfS --connect-timeout 5 https://$tfehostname.$tfedomain/_health_check; do
    sleep 5
done
