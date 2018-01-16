Configuring and deploying an HPCC System on AWS from linux is a three-step process when using the HPCC CloudFormation template, [MyHPCCCloudFormationTemplate.json](MyHPCCCloudFormationTemplate.json), and accompanying scripts found in this repository. The three-step process is:

1.  Clone the github repository https://github.com/tlhumphrey2/EasyFastHPCCoAWS

2.  Copy the scripts in AWSInstanceFiles and your ssh pem file to an S3 bucket.

3.  Build a stack, using CloudFormation on the AWS console, that does the rest.

## Click [here](Documentation/EasyFastHPCCOnAWSLinux.pdf) to read the document that describes the process step-by-step.

Also, in this repository, you will find code and instructions for configuring a small instance that you can use to start and stop your cluster (so AWS costs are minimized). Look at the folder, [StopStartHPCC](StopStartHPCC). The README file there provides instructions for a) setting-up the instance and b) stopping/starting your cluster.
