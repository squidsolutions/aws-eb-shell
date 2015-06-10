#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
#
# List the configuration templates (aka "Saved Configurations") of a given region
#


JQ=`which jq`
AWS=`which aws`

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 conf_file.conf"
        exit 1
fi

CONF_PATH=${1}

if [ -f ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}"  | ${JQ} '.Applications[0] | .ConfigurationTemplates[]'

