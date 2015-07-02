2015/06/25 Added htpasswd authentication.<br />
2015/06/29 added Can select HPCC Platform<br />  

The following is a conversion to markdown of the EasyFastHPCCOnAWS.pdf that is in this repository.

# Easy Setup of Fast HPCC System on AWS
|

1. Introduction

Configuring and deploying an HPCC System on AWS from your Windows computer is a two-step process when using the HPCC CloudFormation template and accompanying scripts.

1. Copy the 14 accompanying scripts and your ssh pem file to an S3 bucket.
2. Use CloudFormation on the AWS console to do the rest.

The scripts of the repository are very similar to those in the BestHPCCoAWS repository.

When you get to section 3, "Using CloudFormation …", you need a placement group in the region where you deploy your HPCC System. Appendix B gives detailed instructions for making one. Also, for section 3, you need an ssh key pair on your Windows machine. Appendix C gives detailed instructions on how to make the key pair on the AWS console and download it to your Windows machine.

This document provides details for accomplishing the above two-step process.

1. Make an S3 Bucket and Copy Scripts and Ssh Pem File

Here is a summary of this process:

1. 1.Make an S3 bucket to copy scripts and ssh pem file.
2. 2.Copy scripts and ssh pem file into created S3 bucket.

You need s3cmd installed on your Windows machine. Installation instructions are given in Appendix A.

