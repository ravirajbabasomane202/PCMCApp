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
from flask_cors import cross_origin
from flask_jwt_extended import jwt_required
import logging
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

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

@admin_bp.route('/users/<int:id>', methods=['DELETE'])
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





@admin_bp.route('/subjects', methods=['POST'])
@admin_required
def manage_subjects(user):
    data = request.json
    print(f"Received data: {data}")
    schema = MasterSubjectsSchema()
    errors = schema.validate(data)
    if errors:
        print(f"Validation errors: {errors}")
        return jsonify(errors), 400
    try:
        subject = MasterSubjects(**data)
        db.session.add(subject)
        db.session.commit()
        print(f"Subject {subject.name} added successfully")
        return schema.dump(subject), 201
    except Exception as e:
        db.session.rollback()
        print(f"Database error: {e}")
        return jsonify({"error": "Failed to save subject"}), 500


@admin_bp.route('/subjects/<int:id>', methods=['PUT'])
@admin_required
def update_subject(user, id):
    data = request.json
    print(f"Update request for subject {id}: {data}")

    schema = MasterSubjectsSchema()
    errors = schema.validate(data, partial=True)  # allow partial updates
    if errors:
        return jsonify(errors), 400

    try:
        subject = db.session.get(MasterSubjects, id)
        if not subject:
            return jsonify({"error": "Subject not found"}), 404

        # Update fields
        subject.name = data.get("name", subject.name)
        subject.description = data.get("description", subject.description)

        db.session.commit()
        print(f"Subject {subject.id} updated successfully")
        return schema.dump(subject), 200
    except Exception as e:
        db.session.rollback()
        print(f"Database error: {e}")
        return jsonify({"error": "Failed to update subject"}), 500

@admin_bp.route('/subjects/<int:id>', methods=['DELETE'])
@admin_required
def delete_subject(user, id):
    """Delete a specific subject by ID."""
    try:
        subject_to_delete = MasterSubjects.query.get(id)
        if not subject_to_delete:
            return jsonify({"msg": "Subject not found"}), 404
        
        db.session.delete(subject_to_delete)
        db.session.commit()
        return jsonify({"msg": "Subject deleted successfully"}), 200
    except Exception as e:
        db.session.rollback()
        # Check for foreign key constraint error
        error_info = str(e).lower()
        if 'foreign key constraint' in error_info or 'violates foreign key' in error_info:
            return jsonify({"msg": "Cannot delete subject. It is in use by existing grievances."}), 409
        
        return jsonify({"msg": "Failed to delete subject", "error": str(e)}), 500


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

@admin_bp.route('/areas/<int:id>', methods=['PUT'])
@admin_required
def update_area(user, id):
    data = request.json
    schema = MasterAreasSchema(partial=True)
    errors = schema.validate(data)
    if errors:
        return jsonify(errors), 400
    
    area = db.session.get(MasterAreas, id)
    if not area:
        return jsonify({"error": "Area not found"}), 404
    
    area.name = data.get('name', area.name)
    area.description = data.get('description', area.description)
    db.session.commit()
    
    return MasterAreasSchema().dump(area), 200

@admin_bp.route('/areas/<int:id>', methods=['DELETE'])
@admin_required
def delete_area(user, id):
    area_to_delete = MasterAreas.query.get(id)
    if not area_to_delete:
        return jsonify({"msg": "Area not found"}), 404
    
    db.session.delete(area_to_delete)
    db.session.commit()
    return jsonify({"msg": "Area deleted successfully"}), 200

