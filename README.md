## CSV to JSON With (Lambda,SQS,S3,DynamoDB,Python)
This AWS Lambda function provides a powerful solution for data transformation and storage. Specifically, it reads CSV files from an S3 bucket, transforms them into JSON format, and then sends the resulting JSON data to an SQS queue. From there, another AWS Lambda function can be set up to read the data from the SQS queue and save it to DynamoDB for long-term storage and analysis.


### Prerequisites:

1. An AWS account

2. Terraform installed on your local machine. You can download Terraform from the official website: https://www.terraform.io/downloads.html
3. The AWS CLI installed on your local machine. You can download the AWS CLI from the official website: https://aws.amazon.com/cli/


### Configure AWS
1. Create an access key and secret key in your AWS account with the necessary permissions to create resources. You can do this by following the instructions in the official AWS documentation: https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys

2. Configure the AWS CLI on your local machine by running the following command and providing your access key and secret key:

```bash
aws configure
```
### Functionality
The function does the following:

Receives an event from S3 containing the bucket and object key
Reads three CSV files from the S3 bucket: customers, orders, and items
Processes the CSV files and creates a JSON object for each customer containing the customer's reference, number of orders, and total amount spent
Sends the resulting JSON object to an SQS queue. and the read the JSON and save it into the DynamoDB

### How run the setup

Make sure to change the names of the buckets and update the variables.tf file accordingly.

```bash 
terraform init

Terraform plan 

Terraform apply 
```


#### Uplaod test data

```bash
aws s3 cp example-data/*.csv s3://your-bucket/
```

### How Python Lambda function Works

##### index.py:
This Python code is designed to read CSV files and convert them to JSON format. It then sends the resulting JSON data to an Amazon Simple Queue Service (SQS) queue. This code is well-suited for a serverless setup using services such as AWS Lambda. It can be used to automate the process of processing large amounts of data from CSV files, which can be time-consuming and error-prone if done manually.

The code uses the Boto3 library to interact with AWS services, specifically S3 and SQS. When a new file is uploaded to an S3 bucket, the Lambda function is triggered. The function reads the CSV file, converts it to JSON, and sends the resulting JSON data to an SQS queue. The JSON data contains information about the customer, including their reference number, the number of orders they have placed, and the total amount they have spent. The SQS queue can then be used by other Lambda functions to process the data further, for example, to save it to a database.

##### sqs-db.py:
This Python code is designed to read JSON data from an SQS queue and save it to Amazon DynamoDB. It is designed to work in a serverless setup using services such as AWS Lambda. It can be used to automate the process of processing and storing large amounts of data.

### To achieve the CSV to JSON conversion in a serverless setup using AWS Lambda, we can follow these steps:

1. Create an S3 bucket to store your CSV files.
2. Create three CSV files in the S3 bucket: customers.csv, orders.csv, and items.csv.
3. Create an SQS queue to receive the resulting JSON data.
4. Create an AWS Lambda function to read the CSV files from the S3 bucket.
5. In the Lambda function, process the CSV files and create a JSON object for each customer containing the customer's reference, number of orders, and total amount spent.
6. Send the resulting JSON object to the SQS queue.
7. Create a second AWS Lambda function to read the data from the SQS queue.
8. In the second Lambda function, save the JSON data to DynamoDB.

By using AWS Lambda functions, we can achieve a fully serverless setup that automatically converts CSV files to JSON format and stores the resulting data in DynamoDB without any need for servers or infrastructure management. This setup is highly scalable, reliable, and cost-effective, as we only pay for the computing resources used during the function execution.

### How it scales
The solution is scalable because AWS Lambda is a serverless compute service, which means that it automatically scales to handle increased traffic and workloads. With Lambda, we can set the amount of memory and CPU allocated to each function, and AWS takes care of the rest, automatically scaling the number of instances running the function up or down based on demand.


### Troubleshoot


##### Error: local-exec provisioner error
The local-exec provisioner in Terraform executes a command locally on the machine running the Terraform code. If you are seeing an error with this provisioner, it usually means that the command being executed failed.

Please Run `Terraform apply` again


Note: if in your first try you can't see the data in DaynamoDB please try to delete the files and upload again.
