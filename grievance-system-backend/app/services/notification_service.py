from flask_mail import Message
from .. import mail
import firebase_admin
from firebase_admin import messaging
from ..models import NotificationToken
from .. import db

def initialize_fcm():
    if not firebase_admin._apps:
        cred = firebase_admin.credentials.Certificate(os.environ.get('FIREBASE_CREDENTIALS'))
        firebase_admin.initialize_app(cred)

def send_notification(to, subject, body, fcm_token=None):
    msg = Message(subject, recipients=[to])
    msg.body = body
    mail.send(msg)

    if fcm_token:
        initialize_fcm()
        message = messaging.Message(
            notification=messaging.Notification(title=subject, body=body),
            token=fcm_token
        )
        messaging.send(message)

def register_fcm_token(user_id, fcm_token):
    token = NotificationToken(user_id=user_id, fcm_token=fcm_token)
    db.session.add(token)
    db.session.commit()