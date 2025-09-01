from flask import Blueprint, request, jsonify
from ..services.notification_service import register_fcm_token
from flask_jwt_extended import jwt_required


notification_bp = Blueprint('notification', __name__)

@notification_bp.route('/register', methods=['POST'])
@jwt_required
def register_notification_token(user):
    data = request.json
    fcm_token = data.get('fcm_token')
    if not fcm_token:
        return jsonify({"msg": "FCM token required"}), 400
    register_fcm_token(user.id, fcm_token)
    return jsonify({"msg": "FCM token registered"}), 200