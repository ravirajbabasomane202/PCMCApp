from datetime import datetime, timedelta
from flask import current_app
from marshmallow import ValidationError
from ..models import Grievance, GrievanceAttachment, GrievanceComment, Workproof, GrievanceStatus, Priority, AuditLog, User, NotificationToken, Role
from ..schemas import GrievanceSchema, GrievanceAttachmentSchema, GrievanceCommentSchema, WorkproofSchema
from ..utils.file_utils import upload_files, upload_workproof
from .. import db
from ..config import Config
from .notification_service import send_notification
from flask_jwt_extended import get_jwt_identity

def submit_grievance(citizen_id, data, files):
    try:
        schema = GrievanceSchema()
        try:
            validated_data = schema.load(data)
        except ValidationError as err:
            current_app.logger.error(f"Validation error in submit_grievance: {err.messages}")
            raise ValueError(f"Invalid grievance data: {err.messages}")

        # Create grievance, letting the model handle default priority if not provided
        grievance = Grievance(
            citizen_id=citizen_id,
            subject_id=validated_data['subject_id'],
            area_id=validated_data['area_id'],
            title=validated_data['title'],
            description=validated_data['description'],
            latitude=validated_data.get('latitude'),
            longitude=validated_data.get('longitude'),
            address=validated_data.get('address'),
            status=GrievanceStatus.NEW,
            priority=validated_data.get('priority', Priority.MEDIUM)  # ← Use validated_data or default
        )
        db.session.add(grievance)
        db.session.flush()  # Get grievance ID before committing

        if files:
            try:
                uploaded = upload_files(files, grievance.id)
                for path, typ, size in uploaded:
                    attachment = GrievanceAttachment(
                        grievance_id=grievance.id,
                        file_path=path,
                        file_type=typ,
                        file_size=size
                    )
                    db.session.add(attachment)
            except ValueError as e:
                db.session.rollback()
                current_app.logger.error(f"File upload failed for grievance {grievance.id}: {str(e)}")
                raise ValueError(f"File upload error: {str(e)}")

        db.session.commit()

        log_audit(f'Grievance created (Complaint ID {grievance.complaint_id})', citizen_id, grievance.id)

        token = NotificationToken.query.filter_by(user_id=citizen_id).first()
        send_notification(
            grievance.citizen.email,
            'Grievance Submitted',
            'Your grievance has been submitted.',
            fcm_token=token.fcm_token if token else None
        )
        return schema.dump(grievance)
    except ValidationError as e:
        current_app.logger.error(f"Validation error in submit_grievance: {str(e.messages)}")
        raise ValueError(f"Invalid grievance data: {str(e.messages)}")
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error submitting grievance for citizen {citizen_id}: {str(e)}")
        raise ValueError(f"File upload error: {str(e)}")

        db.session.commit()

        log_audit(f'Grievance created (Complaint ID {grievance.complaint_id})', citizen_id, grievance.id)

        token = NotificationToken.query.filter_by(user_id=citizen_id).first()
        send_notification(
            grievance.citizen.email,
            'Grievance Submitted',
            'Your grievance has been submitted.',
            fcm_token=token.fcm_token if token else None
        )
        return schema.dump(grievance)
    except ValidationError as e:
        current_app.logger.error(f"Validation error in submit_grievance: {str(e.messages)}")
        raise ValueError(f"Invalid grievance data: {str(e.messages)}")
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error submitting grievance for citizen {citizen_id}: {str(e)}")
        raise

def get_my_grievances(citizen_id):
    try:
        grievances = Grievance.query.filter_by(citizen_id=citizen_id).all()
        schema = GrievanceSchema(many=True)
        return schema.dump(grievances)
    except Exception as e:
        current_app.logger.error(f"Error fetching grievances for citizen {citizen_id}: {str(e)}")
        raise

def get_grievance_details(id, user_id):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance:
            current_app.logger.error(f"Grievance {id} not found")
            return None

        user = db.session.get(User, user_id)
        if not user:
            current_app.logger.error(f"User {user_id} not found")
            return None

        if user.role != Role.ADMIN and grievance.citizen_id != user_id:
            current_app.logger.error(f"User {user_id} not authorized to view grievance {id}")
            return None

        _check_auto_close(grievance)
        schema = GrievanceSchema()
        return schema.dump(grievance)
    except Exception as e:
        current_app.logger.error(f"Error fetching grievance details for ID {id}: {str(e)}")
        raise

