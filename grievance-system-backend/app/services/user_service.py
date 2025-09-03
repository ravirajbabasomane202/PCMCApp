# app/services/user_service.py

from ..models import User, Role
from ..schemas import UserSchema
from .. import db

def add_update_user(data):
    schema = UserSchema()
    user_data = schema.load(data, partial=True)
    if 'id' in data and data['id']:
        user = db.session.get(User, data['id'])
        if not user:
            raise ValueError("User not found")
        for key, value in user_data.items():
            setattr(user, key, value)
    else:
        if User.query.filter_by(email=user_data.get('email')).first():
            raise ValueError("Email already exists")
        if User.query.filter_by(phone_number=user_data.get('phone_number')).first():
            raise ValueError("Phone number already exists")
        user = User(**user_data)
        db.session.add(user)
    if 'password' in data:
        user.set_password(data['password'])
    db.session.commit()
    return schema.dump(user)

def delete_user(user_id):
    user = db.session.get(User, user_id)
    if not user:
        raise ValueError("User not found")
    db.session.delete(user)
    db.session.commit()

def get_users():
    """
    Fetch all users, particularly those suitable for grievance assignment (e.g., FIELD_STAFF).
    """
    try:
        users = User.query.filter_by(role=Role.FIELD_STAFF).all()
        return [UserSchema().dump(user) for user in users]
    except Exception as e:
        raise Exception(f"Failed to fetch users: {str(e)}")