from flask import Blueprint, request, jsonify
from ..utils.auth_utils import admin_required
from ..utils.kpi_utils import calculate_resolution_rate, calculate_pending_aging, calculate_sla_compliance
from ..models import AuditLog,MasterConfig, MasterSubjects, MasterAreas, Grievance, User, Role, Announcement, NearbyPlace, Advertisement
from ..services.report_service import generate_report,get_staff_performance, get_location_reports

from ..services.report_service import get_citizen_history
from ..services.report_service import escalate_grievance
from ..services.report_service import get_advanced_kpis
from datetime import datetime
from ..schemas import GrievanceSchema, UserSchema, AnnouncementSchema, NearbyPlaceSchema
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
import os
from werkzeug.utils import secure_filename
from flask import current_app
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
    errors = schema.validate(data, partial=True) 
    if errors:
        return jsonify(errors), 400

    try:
        subject = db.session.get(MasterSubjects, id)
        if not subject:
            return jsonify({"error": "Subject not found"}), 404
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
    try:
        data = request.get_json()
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
        return jsonify({"success": True, "message": "Grievance reassigned successfully"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"success": False, "message": str(e)}), 500

@admin_bp.route('/audit-logs', methods=['GET', 'OPTIONS'])
def audit_logs():
    if request.method == 'OPTIONS':
        return '', 200  

    return _audit_logs_protected()


@jwt_required()
@admin_required
def _audit_logs_protected(user):
    logs = AuditLog.query.all()
    schema = AuditLogSchema(many=True)
    return jsonify(schema.dump(logs)), 200
@admin_bp.route('/kpis/advanced', methods=['GET'])
@admin_required
def advanced_kpis(user):
    return jsonify(get_advanced_kpis()), 200

@admin_bp.route('/reports', methods=['GET'])
@admin_required
def reports(user):
    filter_type = request.args.get('filter_type', 'all')
    format = request.args.get('format', 'pdf')
    report_data = generate_report(filter_type, format)

    if format == 'pdf':
        return Response(
            report_data,
            mimetype='application/pdf',
            headers={"Content-Disposition": "attachment; filename=report.pdf"}
        )

    elif format == 'csv':
        return Response(
            report_data,
            mimetype='text/csv',
            headers={"Content-Disposition": "attachment; filename=report.csv"}
        )

    elif format == 'excel':
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

        result = escalate_grievance(
            grievance_id=id,
            escalated_by=user.id,   
            new_assignee_id=new_assignee_id
        )

        status_code = 200 if result.get("success") else 400
        return jsonify(result), status_code

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500



@admin_bp.route('/configs', methods=['GET', 'POST', 'OPTIONS'])
def manage_configs():
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    return _manage_configs_protected()


@jwt_required()
@admin_required
def _manage_configs_protected(user):
    if request.method == 'POST':
        data = request.json
        config = MasterConfig.query.filter_by(key=data['key']).first()
        if config:
            config.value = data['value']
            config.updated_at = datetime.now(timezone.utc)
            if 'description' in data:
                config.description = data['description']
        else:
            config = MasterConfig(
                key=data['key'],
                value=data['value'],
                description=data.get('description')
            )
            db.session.add(config)

        db.session.commit()

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
    schema = UserSchema(many=True, exclude=['password'])  
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

        result = add_update_user(data) 

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
           
            data["expires_at"] = datetime.fromisoformat(data["expires_at"].replace("Z", ""))
        except ValueError:
            return jsonify({"error": "Invalid date format for expires_at"}), 400
    announcement = Announcement(**data)
    db.session.add(announcement)
    db.session.commit()

    return schema.dump(announcement), 201

@admin_bp.route('/announcements', methods=['GET'])
def get_announcements():
    now = datetime.now(timezone.utc)
    announcements = Announcement.query.filter(
        Announcement.is_active == True,
        db.or_(Announcement.expires_at > now, Announcement.expires_at == None)
    ).order_by(Announcement.created_at.desc()).all()
    return AnnouncementSchema(many=True).dump(announcements), 200

