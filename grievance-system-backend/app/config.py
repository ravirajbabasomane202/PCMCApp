import os
from datetime import timedelta
from dotenv import load_dotenv
basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, '..', '.env'))

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a-hard-to-guess-string-for-dev'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or f'sqlite:///{os.path.join(basedir, "..", "app.db")}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'another-super-secret-jwt-key-for-dev'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=60)
    UPLOAD_FOLDER = os.path.join(basedir, '..', 'uploads')
    ALLOWED_EXTENSIONS = {'pdf', 'txt', 'jpg', 'jpeg', 'png', 'mp4', 'mov'}
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024 
    SECURITY_PASSWORD_SALT = os.environ.get('SECURITY_PASSWORD_SALT') or 'a-salt-for-hashing'
    SECURITY_TRACKABLE = True 
    SECURITY_REGISTERABLE = False  
    SECURITY_SEND_REGISTER_EMAIL = False
    SECURITY_LOGIN_URL = '/admin/login'  
    SECURITY_LOGOUT_URL = '/admin/logout'
    SECURITY_POST_LOGIN_VIEW = '/admin/' 
    SECURITY_POST_LOGOUT_VIEW = '/auth/login' 
    SECURITY_UNAUTHORIZED_VIEW = '/auth/unauthorized' 
    GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
    GOOGLE_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')
    GOOGLE_DISCOVERY_URL = "https://accounts.google.com/.well-known/openid-configuration"

