#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# 4. Create EB environment
#

JQ=`which jq`
AWS=`which aws`

[ -x "${JQ}" ] || (echo "Please install jq";exit 1;)
[ -x "${AWS}" ] || (echo "Please install awscli";exit 1;)

usage () {
        echo "Usage: $0 path/to/conf_file.conf [environment|--] [configuration|--] [app_version]"
}
if [ $# -lt 1 ];then
	usage
        exit 1
fi

CONF_PATH=${1}
ENV_NAME=${2}
CONF_NAME=${3}
APP_VERSION=${4}

if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

[ -z "${ENV_NAME}" -o "${ENV_NAME}" = "--" ] && ENV_NAME=${EB_ENV}
if [ -z "${EB_ENV}" ];then
	echo "No EB_ENV var in ${CONF_PATH}, or no environment given"
	exit 2
fi

if [ -z "${CONF_NAME}"  -o "${CONF_NAME}" = "--" ];then
	CONF_NAME=${EB_CONF_TEMPLATE}
	PREFIX="--cname-prefix ${EB_PREFIX}"
fi
[ -z "${APP_VERSION}" ] && APP_VERSION=${EB_APP_VERSION}

# Version label can't have a "/". We choose to keep the beginning of the war_file
VERSION_LABEL=`echo ${APP_VERSION} | cut -d"/" -f 1`


# Verify if the EB env exists
ENV_NB=`${AWS} elasticbeanstalk describe-environments --application-name "${EB_APP}" --environment-names "${ENV_NAME}" --no-include-deleted | ${JQ} '.Environments|length'`

if [ -z "${ENV_NB}" -o ${ENV_NB} -gt 0 ];then
	echo "EB environment ${ENV_NAME} already exists in application ${EB_APP}"
	echo "You can specify the name of another environment:"
	usage
	exit 1
fi

# Create EB env
echo "Creating Elasticbeanstalk environment \"${ENV_NAME}\" in application \"${EB_APP}\""
${AWS} elasticbeanstalk create-environment --application-name "${EB_APP}" --environment-name "${ENV_NAME}" --template-name "${CONF_NAME}" --version-label "${VERSION_LABEL}" ${PREFIX}
