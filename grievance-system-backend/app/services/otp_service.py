from twilio.rest import Client
import random
from .. import db
from ..models import OtpToken
from datetime import datetime, timedelta, timezone
import os

def send_otp(phone_number):
    client = Client(os.environ.get('TWILIO_SID'), os.environ.get('TWILIO_AUTH_TOKEN'))
    otp = str(random.randint(100000, 999999))
    message = client.messages.create(
        body=f"Your OTP for Nivaran is {otp}. Valid for 5 minutes.",
        from_=os.environ.get('TWILIO_PHONE_NUMBER'),
        to=phone_number
    )
    otp_token = OtpToken(phone_number=phone_number, otp=otp, expires_at=datetime.now(timezone.utc) + timedelta(minutes=5))
    db.session.add(otp_token)
    db.session.commit()
    return {"msg": "OTP sent"}

def verify_otp(phone_number, otp):
    token = OtpToken.query.filter_by(phone_number=phone_number, otp=otp).first()
    if token and token.expires_at > datetime.now(timezone.utc):
        db.session.delete(token)
        db.session.commit()
        return True
    return False