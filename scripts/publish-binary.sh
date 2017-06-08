#!/usr/bin/env bash
cwd=$(pwd)
set -e

BUILD_CMD="wbs-build.ps1"
COMMIT_MESSAGE=$(git show -s --format=%B $TRAVIS_COMMIT | tr -d '\n')

echo $COMMIT_MESSAGE
if test "${COMMIT_MESSAGE#*'[publish binary]'}" != "$COMMIT_MESSAGE"
then
    echo "PUBLISHING mapnik SDK"
    PUBLISH_SDK=1
else
    echo "NOT publishing"
fi

pip install --user awscli

gitsha="$1"
sleep=10
date_time=`date +%Y%m%d%H%M`
start_timestamp=`date +"%s"`
maxtimeout=2880
######first 2015 ami
#region="eu-central-1"
#ami_id="ami-a4181cb9"
#security_groups=""
######first 2015 ami
#region="us-west-2"
#ami_id="ami-3d232a0d"
#security_groups="--security-groups windows-builds"
######2015 ami with updated EC2Config
region="eu-central-1"
ami_id="ami-b104ddde"
security_groups=""


user_data="<powershell>
    ([ADSI]\"WinNT://./Administrator\").SetPassword(\"${CRED}\");
    \$env:CRED=\"${CRED}\";
    \$env:AWS_ACCESS_KEY_ID=\"${AWS_ACCESS_KEY_ID}\";
    \$env:AWS_SECRET_ACCESS_KEY=\"${AWS_SECRET_ACCESS_KEY}\";
    Invoke-WebRequest https://raw.githubusercontent.com/mapbox/windows-builds/master/scripts/${BUILD_CMD} -OutFile Z:\\${BUILD_CMD};
    & Z:\\${BUILD_CMD} \"${COMMIT_MESSAGE}\" \"${gitsha}\"
    Write-Host \"exiting userdata\"
    </powershell>
    <persist>true</persist>"

id=$(aws ec2 run-instances \
    --instance-initiated-shutdown-behavior terminate \
    --region $region \
    --image-id $ami_id \
    --count 1 \
    --instance-type c3.4xlarge \
    $security_groups \
    --user-data "$user_data" | jq -r '.Instances[0].InstanceId')

echo "Created instance: $id"

aws ec2 create-tags --region $region --resources $id --tags "Key=Name,Value=Temp-mapnik-windows-build-server-${TRAVIS_REPO_SLUG}-${TRAVIS_JOB_NUMBER}"
aws ec2 create-tags --region $region --resources $id --tags "Key=GitSha,Value=$gitsha"

dns=''
instance_status_stopped=$(aws ec2 describe-instances --region $region --instance-id $id | jq -r '.Reservations[0].Instances[0].State.Name')
until [ "$instance_status_stopped" = "stopped" ]; do
    if [ `expr $(date "+%s") - $start_timestamp` -gt $maxtimeout ]; then
        echo "The instance has timed out. Terminating instance: $id"
        terminating_status=$(aws ec2 terminate-instances --region $region --instance-ids $id | jq -r '.TerminatingInstances[0].CurrentState.Name')
        exit 1
    fi

    instance_status_stopped=$(aws ec2 describe-instances --region $region --instance-id $id | jq -r '.Reservations[0].Instances[0].State.Name')
    echo "Instance stopping status $region $id: $instance_status_stopped"

    if [[ -z $dns ]]; then
        dns=$(aws ec2 describe-instances --instance-ids $id --region $region --query "Reservations[0].Instances[0].PublicDnsName")
        dns="${dns//\"/}"
        echo "temporary windows build server: $dns/wbs"
    fi;
    if [[ ${#dns} -gt 1 ]]; then
        instance_status_stopped="stopped"
    fi;

    sleep $sleep
done

#terminating_status=$(aws ec2 terminate-instances --region $region --instance-ids $id | jq -r '.TerminatingInstances[0].CurrentState.Name')
#echo "Publish complete, terminating instance: $id"

echo "build takes longer than 50 minutes"
echo "exiting travis build"
echo "instance will self-terminate, when finished"


exit 0
