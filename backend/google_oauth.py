"""
Google OAuth 2.0 Integration - Native Implementation
No external services required, direct Google API integration
"""

import os
import json
from typing import Optional
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from fastapi import HTTPException
from datetime import datetime, timezone, timedelta
import secrets

# Google OAuth Configuration
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID', '')
GOOGLE_CLIENT_SECRET = os.getenv('GOOGLE_CLIENT_SECRET', '')
GOOGLE_REDIRECT_URI = os.getenv('GOOGLE_REDIRECT_URI', 'http://localhost:3000/auth/callback')

# OAuth URLs
GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"

def get_google_auth_url(state: str) -> str:
    """
    Genera la URL de autorización de Google
    
    Args:
        state: Token único para prevenir CSRF
        
    Returns:
        URL completa para redirigir al usuario a Google
    """
    params = {
        "client_id": GOOGLE_CLIENT_ID,
        "redirect_uri": GOOGLE_REDIRECT_URI,
        "response_type": "code",
        "scope": "openid email profile",
        "access_type": "offline",
        "state": state,
        "prompt": "consent"
    }
    
    query_string = "&".join([f"{k}={v}" for k, v in params.items()])
    return f"{GOOGLE_AUTH_URL}?{query_string}"

def generate_state_token() -> str:
    """Genera un token de estado seguro para prevenir CSRF"""
    return secrets.token_urlsafe(32)

async def exchange_code_for_token(code: str) -> dict:
    """
    Intercambia el código de autorización por tokens de acceso
    
    Args:
        code: Código de autorización de Google
        
    Returns:
        Dict con access_token, id_token y refresh_token
    """
    import requests
    
    data = {
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": GOOGLE_REDIRECT_URI
    }
    
    response = requests.post(GOOGLE_TOKEN_URL, data=data)
    
    if response.status_code != 200:
        raise HTTPException(
            status_code=400,
            detail=f"Error al intercambiar código: {response.text}"
        )
    
    return response.json()

async def verify_google_token(id_token_str: str) -> dict:
    """
    Verifica el ID token de Google y extrae la información del usuario
    
    Args:
        id_token_str: Token JWT de Google
        
    Returns:
        Dict con información del usuario (email, name, picture)
    """
    try:
        # Verificar el token con Google
        idinfo = id_token.verify_oauth2_token(
            id_token_str,
            google_requests.Request(),
            GOOGLE_CLIENT_ID
        )
        
        # Verificar el issuer
        if idinfo['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
            raise ValueError('Token inválido')
        
        return {
            "email": idinfo.get("email"),
            "name": idinfo.get("name", ""),
            "picture": idinfo.get("picture"),
            "email_verified": idinfo.get("email_verified", False),
            "google_id": idinfo.get("sub")
        }
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Token de Google inválido: {str(e)}"
        )

async def get_user_info_from_access_token(access_token: str) -> dict:
    """
    Obtiene información del usuario usando el access token
    
    Args:
        access_token: Token de acceso de Google
        
    Returns:
        Dict con información del usuario
    """
    import requests
    
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(GOOGLE_USERINFO_URL, headers=headers)
    
    if response.status_code != 200:
        raise HTTPException(
            status_code=400,
            detail="No se pudo obtener información del usuario"
        )
    
    return response.json()

def split_name(full_name: str) -> tuple:
    """
    Divide el nombre completo en nombre y apellido
    
    Args:
        full_name: Nombre completo
        
    Returns:
        Tuple (nombre, apellido)
    """
    parts = full_name.strip().split()
    if len(parts) == 0:
        return ("Usuario", "Google")
    elif len(parts) == 1:
        return (parts[0], "")
    else:
        return (parts[0], " ".join(parts[1:]))

def is_google_oauth_configured() -> bool:
    """Verifica si Google OAuth está configurado"""
    return bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET)
