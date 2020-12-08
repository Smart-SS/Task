vpcID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 |  jq -r '.Vpc.VpcId'`

subnetID1=`aws ec2 create-subnet --vpc-id $vpcID --cidr-block 10.0.1.0/24 --availability-zone us-east-2a| jq -r '.Subnet.SubnetId'`
subnetID2=`aws ec2 create-subnet --vpc-id $vpcID --cidr-block 10.0.2.0/24 --availability-zone us-east-2b| jq -r '.Subnet.SubnetId'`
subnetID3=`aws ec2 create-subnet --vpc-id $vpcID --cidr-block 10.0.3.0/24 --availability-zone us-east-2c| jq -r '.Subnet.SubnetId'`

InternetGatewayID=`aws ec2 create-internet-gateway |  jq -r '.InternetGateway.InternetGatewayId'`



aws ec2 attach-internet-gateway --vpc-id $vpcID  --internet-gateway-id $InternetGatewayID


RoutetableID=`aws ec2 create-route-table --vpc-id $vpcID |jq -r '.RouteTable.RouteTableId'`


aws ec2 create-route --route-table-id $RoutetableID  --destination-cidr-block 0.0.0.0/0 --gateway-id $InternetGatewayID

aws ec2 describe-route-tables --route-table-id $RoutetableID

aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcID" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}'


aws ec2 associate-route-table  --subnet-id $subnetID1 --route-table-id $RoutetableID
aws ec2 associate-route-table  --subnet-id $subnetID2 --route-table-id $RoutetableID


aws ec2 modify-subnet-attribute --subnet-id $subnetID1  --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $subnetID2 --map-public-ip-on-launch


aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem

chmod 400 MyKeyPair.pem

groupID=`aws ec2 create-security-group --group-name BastionSSHAccess --description "Security group for SSH access" --vpc-id $vpcID| jq -r '.GroupId'`


aws ec2 authorize-security-group-ingress --group-id $groupID  --protocol tcp --port 22 --cidr 0.0.0.0/0



instanceID1=`aws ec2 run-instances --image-id ami-0dacb0c129b49f529 --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids $groupID --subnet-id $subnetID1 | jq -r '.Instances[].InstanceId'`
sleep 60

publicIpAddr=`aws ec2 describe-instances --instance-ids $instanceID1 | jq -r '.Reservations[].Instances[].PublicIpAddress'`
privateIpAddr=`aws ec2 describe-instances --instance-ids $instanceID1 | jq -r '.Reservations[].Instances[].PrivateIpAddress'`

ssh -i MyKeyPair.pem ec2-user@"$publicIpAddr" "sudo yum update -y"


webgroupID=`aws ec2 create-security-group --group-name WebSubnetSSHAccess --description "Security group for WEB Subnet" --vpc-id $vpcID| jq -r '.GroupId'`

aws ec2 authorize-security-group-ingress --group-id $webgroupID  --protocol tcp --port 22 --cidr $privateIpAddr/32
aws ec2 authorize-security-group-ingress --group-id $webgroupID  --protocol tcp --port 443 --cidr 0.0.0.0/0
instanceID2=`aws ec2 run-instances --image-id ami-0dacb0c129b49f529 --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids $webgroupID --subnet-id $subnetID2 --user-data file://userdata.txt | jq -r '.Instances[].InstanceId'`
sleep 60

publicIpAddr=`aws ec2 describe-instances --instance-ids $instanceID2 | jq -r '.Reservations[].Instances[].PublicIpAddress'`
webprivateIpAddr=`aws ec2 describe-instances --instance-ids $instanceID2 | jq -r '.Reservations[].Instances[].PrivateIpAddress'`


appgroupID=`aws ec2 create-security-group --group-name AppSubnetSSHAccess --description "Security group for App Subnet" --vpc-id $vpcID| jq -r '.GroupId'`

aws ec2 authorize-security-group-ingress --group-id $appgroupID  --protocol tcp --port 22 --cidr $privateIpAddr/32
aws ec2 authorize-security-group-ingress --group-id $appgroupID  --protocol tcp --port 80 --cidr $webprivateIpAddr/32

instanceID3=`aws ec2 run-instances --image-id ami-0dacb0c129b49f529 --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids $appgroupID --subnet-id $subnetID3  | jq -r '.Instances[].InstanceId'`




echo "Congratulations entire setup is done and ready"

