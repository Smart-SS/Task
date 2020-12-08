README

Following things are required to be done.

1. Run this shell script from any Linux server which has access to internet

2. Run aws configure to connect to appropriate AWS account with role having permission to create resources on AWS

3. Please use us-east-2 as default region

4. Ensure jq utility is installed, if not installed, please run yum -y install jq


Post above pre requ

Execute ./creatInfra.sh

IT will 
 - create the VPC
 - subnet in different regions
 - security group with specified access
 - create keypair
 - create the EC2 in each subnet with different security groups
 - Install Apache and start the service - on WebSubnet EC2
 


Entire automation is done using AWS CLI 

Please note, you need to enter yes, when asked by script, its used for first time connection to newly created EC2 instances.

This script is working fine, test and giving expected results.

Overall Solution:


1. VPC is created

2. Total three subnets are created in each availability zone. 

3. Three security groups are created, bastion host, WebSubnet and AppSubnet

4. Appropriate access is given on these security groups.

5. Ec2 instances are created on each group.

6. Bastion host has access from outside on port 22 and no other port is allowed.

7. WebSubnet and AppSubnet are accesible on port 22 from bastion host only

8. AppSubnet is accesilbe on port 443 from outside.

9. Http and curl installation done on Websubnet using userdata which ensures to run command while launching the EC2

10. Appsubnet is accessible only on port 80 from WebSubnet.

11. Entire solution is working and tested.





Follow up questions:


How would you make this deployment fault tolerant and highly available?

Answer:  I will launch Ec2 under different Availability Zone to ensure HA, also, I can consider to have auto scale group, which will ensure that its able to sustain sudden burst of traffic.


How would you make this deployment more secure?

I will use encryption at rest and ensure all the data on EC2 are encrypted. Also, all the communication between applications and different subnet to be encrypted, like we have allowed port 80 from Web to App, rather 
we should use secure port with certificates.  Access to be open only for specific IP.

How would you make this deployment cloud agnostic?

I can use Terraform and externalize all the variables like image, number of Ec2, ports to be opened, name of groups, and the public cloud to be used. This will ensure same set of Terraform code to be used for create the setup on any public cloud like GCP, Azure or AWS


