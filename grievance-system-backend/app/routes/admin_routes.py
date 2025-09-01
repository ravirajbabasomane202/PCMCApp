# app/routes/admin_routes.py

from flask import Blueprint, request, jsonify
from ..utils.auth_utils import admin_required
from ..utils.kpi_utils import calculate_resolution_rate, calculate_pending_aging, calculate_sla_compliance
from ..models import AuditLog,MasterConfig, MasterSubjects, MasterAreas, Grievance, User, Role, Announcement, NotificationToken
from ..services.report_service import generate_report,get_staff_performance, get_location_reports
from ..services.notification_service import send_notification
from ..services.report_service import get_citizen_history
from ..services.report_service import escalate_grievance
from ..services.report_service import get_advanced_kpis
from datetime import datetime
from ..schemas import GrievanceSchema, UserSchema, AnnouncementSchema
from flask import Response
from ..schemas import AuditLogSchema, MasterSubjectsSchema, MasterAreasSchema
from .. import db
from ..services.grievance_service import reassign_grievance
from ..services.user_service import add_update_user
admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/dashboard', methods=['GET'])
@admin_required
def dashboard(user):
    kpis = {
        'resolution_rate': calculate_resolution_rate(),
        'pending_aging': calculate_pending_aging(),
        'sla_compliance': calculate_sla_compliance()
    }
    return jsonify(kpis), 200

@admin_bp.route('/subjects', methods=['POST'])
@admin_required
def manage_subjects(user):
    data = request.json
    schema = MasterSubjectsSchema()
    errors = schema.validate(data)
    if errors:
        return jsonify(errors), 400
    subject = MasterSubjects(**data)
    db.session.add(subject)
    db.session.commit()
    return schema.dump(subject), 201

@admin_bp.route('/areas', methods=['POST'])
@admin_required
def manage_areas(user):
    data = request.json
    schema = MasterAreasSchema()
    errors = schema.validate(data)
    if errors:
        return jsonify(errors), 400
    area = MasterAreas(**data)
    db.session.add(area)
    db.session.commit()
    return schema.dump(area), 201

@admin_bp.route('/reassign/<int:id>', methods=['POST'])
@admin_required
def reassign(user, id):
    data = request.json
    result = reassign_grievance(id, data['assigned_to'], user.id)
    return jsonify(result), 200

@admin_bp.route('/audit-logs', methods=['GET', 'OPTIONS'])
@admin_required
def audit_logs(user):
    if request.method == 'OPTIONS':
        return '', 200  # Handle preflight request
    logs = AuditLog.query.all()
    schema = AuditLogSchema(many=True)
    return jsonify(schema.dump(logs)), 200

# Add to existing admin_bp

@admin_bp.route('/kpis/advanced', methods=['GET'])
@admin_required
def advanced_kpis(user):
    return jsonify(get_advanced_kpis()), 200

@admin_bp.route('/reports', methods=['GET'])
@admin_required
def reports(user):
    filter_type = request.args.get('filter', 'all')
    format = request.args.get('format', 'pdf')

    # Your existing function that generates report data
    report_data = generate_report(filter_type, format)

    if format == 'pdf':
        # report_data should be bytes for PDF
        return Response(
            report_data,
            mimetype='application/pdf',
            headers={"Content-Disposition": "attachment; filename=report.pdf"}
        )

    elif format == 'csv':
        # report_data should be a string (CSV text)
        return Response(
            report_data,
            mimetype='text/csv',
            headers={"Content-Disposition": "attachment; filename=report.csv"}
        )

    elif format == 'excel':
        # report_data should be bytes (Excel file content)
        return Response(
            report_data,
            mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            headers={"Content-Disposition": "attachment; filename=report.xlsx"}
        )

    else:
        return {"error": "Invalid format. Supported: pdf, csv, excel"}, 400
@admin_bp.route('/users/<int:id>/history', methods=['GET'])
@admin_required
def citizen_history(user, id):
    history = get_citizen_history(id)
    schema = GrievanceSchema(many=True)
    return jsonify(schema.dump(history)), 200

@admin_bp.route('/grievances/all', methods=['GET'])
@admin_required
def all_grievances(user):
    # Add filters: status=request.args.get('status'), etc.
    grievances = Grievance.query.all()  # Apply filters
    schema = GrievanceSchema(many=True)
    return jsonify(schema.dump(grievances)), 200

