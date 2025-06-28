import json
import boto3
import os
from pinecone import Pinecone
from botocore.exceptions import BotoCoreError, ClientError
from datetime import datetime

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

pinecone_api_key = None
pinecone_index = None
pinecone_client = None

def get_secret(secret_name):
    client = boto3.client("secretsmanager", region_name="us-east-1")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

def init_pinecone():
    global pinecone_client, pinecone_index
    if pinecone_index:
        return pinecone_index
    if not pinecone_client:
        secret = get_secret("thoughtspark/pinecone")
        pinecone_api_key = secret["PINECONE_API_KEY"]
        pinecone_client = Pinecone(api_key=pinecone_api_key)
    pinecone_index = pinecone_client.Index(os.environ["PINECONE_INDEX_NAME"])
    return pinecone_index

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        user_id = body.get("user_id", "default")
        text = body.get("text", "").strip()
        timestamp = body.get("timestamp") or datetime.utcnow().isoformat()

        if not text:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing text"})}

        index = init_pinecone()

        embed_response = bedrock.invoke_model(
            modelId="amazon.titan-embed-text-v2:0",
            body=json.dumps({
                "inputText": text,
            }),
            contentType="application/json",
            accept="application/json"
        )

        embedding = json.loads(embed_response["body"].read())["embedding"]

        vector_id = f"{user_id}-{timestamp}"

        index.upsert(
            vectors=[{
                "id": vector_id,
                "values": embedding,
                "metadata": {
                    "text": text,
                    "user_id": user_id,
                    "timestamp": timestamp
                }
            }],
            namespace=user_id
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Log stored successfully"})
        }

    except (BotoCoreError, ClientError) as e:
        return {"statusCode": 500, "body": json.dumps({"error": f"AWS error: {str(e)}"})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