The following link shows the s3cmd usage commands: [http://s3tools.org/usage](http://s3tools.org/usage)

## 2.1 Make an S3 Bucket

First, you need an s3 bucket to copy the scripts and ssh pem file to. The following commands make an s3 bucket called BuildHPCCScripts.

| python c:\s3cmd\s3cmd mb s3://BuildHPCCScripts |
| --- |

Next, in a DOS window, cd into the folder containing all 14 perl/bash scripts and your ssh pem file for the region you will deploy your HPCC System on AWS.

## 2.2 Copy Scripts and Ssh Pem File to S3 Bucket

The following command copies everything in the current folder into the s3 bucket, BuildHPCCScripts.

| python c:\s3cmd\s3cmd  --recursive put . s3://BuildHPCCScripts |
| --- |

You can check to see if the scripts and ssh pem file are in the s3 bucket using the following command.

| python c:\s3cmd\s3cmd  ls s3://BuildHPCCScripts/\* |
| --- |

1. Using CloudFormation on AWS Console to Configure and Deploy an HPCC System

Here is a summary of this process:

1. 1.Navigate to the CloudFormation web page.
2. 2.Enter a Unique Name for the stack being created and give a path to the HPCC CF template.
3. 3.Fill in the HPCC CF template parameters, e.g. name of pem file, placement group, etc.
4. 4.Click the "Create" button to start the process of creating the HPCC System on AWS.

## 3.1 Navigate to CloudFormation Web Page

Log into the AWS console (from your browser) and click on Services. Then goto the CloudFormation section. Then click on "Create Stack".

## 3.2 Enter a Unique Stack Name and Path to HPCC CF Template

Figure 4 shows the next web page you will see. On this page, enter a unique stack name in the textbox labeled "Name" (pointed to by the top green arrow of Figure 4). Then click on the "Choose File" button (pointed to by the bottom green arrow of Figure 4).

When you click on "Choose File", you get an open-file dialog box, like that of Figure 5,  below.

Use the open-file dialog box to find the HPCC CF template on your Windows computer and then click on open. The name of the HPCC CF template is: MyHPCCCloudFormationTemplate.json.

After entering a unique name for the stack and choosing the HPCC CF template, the web page should  look like Figure 6,  below (note. The following screenshot is after I scrolled down enough to see the "Next" button). Now, click on the "Next" button (pointed to by the green arrow in Figure 6, below).

## 3.3 Enter HPCC CF Template Parameters

After clicking on the "Next" button, the next web page you see should look like Figure 7, below.

First, notice that the ScriptsS3BucketFolder has been set to the name of the bucket where we placed the scripts and ssh pem, i.e., s3://BuildHPCCScripts (see Section 2.2, above).  And, KeyPair has been set to the name of the ssh pem file that was put into the above mentioned s3 bucket; that is tlh\_keys\_us\_west\_2  (notice that '.pem' is omitted).

The other non-empty text boxes have been set to the recommended settings for an HPCC System that runs fast on AWS, except for NumberOfRoxieNodes, which has been set to "0".

HPCCPlacementGroup is the only text box that doesn't have anything in it. Enter the name of the placement group you want to use for the current region (Appendix B shows you how to setup a placement group using the AWS console).

For the purpose of demonstrating the use of the HPCC CF template, I will change some of the recommended values so the HPCC System that is configured and deployed doesn't cost me much money. The following screenshot is what Figure 7 looks like after making my changes.

Notice I changed NumberOfSlavesPerNode from 12 to 2, the NumberOfSlaveInstances from 7 to 1 and the instance types for the Master and Slaves, I changed to c3.2xlarge. Also, notice in Figure 8, above, that I've set HPCCPlacementGroup to "pg-tlh-best", which is the name of the placement group I created for the us-west-2 region, which is where this stack will be created.

## 3.4 Start Creation Process

Once you have the parameters the way you want them, you click on "Next" (where green arrow points in Figure 8, above). The next web page looks like Figure 9, below.

There is nothing to do on this web page. So, just click the "Next" button to continue to the next web page which looks like Figure 10, below.

This page shows all your settings, so you can verify they are what you want before starting the stack building process.

The next screenshot shows the same web page as above, except I've scrolled down so you can see the "Create" button. You click on the "Create" button to start the stack building process.

But, before you doing, you must click on the acknowledge checkbox (pointed to by the green arrow of Figure 11, below) to indicate that you know that the template comes from a trusted source. Why? Because the template creates AWS resources that you have to pay for and also the template gives permission to the instances created to access AWS resources such as S3 buckets.

 ![](data:image/*;base64,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)

The next web page you see should look like Figure 12, below.

 It is divided into 2 parts. The top part shows the stacks (in this case only one). And the bottom part shows the progress of the stack build process for the stack with the checkbox "checked" (where the green arrow points in Figure 12).

If you refresh the web page, you will see an update of the progress of the stack build process (like Figure 13, below).

The stack build process is done (meaning the HPCC System is setup) when "CREATE\_COMPLETE" is the Status of the stack building process (where the green arrow points in Figure 14, below).

When the stack creation process has completed go to the "Instances" page on the AWS console to get the IP address of the Master, which is needed to access ECL Watch and to setup the ECL IDE.

## Getting Public IP of Master

From the EC2 Dashboard, click on "Instances" (pointed to by the green arrow of Figure 15, below).

Next, you will see the Instance page which should look like Figure 16, below. The Master instance has been selected by clicking on the button just to the left of the instance's name (pointed to by the top-left green arrow in Figure 16). And because this instance is selected, its Public IP address is shown where the bottom-right  green arrow points. You can swipe across this Public IP address and save it. Then, paste it into your browser's address bar and append ":8010" to access ECL Watch.

# Appendix A. Install S3cmd on Your Windows Machine

The following link gives detailed instructions for installing s3cmd:

[http://tecadmin.net/setup-s3cmd-in-windows/](http://tecadmin.net/setup-s3cmd-in-windows/)

S3cmd needs both python and gpg for windows. This web site shows how to install both as well as how to install and configure s3cmd.

To install python, click on the link pointed to by the green arrow in Figure 15, above. The next page you see looks like Figure 18, below – for downloading python.

You don't want the latest Python. You want Python 2.7.6 which is in the list of other versions shown at the bottom of the page (you may have to scroll down to see the list and them scroll the list to find version 2.7.6).

## Installing pgp4win

No additional instructions are needed for the installation of pgp4win. Just following the instructions on the "How to Install S3cmd on Windows" web page.

## Installing s3cmd

No additional instructions are needed for the installation of s3cmd. Just following the instructions on the "How to Install S3cmd on Windows" web page.

## Configuring s3cmd

Once, s3cmd is install, do the following command to configure it. This command creates a the file, .s3cfg, in your home directory.

| Python c:\s3cmd\s3cmd --configure |
| --- |

The above command will prompt you for information. You will use the defaults supplied accept for those prompts given in the following table.

Table 1. S3cmd Configuration Parameters

| Prompt | Your Response |
| --- | --- |
| Access key | Enter your AWS access key |
| Secret key | Enter your AWS secret key |
| Encryption password | Just hit enter, i.e. don't provide a password |
| Path to GPG program | Enter the path where gpg was installed (my is C:\Program Files (x86)\GNU\GnuPG\pub\gpg.exe) |
| Test access with supplied credentials | Enter yes (this assures you didn't make any mistakes when entering the above parameters) |
| Save settings | Enter yes |



# Appendix B. Making a Placement Group

The EC2 instances of the deployed HPCC System are in the same placement group. This assures the instances are close together and therefore communication is faster.

The following gives detailed instructions for making a placement group in the region your HPCC System is deployed.

igure 19 is the top right corner of the home page of the AWS console. It and other AWS console pages have the region where instances will be launched in the top right-hand corner of the page (where the green arrow is pointing). If you click on the region, you get a dropdown menu containing all the regions. And, you can pick from the dropdown list another region.



Figure 20, below, shows the AWS Services page which you get when you click on "Services" in the top left-hand corner of the AWS console home page.  Click on EC2 pointed at by the green arrow of Figure18.

Next you will see the EC2 Dashboard page, Figure 21, below. Click on "Placement Groups", pointed to by the green arrow of Figure 21.

Next, you will see Figure 22, Placement Groups. Click on "Create Placement Group", pointed to by the green arrow of Figure 22.

 ![](data:image/*;base64,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)

This causes a popup as shown in Figure 23, below. Enter the name you want the placement group to have in the textbox named "Name" (In Figure 23, I have entered the name "pg-hpcc-us-west-2". After entering the name, click on "Create" pointed to by the green arrow of Figure 23. This causes the placement group to be created.

Next, as shown in Figure 24, you will see the newly created placement group in the list of placement groups (see where green arrow is pointing in Figure 24).



# Appendix C. Make a Ssh Pem File

An ssh key pair is used by the nodes of your deployed HPCC System to access other nodes of the system. The following gives details on how to create an ssh key pair and have it pem file downloaded to your Windows computer.

First from the EC2 Dashboard, click on Key Pair (pointed to by the green arrow of Figure 25).

Next, you will see the page where you can create a new key pair. It should look like Figure 26, below. Click on "Create Key Pair" (pointed to by the green arrow of Figure 26).

Next, you will see a popup with the title "Create Key Pair". It should look like Figure 27. Enter the name of your new key pair and then click on "Create" (pointed to by the green arrow of Figure 27). You will notice that in Figure 27, I entered the name "us-west-2-keypair".

After clicking on the "Create" button, the next think you will see is a page that looks like Figure 28, below. And, you should get an indication that the pem file for the newly created key pair was downloaded to your Windows computer (pointed to by the green arrow of Figure 28, below).
