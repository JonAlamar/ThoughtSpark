import json
import boto3
import os
import pinecone
from botocore.exceptions import BotoCoreError, ClientError

# Initialize Bedrock client and Pinecone
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

pinecone.init(
    api_key=os.environ["PINECONE_API_KEY"],
    environment=os.environ["PINECONE_ENV"]
)
index = pinecone.Index(os.environ["PINECONE_INDEX_NAME"])

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        query_text = body.get("query", "").strip()
        user_id = body.get("user_id", "default")

        if not query_text:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing query"})}

        # Step 1: Get Titan embedding
        embed_response = bedrock.invoke_model(
            modelId="amazon.titan-embed-text-v1",
            body=json.dumps({"inputText": query_text}),
            contentType="application/json",
            accept="application/json"
        )
        embedding = json.loads(embed_response["body"].read())["embedding"]

        # Step 2: Query Pinecone
        pinecone_results = index.query(
            vector=embedding,
            top_k=5,
            namespace=user_id,
            include_metadata=True
        )

        context_lines = [
            f"- {match['metadata']['text']}" for match in pinecone_results.get("matches", [])
        ]
        context_text = "\n".join(context_lines)

        # Step 3: Build prompt and send to Claude
        prompt = (
            "You are a helpful household item memory assistant. "
            "Using the memory below, answer the user's question.\n\n"
            f"{context_text}\n\n"
            f"Question: {query_text}\nAnswer:"
        )

        claude_response = bedrock.invoke_model(
            modelId="anthropic.claude-3-haiku-20240307",
            body=json.dumps({
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 300
            }),
            contentType="application/json",
            accept="application/json"
        )

        answer = json.loads(claude_response["body"].read())["content"][0]["text"]

        return {
            "statusCode": 200,
            "body": json.dumps({"answer": answer})
        }

    except (BotoCoreError, ClientError) as e:
        return {"statusCode": 500, "body": json.dumps({"error": f"AWS error: {str(e)}"})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
