#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# 2. Create app version in application
#

JQ=`which jq`
AWS=`which aws`

[ -x "${JQ}" ] || (echo "Please install jq";exit 1;)
[ -x "${AWS}" ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 path/to/conf_file.conf [app_file]"
        exit 1
fi

CONF_PATH=${1}
shift
WAR_FILE=$*


if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

list_s3 () {

if [ ! -z "${SOURCE_S3_REGION}" ];then
	SOURCE_REGION="--region ${SOURCE_S3_REGION}"
fi
	echo "Please provide the app file to use, chosen from this list:"
	${AWS} ${SOURCE_REGION} s3 ls s3://${SOURCE_S3_BUCKET}/${SOURCE_S3_PREFIX}/

}

if [ -z "${EB_APP}" ];then
	echo "No EB_APP var in ${CONF_PATH}"
	exit 2
fi

if [ -z "${WAR_FILE}" ];then
	# See if we can get the EB_APP_VERSION from conf file
	if [  -z "${EB_APP_VERSION}" ] ;then
		list_s3
		exit 3
	fi
	# See if EB_APP_VERSION is already in the EB app
	NB_VERS=`${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}" | ${JQ} '.Applications[] | .Versions[]' | grep -c "\"${EB_APP_VERSION}\""`
	if [ ${NB_VERS} -gt 0 ];then
		echo "Version ${EB_APP_VERSION} already exists in EB application \"${EB_APP}\"."
		echo "(See EB_APP_VERSION in ${CONF_PATH})"
		list_s3
		exit 4
	fi
	# No it's not. Let's use it as a default.
	WAR_FILE=${EB_APP_VERSION}
fi

EB_S3_BUCKET=elasticbeanstalk-${AWS_DEFAULT_REGION}-${ACCOUNT_ID}
echo "Copying ${EB_APP_VERSION} to ${EB_S3_BUCKET}"
if [ ! -z "${SOURCE_S3_REGION}" ];then
	SOURCE_REGION="--source-region ${SOURCE_S3_REGION}"
fi
${AWS} s3 cp s3://${SOURCE_S3_BUCKET}/${SOURCE_S3_PREFIX}/${WAR_FILE} s3://${EB_S3_BUCKET}/${WAR_FILE} ${SOURCE_REGION}

echo "Creating EB app version ${WAR_FILE} in EB app \"${EB_APP}\" on region ${AWS_DEFAULT_REGION}"

${AWS} elasticbeanstalk create-application-version --application-name "${EB_APP}" \
 --version-label "${WAR_FILE}" --source-bundle S3Bucket=${EB_S3_BUCKET},S3Key=${WAR_FILE}
