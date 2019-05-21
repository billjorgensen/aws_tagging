#!/bin/bash
#
# Title: lolotags.sh
#
# Description: lolotags.sh will remove or add the tags related to Cloud Custodian
# Ligths-on/Lights-off (lo/lo) Lambda function. The function looks for the tags
# parses the key value to know when to either stop or start the AWS resource
#
# Usage: lolotags.sh [add|remove] [Custodian tag]
#
##############################################################################
# variables...
export AWS_DEFAULT_REGION=us-east-1
export AWS_DEFAULT_OUTPUT=text
Task=${1}
KeyName=${2}

# function to add tags to instance(s)...
function add_tags() {
  # single instance or a list?
  echo -n "EC2 instance ID list (space delimited): "
  read Response

  # associate a value...
  case ${KeyName} in
    c7n-offhours)
      KeyValue="off=(M-F,19);on=(M-F,7);tz=mt;"
      TagValue=$(echo "'${KeyValue}'")
      ;;
    c7ndb-offhours)
      KeyValue="off=(M-F,20);on=(M-F,6);tz=mt;"
      TagValue=$(echo "'${KeyValue}'")
      ;;
    c7n-xxxxx)
      KeyValue="off=(M-F,22);on=(M-F,4);tz=mt;"
      TagValue=$(echo "'${KeyValue}'")
      ;;
    c7ndb-xxxxx)
      KeyValue="off=(M-F,23);on=(M-F,3);tz=mt;"
      TagValue=$(echo "'${KeyValue}'")
      ;;
  esac

  # add tags...
  aws ec2 create-tags --resources ${Response} --tags Key=${KeyName},Value=${TagValue}
  ValCheck=$(aws ec2 describe-instances --instance-ids ${Response} --query 'Reservations[].Instances[].[Tags]' --output text | grep ${KeyName} | awk '{print $2}')
  echo "Tag, ${KeyName}, on ${Response}: ${ValCheck}"
}

# function to remove tags from instances...
function remove_tags() {
  # single instance or a list?
  echo -n "EC2 instance ID list (space delimited): "
  read Response

  # remove tags...
  aws ec2 delete-tags --resources ${Response} --tags Key=${KeyName}
  ValCheck=$(aws ec2 describe-instances --instance-ids ${Response} --query 'Reservations[].Instances[].[Tags]' --output text | grep ${KeyName} | awk '{print $2}')
  echo "Tag, ${KeyName}, on ${Response}: ${ValCheck}"
}

# main and usage...
case ${Task} in
  add)
    # check for valid tags...
    if [ "${KeyName}" = "c7n-offhours" -o "${KeyName}" = "c7ndb-offhours" -o "${KeyName}" = "c7ndb-xxxxx" -o "${KeyName}" = "c7n-xxxxxx" ]
    then
      add_tags
    else
      echo "
SCRIPT ERROR: That tag is not used...
  Custodian tags:
    c7n-offhours
    c7n-xxxxx
    c7ndb-offhours
    c7ndb-xxxxx

Usage: `basename $0` [add|remove] [Custodian tag]
"
      exit 1
    fi
    ;;
  remove)
    # check for valid keys...
    if [ "${KeyName}" = "c7n-offhours" -o "${KeyName}" = "c7ndb-offhours" -o "${KeyName}" = "c7ndb-xxxxx" -o "${KeyName}" = "c7n-xxxxx" ]
    then
      remove_tags
    else
      echo "
SCRIPT ERROR: That tag is not used...
  Custodian tags:
    c7n-offhours
    c7n-xxxxx
    c7ndb-offhours
    c7ndb-xxxxx

Usage: `basename $0` [add|remove] [Custodian tag]
"
      exit 1
    fi
    ;;
  -h|--help)
    echo "
  Usage: `basename $0` [add|remove] [Custodian tag]
"
    exit 1
    ;;
  "")
    echo "
  Usage: `basename $0` [add|remove] [Custodian tag]
"
    exit 1
    ;;
  *)
    echo "
  Usage: `basename $0` [add|remove] [Custodian tag]
"
    exit 1
    ;;
esac
exit 0
