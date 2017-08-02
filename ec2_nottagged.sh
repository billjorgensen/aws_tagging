#!/bin/bash
#
# Title: ec2_nottaggged.sh
#
# Description: ec2_nottagged.sh is used to create a list EC2 resource ID's (instances and
# volumes) that have no <tag_key> tag key value and email the list
#
# Usage: ec2_nottagged.sh
#
# Requirements:
#   - Root level access to a UNIX/Linux system. Sudo will do. Or an EC2 instance
#     with an admin-level role
#   - AWS CLI (pip install awscli)
#   - AWS CLI is root's/superuser's path
#   - Proper AWS IAM role or user with admin level credentials
##################################################################### 
# variables...
PATH=${PATH}:/usr/local/bin:/usr/local/admin/bin
#Region=$1

# list the instance id's, by region, not tagged
for Region in us-east-1 us-west-2
do
   # list the instances first...
   aws ec2 --region ${Region} --output text describe-instances --query 'Reservations[].Instances[?!not_null(Tags[?Key == `<tag_key>`].Value)] | [].[InstanceId]' > /var/tmp/${Region}_instances_totag

   # list the volumes next...
   aws ec2 --region ${Region} --output text describe-volumes --query 'Volumes[?!not_null(Tags[?Key == `<tag_key>`].Value)] | [].[VolumeId]' > /var/tmp/${Region}_volumes_totag
done

# check the files to see if anything needs to be emailed...
for Region in us-east-1 us-west-2
do
   # instances first...
   [[ -s /var/tmp/${Region}_instances_totag ]] && mail -s "${Region}: Instances without <tag_key> tag" your.email@domain.com your.email2@domain.com < /var/tmp/${Region}_instances_totag
   rm /var/tmp/${Region}_instances_totag

   # volumes next...
   [[ -s /var/tmp/${Region}_volumes_totag ]] && mail -s "${Region}: Volumes without <tag_key> tag" your.email@domain.com your.email2@domain.com< /var/tmp/${Region}_volumes_totag
   rm /var/tmp/${Region}_volumes_totag
done
