"""Provision or restore Halaa's encrypted Android signer in the owner's IDrive e2 bucket."""
import argparse
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from zipfile import ZipFile

PREFIX = "android-signing/production/v1/"
ALIAS = "halaa-release"
ROOT = Path(__file__).resolve().parents[2]


def command(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def idrive():
    env = os.environ.copy()
    for name in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"):
        env[name] = "".join(env[name].split())
        if not env[name]:
            raise ValueError("IDrive credentials are missing")
    endpoint = env["IDRIVE_ENDPOINT"].strip().rstrip("/")
    if "://" not in endpoint:
        endpoint = "https://" + endpoint
    if not endpoint.startswith("https://"):
        raise ValueError("IDrive connection must use HTTPS")
    bucket = env["IDRIVE_BUCKET"].strip()
    cli = ["aws", "--no-cli-pager", "--endpoint-url", endpoint, "s3api"]
    for region in ("us-west-4", "us-east-1", "or-2"):
        env["AWS_DEFAULT_REGION"] = region
        result = subprocess.run([*cli, "list-objects-v2", "--bucket", bucket, "--prefix", PREFIX,
                                 "--output", "json"], capture_output=True, env=env)
        if result.returncode == 0:
            keys = [entry["Key"] for entry in json.loads(result.stdout).get("Contents", [])
                    if re.fullmatch(re.escape(PREFIX) + r"[0-9a-f]{64}\.zip", entry["Key"])]
            return cli, bucket, env, keys
    raise RuntimeError("Unable to list the signing prefix in the configured IDrive bucket")


def fingerprint(store):
    cert = command("keytool", "-exportcert", "-storetype", "PKCS12", "-keystore", str(store),
                   "-alias", ALIAS, "-storepass:env", "HALAA_STOREPASS", capture_output=True).stdout
    return hashlib.sha256(cert).hexdigest()


def provision(folder, cli, bucket, env):
    store = folder / "release.p12"
    command("keytool", "-genkeypair", "-storetype", "PKCS12", "-keyalg", "RSA", "-keysize", "3072",
            "-validity", "10000", "-dname", "CN=Halaa Android Release", "-alias", ALIAS,
            "-keystore", str(store), "-storepass:env", "HALAA_STOREPASS", "-keypass:env", "HALAA_STOREPASS")
    cert_hash = fingerprint(store)
    wrapped = command("openssl", "pkeyutl", "-encrypt", "-pubin", "-inkey",
                      str(ROOT / ".github/android-recovery-public.pem"),
                      "-pkeyopt", "rsa_padding_mode:oaep", "-pkeyopt", "rsa_oaep_md:sha256",
                      "-pkeyopt", "rsa_mgf1_md:sha256",
                      input=os.environ["HALAA_STOREPASS"].encode(), capture_output=True).stdout
    archive = folder / "backup.zip"
    with ZipFile(archive, "w") as backup:
        backup.write(store, "release.p12")
        backup.writestr("storepass.oaep", wrapped)
    key = PREFIX + cert_hash + ".zip"
    command(*cli, "put-object", "--bucket", bucket, "--key", key, "--body", str(archive),
            env=env, stdout=subprocess.DEVNULL)
    return key


def sign(store, expected, source, destination):
    build_tools = Path(os.environ["ANDROID_HOME"]) / "build-tools"
    candidates = sorted((p for p in build_tools.glob("*/apksigner") if
                         all(part.isdigit() for part in p.parent.name.split("."))),
                        key=lambda p: tuple(map(int, p.parent.name.split("."))))
    signer = str(candidates[-1])
    destination.mkdir(exist_ok=True)
    for name in ("Halaa-App-Android.apk", "Halaa-Rooms-Android.apk"):
        before, after = source / name, destination / name
        command(signer, "sign", "--ks", str(store), "--ks-key-alias", ALIAS, "--ks-pass",
                "env:HALAA_STOREPASS", "--key-pass", "env:HALAA_STOREPASS", "--out", str(after), str(before))
        info = command(signer, "verify", "--print-certs", str(after), capture_output=True, text=True).stdout
        if f"Signer #1 certificate SHA-256 digest: {expected}" not in info:
            raise ValueError("Unexpected APK signer")
        with ZipFile(before) as original, ZipFile(after) as signed:
            def payload(archive):
                return {i.filename: (i.CRC, i.file_size) for i in archive.infolist()
                        if not re.fullmatch(r"META-INF/(MANIFEST\.MF|[^/]+\.(SF|RSA|EC|DSA))",
                                            i.filename, re.IGNORECASE)}
            if payload(original) != payload(signed):
                raise ValueError("Signing changed the APK payload")
        print("Verified signed installer", name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["provision", "sign"])
    parser.add_argument("--fingerprint")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--destination", type=Path)
    args = parser.parse_args()
    if args.mode == "sign" and not (args.fingerprint and args.source and args.destination):
        parser.error("sign requires a pinned certificate and source/destination directories")
    os.umask(0o077)
    cli, bucket, env, keys = idrive()
    # Normal builds unlock the PKCS12 with the protected e2 credential. If that
    # credential is rotated, the owner can recover the password with the offline
    # RSA key and save it as HALAA_ANDROID_STORE_PASSWORD in Actions secrets.
    password = os.environ.get("HALAA_ANDROID_STORE_PASSWORD") or base64.urlsafe_b64encode(
        hmac.digest(env["AWS_SECRET_ACCESS_KEY"].encode(), b"Halaa Android production keystore v1", "sha256")
    ).decode()
    os.environ["HALAA_STOREPASS"] = password
    with tempfile.TemporaryDirectory() as tmp:
        folder = Path(tmp)
        if args.mode == "sign":
            if not re.fullmatch(r"[0-9a-f]{64}", args.fingerprint):
                raise ValueError("Invalid pinned certificate")
            key = PREFIX + args.fingerprint + ".zip"
            if key not in keys:
                raise ValueError("Pinned signer missing from IDrive")
        elif len(keys) == 1:
            key = keys[0]
        elif not keys:
            key = provision(folder, cli, bucket, env)
        else:
            raise ValueError("More than one candidate signing key exists")
        fetched = folder / "restored.zip"
        command(*cli, "get-object", "--bucket", bucket, "--key", key, str(fetched),
                env=env, stdout=subprocess.DEVNULL)
        store = folder / "restored.p12"
        with ZipFile(fetched) as archive:
            if len(archive.read("storepass.oaep")) != 384:
                raise ValueError("Offline recovery envelope is incomplete")
            store.write_bytes(archive.read("release.p12"))
        cert_hash = fingerprint(store)
        if key != PREFIX + cert_hash + ".zip":
            raise ValueError("Restored certificate does not match the backup name")
        print("Restored Android signing certificate SHA-256:", cert_hash, flush=True)
        if args.mode == "sign":
            sign(store, cert_hash, args.source, args.destination)


if __name__ == "__main__":
    main()
