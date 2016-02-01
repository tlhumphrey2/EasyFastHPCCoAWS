# HPCC System on AWS #

The contents of this github repository enables one to easily configure and deploy an HPCC System on AWS that can do real work in a timely manner.

Section 2 and appendices A through D of [EasyFastHPCCOnAWS_setup.pdf](https://github.com/tlhumphrey2/EasyFastHPCCoAWS/EasyFastHPCCOnAWS_setup.pdf) tell you how to setup so you can use an HPCC System on AWS.

Once you have done the setup, you can configure and deploy an HPCC System on AWS from your Windows computer in two steps using the HPCC CloudFormation template and accompanying scripts found on github at [https://github.com/tlhumphrey2/EasyFastHPCCoAWS](https://github.com/tlhumphrey2/EasyFastHPCCoAWS). The two-step process is:

1.	Copy the accompanying scripts (files in AWSInstanceFiles) and your ssh pem file to an S3 bucket (see section 2 of the setup pdf).
2.	Using CloudFormation on the AWS console, build a stack that does the rest (see section 3 of setup pdf).

