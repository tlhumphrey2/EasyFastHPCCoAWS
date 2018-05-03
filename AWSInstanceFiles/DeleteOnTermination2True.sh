instanceID=$1
dev=$2
region=$3
aws ec2 modify-instance-attribute --instance-id $instanceID --region $region --block-device-mappings "[{\"DeviceName\": \"$dev\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
