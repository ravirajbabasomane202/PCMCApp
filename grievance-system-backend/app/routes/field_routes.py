# app/routes/user_routes.py
from flask import Blueprint, request, jsonify
from app.models import User, Role
from app import db

fieldStaff = Blueprint("fieldStaff", __name__, url_prefix="/fieldStaff")

@fieldStaff.route("/fieldStaff", methods=["GET"])
def get_users():
    role = request.args.get("role")
    query = User.query

    if role:
        try:
            role_enum = Role(role)  # validate role string
            query = query.filter_by(role=role_enum)
        except ValueError:
            return jsonify({"error": "Invalid role"}), 400

    users = query.all()
    return jsonify([
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "phone_number": u.phone_number,
            "role": u.role.value,
        }
        for u in users
    ])
