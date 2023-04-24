import boto3
import json
import time
from decimal import Decimal
import os

sqs = boto3.resource('sqs')
dynamodb = boto3.resource('dynamodb')
queue_url = os.environ['SQS_URL']
table_name = 'customer'

table = dynamodb.Table(table_name)
queue = sqs.Queue(queue_url)

while True:
    try:
        messages = queue.receive_messages(WaitTimeSeconds=20)
        print(messages)
        for message in messages:
            try:
                data = json.loads(message.body)
                if data['type'] == 'customer_message':
                    customer_ref = data['customer_reference']
                    num_orders = data['number_of_orders']
                    total_spent = Decimal(str(data['total_amount_spent']))
                    print(total_spent)
                    table.put_item(Item={'customer_reference': customer_ref, 'num_orders': num_orders, 'total_spent': total_spent})
                message.delete()
            except Exception as e:
                print(f'Error processing message {message.body}: {e}')
    except Exception as e:
        print(f'Error receiving messages from queue: {e}')
        time.sleep(1)
