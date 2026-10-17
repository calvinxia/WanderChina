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
                'from': 'OrienScope <noreply@orienscope.app>',
                'to': [email],
                'subject': 'OrienScope - Password Reset Code',
                'html': (
                    '<div style="font-family: sans-serif; max-width: 400px; margin: 0 auto;">'
                    '<h2 style="color: #1a1a1a;">Reset Your Password</h2>'
                    f'<p>Your verification code is:</p>'
                    f'<p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; '
                    f'color: #16162A; text-align: center; padding: 16px; '
                    f'background: #F7F2E4; border-radius: 8px;">{token}</p>'
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


def send_verification_email(email, code):
    """发送邮箱注册验证码邮件。"""
    import requests

    api_key = os.environ.get('RESEND_API_KEY')
    if not api_key:
        print(f"[EMAIL] RESEND_API_KEY not configured, printing code instead")
        print(f"[EMAIL] Verification code for {email}: {code}")
        return

    try:
        resp = requests.post(
            'https://api.resend.com/emails',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={
                'from': 'OrienScope <noreply@orienscope.app>',
                'to': [email],
                'subject': 'OrienScope - Email Verification Code',
                'html': (
                    '<div style="font-family: sans-serif; max-width: 400px; margin: 0 auto;">'
                    '<h2 style="color: #16162A;">Verify Your Email</h2>'
                    '<p style="color: #666;">Enter the code below to complete your registration:</p>'
                    f'<p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; '
                    f'color: #AB803F; text-align: center; padding: 16px; '
                    f'background: #F7F2E4; border-radius: 8px;">{code}</p>'
                    '<p style="color: #666;">This code expires in <strong style="color: #AB803F;">10 minutes</strong>.</p>'
                    '<p style="color: #999; font-size: 12px;">If you didn\'t try to create an account, '
                    'you can safely ignore this email.</p>'
                    '</div>'
                ),
            },
            timeout=10,
        )

        if resp.status_code == 200:
            print(f"[EMAIL] Verification code sent to {email}")
        else:
            print(f"[EMAIL ERROR] Resend returned {resp.status_code}: {resp.text}")

    except Exception as e:
        print(f"[EMAIL ERROR] Failed to send: {e}")


def send_account_exists_email(email, login_methods):
    """
    发送「你已有账号」提醒邮件。
    login_methods: list，可含 'email'、'apple'、'google'。
    """
    import requests

    api_key = os.environ.get('RESEND_API_KEY')
    if not api_key:
        print(f"[EMAIL] RESEND_API_KEY not configured")
        print(f"[EMAIL] Account exists reminder for {email}, methods: {login_methods}")
        return

    if 'apple' in login_methods:
        method_hint = (
            '<p style="color: #666;">Your account was created with '
            '<strong style="color: #AB803F;">Sign in with Apple</strong>. '
            'Please use the Apple login button to access your account.</p>'
        )
    elif 'google' in login_methods:
        method_hint = (
            '<p style="color: #666;">Your account was created with '
            '<strong style="color: #AB803F;">Sign in with Google</strong>. '
            'Please use the Google login button to access your account.</p>'
        )
    else:
        method_hint = (
            '<p style="color: #666;">Your account uses '
            '<strong style="color: #AB803F;">email and password</strong> login. '
            'You can log in directly. If you\'ve forgotten your password, open the OrienScope app '
            'and tap <strong style="color: #AB803F;">Forgot password</strong> on the login screen.</p>'
        )

    try:
        resp = requests.post(
            'https://api.resend.com/emails',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={
                'from': 'OrienScope <noreply@orienscope.app>',
                'to': [email],
                'subject': 'OrienScope - You Already Have an Account',
                'html': (
                    '<div style="font-family: sans-serif; max-width: 400px; margin: 0 auto;">'
                    '<h2 style="color: #16162A;">This Email is Already Registered</h2>'
                    '<p style="color: #666;">Someone just tried to sign up with this email address. '
                    'If that was you — no new account was created, you already have one.</p>'
                    + method_hint +
                    '<p style="color: #999; font-size: 12px;">If you didn\'t try to sign up, '
                    'you can safely ignore this email.</p>'
                    '</div>'
                ),
            },
            timeout=10,
        )

        if resp.status_code == 200:
            print(f"[EMAIL] Account exists reminder sent to {email}")
        else:
            print(f"[EMAIL ERROR] Resend returned {resp.status_code}: {resp.text}")

    except Exception as e:
        print(f"[EMAIL ERROR] Failed to send: {e}")