def add_comment(id, user_id, text):
    try:
        comment = GrievanceComment(grievance_id=id, user_id=user_id, comment_text=text)
        db.session.add(comment)
        db.session.commit()
        schema = GrievanceCommentSchema()
        return schema.dump(comment)
    except Exception as e:
        current_app.logger.error(f"Error adding comment to grievance {id}: {str(e)}")
        raise

def confirm_closure(id, citizen_id):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance or grievance.citizen_id != citizen_id or grievance.status != GrievanceStatus.RESOLVED:
            current_app.logger.error(f"Invalid closure attempt for grievance {id} by citizen {citizen_id}")
            raise ValueError("Invalid operation")
        grievance.status = GrievanceStatus.CLOSED
        grievance.updated_at = datetime.utcnow()
        db.session.commit()
        log_audit('Grievance closed', citizen_id, id)
        send_notification(grievance.citizen.email, 'Grievance Closed', 'Your grievance has been closed.')
        return {"msg": "Closed"}
    except Exception as e:
        current_app.logger.error(f"Error closing grievance {id}: {str(e)}")
        raise

def get_rejection_reason(id, citizen_id):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance or grievance.citizen_id != citizen_id or grievance.status != GrievanceStatus.REJECTED:
            current_app.logger.error(f"Invalid rejection reason request for grievance {id} by citizen {citizen_id}")
            raise ValueError("Invalid operation")
        return grievance.rejection_reason
    except Exception as e:
        current_app.logger.error(f"Error fetching rejection reason for grievance {id}: {str(e)}")
        raise

def get_new_grievances(department_id):
    try:
        grievances = Grievance.query.filter_by(status=GrievanceStatus.NEW, area_id=department_id).all()
        schema = GrievanceSchema(many=True)
        return schema.dump(grievances)
    except Exception as e:
        current_app.logger.error(f"Error fetching new grievances for department {department_id}: {str(e)}")
        raise

def accept_grievance(id, head_id, data):
    try:
        current_user_id = get_jwt_identity()
        head_user = db.session.get(User, current_user_id)
        grievance = db.session.get(Grievance, id)

        if not grievance or grievance.status != GrievanceStatus.NEW or grievance.area_id != head_user.department_id:
            current_app.logger.error(f"Invalid accept attempt for grievance {id} by user {head_id}")
            raise ValueError("Invalid operation")
        grievance.priority = Priority[data['priority']]
        grievance.assigned_to = data['assigned_to']
        grievance.assigned_by = head_id
        grievance.status = GrievanceStatus.IN_PROGRESS
        db.session.commit()
        log_audit('Grievance accepted and assigned', head_id, id)
        send_notification(grievance.citizen.email, 'Grievance Accepted', 'Your grievance has been accepted.')
        return {"msg": "Accepted"}
    except Exception as e:
        current_app.logger.error(f"Error accepting grievance {id}: {str(e)}")
        raise

def reject_grievance(id, head_id, reason):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance or grievance.status != GrievanceStatus.NEW or grievance.area_id != db.session.get(User, head_id).department_id:
            current_app.logger.error(f"Invalid reject attempt for grievance {id} by user {head_id}")
            raise ValueError("Invalid operation")
        grievance.status = GrievanceStatus.REJECTED
        grievance.rejection_reason = reason
        db.session.commit()
        log_audit('Grievance rejected', head_id, id)
        send_notification(grievance.citizen.email, 'Grievance Rejected', f'Your grievance has been rejected: {reason}')
        return {"msg": "Rejected"}
    except Exception as e:
        current_app.logger.error(f"Error rejecting grievance {id}: {str(e)}")
        raise

def get_assigned_grievances(employer_id):
    try:
        grievances = Grievance.query.filter_by(assigned_to=employer_id).all()
        schema = GrievanceSchema(many=True)
        return schema.dump(grievances)
    except Exception as e:
        current_app.logger.error(f"Error fetching assigned grievances for user {employer_id}: {str(e)}")
        raise

def update_status(id, employer_id, new_status):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance or grievance.assigned_to != employer_id:
            current_app.logger.error(f"Invalid status update attempt for grievance {id} by user {employer_id}")
            raise ValueError("Invalid operation")
        old_status = grievance.status
        grievance.status = GrievanceStatus[new_status.upper()]
        if grievance.status == GrievanceStatus.RESOLVED:
            grievance.resolved_at = datetime.utcnow()
        db.session.commit()
        log_audit(f'Status updated from {old_status} to {grievance.status}', employer_id, id)
        send_notification(grievance.citizen.email, 'Status Updated', f'Your grievance status is now {new_status}.')
        return {"msg": "Status updated"}
    except Exception as e:
        current_app.logger.error(f"Error updating status for grievance {id}: {str(e)}")
        raise

