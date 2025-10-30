# app/routes/public.py (create if it doesn't exist)
from flask import Blueprint, jsonify
from ..models import MasterSubjects, MasterAreas, Advertisement
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


@public_bp.route('/advertisements', methods=['GET'])
def get_advertisements():
    try:
        ads = Advertisement.query.filter_by(is_active=True).order_by(Advertisement.created_at.desc()).all()
        ads_data = [ad.to_dict() for ad in ads]
        return jsonify({
            'success': True,
            'data': ads_data,
            'count': len(ads_data)
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500