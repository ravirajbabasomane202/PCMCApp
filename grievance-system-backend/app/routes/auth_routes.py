# app/routes/auth_routes.py

# app/routes/auth_routes.py

from flask import Blueprint, request, jsonify, redirect, url_for, session, current_app
from flask_jwt_extended import create_access_token, create_refresh_token, get_jwt_identity, jwt_required
from requests_oauthlib.oauth2_session import OAuth2Session
import requests
from ..models import User, Role
from .. import db
from ..schemas import UserSchema
from werkzeug.security import check_password_hash
from ..services.otp_service import send_otp, verify_otp
from ..utils.file_utils import allowed_file
from werkzeug.utils import secure_filename
import os
from sqlalchemy.exc import IntegrityError
auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    schema = UserSchema()
    try:
        user_data = schema.load(data)
    except Exception as e:
        return jsonify({"msg": "Invalid input", "errors": str(e)}), 400

    if User.query.filter_by(email=user_data['email']).first():
        return jsonify({"msg": "Email already exists"}), 400

    user = User(
        name=user_data['name'],
        email=user_data['email'],
        role=Role.CITIZEN,  # Default to CITIZEN for registration
    )
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id))
    return jsonify({"access_token": access_token}), 201

@auth_bp.route('/login', methods=['POST'])
def password_login():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"msg": "Invalid email or password"}), 401

    access_token = create_access_token(identity=str(user.id))
    return jsonify({"access_token": access_token}), 200

# app/routes/auth_routes.py
@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)
    new_refresh_token = create_refresh_token(identity=current_user_id)
    return jsonify({
        "access_token": new_access_token,
        "refresh_token": new_refresh_token
    }), 200



@auth_bp.route('/google/login')
def google_login():
    """
    Step 1: Redirects the user to Google's authentication page.
    """
    if not current_app.config.get('GOOGLE_CLIENT_ID') or not current_app.config.get('GOOGLE_CLIENT_SECRET'):
        return jsonify({"msg": "Google OAuth is not configured on the server."}), 500

    try:
        google_discovery_doc = requests.get(current_app.config['GOOGLE_DISCOVERY_URL']).json()
        authorization_endpoint = google_discovery_doc.get("authorization_endpoint")
    except requests.exceptions.RequestException as e:
        return jsonify({"msg": "Could not connect to Google's discovery service.", "error": str(e)}), 500

    oauth_session = OAuth2Session(
        client_id=current_app.config['GOOGLE_CLIENT_ID'],
        redirect_uri=url_for('auth.google_callback', _external=True),
        scope=["openid", "email", "profile"]
    )

    authorization_url, state = oauth_session.authorization_url(authorization_endpoint)
    session['oauth_state'] = state
    return redirect(authorization_url)

@auth_bp.route('/google/callback')
def google_callback():
    if not current_app.config.get('GOOGLE_CLIENT_ID') or not current_app.config.get('GOOGLE_CLIENT_SECRET'):
        return jsonify({"msg": "Google OAuth is not configured on the server."}), 500

    try:
        google_discovery_doc = requests.get(current_app.config['GOOGLE_DISCOVERY_URL']).json()
        token_endpoint = google_discovery_doc.get("token_endpoint")
        userinfo_endpoint = google_discovery_doc.get("userinfo_endpoint")
    except requests.exceptions.RequestException as e:
        return jsonify({"msg": "Could not connect to Google's discovery service.", "error": str(e)}), 500

    oauth_session = OAuth2Session(
        client_id=current_app.config['GOOGLE_CLIENT_ID'],
        state=session.get('oauth_state'),
        redirect_uri=url_for('auth.google_callback', _external=True)
    )

    try:
        token = oauth_session.fetch_token(
            token_endpoint,
            client_secret=current_app.config['GOOGLE_CLIENT_SECRET'],
            authorization_response=request.url
        )
    except Exception as e:
        return jsonify({"msg": "Failed to fetch token from Google.", "error": str(e)}), 400

    user_info = oauth_session.get(userinfo_endpoint).json()
    email, name = user_info.get('email'), user_info.get('name')

    user = User.query.filter_by(email=email).first()
    if not user:
        user = User(name=name, email=email, role=Role.CITIZEN)
        db.session.add(user)
        db.session.commit()

    access_token = create_access_token(identity=str(user.id))
    frontend_callback_url = f"http://localhost:5500/login/callback?access_token={access_token}"
    return redirect(frontend_callback_url)

@auth_bp.route('/logout', methods=['POST'])
def logout():
    return jsonify({"msg": "Logout successful"}), 200

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))   # convert back to int
    if not user:
        return jsonify({"msg": "User not found"}), 404
    schema = UserSchema()
    return jsonify(schema.dump(user)), 200


@auth_bp.route('/me', methods=['PUT'])
@jwt_required()
def update_current_user():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"msg": "User not found"}), 404

    # Handle form data (text fields)
    data = request.form
    if 'name' in data:
        user.name = data['name']
    if 'email' in data:
        if User.query.filter(User.email == data['email'], User.id != current_user_id).first():
            return jsonify({"msg": "Email already exists"}), 400
        user.email = data['email']
    if 'password' in data and data['password']:
        user.set_password(data['password'])
    if 'address' in data:
        user.address = data['address']

    # Handle file upload for profile_picture
    if 'profile_picture' in request.files:
        file = request.files['profile_picture']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            user_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], f'user_{user.id}')
            os.makedirs(user_dir, exist_ok=True)
            file_path = os.path.join(user_dir, filename)
            file.save(file_path)
            # Store relative path for easy serving (e.g., via /uploads/<path>)
            user.profile_picture = f'user_{user.id}/{filename}'
        else:
            return jsonify({"msg": "Invalid file type"}), 400

    try:
        db.session.commit()
        return jsonify(UserSchema().dump(user))
    except IntegrityError:
        db.session.rollback()
        return jsonify({"msg": "Update failed due to duplicate data"}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": f"Update failed: {str(e)}"}), 500






@auth_bp.route('/otp/send', methods=['POST'])
def send_otp():
    data = request.json
    phone_number = data.get('phone_number')
    if not phone_number:
        return jsonify({"msg": "Phone number required"}), 400
    return jsonify(send_otp(phone_number)), 200

@auth_bp.route('/otp/verify', methods=['POST'])
def verify_otp_route():
    data = request.json
    phone_number = data.get('phone_number')
    otp = data.get('otp')

    if verify_otp(phone_number, otp):
        user = User.query.filter_by(phone_number=phone_number).first()
        if not user:
            # ✅ Auto-register new user if first OTP login
            user = User(phone_number=phone_number, role=Role.CITIZEN, name="Guest User")
            db.session.add(user)
            db.session.commit()

        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        return jsonify({"access_token": access_token, "refresh_token": refresh_token}), 200
    
    return jsonify({"msg": "Invalid or expired OTP"}), 401

@auth_bp.route('/guest-login', methods=['POST'])
def guest_login():
    """
    Allows users to login as Guest with limited access (read-only).
    """
    guest_user = User(name="Guest User", role=Role.CITIZEN)
    db.session.add(guest_user)
    db.session.commit()

    access_token = create_access_token(identity=str(guest_user.id))
    refresh_token = create_refresh_token(identity=str(guest_user.id))
    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "msg": "Logged in as Guest"
    }), 200
