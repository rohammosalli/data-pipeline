import json
import boto3
import csv
from collections import defaultdict
from io import StringIO
import os

s3 = boto3.client("s3")
sqs = boto3.client("sqs")
queue_url =  os.environ['SQS_URL']

def lambda_handler(event, context):
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    # Find the file keys for customers, orders, and items
    customers_key = find_key_by_prefix(bucket, "customers")
    orders_key = find_key_by_prefix(bucket, "orders")
    items_key = find_key_by_prefix(bucket, "items")

    # Process customers, orders, and items
    customers = read_csv_file(bucket, customers_key)
    customer_orders = read_csv_file(bucket, orders_key)
    order_items = read_csv_file(bucket, items_key)

    process_customers(customers, customer_orders, order_items)

def find_key_by_prefix(bucket, prefix):
    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    for obj in response.get("Contents", []):
        if obj["Key"].startswith(prefix):
            return obj["Key"]
    return None

def read_csv_file(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    file_content = response["Body"].read().decode("utf-8")
    rows = list(csv.DictReader(StringIO(file_content)))
    return rows

def process_customers(customers, customer_orders, order_items):
    try:
        # Organize orders by customer_reference
        orders_by_customer = defaultdict(list)
        for order in customer_orders:
            customer_reference = order["customer_reference"]
            orders_by_customer[customer_reference].append(order)

        # Organize items by order_reference
        items_by_order = defaultdict(list)
        for item in order_items:
            order_reference = item["order_reference"]
            items_by_order[order_reference].append(item)


        # Process customers, orders, and items
        for customer in customers:
            customer_reference = customer["customer_reference"]
            total_amount_spent = 0.0
            customer_orders_output = []

            for order in orders_by_customer[customer_reference]:
                order_reference = order["order_reference"]
                order_items_output = []

                for item in items_by_order[order_reference]:
                    item_total = float(item["total_price"])
                    total_amount_spent += item_total

                    order_items_output.append({
                        "product": item["item_name"],
                        "price": item_total / int(item["quantity"]),
                        "quantity": int(item["quantity"]),
                        "total": item_total
                    })

                customer_orders_output.append({
                    "order_id": order_reference,
                    "items": order_items_output
                })

            customer_message = {
                "type": "customer_message",
                "customer_reference": customer_reference,
                "number_of_orders": len(customer_orders_output),
                "total_amount_spent": total_amount_spent
            }
            sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(customer_message))
            datatolog=json.dumps(customer_message)
            print(datatolog)
    except Exception as e:
        error_message = {
            "type": "error_message",
            "customer_reference": customer_reference,
            "order_reference": order_reference,
            "message": str(e)
        }
        sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(error_message))
        datatolog=json.dumps(error_message)
        print(datatolog)
