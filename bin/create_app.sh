#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# 1. Create EB application
#

JQ=`which jq`
AWS=`which aws`

[ -x "${JQ}" ] || (echo "Please install jq";exit 1;)
[ -x "${AWS}" ] || (echo "Please install awscli";exit 1;)

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

if [ -z "${EB_APP}" ];then
	echo "No EB_APP var in ${CONF_PATH}"
	exit 2
fi


# Verify if the BE app exists
APP_NB=`${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}" | ${JQ} '.Applications|length'`

if [ ${APP_NB} -gt 0 ];then
	echo "EB App \"${EB_APP}\" already exists"
	echo "(See EB_APP in ${CONF_PATH})"
	exit 1
fi

echo "Creating EB app \"${EB_APP}\" on region ${AWS_DEFAULT_REGION}"
# Create EB app
${AWS} elasticbeanstalk create-application --application-name "${EB_APP}"
