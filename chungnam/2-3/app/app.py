from flask import Flask, render_template, request
import boto3
import logging
import os

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

dynamodb = boto3.client('dynamodb')

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        try:
            table_name = request.form['table_name']
            s3_bucket = request.form['s3_bucket']
            attribute1_value = request.form['attribute1_value']
            attribute2_value = request.form['attribute2_value']

            response = dynamodb.put_item(
                TableName=table_name,
                Item={
                    'PK': {'S': 'partition_key_value'},
                    'SK': {'S': 'sort_key_value'},        
                    'Attribute1': {'S': attribute1_value},
                    'Attribute2': {'S': attribute2_value}
                }
            )

            logger.info(f"Item added to DynamoDB successfully. Attribute1: {attribute1_value}, Attribute2: {attribute2_value}")

            try:
                with open('logs.log', 'a') as log_file:
                    log_file.write(f"Item added to DynamoDB successfully. Attribute1: {attribute1_value}, Attribute2: {attribute2_value}\n")

            except Exception as e:
                logger.error(f"Error writing logs to file: {e}")

            try:
                file_name = 'logs.log'

                with open(file_name, 'rb') as data:
                    s3 = boto3.client('s3')
                    s3.upload_fileobj(data, s3_bucket, file_name)

                logger.info("Logs uploaded to S3 successfully.")

                os.remove(file_name)

            except Exception as e:
                logger.error(f"Error uploading logs to S3: {e}")

        except Exception as e:
            logger.error(f"Error adding item to DynamoDB: {e}")
            return "Error adding item to DynamoDB"
    
    return render_template('index.html')

@app.route('/healthcheck')
def healthcheck():
    return "OK"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
