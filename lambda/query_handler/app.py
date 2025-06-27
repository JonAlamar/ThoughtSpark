import json
import boto3
import os
from pinecone import Pinecone
from botocore.exceptions import BotoCoreError, ClientError

# Initialize Bedrock client once (safe to cache)
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

# Globals for lazy init
pinecone_index = None

def get_secret(secret_name):
    print(f"🔐 Retrieving secret: {secret_name}")
    client = boto3.client("secretsmanager", region_name="us-east-1")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

def init_pinecone():
    global pinecone_index

    if pinecone_index:
        print("✅ Pinecone already initialized")
        return pinecone_index

    try:
        print("🧠 Initializing Pinecone")
        secret = get_secret("thoughtspark/pinecone")
        pinecone_api_key = secret["PINECONE_API_KEY"]

        pc = Pinecone(api_key=pinecone_api_key)
        pinecone_index = pc.Index(os.environ["PINECONE_INDEX_NAME"])
        print("✅ Pinecone initialized")
        return pinecone_index
    except Exception as e:
        print(f"❌ Pinecone init failed: {e}")
        raise e

def lambda_handler(event, context):
    print("🚀 Lambda started")
    print("📥 Event received:")
    print(json.dumps(event))

    try:
        body = json.loads(event.get("body", "{}"))
        print(f"📦 Parsed body: {body}")

        query_text = body.get("query", "").strip()
        user_id = body.get("user_id", "default")

        if not query_text:
            print("⚠️ Missing 'query' in request")
            return {"statusCode": 400, "body": json.dumps({"error": "Missing query"})}

        # Step 1: Get embedding
        print(f"🔎 Embedding text: {query_text}")
        index = init_pinecone()

        embed_response = bedrock.invoke_model(
            modelId="amazon.titan-embed-text-v2:0",
            body=json.dumps({
                "inputText": query_text,
                "embeddingDimension": 1024
            }),
            contentType="application/json",
            accept="application/json"
        )
        embedding = json.loads(embed_response["body"].read())["embedding"]
        print("✅ Embedding received")

        # Step 2: Pinecone vector search
        print(f"🔍 Querying Pinecone index with namespace '{user_id}'")
        pinecone_results = index.query(
            vector=embedding,
            top_k=5,
            namespace=user_id,
            include_metadata=True
        )

        matches = pinecone_results.get("matches", [])
        print(f"🔗 Pinecone returned {len(matches)} matches")

        context_lines = [f"- {match['metadata']['text']}" for match in matches]
        context_text = "\n".join(context_lines)

        # Step 3: Send to Claude
        prompt = (
            "You are a helpful household item memory assistant. "
            "Using the memory below, answer the user's question.\n\n"
            f"{context_text}\n\n"
            f"Question: {query_text}\nAnswer:"
        )
        print("🧠 Sending prompt to Claude")

        claude_response = bedrock.invoke_model(
            modelId="anthropic.claude-3-haiku-20240307",
            body=json.dumps({
                "messages": [{"role": "user", "content": prompt}],
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 300
            }),
            contentType="application/json",
            accept="application/json"
        )

        answer = json.loads(claude_response["body"].read())["content"][0]["text"]
        print(f"✅ Claude response: {answer}")

        return {
            "statusCode": 200,
            "body": json.dumps({"answer": answer})
        }

    except (BotoCoreError, ClientError) as e:
        print(f"❌ AWS error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": f"AWS error: {str(e)}"})}
    except Exception as e:
        print(f"❌ Unhandled exception: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
