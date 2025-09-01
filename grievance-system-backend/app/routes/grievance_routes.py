from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..utils.auth_utils import citizen_required, jwt_required_with_role, admin_required, member_head_required, field_staff_required
from ..models import Grievance, GrievanceStatus, Role, User, GrievanceComment, MasterConfig
from ..schemas import GrievanceSchema, GrievanceCommentSchema
from ..services.grievance_service import (
    submit_grievance, get_my_grievances, get_grievance_details,
    add_comment, confirm_closure, get_rejection_reason,
    get_new_grievances, accept_grievance, reject_grievance,
    get_assigned_grievances, update_status, upload_workproof,
    escalate_grievance
)
from ..services.notification_service import send_notification
from .. import db
from ..services.grievance_service import log_audit
from datetime import datetime

grievance_bp = Blueprint('grievances', __name__)

@grievance_bp.route('/', methods=['POST'])
@citizen_required
def create_grievance(user):
    try:
        data = request.form.to_dict()
        files = request.files.getlist('files')
        
        # Set default priority if not provided
        if 'priority' not in data or not data['priority']:
            default_priority = MasterConfig.query.filter_by(key='DEFAULT_PRIORITY').first()
            data['priority'] = default_priority.value if default_priority else 'medium'

        # Ensure lat/lng passed as float
        if "latitude" in data and data["latitude"]:
            data["latitude"] = float(data["latitude"])
        if "longitude" in data and data["longitude"]:
            data["longitude"] = float(data["longitude"])

        result = submit_grievance(user.id, data, files)
        log_audit(f"Grievance created by user {user.id}", user.id, result.get('id'))
        return jsonify(result), 201
    except Exception as e:
        current_app.logger.error(f"Error creating grievance: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/mine', methods=['GET'])
@citizen_required
def my_grievances(user):
    try:
        result = get_my_grievances(user.id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching grievances for user {user.id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>', methods=['GET'])
@jwt_required_with_role([Role.CITIZEN, Role.MEMBER_HEAD, Role.FIELD_STAFF, Role.ADMIN])
def get_grievance(user, id):
    current_app.logger.info(f"Fetching grievance ID {id} for user ID {user.id} with role {user.role}")
    grievance = db.session.get(Grievance, id)
    if not grievance:
        current_app.logger.error(f"Grievance ID {id} not found")
        return jsonify({"msg": "Grievance not found"}), 404
    schema = GrievanceSchema()
    current_app.logger.info(f"Grievance found: {schema.dump(grievance)}")
    return jsonify(schema.dump(grievance)), 200

@grievance_bp.route('/<int:id>/comments', methods=['POST'])
@citizen_required
def add_grievance_comment(user, id):
    try:
        data = request.get_json()
        comment_text = data.get('comment_text')
        if not comment_text:
            return jsonify({"msg": "Comment text is required"}), 400
        result = add_comment(id, user.id, comment_text)
        log_audit(f"Comment added to grievance {id}", user.id, id)
        return jsonify(result), 201
    except Exception as e:
        current_app.logger.error(f"Error adding comment to grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/close', methods=['POST'])
@citizen_required
def close_grievance(user, id):
    try:
        result = confirm_closure(id, user.id)
        log_audit(f"Grievance {id} closed by user {user.id}", user.id, id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error closing grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/rejection', methods=['GET'])
@citizen_required
def rejection_reason(user, id):
    try:
        reason = get_rejection_reason(id, user.id)
        return jsonify({"rejection_reason": reason}), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching rejection reason for grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/new', methods=['GET'])
@member_head_required
def new_grievances(user):
    try:
        result = get_new_grievances(user.department_id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching new grievances for department {user.department_id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/accept', methods=['POST'])
@member_head_required
def accept(user, id):
    try:
        data = request.get_json()
        result = accept_grievance(id, user.id, data)
        log_audit(f"Grievance {id} accepted by user {user.id}", user.id, id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error accepting grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/reject', methods=['POST'])
@member_head_required
def reject(user, id):
    try:
        data = request.get_json()
        reason = data.get('reason')
        if not reason:
            return jsonify({"msg": "Rejection reason is required"}), 400
        result = reject_grievance(id, user.id, reason)
        log_audit(f"Grievance {id} rejected by user {user.id}", user.id, id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error rejecting grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/assigned', methods=['GET'])
@field_staff_required
def assigned_grievances(user):
    try:
        result = get_assigned_grievances(user.id)
        return jsonify(result), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching assigned grievances for user {user.id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/status', methods=['PUT'])
@field_staff_required
def update_grievance_status(user, id):
    data = request.json
    new_status = data.get('status')
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance:
            return jsonify({"error": "Grievance not found"}), 404
        if grievance.assigned_to != user.id:
            return jsonify({"error": "Not authorized to update this grievance"}), 403
        old_status = grievance.status
        grievance.status = GrievanceStatus[new_status.upper()]
        if grievance.status == GrievanceStatus.RESOLVED:
            grievance.resolved_at = datetime.utcnow()
        db.session.commit()
        log_audit(f'Status updated from {old_status} to {grievance.status}', user.id, id)
        send_notification(
            grievance.citizen.email,
            'Status Updated',
            f'Your grievance #{id} status is now {new_status}.'
        )
        schema = GrievanceSchema()
        return jsonify(schema.dump(grievance)), 200
    except ValueError as e:
        current_app.logger.error(f"Invalid status value for grievance {id}: {str(e)}")
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Failed to update status for grievance {id}: {str(e)}")
        return jsonify({"error": f"Failed to update status: {str(e)}"}), 500

@grievance_bp.route('/<int:id>/workproof', methods=['POST'])
@field_staff_required
def upload_grievance_workproof(user, id):
    try:
        file = request.files.get('file')
        if not file:
            return jsonify({"msg": "File is required"}), 400
        data = request.form
        result = upload_workproof(id, user.id, file, data.get('notes'))
        log_audit(f"Workproof uploaded for grievance {id}", user.id, id)
        return jsonify(result), 201
    except Exception as e:
        current_app.logger.error(f"Error uploading workproof for grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/feedback', methods=['POST'])
@citizen_required
def submit_feedback(user, id):
    try:
        grievance = Grievance.query.get_or_404(id)
        if grievance.citizen_id != user.id or grievance.status != GrievanceStatus.RESOLVED:
            return jsonify({"msg": "Invalid operation: Grievance must be resolved and owned by user"}), 400
        data = request.get_json()
        rating = data.get('rating')
        if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
            return jsonify({"msg": "Valid rating (1-5) is required"}), 400
        grievance.feedback_rating = rating
        grievance.feedback_text = data.get('feedback_text')
        db.session.commit()
        log_audit(f"Feedback submitted for grievance {id}", user.id, id)
        return jsonify({"msg": "Feedback submitted successfully"}), 200
    except Exception as e:
        current_app.logger.error(f"Error submitting feedback for grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/admin/<int:id>', methods=['GET'])
@admin_required
def get_grievance_admin(user, id):
    try:
        grievance = Grievance.query.get_or_404(id)
        schema = GrievanceSchema()
        return jsonify(schema.dump(grievance)), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching grievance {id} for admin: {str(e)}")
        return jsonify({"msg": str(e)}), 404

@grievance_bp.route('/admin/grievances/all', methods=['GET'])
@admin_required
def get_all_grievances(user):
    try:
        grievances = Grievance.query.all()
        schema = GrievanceSchema(many=True)
        log_audit(f"Admin {user.id} fetched all grievances", user.id, None)
        return jsonify(schema.dump(grievances)), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching all grievances for admin {user.id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/reassign', methods=['PUT'])
@admin_required
def reassign_grievance(user, id):
    try:
        data = request.get_json()
        assignee_id = data.get('assignee_id')
        if not assignee_id:
            return jsonify({"msg": "Assignee ID is required"}), 400
        grievance = Grievance.query.get_or_404(id)
        assignee = User.query.get_or_404(assignee_id)
        if assignee.role != Role.FIELD_STAFF:
            return jsonify({"msg": "Assignee must have field staff role"}), 400
        grievance.assigned_to = assignee_id
        db.session.commit()
        log_audit(f"Grievance {id} reassigned to user {assignee_id}", user.id, id)
        return jsonify({"msg": "Grievance reassigned successfully"}), 200
    except Exception as e:
        current_app.logger.error(f"Error reassigning grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/<int:id>/escalate', methods=['POST'])
@admin_required
def escalate_grievance(user, id):
    try:
        result = escalate_grievance(id, user.id)
        log_audit(f"Grievance {id} escalated by user {user.id}", user.id, id)
        return jsonify(result), 200 if result['success'] else 404
    except Exception as e:
        current_app.logger.error(f"Error escalating grievance {id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400

@grievance_bp.route('/search/<string:complaint_id>', methods=['GET'])
@jwt_required_with_role([Role.CITIZEN, Role.MEMBER_HEAD, Role.FIELD_STAFF, Role.ADMIN])
def search_grievance_by_complaint_id(user, complaint_id):
    try:
        grievance = Grievance.query.filter_by(complaint_id=complaint_id).first()
        if not grievance:
            current_app.logger.error(f"Grievance with complaint ID {complaint_id} not found")
            return jsonify({"msg": "Grievance not found"}), 404
        schema = GrievanceSchema()
        return jsonify(schema.dump(grievance)), 200
    except Exception as e:
        current_app.logger.error(f"Error searching grievance by complaint ID {complaint_id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400
    

@grievance_bp.route('/track', methods=['GET'])
@jwt_required_with_role([Role.CITIZEN])
def track_grievances(user):
    try:
        current_app.logger.info(f"Track grievances called for user ID {user.id}")
        grievances = Grievance.query.filter_by(citizen_id=user.id).all()
        schema = GrievanceSchema(many=True)
        
        grievances_data = schema.dump(grievances)
        for grievance in grievances_data:
            # Ensure no null values in critical fields
            grievance['id'] = grievance.get('id') or 0
            grievance['citizen_id'] = grievance.get('citizen_id') or user.id
            grievance['subject_id'] = grievance.get('subject_id') or 0
            grievance['area_id'] = grievance.get('area_id') or 0
            grievance['title'] = grievance.get('title') or 'Untitled Grievance'
            grievance['description'] = grievance.get('description') or 'No description provided'
            grievance['complaint_id'] = grievance.get('complaint_id') or str(uuid.uuid4())[:8]
            grievance['citizen'] = grievance.get('citizen') or {'id': 0, 'name': 'Unknown User'}
            grievance['assignee'] = grievance.get('assignee') or {'id': 0, 'name': 'Unassigned'}
            if grievance.get('assigned_to') is None:
                grievance['assigned_to'] = 0
        
        return jsonify(grievances_data), 200
    except Exception as e:
        current_app.logger.error(f"Error tracking grievances for user {user.id}: {str(e)}")
        return jsonify({"msg": str(e)}), 400