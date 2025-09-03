# app/routes.py (or in blueprints)
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models import User, UserPreference
from .. import db
from ..utils.auth_utils import jwt_required_with_role  # If roles are needed, but since common, no role check

settings_bp = Blueprint('settings', __name__)

@settings_bp.route('/', methods=['GET'])
@jwt_required()
def get_settings():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({"msg": "User not found"}), 404
    
    pref = UserPreference.query.filter_by(user_id=user_id).first()
    return jsonify({
        "name": user.name,
        "email": user.email,
        "notifications_enabled": pref.notifications_enabled if pref else True,
        "language": pref.language if pref else 'en'
    }), 200

@settings_bp.route('/', methods=['POST'])
@jwt_required()
def save_settings():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({"msg": "User not found"}), 404
    
    data = request.json
    if 'name' in data:
        user.name = data['name']
    if 'email' in data:
        user.email = data['email']
    if 'password' in data and data['password']:
        user.set_password(data['password'])

    
    pref = UserPreference.query.filter_by(user_id=user_id).first()
    if not pref:
        pref = UserPreference(user_id=user_id)
        db.session.add(pref)
    
    if 'notifications_enabled' in data:
        pref.notifications_enabled = data['notifications_enabled']
    if 'language' in data:
        pref.language = data['language']
    
    db.session.commit()
    return jsonify({"msg": "Settings saved"}), 200

@settings_bp.route('/user', methods=['GET'])
@jwt_required()
def get_user():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({"msg": "User not found"}), 404
    
    return jsonify({
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role.value if user.role else None
    }), 200
