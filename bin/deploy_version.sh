#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# (re-)deploy a webapp in an existing EB environment
#


JQ=`which jq`
AWS=`which aws`

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

usage () {
        echo "Usage: $0 conf_file.conf [env_name|--] [app_version]"

}
if [ $# -lt 1 ];then
	usage
        exit 1
fi

CONF_PATH=${1}
ENV_NAME=${2}
APP_VERSION=${3}

if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

list_apps () {

	echo "Please provide the app to use, chosen from this list:"
	${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}" | ${JQ} '.Applications[] | .Versions[]'
	usage
	exit 2

}

[ -z "${ENV_NAME}" -o "${ENV_NAME}" = "--" ] && ENV_NAME=${EB_ENV}
if [ -z "${EB_ENV}" ];then
        echo "No EB_ENV var in ${CONF_PATH}, or no environment given"
	usage
        exit 2
fi


if [ -z "${APP_VERSION}" ];then
	# See if we can get the EB_APP_VERSION from conf file
	if [  -z "${EB_APP_VERSION}" ] ;then
		list_apps
		usage
		exit 3
	fi
	# Yes it is. Let's use it as a default.
	APP_VERSION=${EB_APP_VERSION}
fi

# Version label can't have a "/". We choose to keep the beginning of the war_file
VERSION_LABEL=`echo ${APP_VERSION} | cut -d"/" -f 1`

# See if EB_APP_VERSION is in the EB app
NB_VERS=`${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}" | ${JQ} '.Applications[] | .Versions[]' | grep -c "\"${VERSION_LABEL}\""`
if [ ${NB_VERS} = 0 ];then
	echo "No app version called \"${VERSION_LABEL}\" in EB application \"${EB_APP}\"."
	list_apps
	echo "(please add it in EB_APP_VERSION in ${CONF_PATH})"
	usage
	exit 4
fi

echo "Deploying EB app version ${VERSION_LABEL} in EB app \"${EB_APP}\" on region ${AWS_DEFAULT_REGION}"

${AWS} elasticbeanstalk update-environment --environment-name "${ENV_NAME}"  \
 --version-label "${VERSION_LABEL}"
