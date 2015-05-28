#!/bin/sh

#
# Author: G. Doumergue <gdoumergue@squidsolutions.com
# Display the status of an EB environment (last events, ELB status)
#


JQ=/usr/bin/jq
AWS=/usr/local/bin/aws

[ -x ${JQ} ] || (echo "Please install jq";exit 1;)
[ -x ${AWS} ] || (echo "Please install awscli";exit 1;)

usage () {
        echo "Usage: $0 conf_file.conf [env_name]"

}
if [ $# -lt 1 ];then
	usage
        exit 1
fi

CONF_PATH=${1}
ENV_NAME=${2}


if [ -r ${CONF_PATH} ];then

        . ${CONF_PATH}
else
        echo "${CONF_PATH} not found"
        exit 2
fi

[ -z "${ENV_NAME}" ] && ENV_NAME=${EB_ENV}
if [ -z "${EB_ENV}" ];then
        echo "No EB_ENV var in ${CONF_PATH}, or no environment given"
	usage
        exit 2
fi

echo "=== ENVIRONMENT \"${ENV_NAME}\" === "
ELB=`${AWS} elasticbeanstalk describe-environment-resources --environment-name "${ENV_NAME}" | ${JQ} -r '.EnvironmentResources.LoadBalancers[0].Name'`

echo ""
echo "== Environment health =="

${AWS} elasticbeanstalk describe-environments --environment-name "${ENV_NAME}" | ${JQ} -r '.Environments[0] | .Health'
echo ""

echo "== ELB ${ELB} health =="

${AWS}  elb describe-instance-health --load-balancer-name ${ELB} --output text --query 'InstanceStates[*].[InstanceId,State,Description]'
echo ""

echo "== Last events in environment =="

${AWS} elasticbeanstalk describe-events  --environment-name "${ENV_NAME}" --output text --query  'Events[*].[EventDate,Severity,Message]' | head -5

