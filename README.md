Configuring and deploying an HPCC System on AWS from linux is a three-step process when using the HPCC CloudFormation template, [MyHPCCCloudFormationTemplate.json](MyHPCCCloudFormationTemplate.json), and accompanying scripts found in this repository. The three-step process is:

1.  Clone the github repository https://github.com/hpcc-systems/hpcc2aws

2.  Copy the scripts in AWSInstanceFiles and your ssh pem file to an S3 bucket.

3.  Build a stack, using CloudFormation on the AWS console, that does the rest.

## Click [here](Documentation/EasyFastHPCCOnAWSLinux.pdf) to read the document that describes the process step-by-step.