@admin_bp.route('/reassign/<int:grievance_id>', methods=['POST'])
@admin_required
def reassign_grievance(user, grievance_id):
    """
    Reassign a grievance to a new field staff member.
    """
    try:
        data = request.get_json()
        # The frontend code is sending 'assigned_to', not 'assignee_id'.
        new_assignee_id = data.get('assigned_to')
        if not new_assignee_id:
            return jsonify({"success": False, "message": "Assignee ID is required"}), 400
        
        grievance = Grievance.query.get(grievance_id)
        if not grievance:
            return jsonify({"success": False, "message": "Grievance not found"}), 404
        
        assignee = User.query.get(new_assignee_id)
        if not assignee or assignee.role != Role.FIELD_STAFF:
            return jsonify({"success": False, "message": "Invalid assignee"}), 400
        
        grievance.assigned_to = new_assignee_id
        grievance.assigned_by = user.id
        grievance.updated_at = datetime.now(timezone.utc)
        
        db.session.commit()
        
        # Notify the new assignee
        from ..services.notification_service import send_notification
        send_notification(
            assignee.email,
            'Grievance Assigned',
            f'You have been assigned grievance #{grievance_id}'
        )
        
        return jsonify({"success": True, "message": "Grievance reassigned successfully"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"success": False, "message": str(e)}), 500

@admin_bp.route('/audit-logs', methods=['GET', 'OPTIONS'])
def audit_logs():
    if request.method == 'OPTIONS':
        return '', 200  # Allow preflight without JWT

    return _audit_logs_protected()


@jwt_required()
@admin_required
def _audit_logs_protected(user):
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
    filter_type = request.args.get('filter_type', 'all')
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
def get_all_grievances(user):
    """
    Fetch all grievances with optional filters.
    """
    try:
        from ..models import Grievance
        status = request.args.get('status')
        priority = request.args.get('priority')
        area_id = request.args.get('area_id', type=int)
        subject_id = request.args.get('subject_id', type=int)
        
        query = Grievance.query
        if status:
            query = query.filter_by(status=status)
        if priority:
            query = query.filter_by(priority=priority)
        if area_id:
            query = query.filter_by(area_id=area_id)
        if subject_id:
            query = query.filter_by(subject_id=subject_id)
        
        grievances = query.order_by(Grievance.created_at.desc()).all()

        return jsonify([g.to_dict() for g in grievances])
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500



@admin_bp.route('/grievances/<int:id>/escalate', methods=['POST'])
@admin_required
def escalate(user, id):
    try:
        data = request.json or {}
        print("Incoming escalate request:", data)

        new_assignee_id = data.get('assignee_id')

        # Escalate grievance
        result = escalate_grievance(
            grievance_id=id,
            escalated_by=user.id,   # always take from current logged-in user
            new_assignee_id=new_assignee_id
        )

        status_code = 200 if result.get("success") else 400
        return jsonify(result), status_code

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500



@admin_bp.route('/configs', methods=['GET', 'POST', 'OPTIONS'])
def manage_configs():
    if request.method == 'OPTIONS':
        # Respond to preflight without JWT
        return jsonify({}), 200

    return _manage_configs_protected()


@jwt_required()
@admin_required
def _manage_configs_protected(user):
    if request.method == 'POST':
        data = request.json

        # Check if config already exists (upsert)
        config = MasterConfig.query.filter_by(key=data['key']).first()
        if config:
            # Update existing
            config.value = data['value']
            config.updated_at = datetime.now(timezone.utc)
            if 'description' in data:
                config.description = data['description']
        else:
            # Insert new
            config = MasterConfig(
                key=data['key'],
                value=data['value'],
                description=data.get('description')
            )
            db.session.add(config)

        db.session.commit()

    # Always return configs
    configs = MasterConfig.query.all()
    return jsonify([
        {
            'id': c.id,
            'key': c.key,
            'value': c.value,
            'description': c.description,
            'created_at': c.created_at,
            'updated_at': c.updated_at,
        }
        for c in configs
    ]), 200

# In app/routes/admin_routes.py
@admin_bp.route('/configs/<string:key>', methods=['PUT'])
@admin_required
def update_config( key):
    data = request.json
    config = MasterConfig.query.filter_by(key=key).first()
    if not config:
        return jsonify({"error": "Config not found"}), 404
    config.value = data.get('value')
    config.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify({'key': config.key, 'value': config.value}), 200

