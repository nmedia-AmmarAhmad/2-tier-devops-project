import json
import boto3
import base64

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # This dictionary is the "Key" to fixing the CORS error
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
    }

    # 1. Handle the Browser's Pre-flight security check
    method = event.get('requestContext', {}).get('http', {}).get('method')
    if method == 'OPTIONS':
        return {
            "statusCode": 200,
            "headers": cors_headers,
            "body": ""
        }

    try:
        # 2. Parse the body
        body = json.loads(event['body'])
        file_name = body['filename']
        file_data = body['file'].split(",")[-1]
        
        # 3. Upload to S3 (Make sure bucket name is exact!)
        s3.put_object(
            Bucket="ammar-portal-uploads-2026", 
            Key=file_name,
            Body=base64.b64decode(file_data),
            ContentType='image/jpeg'
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps({"message": "Successfully uploaded to S3!"})
        }

    except Exception as e:
        print(f"CRASH LOG: {str(e)}")
        return {
            "statusCode": 500,
            "headers": cors_headers,
            "body": json.dumps({"error": str(e)})
        }