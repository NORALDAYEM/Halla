import os
import re
from contextlib import closing

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

ASSET = re.compile(r"/assets/([0-9a-f]{64})\.(jpg|png|gif|webp)\Z")
MIME = {"jpg": "image/jpeg", "png": "image/png", "gif": "image/gif", "webp": "image/webp"}
BUCKET = "halla"
PREFIX = "halla-web/"
client = None

def storage():
    global client
    if client is None:
        client = boto3.client(
            "s3", region_name="us-west-4", endpoint_url="https://s3.us-west-4.idrivee2.com",
            aws_access_key_id=os.environ["E2_ACCESS_KEY_ID"],
            aws_secret_access_key=os.environ["E2_SECRET_ACCESS_KEY"],
            config=Config(signature_version="s3v4", s3={"addressing_style": "path"},
                          connect_timeout=3, read_timeout=8, retries={"total_max_attempts": 2})
        )
    return client

def application(environ, start_response):
    method = environ.get("REQUEST_METHOD", "GET")
    path = environ.get("PATH_INFO", "/")

    def respond(status, data=b"", extra=()):
        start_response(status, [("Content-Type", "text/plain; charset=utf-8"),
                                ("Cache-Control", "no-store"), *extra])
        return [] if method == "HEAD" else [data]

    if method not in ("HEAD", "GET"):
        return respond("405 Method Not Allowed", extra=[("Allow", "GET, HEAD")])
    is_health = path == "/health"
    if path in ("/", "/index.html", "/halaa_voice_app.html") or is_health:
        name, mime, cache = "index.html", "text/html; charset=utf-8", "no-cache"
    elif (match := ASSET.fullmatch(path)):
        name, mime = path[1:], MIME[match.group(2)]
        cache = "public, max-age=31536000, immutable"
    else:
        return respond("404 Not Found")
    try:
        s3 = storage()
        args = {"Bucket": BUCKET, "Key": PREFIX + name}
        if method == "HEAD" or is_health:
            result = s3.head_object(**args)
            data = b""
        else:
            result = s3.get_object(**args)
            with closing(result["Body"]) as stream:
                data = stream.read()
    except ClientError as exc:
        code = exc.response["Error"]["Code"]
        if code in ("NoSuchKey", "404", "NotFound") and not is_health:
            return respond("404 Not Found")
        return respond("503 Service Unavailable", b"Storage unavailable.")
    except (KeyError, BotoCoreError, OSError):
        return respond("503 Service Unavailable", b"Storage unavailable.")
    if is_health:
        return respond("200 OK", b"ok")
    headers = [("ETag", result["ETag"]), ("Cache-Control", cache),
               ("X-Content-Type-Options", "nosniff"), ("Referrer-Policy", "strict-origin-when-cross-origin")]
    if environ.get("HTTP_IF_NONE_MATCH") == result["ETag"]:
        start_response("304 Not Modified", headers)
        return []
    start_response("200 OK", [*headers, ("Content-Type", mime), ("Content-Length", str(result["ContentLength"]))])
    return [] if method == "HEAD" else [data]
