#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# 1. Create EB application
# 2. Create app version in application
# 3. Create Conf template in application
# 4. Create EB environment
#

JQ=/usr/bin/jq
AWS=/usr/local/bin/aws

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 path/to/conf_file.conf"
        exit 1
fi

CONF_PATH=${1}


if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

set -e

`dirname $0`/create_app.sh ${CONF_PATH}
`dirname $0`/create_version.sh ${CONF_PATH}
`dirname $0`/create_conf.sh ${CONF_PATH}
`dirname $0`/create_env.sh ${CONF_PATH}