@admin_bp.route('/users/history', methods=['GET'])
@admin_required
def all_users_history(user):
    users = User.query.filter(User.role == Role.CITIZEN).all()
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
    try:
        data = request.json
        print(f"Received data: {data}")
        if not data:
            return jsonify({"msg": "No data provided"}), 400
        
        result = add_update_user(data, user_id=id)

        return jsonify(result), 200
    except ValueError as e:
        return jsonify({"msg": str(e)}), 400
    except IntegrityError as e:
        return jsonify({"msg": "Database integrity error, possible duplicate data.", "error": str(e)}), 409
    except SQLAlchemyError as e:
        print(f"Database error: {str(e)}")
        
        return jsonify({"msg": "Database error occurred", "error": str(e)}), 500
    except AttributeError as e:
        print(f"Attribute error: {str(e)}")
       
        return jsonify({"msg": "Invalid user attribute", "error": str(e)}), 400
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        
        return jsonify({
            "msg": "Failed to update user",
            "error": str(e) or "Unknown error"
        }), 500



@admin_bp.route('/users', methods=['POST'])
@admin_required
def create_user(user):
    try:
        data = request.json
        print(f"Received data for new user: {data}")
        if not data:
            return jsonify({"msg": "No data provided"}), 400

        result = add_update_user(data)  # no user_id → create

        return jsonify(result), 201
    except ValueError as e:
        return jsonify({"msg": str(e)}), 400
    except IntegrityError as e:
        return jsonify({"msg": "Database integrity error, possible duplicate data.", "error": str(e)}), 409
    except SQLAlchemyError as e:
        print(f"Database error: {str(e)}")
        return jsonify({"msg": "Database error occurred", "error": str(e)}), 500
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return jsonify({"msg": "Failed to create user", "error": str(e)}), 500






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
    print("DEBUG incoming:", data)
    schema = AnnouncementSchema()
    errors = schema.validate(data)
    print("DEBUG errors:", errors)
    if errors:
        return jsonify(errors), 400
    data["target_role"] = data["target_role"].upper() if data.get("target_role") else None
    if data.get("expires_at"):
        try:
            # Handle ISO 8601 format from frontend
            data["expires_at"] = datetime.fromisoformat(data["expires_at"].replace("Z", ""))
        except ValueError:
            return jsonify({"error": "Invalid date format for expires_at"}), 400
    announcement = Announcement(**data)
    db.session.add(announcement)
    db.session.commit()

    # Broadcast via email/FCM
    users = User.query.all()
    for u in users:
        if not u.email:  # skip users without email
            continue
        token = NotificationToken.query.filter_by(user_id=u.id).first()
        send_notification(
            to=u.email,
            subject=f"{data['type'].capitalize()} Announcement",
            body=data['message'],
            fcm_token=token.fcm_token if token else None
        )
    return schema.dump(announcement), 201

@admin_bp.route('/announcements', methods=['GET'])
def get_announcements():
    # This could be moved to a public blueprint if needed, but for now under admin
    # Optionally filter by active, non-expired, etc.
    now = datetime.now(timezone.utc)
    announcements = Announcement.query.filter(
        Announcement.is_active == True,
        db.or_(Announcement.expires_at > now, Announcement.expires_at == None)
    ).order_by(Announcement.created_at.desc()).all()
    return AnnouncementSchema(many=True).dump(announcements), 200

@admin_bp.route('/reports/kpis/advanced', methods=['GET', 'OPTIONS'])
def get_advanced_kpis_route():
    # Skip authentication for OPTIONS preflight requests
    if request.method == "OPTIONS":
        return '', 200

    # For actual GET requests, enforce JWT + admin
    @jwt_required()
    @admin_required
    def actual_route(user):
        time_period = request.args.get('time_period', 'all')
        try:
            kpis = get_advanced_kpis(time_period)
            return jsonify(kpis), 200
        except ValueError as ve:
            return jsonify({"error": str(ve)}), 400
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    return actual_route()
