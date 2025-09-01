# app/routes/public.py (create if it doesn't exist)
from flask import Blueprint, jsonify
from ..models import MasterSubjects, MasterAreas
from .. import db

public_bp = Blueprint('public', __name__)

@public_bp.route('/subjects', methods=['GET'])
def get_subjects():
    subjects = MasterSubjects.query.all()
    return jsonify([{'id': s.id, 'name': s.name, 'description': s.description} for s in subjects])

@public_bp.route('/areas', methods=['GET'])
def get_areas():
    areas = MasterAreas.query.all()
    return jsonify([{'id': a.id, 'name': a.name, 'description': a.description} for a in areas])