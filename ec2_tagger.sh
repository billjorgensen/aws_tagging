#!/bin/bash
#
# Title: ec2_tagger.sh
#
# Description: ec2_tagger.sh is used to tag EC2-related infrastructure
# It requires Python and AWS CLI to be installed
#
# Usage: ec2_tagger.sh [tag_key] [tag_value] [resource_id] [aws_region]
#
# Requirements:
#   - Root level access to a UNIX/Linux system. Sudo will do. Or an EC2 instance
#     with an admin-level role
#   - AWS CLI (pip install awscli)
#   - AWS CLI is root's/superuser's path
#   - Proper AWS IAM role or user with admin level credentials
##################################################################### 
# variables...
Region=$4
ResrcId=$3
Tag=$1
Value=$2

# test to make sure all arguments are present...
# otherwise usage statement...
if [ $# -ne 4 ]
then
   echo "
  Usage: ec2_tagger.sh [tag_key] [tag_value] [resource_id] [aws_region]
"
   exit 1
fi

# use aws cli to tag... 

aws ec2 --region ${Region} create-tags --resources ${ResrcId} --tags "Key=${Tag},Value=${Value}"
if [ $? = 0 ]
then
   echo "
Success...!
"
   exit 0
else
   echo "
Apparent problem tagging EC2 resource...
"
   exit 1
fi
