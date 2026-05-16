# shared/validators.py
# -*- coding: utf-8 -*-
"""
输入校验模块 — 统一校验逻辑，避免每个 action 重复写
"""
import re

_EMAIL_RE = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')


def validate_required(body, fields):
    """
    检查必填字段是否存在且非空。

    Args:
        body: 请求体 dict
        fields: 必填字段名列表

    Returns:
        缺失的字段名（str），全部存在则返回 None
    """
    for f in fields:
        val = body.get(f)
        if val is None or (isinstance(val, str) and not val.strip()):
            return f
    return None


def validate_email(email):
    """基础邮箱格式校验，返回 True/False"""
    if not email:
        return False
    return bool(_EMAIL_RE.match(email.strip()))


def validate_password(password):
    """
    密码强度校验。

    Returns:
        错误信息（str），通过则返回 None
    """
    if not password:
        return 'Password is required'
    if len(password) < 8:
        return 'Password must be at least 8 characters'
    return None
