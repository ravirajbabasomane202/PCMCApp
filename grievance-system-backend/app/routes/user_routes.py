# app/routes/user_routes.py

from flask import Blueprint, request, jsonify
from ..utils.auth_utils import admin_required, citizen_required, get_jwt_identity
from ..services.user_service import add_update_user
from ..models import User,Role, Grievance, MasterAreas
from ..schemas import GrievanceSchema
from ..schemas import UserSchema
from .. import db

user_bp = Blueprint('user', __name__)

@user_bp.route('/', methods=['GET'] , endpoint='user_list')
@admin_required
def get_users(user):
    """Retrieve all users."""
    try:
        users = User.query.filter(User.role != Role.ADMIN).all()
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


    

from flask import Blueprint, request, jsonify
from ..services.user_service import add_update_user, delete_user
from ..utils.file_utils import upload_files
from .. import db
from ..models import User
from flask_jwt_extended import jwt_required, get_jwt_identity

user_routes = Blueprint('users', __name__)

@user_routes.route('/users', methods=['POST'])
@jwt_required()
def update_user():
    try:
        data = request.get_json()
        user = add_update_user(data)
        return jsonify(user), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@user_routes.route('/users/<int:user_id>', methods=['DELETE'])
@jwt_required()
def delete_user_route(user_id):
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        if user.role != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        delete_user(user_id)
        return jsonify({'message': 'User deleted successfully'}), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@user_routes.route('/users/profile-picture', methods=['POST'])
@jwt_required()
def upload_profile_picture():
    try:
        current_user_id = get_jwt_identity()
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        file = request.files['file']
        uploaded_paths = upload_files([file], current_user_id)
        if not uploaded_paths:
            return jsonify({'error': 'No valid files uploaded'}), 400
        file_path, _, _ = uploaded_paths[0]
        user = User.query.get(current_user_id)
        user.profile_picture = file_path
        db.session.commit()
        return jsonify({'file_path': file_path}), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@user_routes.route('/areas/<int:area_id>', methods=['GET'])
@jwt_required()
def get_area(area_id):
    try:
        area = db.session.query(MasterAreas).get(area_id)
        if not area:
            return jsonify({'error': 'Area not found'}), 404
        return jsonify({'id': area.id, 'name': area.name, 'description': area.description}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