def upload_workproof(id, employer_id, file, notes):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance or grievance.assigned_to != employer_id:
            current_app.logger.error(f"Invalid workproof upload attempt for grievance {id} by user {employer_id}")
            raise ValueError("Invalid operation")
        path = upload_workproof(file, id)
        workproof = Workproof(grievance_id=id, uploaded_by=employer_id, file_path=path, notes=notes)
        db.session.add(workproof)
        db.session.commit()
        schema = WorkproofSchema()
        return schema.dump(workproof)
    except Exception as e:
        current_app.logger.error(f"Error uploading workproof for grievance {id}: {str(e)}")
        raise

def reassign_grievance(id, new_assigned_to, admin_id):
    try:
        grievance = db.session.get(Grievance, id)
        if not grievance:
            current_app.logger.error(f"Grievance {id} not found for reassignment")
            raise ValueError("Grievance not found")
        grievance.assigned_to = new_assigned_to
        db.session.commit()
        log_audit('Grievance reassigned', admin_id, id)
        return {"msg": "Reassigned"}
    except Exception as e:
        current_app.logger.error(f"Error reassigning grievance {id}: {str(e)}")
        raise

def log_audit(action, user_id, grievance_id=None):
    try:
        log = AuditLog(action=action, performed_by=user_id, grievance_id=grievance_id)
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        current_app.logger.error(f"Error logging audit for action {action}: {str(e)}")
        raise

def _check_auto_close(grievance):
    try:
        if grievance.status == GrievanceStatus.RESOLVED and grievance.resolved_at:
            sla_days = int(Config.SLA_CLOSURE_DAYS) if hasattr(Config, 'SLA_CLOSURE_DAYS') else 7
            if datetime.utcnow() - grievance.resolved_at > timedelta(days=sla_days):
                grievance.status = GrievanceStatus.CLOSED
                db.session.commit()
                log_audit('Auto-closed due to SLA', grievance.assigned_to, grievance.id)
                send_notification(grievance.citizen.email, 'Grievance Auto-Closed', 'Your grievance has been auto-closed.')
    except Exception as e:
        current_app.logger.error(f"Error checking auto-close for grievance {grievance.id}: {str(e)}")
        raise

def escalate_grievance(grievance_id, escalated_by, new_assignee_id=None):
    MAX_ESCALATION_LEVEL = 3
    ESCALATION_FLOW = {
        0: "Assigned Staff",
        1: "Member Head",
        2: "Admin",
        3: "Super Admin"
    }
    try:
        grievance = db.session.get(Grievance, grievance_id)
        if not grievance:
            current_app.logger.error(f"Grievance {grievance_id} not found for escalation")
            raise ValueError("Grievance not found")

        if grievance.escalation_level >= MAX_ESCALATION_LEVEL:
            current_app.logger.error(f"Grievance {grievance_id} already at maximum escalation level")
            return {"success": False, "msg": "Already at maximum escalation level"}

        grievance.escalation_level += 1

        if new_assignee_id:
            new_assignee = db.session.get(User, new_assignee_id)
            if not new_assignee:
                current_app.logger.error(f"New assignee {new_assignee_id} not found")
                raise ValueError("New assignee not found")
            grievance.assigned_to = new_assignee_id
            grievance.assigned_by = escalated_by

        grievance.updated_at = datetime.utcnow()
        db.session.commit()

        log_audit(
            f"Grievance {grievance_id} escalated to level {grievance.escalation_level}",
            escalated_by,
            grievance_id
        )

        send_notification(
            grievance.citizen.email,
            "Grievance Escalated",
            f"Your grievance #{grievance.id} has been escalated to {ESCALATION_FLOW.get(grievance.escalation_level, 'higher authority')}."
        )
        if grievance.assigned_to:
            assignee = db.session.get(User, grievance.assigned_to)
            if assignee:
                send_notification(
                    assignee.email,
                    "New Escalated Grievance Assigned",
                    f"You have been assigned an escalated grievance #{grievance.id}."
                )

        return {"success": True, "msg": f" Escalated to level {grievance.escalation_level}"}
    except Exception as e:
        current_app.logger.error(f"Error escalating grievance {grievance_id}: {str(e)}")
        raise