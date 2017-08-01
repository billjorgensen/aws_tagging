### aws_tagging
### Scripts to tag AWS EC2 resources: Instances, EBS volumes and snapshots
--------------------------------------------

### ec2_tagger.sh...
-----------------------
```
Usage: ec2_tagger.sh [tag_key] [tag_value] [ec2_resource_id] [aws_region]
```
```
~/aws/tagging/aws_tagging (master)-> ./ec2_tagger.sh CostCenter <value> <instance_id> <aws_region>

aws ec2 --region us-west-2 create-tags --resources <instance_id> --tags Key=key,Value=value

Success...!
```

### ec2_byip_tag.sh...
-------------------------
```
~/aws/tagging/aws_tagging  (master)-> ./ec2_byip_tag.sh

  Usage: ec2_byip_tag.sh [tag_key] [tag_value] [private_ip_address] [aws_region]
```
```
~/aws/tagging/aws_tagging  (master)-> ./ec2_byip_tag.sh <value> <value> <ip_address> <aws_region>

Success...!
```

### ec2_ebs_tagger.sh...
---------------------
```
~/aws/tagging/aws_tagging  (master)-> ./ec2_ebs_tagger.sh

   Usage: ec2_ebs_tagger.sh [AWS_Region]
```

### ec2_snap_tagger.sh...
---------------------
```
~/aws/tagging/aws_tagging  (master)-> ./ec2_snap_tagger.sh

   Usage: ec2_snap_tagger.sh [AWS_Region]
```

### ec2_tagresrcs.sh...
------------------------------
```
~/aws/tagging/aws_tagging  (master)-> ./ec2_tagresrcs.sh

   Two (2) arguments are needed for ec2_tagresrcs.sh

   USAGE:  ec2_tagresrcs.sh [AWS region] [name | id | ip | tag | bykey]
```
