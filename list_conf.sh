#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
#
# List the configuration templates (aka "Saved Configurations") of a given region
#


JQ=/usr/bin/jq
AWS=/usr/local/bin/aws

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 conf_file.conf"
        exit 1
fi

CONF=${1}

CONF_PATH=`dirname $0`"/../${CONF}"
if [ -f ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}"  | ${JQ} '.Applications[0] | .ConfigurationTemplates[]'

