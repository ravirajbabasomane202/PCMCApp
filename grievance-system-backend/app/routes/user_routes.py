# app/routes/user_routes.py

from flask import Blueprint, request, jsonify
from ..utils.auth_utils import admin_required, citizen_required, get_jwt_identity
from ..services.user_service import add_update_user
from ..models import User,Role, Grievance
from ..schemas import GrievanceSchema
from ..schemas import UserSchema
from .. import db

user_bp = Blueprint('user', __name__)

@user_bp.route('/', methods=['GET'] , endpoint='user_list')
@admin_required
def get_users(user):
    """Retrieve all users."""
    try:
        users = User.query.all()
        schema = UserSchema(many=True)
        return jsonify(schema.dump(users)), 200
    except Exception as e:
        return jsonify({"msg": "Failed to retrieve users", "error": str(e)}), 500

@user_bp.route('/<int:id>', methods=['GET'])
@admin_required
def get_user2(user, id):
    """Retrieve a specific user by ID."""
    try:
        user = User.query.get(id)
        if not user:
            return jsonify({"msg": "User not found"}), 404
        schema = UserSchema()
        return jsonify(schema.dump(user)), 200
    except Exception as e:
        return jsonify({"msg": "Failed to retrieve user", "error": str(e)}), 500



@user_bp.route('/admin/users', methods=['GET'])
@admin_required
def get_users(user):
    """Retrieve all users."""
    try:
        users = User.query.all()
        schema = UserSchema(many=True, exclude=['password'])
        return jsonify(schema.dump(users)), 200
    except Exception as e:
        return jsonify({"msg": "Failed to retrieve users", "error": str(e)}), 500



# Keep your other routes but update the URLs to match
@user_bp.route('/admin/users', methods=['POST'])
@admin_required
def manage_user(user):
    """Add a new user."""
    data = request.json
    
    # Convert role string to Role enum
    if 'role' in data:
        try:
            role_mapping = {
                'citizen': Role.CITIZEN,
                'member_head': Role.MEMBER_HEAD,
                'field_staff': Role.FIELD_STAFF,
                'admin': Role.ADMIN
            }
            if data['role'] in role_mapping:
                data['role'] = role_mapping[data['role']]
            else:
                return jsonify({"msg": f"Invalid role: {data['role']}"}), 400
        except Exception as e:
            return jsonify({"msg": f"Error processing role: {str(e)}"}), 400
    
    try:
        result = add_update_user(data)
        return jsonify(result), 201
    except ValueError as e:
        return jsonify({"msg": str(e)}), 400
    except Exception as e:
        return jsonify({"msg": "An error occurred", "error": str(e)}), 500

@user_bp.route('/admin/users/<int:id>', methods=['DELETE'])
@admin_required
def delete_user(user, id):
    """Delete a specific user by ID."""
    try:
        user_to_delete = User.query.get(id)
        if not user_to_delete:
            return jsonify({"msg": "User not found"}), 404
        db.session.delete(user_to_delete)
        db.session.commit()
        return jsonify({"msg": "User deleted successfully"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": "Failed to delete user", "error": str(e)}), 500
    
