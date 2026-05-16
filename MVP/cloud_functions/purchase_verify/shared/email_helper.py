# shared/email_helper.py
# -*- coding: utf-8 -*-
"""
邮件发送模块 — 使用 Resend API
文档: https://resend.com/docs/api-reference/emails/send-email
"""
import os
import json


def send_reset_email(email, token):
    """
    发送密码重置邮件。

    Args:
        email: 用户邮箱
        token: 6 位数字验证码（明文）
    """
    import requests

    api_key = os.environ.get('RESEND_API_KEY')
    if not api_key:
        print(f"[EMAIL] RESEND_API_KEY not configured, printing code instead")
        print(f"[EMAIL] Reset code for {email}: {token}")
        return

    try:
        resp = requests.post(
            'https://api.resend.com/emails',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={
                'from': 'WanderChina <onboarding@resend.dev>',
                'to': [email],
                'subject': 'WanderChina - Password Reset Code',
                'html': (
                    '<div style="font-family: sans-serif; max-width: 400px; margin: 0 auto;">'
                    '<h2 style="color: #1a1a1a;">Reset Your Password</h2>'
                    f'<p>Your verification code is:</p>'
                    f'<p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; '
                    f'color: #2D6A4F; text-align: center; padding: 16px; '
                    f'background: #f0f7f4; border-radius: 8px;">{token}</p>'
                    '<p style="color: #666;">This code expires in <strong>10 minutes</strong>.</p>'
                    '<p style="color: #999; font-size: 12px;">If you didn\'t request this, '
                    'please ignore this email.</p>'
                    '</div>'
                ),
            },
            timeout=10,
        )

        if resp.status_code == 200:
            print(f"[EMAIL] Reset code sent to {email}")
        else:
            print(f"[EMAIL ERROR] Resend returned {resp.status_code}: {resp.text}")

    except Exception as e:
        print(f"[EMAIL ERROR] Failed to send: {e}")
        # 邮件发送失败不应阻塞主流程
        # token 已存入 DB，用户可以重试
