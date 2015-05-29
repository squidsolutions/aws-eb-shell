#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# List the app versions of an app for a given region
#


JQ=`which jq`
AWS=`which aws`

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 conf_file.conf"
        exit 1
fi

CONF=${1}
shift
WAR_FILE=$*


CONF_PATH=`dirname $0`"/../${CONF}"
if [ -f ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

if [ -z "${EB_APP}" ];then
	echo "No EB_APP var in ${CONF_PATH}"
	exit 2
fi

${AWS} elasticbeanstalk  describe-application-versions --application-name "${EB_APP}" \
	| ${JQ} '.ApplicationVersions[] |.VersionLabel'