@admin_bp.route('/grievances/<int:id>/escalate', methods=['POST'])
@admin_required
def escalate(user, id):
    try:
        data = request.json or {}
        new_assignee_id = data.get('assignee_id')
        result = escalate_grievance(id, user.id, new_assignee_id)
        return jsonify(result), 200 if result["success"] else 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@admin_bp.route('/configs', methods=['GET', 'POST' , 'OPTIONS'])
@admin_required
def manage_configs():
    if request.method == 'POST' :
        data = request.json
        config = MasterConfig(key=data['key'], value=data['value'])
        db.session.add(config)
        db.session.commit()
    configs = MasterConfig.query.all()
    return jsonify([{'key': c.key, 'value': c.value} for c in configs]), 200

# In app/routes/admin_routes.py
@admin_bp.route('/configs/<string:key>', methods=['PUT'])
@admin_required
def update_config( key):
    data = request.json
    config = MasterConfig.query.filter_by(key=key).first()
    if not config:
        return jsonify({"error": "Config not found"}), 404
    config.value = data.get('value')
    config.updated_at = datetime.utcnow()
    db.session.commit()
    return jsonify({'key': config.key, 'value': config.value}), 200

@admin_bp.route('/users/history', methods=['GET'])
@admin_required
def all_users_history(user):
    users = User.query.all()
    result = []
    grievance_schema = GrievanceSchema(many=True)
    for u in users:
        history = get_citizen_history(u.id)
        result.append({
            "user": {
                "id": u.id,
                "name": u.name,
                "email": u.email,
                "role": u.role.value if u.role else None
            },
            "grievances": grievance_schema.dump(history)
        })
    return jsonify(result), 200

@admin_bp.route('/subjects', methods=['GET'])
@admin_required
def list_subjects(user):
    subjects = MasterSubjects.query.all()
    schema = MasterSubjectsSchema(many=True)
    return jsonify(schema.dump(subjects)), 200

@admin_bp.route('/areas', methods=['GET'])
@admin_required
def list_areas(user):
    areas = MasterAreas.query.all()
    schema = MasterAreasSchema(many=True)
    return jsonify(schema.dump(areas)), 200

@admin_bp.route('/users', methods=['GET'])
@admin_required
def list_users(user):
    users = User.query.all()
    schema = UserSchema(many=True, exclude=['password'])  # Exclude sensitive fields
    return jsonify(schema.dump(users)), 200

@admin_bp.route('/users/<int:id>', methods=['PUT'])
@admin_required
def update_user(user, id):
    """Update a specific user by ID."""
    data = request.json
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
        result = add_update_user({**data, 'id': id})
        return jsonify(result), 200
    except ValueError as e:
        return jsonify({"msg": str(e)}), 400
    except Exception as e:
        return jsonify({"msg": "Failed to update user", "error": str(e)}), 500
    
@admin_bp.route('/reports/staff-performance', methods=['GET'])
@admin_required
def staff_performance(user):
    return jsonify(get_staff_performance()), 200

@admin_bp.route('/reports/location', methods=['GET'])
@admin_required
def location_reports(user):
    return jsonify(get_location_reports()), 200

@admin_bp.route('/announcements', methods=['POST'])
@admin_required
def create_announcement(user):
    data = request.json
    schema = AnnouncementSchema()
    errors = schema.validate(data)
    if errors:
        return jsonify(errors), 400
    
    announcement = Announcement(**data)
    db.session.add(announcement)
    db.session.commit()

    # Broadcast via email/FCM
    users = User.query.all()
    for u in users:
        token = NotificationToken.query.filter_by(user_id=u.id).first()
        send_notification(
            to=u.email,
            subject=f"{data['type'].capitalize()} Announcement",
            body=data['message'],
            fcm_token=token.fcm_token if token else None
        )
    return schema.dump(announcement), 201

@admin_bp.route('/announcements', methods=['GET'])
@admin_required
def list_announcements(user):
    announcements = Announcement.query.order_by(Announcement.created_at.desc()).all()
    schema = AnnouncementSchema(many=True)
    return jsonify(schema.dump(announcements)), 200