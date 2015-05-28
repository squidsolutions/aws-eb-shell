#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# 3. Create EB conf
#
# EB configuration is the "saved configurations" part in the EB applications in the aws console
# In awscli, it's called configuration template.
# It configures how the EB environment can be created
# It is a huge JSON structure, that must be templatised for our needs because each AWS region has its particularity:
#
# _APP_NAME_		Application name		${EB_APP}
# _TEMPLATE_		Conf template			${EB_CONF_TEMPLATE} or arg N.2
# _INST_ROLE_		Instance role			${EB_INST_ROLE}
# _INST_TYPE_		Instance type			${EB_INST_TYPE}
# _INST_SIZE_		Instance root vol size		${EB_INST_SIZE}
# _MIN_INST_		Minimun instance nb		${EB_MIN_INST}
# _STACK_NAME_		Solution stack name		${EB_STACK} 
# _SEC_GROUP_		Security group			${PRIVATE_SEC_GROUP}
# _ELB_SUBNETS_		ELB subnets (pub)		${EB_ELB_SUBNETS}
# _INST_SUBNETS_	Instances subnets (priv	)	${EB_INST_SUBNETS}
# _VPC_ID_		VPC Id				${VPC_ID}
# _SSL_CERTIFICATE_	SSL Certificate ID		${SSL_CERTIFICATE}
# _NOTIF_EMAIL_		SNS Notif. email		${NOTIF_EMAIL}
# _SSH_KEY_		SSH pub key name		${SSH_KEY}
# 
# (a template of a conf-template file. Do you still follow ?)
#
#


JQ=`which jq`
AWS=`which aws`

[ -x "${JQ}" ] || (echo "Please install jq";exit 1;)
[ -x "${AWS}" ] || (echo "Please install awscli";exit 1;)

if [ $# -lt 1 ];then
        echo "Usage: $0 path/to/conf_file.conf [template_name]"
	echo "The file "`dirname $0`"/conf_template_[template_name].json must contain the proper conf definition"
        exit 1
fi

EB_INST_TYPE="m1.small"
EB_MIN_INST=2
EB_INST_SIZE=10

CONF_PATH=${1}
TEMPLATE_NAME=${2}

if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

[ -z "${TEMPLATE_NAME}" ]  && TEMPLATE_NAME=${EB_CONF_TEMPLATE}

if [ -z "${TEMPLATE_NAME}" ];then
	echo "No EB_CONF_TEMPLATE var in ${CONF_PATH}, or no template_name given"
	exit 2
fi

TEMPLATE_FILE=`dirname $0`"/conf_template_${TEMPLATE_NAME}.json"

if [ ! -f "${TEMPLATE_FILE}" ];then
	echo "Please create a file ${TEMPLATE_FILE}"
	exit 3
fi

# Verify if the EB conf exists
ENV_NB=`${AWS} elasticbeanstalk describe-applications --application-name "${EB_APP}"  | ${JQ} '.Applications[0] | .ConfigurationTemplates[]' | grep -c "\"${TEMPLATE_NAME}\""`

if [ ${ENV_NB} -gt 0 ];then
	echo "EB conf ${TEMPLATE_NAME} already exists in elasticbeanstalk app ${EB_APP}"
	echo "(See EB_CONF_TEMPLATE in ${CONF_PATH}. You can specify another template.)"
	exit 1
fi

# Create the conf file

TMP_FILE=`mktemp`
sed	-e "s/_APP_NAME_/${EB_APP}/" -e "s/_TEMPLATE_/${TEMPLATE_NAME}/" -e "s/_STACK_NAME_/${EB_STACK}/" -e "s/_INST_ROLE_/${EB_INST_ROLE}/"\
	-e "s/_SEC_GROUP_/${PRIVATE_SEC_GROUP}/" -e "s/_ELB_SUBNETS_/${EB_ELB_SUBNETS}/" -e "s/_INST_SUBNETS_/${EB_INST_SUBNETS}/" \
	-e "s/_INST_TYPE_/${EB_INST_TYPE}/" -e "s/_MIN_INST_/${EB_MIN_INST}/" -e "s/_INST_SIZE_/${EB_INST_SIZE}/" \
	-e "s/_NOTIF_EMAIL_/${NOTIF_EMAIL}/" -e "s/_SSH_KEY_/${SSH_KEY}/" \
	-e "s/_VPC_ID_/${VPC_ID}/" -e "s|_SSL_CERTIFICATE_|${SSL_CERTIFICATE}|" ${TEMPLATE_FILE} > ${TMP_FILE}

# Create EB conf
echo "Creating Saved Configuration for application \"${EB_APP}\""
${AWS} elasticbeanstalk create-configuration-template --application-name "${EB_APP}" --cli-input-json file://${TMP_FILE}
EXIT_CODE=$?
rm -f ${TMP_FILE}

exit ${EXIT_CODE}
