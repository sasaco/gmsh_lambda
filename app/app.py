import json
import sys

def handler(event, context):

    sys.path.append('/usr/local/lib/python3.8/site-packages/gmsh-4.8.4-Linux64-sdk/lib')

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "hello world",
            }
        ),
    }