@admin_bp.route('/announcements/<int:id>', methods=['DELETE'])
@admin_required
def delete_announcement(user, id):
    """Delete an announcement by ID."""
    try:
        announcement = Announcement.query.get(id)
        if not announcement:
            return jsonify({"msg": "Announcement not found"}), 404
        
        db.session.delete(announcement)
        db.session.commit()
        return jsonify({"msg": "Announcement deleted successfully"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": "Failed to delete announcement", "error": str(e)}), 500

@admin_bp.route('/reports/kpis/advanced', methods=['GET', 'OPTIONS'])
def get_advanced_kpis_route():
    if request.method == "OPTIONS":
        return '', 200
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

nearby_place_schema = NearbyPlaceSchema()
nearby_places_schema = NearbyPlaceSchema(many=True)

# CREATE
@admin_bp.route('/nearby', methods=['POST'])
@admin_required
def add_nearby_place(user):
    data = request.get_json()
    place = NearbyPlace(**data)
    db.session.add(place)
    db.session.commit()
    return jsonify({"message": "Added successfully", "data": nearby_place_schema.dump(place)}), 201

# READ ALL
@admin_bp.route('/nearby', methods=['GET'])
@admin_required
def get_all_nearby(user):
    places = NearbyPlace.query.all()
    return jsonify(nearby_places_schema.dump(places))

# UPDATE
@admin_bp.route('/nearby/<int:id>', methods=['PUT'])
@admin_required
def update_nearby(user, id):
    place = NearbyPlace.query.get_or_404(id)
    data = request.get_json()
    for key, value in data.items():
        setattr(place, key, value)
    db.session.commit()
    return jsonify({"message": "Updated successfully", "data": nearby_place_schema.dump(place)})

# DELETE
@admin_bp.route('/nearby/<int:id>', methods=['DELETE'])
@admin_required
def delete_nearby(user, id):
    place = NearbyPlace.query.get_or_404(id)
    db.session.delete(place)
    db.session.commit()
    return jsonify({"message": "Deleted successfully"})











@admin_bp.route('/ads', methods=['GET'])
@admin_required  # This ensures only ADMIN role can access
@jwt_required()  # Basic JWT check
def get_ads(user):
    try:
        # Deactivate expired ads
        now = datetime.now(timezone.utc)
        expired_ads = Advertisement.query.filter(Advertisement.is_active == True, Advertisement.expires_at != None, Advertisement.expires_at <= now).all()
        for ad in expired_ads:
            ad.is_active = False
        db.session.commit()

        ads = Advertisement.query.order_by(Advertisement.created_at.desc()).all()
        return jsonify([ad.to_dict() for ad in ads])
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/ads', methods=['POST'])
@admin_required
@jwt_required()
def create_ad(user):
    try:
        if 'title' not in request.form:
            return jsonify({'error': 'Title is required'}), 400

        title = request.form.get('title')
        description = request.form.get('description')
        link_url = request.form.get('link_url')
        is_active = request.form.get('is_active', 'true').lower() == 'true'
        expires_at_str = request.form.get('expires_at')
        expires_at = None
        if expires_at_str:
            expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))

        image_url = None

        if 'image_file' in request.files:
            file = request.files['image_file']
            if file.filename != '':
                filename = secure_filename(file.filename)
                # Create a specific folder for ad uploads if it doesn't exist
                ads_upload_folder = os.path.join(current_app.config['UPLOAD_FOLDER'], 'ads')
                os.makedirs(ads_upload_folder, exist_ok=True)
                
                file_path = os.path.join(ads_upload_folder, filename)
                file.save(file_path)
                image_url = f'ads/{filename}' # Store relative path

        ad = Advertisement(
            title=title,
            description=description,
            image_url=image_url,
            link_url=link_url,
            expires_at=expires_at,
            is_active=is_active,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        db.session.add(ad)
        db.session.commit()
        return jsonify({
            'message': 'Advertisement created successfully',
            'data': ad.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500



@admin_bp.route('/ads/<int:ad_id>', methods=['PUT'])
@admin_required
def update_ad(user, ad_id):
    ad = Advertisement.query.get_or_404(ad_id)
    
    ad.title = request.form.get('title', ad.title)
    ad.description = request.form.get('description', ad.description)
    ad.link_url = request.form.get('link_url', ad.link_url)
    is_active_str = request.form.get('is_active')
    if is_active_str is not None:
        ad.is_active = is_active_str.lower() in ['true', '1']

    expires_at_str = request.form.get('expires_at')
    if expires_at_str:
        ad.expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))


    if 'image_file' in request.files:
        file = request.files['image_file']
        if file and file.filename != '':
            # Optionally, delete the old file
            if ad.image_url:
                old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], ad.image_url)
                if os.path.exists(old_path):
                    os.remove(old_path)

            filename = secure_filename(file.filename)
            ads_upload_folder = os.path.join(current_app.config['UPLOAD_FOLDER'], 'ads')
            os.makedirs(ads_upload_folder, exist_ok=True)
            file_path = os.path.join(ads_upload_folder, filename)
            file.save(file_path)
            ad.image_url = f'ads/{filename}'

    db.session.commit()
    return jsonify({"message": "Advertisement updated"}), 200


@admin_bp.route('/ads/<int:ad_id>', methods=['DELETE'])
@admin_required
def delete_ad(user, ad_id):
    ad = Advertisement.query.get_or_404(ad_id)
    db.session.delete(ad)
    db.session.commit()
    return jsonify({"message": "Advertisement deleted"}), 200
