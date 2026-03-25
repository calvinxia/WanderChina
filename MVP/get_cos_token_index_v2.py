# get_cos_token/index.py
# -*- coding: utf-8 -*-
"""
COS 临时凭证 + 预签名上传 URL 云函数
- 返回 STS 临时凭证（向后兼容）
- 新增：返回预签名 upload_url，Flutter 端只需 http.put(url, body: bytes)
"""
import os
import sys
import json
import time
import hashlib
import hmac
from urllib.parse import quote

from tencentcloud.common import credential
from tencentcloud.sts.v20180813 import sts_client, models

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from shared.db_helper import json_response, parse_body


def _generate_presigned_url(bucket, region, object_path, tmp_secret_id, tmp_secret_key, session_token, expires=1800):
    """生成 COS 预签名上传 URL（HMAC-SHA1 签名）"""
    host = f"{bucket}.cos.{region}.myqcloud.com"
    http_method = 'put'
    uri_path = f"/{object_path}"
    
    # 签名有效期
    start_time = int(time.time())
    end_time = start_time + expires
    key_time = f"{start_time};{end_time}"
    
    # Step 1: SignKey = HMAC-SHA1(SecretKey, KeyTime)
    sign_key = hmac.new(
        tmp_secret_key.encode('utf-8'),
        key_time.encode('utf-8'),
        hashlib.sha1
    ).hexdigest()
    
    # Step 2: HttpString
    http_string = f"{http_method}\n{uri_path}\n\nhost={host}\n"
    
    # Step 3: StringToSign
    sha1_of_http_string = hashlib.sha1(http_string.encode('utf-8')).hexdigest()
    string_to_sign = f"sha1\n{key_time}\n{sha1_of_http_string}\n"
    
    # Step 4: Signature
    signature = hmac.new(
        sign_key.encode('utf-8'),
        string_to_sign.encode('utf-8'),
        hashlib.sha1
    ).hexdigest()
    
    # Step 5: 构造 Authorization
    authorization = (
        f"q-sign-algorithm=sha1"
        f"&q-ak={tmp_secret_id}"
        f"&q-sign-time={key_time}"
        f"&q-key-time={key_time}"
        f"&q-header-list=host"
        f"&q-url-param-list="
        f"&q-signature={signature}"
    )
    
    # 预签名 URL（包含临时 token）
    encoded_path = quote(object_path, safe='/')
    presigned_url = (
        f"https://{host}/{encoded_path}"
        f"?{authorization}"
        f"&x-cos-security-token={quote(session_token, safe='')}"
    )
    
    return presigned_url


def main_handler(event, context):
    """云函数入口"""
    try:
        body = parse_body(event)
        
        user_id = body.get('user_id', 'anonymous')
        object_path = body.get('object_path', '')
        
        bucket = os.environ['COS_BUCKET']
        region = os.environ['COS_REGION']
        appid = os.environ['COS_APPID']

        cred = credential.Credential(
            os.environ['COS_SECRET_ID'],
            os.environ['COS_SECRET_KEY']
        )

        client = sts_client.StsClient(cred, region)
        req = models.GetFederationTokenRequest()
        req.Name = f'wanderchina-{user_id[:8]}'
        req.DurationSeconds = 1800

        # 权限策略：允许上传头像和行程封面
        req.Policy = json.dumps({
            "version": "2.0",
            "statement": [{
                "effect": "allow",
                "action": [
                    "cos:PutObject",
                    "cos:InitiateMultipartUpload",
                    "cos:UploadPart",
                    "cos:CompleteMultipartUpload"
                ],
                "resource": [
                    f"qcs::cos:{region}:uid/{appid}:{bucket}/user/avatars/{user_id}/*",
                    f"qcs::cos:{region}:uid/{appid}:{bucket}/avatars/*",
                    f"qcs::cos:{region}:uid/{appid}:{bucket}/trips/covers/*"
                ]
            }]
        })

        resp = client.GetFederationToken(req)
        creds = resp.Credentials

        # 构造返回
        result = {
            'tmpSecretId': creds.TmpSecretId,
            'tmpSecretKey': creds.TmpSecretKey,
            'sessionToken': creds.Token,
            'expiredTime': resp.ExpiredTime,
            'bucket': bucket,
            'region': region,
        }

        # 如果指定了 object_path，生成预签名上传 URL
        if object_path:
            result['upload_url'] = _generate_presigned_url(
                bucket=bucket,
                region=region,
                object_path=object_path,
                tmp_secret_id=creds.TmpSecretId,
                tmp_secret_key=creds.TmpSecretKey,
                session_token=creds.Token,
            )

        return json_response(200, result)

    except Exception as e:
        print(f"[COS TOKEN ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return json_response(500, {'error': str(e)})
