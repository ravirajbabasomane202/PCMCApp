from ..models import User, Role
from ..schemas import UserSchema
from .. import db

def add_update_user(data, user_id=None): 
    schema = UserSchema()
    data.pop("id", None)
    raw_password = data.pop("password", None)

    user_data = schema.load(data, partial=True)
    print(f"Received user data: {user_data}")

    if user_id:  
        user = db.session.get(User, user_id)
        if not user:
            raise ValueError("User not found")
        print(f"Updating user {user_id} with data: {user_data}")
        for key, value in user_data.items():
            setattr(user, key, value)
    else:
        if User.query.filter_by(email=user_data.get('email')).first():
            raise ValueError("Email already exists")
        if User.query.filter_by(phone_number=user_data.get('phone_number')).first():
            raise ValueError("Phone number already exists")
        user = User(**user_data)
        db.session.add(user)
    if raw_password:
        user.set_password(raw_password)

    db.session.commit()
    return schema.dump(user)



def delete_user(user_id):
    user = db.session.get(User, user_id)
    if not user:
        raise ValueError("User not found")
    db.session.delete(user)
    db.session.commit()

def get_users():
    try:
        users = User.query.filter_by(role=Role.FIELD_STAFF).all()
        return [UserSchema().dump(user) for user in users]
    except Exception as e:
        raise Exception(f"Failed to fetch users: {str(e)}")