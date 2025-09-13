# app/config.py

import os
from datetime import timedelta
from dotenv import load_dotenv

# The base directory of the application
basedir = os.path.abspath(os.path.dirname(__file__))

# Load environment variables from a .env file at the project root
# This is useful for development.
# Create a .env file in the root directory and add your environment-specific variables there.
# See .env.example for a template.
load_dotenv(os.path.join(basedir, '..', '.env'))

class Config:
    """
    Base configuration class.
    Contains default configuration settings and settings loaded from environment variables.
    """
    # --- General Flask Settings ---
    # A secret key is required for session management, flash messages, and other security features.
    # In production, this MUST be a long, random, and secret string.
    # You can generate one using: python -c 'import secrets; print(secrets.token_hex(16))'
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a-hard-to-guess-string-for-dev'

    # --- Database Settings ---
    # Defines the database connection URI.
    # The default is an SQLite database named 'app.db' in the project root, which is good for development.
    # For production, you should use a more robust database like PostgreSQL or MySQL.
    # Example for PostgreSQL: DATABASE_URL="postgresql://user:password@host:port/dbname"
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or f'sqlite:///{os.path.join(basedir, "..", "app.db")}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # --- JWT (JSON Web Token) Settings ---
    # Secret key for signing JWTs. This should also be a strong, secret value in production.
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'another-super-secret-jwt-key-for-dev'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=60)

    # --- File Upload Settings ---
    UPLOAD_FOLDER = os.path.join(basedir, '..', 'uploads')
    ALLOWED_EXTENSIONS = {'pdf', 'txt', 'jpg', 'jpeg', 'png', 'mp4', 'mov'}
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 16MB max file size


    # Security Settings (for Flask-Security-Too)
    SECURITY_PASSWORD_SALT = os.environ.get('SECURITY_PASSWORD_SALT') or 'a-salt-for-hashing'
    SECURITY_TRACKABLE = True  # Track logins
    SECURITY_REGISTERABLE = False  # Disable public registration (admins only)
    SECURITY_SEND_REGISTER_EMAIL = False
    SECURITY_LOGIN_URL = '/admin/login'  # Custom login for admin
    SECURITY_LOGOUT_URL = '/admin/logout'
    SECURITY_POST_LOGIN_VIEW = '/admin/'  # Redirect to admin after login
    SECURITY_POST_LOGOUT_VIEW = '/auth/login'  # Back to main login
    SECURITY_UNAUTHORIZED_VIEW = '/auth/unauthorized'  # Handle forbidden access


    # --- Email Settings ---
    # To send emails, you need to configure an SMTP server.
    # For development, you can use a service like Mailtrap.io or a local debugging server.
    # The settings below are configured to use environment variables, with Google's SMTP as the default.
    # For this to work, you must enable 2-Step Verification on your Google account and generate an "App Password".
    # If you don't set these in your .env, email sending will likely fail.
    # MAIL_SERVER = os.environ.get('MAIL_SERVER') or 'smtp.gmail.com'
    # MAIL_PORT = int(os.environ.get('MAIL_PORT') or 587)
    # MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'True').lower() in ('true', '1', 't')
    # MAIL_USE_SSL = os.environ.get('MAIL_USE_SSL', 'False').lower() in ('true', '1', 't')
    # MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    # MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    # MAIL_DEFAULT_SENDER = os.environ.get('MAIL_DEFAULT_SENDER') or ('Grievance System', os.environ.get('MAIL_USERNAME'))

    # --- Google OAuth Settings ---
    # These are required for Google Sign-In to work.
    # You must create a project in the Google Cloud Console (https://console.cloud.google.com/)
    # and get "OAuth 2.0 Client ID" credentials.
    # If these are not set, the Google login feature should be disabled or handled gracefully in the code.
    GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
    GOOGLE_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')
    GOOGLE_DISCOVERY_URL = "https://accounts.google.com/.well-known/openid-configuration"

