# app/utils/auth_utils.py

from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from flask import jsonify
from ..models import User, Role
from .. import db
def jwt_required_with_role(roles):
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            verify_jwt_in_request()
            current_user_id = get_jwt_identity()
            print(f"JWT Identity: {current_user_id}")
            user = db.session.get(User, current_user_id)
            if not user:
                print("User not found for ID:", current_user_id)
                return jsonify({"msg": "User not found"}), 404
            if user.role not in roles:
                print(f"Access forbidden: User role {user.role} not in {roles}")
                return jsonify({"msg": "Access forbidden"}), 403
            return fn(user, *args, **kwargs)
        return decorator
    return wrapper

# Role decorators
def citizen_required(fn):
    return jwt_required_with_role([Role.CITIZEN])(fn)

def member_head_required(fn):
    return jwt_required_with_role([Role.MEMBER_HEAD])(fn)

def field_staff_required(fn):
    return jwt_required_with_role([Role.FIELD_STAFF])(fn)

def admin_required(fn):
    return jwt_required_with_role([Role.ADMIN])(fn)