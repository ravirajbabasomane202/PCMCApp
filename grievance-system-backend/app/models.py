from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash
from . import db
from enum import Enum
import uuid


class Role(Enum):
    CITIZEN = 'citizen'
    MEMBER_HEAD = 'member_head'
    FIELD_STAFF = 'field_staff'
    ADMIN = 'admin'

class GrievanceStatus(Enum):
    NEW = 'new'
    IN_PROGRESS = 'in_progress'
    ON_HOLD = 'on_hold'
    RESOLVED = 'resolved'
    CLOSED = 'closed'
    REJECTED = 'rejected'

class Priority(Enum):
    LOW = 'low'
    MEDIUM = 'medium'
    HIGH = 'high'
    URGENT = 'urgent'

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    email = db.Column(db.String(128), unique=True, nullable=True)
    phone_number = db.Column(db.String(15), unique=True, nullable=True)
    voter_id = db.Column(db.String(50), unique=True, nullable=True)
    password_hash = db.Column(db.String(256), nullable=True)
    role = db.Column(db.Enum(Role), nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey('master_areas.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    address = db.Column(db.String(256), nullable=True) 
    profile_picture = db.Column(db.String(256), nullable=True) 
    last_login = db.Column(db.DateTime, nullable=True)  
    two_factor_enabled = db.Column(db.Boolean, default=False) 
    is_active = db.Column(db.Boolean, default=True)  

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Grievance(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    complaint_id = db.Column(db.String(50), unique=True, nullable=False, default=lambda: str(uuid.uuid4())[:8])
    citizen_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    subject_id = db.Column(db.Integer, db.ForeignKey('master_subjects.id'), nullable=False)
    area_id = db.Column(db.Integer, db.ForeignKey('master_areas.id'), nullable=False)
    title = db.Column(db.String(256), nullable=False)
    description = db.Column(db.Text, nullable=False)
    ward_number = db.Column(db.String(50), nullable=True)
    status = db.Column(db.Enum(GrievanceStatus), default=GrievanceStatus.NEW, nullable=False)
    priority = db.Column(db.Enum(Priority), default=Priority.MEDIUM, nullable=True)
    assigned_to = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    assigned_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    rejection_reason = db.Column(db.Text, nullable=True)
    resolved_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    address = db.Column(db.String(256), nullable=True)
    escalation_level = db.Column(db.Integer, default=0)
    feedback_rating = db.Column(db.Integer, nullable=True)  
    feedback_text = db.Column(db.Text, nullable=True)
    category_id = db.Column(db.Integer, db.ForeignKey('master_categories.id'), nullable=True) 

    citizen = db.relationship('User', backref=db.backref('submitted_grievances', lazy=True), foreign_keys=[citizen_id])
    assignee = db.relationship('User', backref=db.backref('assigned_grievances', lazy=True), foreign_keys=[assigned_to])
    assigner = db.relationship('User', backref=db.backref('assigned_by_grievances', lazy=True), foreign_keys=[assigned_by])
    subject = db.relationship('MasterSubjects')
    area = db.relationship('MasterAreas')
    category = db.relationship('MasterCategories')
    attachments = db.relationship('GrievanceAttachment', backref='grievance', lazy='dynamic', cascade="all, delete-orphan")
    comments = db.relationship('GrievanceComment', backref='grievance', lazy='dynamic', cascade="all, delete-orphan")
    workproofs = db.relationship('Workproof', backref='grievance', lazy='dynamic', cascade="all, delete-orphan")
    def to_dict(self):
        """
        Convert Grievance object to a dictionary for JSON serialization.
        """
        attachments_list = [attachment.to_dict() for attachment in self.attachments.all()]
        comments_list = [comment.to_dict() for comment in self.comments.all()]
        workproofs_list = [workproof.to_dict() for workproof in self.workproofs.all()]
        
        return {
            'id': self.id,
            'complaint_id': self.complaint_id,
            'citizen_id': self.citizen_id,
            'citizen': {
                'id': self.citizen.id,
                'name': self.citizen.name
            } if self.citizen else None,
            'subject_id': self.subject_id,
            'subject': {
                'id': self.subject.id,
                'name': self.subject.name,
                'description': self.subject.description,
                'category': {
                    'id': self.subject.category.id,
                    'name': self.subject.category.name,
                    'description': self.subject.category.description
                } if self.subject.category else None
            } if self.subject else None,
            'area_id': self.area_id,
            'area': {
                'id': self.area.id,
                'name': self.area.name,
                'description': self.area.description
            } if self.area else None,
            'title': self.title,
            'description': self.description,
            'ward_number': self.ward_number,
            'status': self.status.value if self.status else None,
            'priority': self.priority.value if self.priority else None,
            'assigned_to': self.assigned_to,
            'assignee': {
                'id': self.assignee.id,
                'name': self.assignee.name
            } if self.assignee else {'id': 0, 'name': 'Unassigned'},
            'assigned_by': self.assigned_by,
            'assigner': {
                'id': self.assigner.id,
                'name': self.assigner.name
            } if self.assigner else None,
            'rejection_reason': self.rejection_reason,
            'resolved_at': self.resolved_at.isoformat() if self.resolved_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'address': self.address,
            'escalation_level': self.escalation_level,
            'feedback_rating': self.feedback_rating,
            'feedback_text': self.feedback_text,
            'category_id': self.category_id,
            'category': {
                'id': self.category.id,
                'name': self.category.name,
                'description': self.category.description
            } if self.category else None,
            'attachments': attachments_list,  
            'comments': comments_list,  
            'workproofs': workproofs_list
        }
class GrievanceAttachment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    file_path = db.Column(db.String(256), nullable=False)
    file_type = db.Column(db.String(10), nullable=False)  
    file_size = db.Column(db.Integer, nullable=True)  
    uploaded_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    def to_dict(self):
        return {
            'id': self.id,
            'grievance_id': self.grievance_id,
            'file_path': self.file_path,
            'file_type': self.file_type,
            'file_size': self.file_size,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None
        }

class GrievanceComment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    comment_text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    is_public = db.Column(db.Boolean, default=True)  
    attachments = db.relationship('CommentAttachment', backref='comment', lazy='dynamic', cascade="all, delete-orphan")
    user = db.relationship('User', backref='comments')
    def to_dict(self):
        attachments_list = [attachment.to_dict() for attachment in self.attachments.all()]
        
        return {
            'id': self.id,
            'grievance_id': self.grievance_id,
            'user_id': self.user_id,
            'comment_text': self.comment_text,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'is_public': self.is_public,
            'attachments': attachments_list, 
            'user': {
                'id': self.user.id,
                'name': self.user.name
            } if self.user else None
        }


class CommentAttachment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    comment_id = db.Column(db.Integer, db.ForeignKey('grievance_comment.id'), nullable=False)
    file_path = db.Column(db.String(256), nullable=False)
    file_type = db.Column(db.String(10), nullable=True) 
    file_size = db.Column(db.Integer, nullable=True)  
    uploaded_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'comment_id': self.comment_id,
            'file_path': self.file_path,
            'file_type': self.file_type,
            'file_size': self.file_size,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None
        }


class Workproof(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    file_path = db.Column(db.String(256), nullable=False)
    file_type = db.Column(db.String(10), nullable=False)  
    file_size = db.Column(db.Integer, nullable=False) 
    notes = db.Column(db.Text, nullable=False)
    uploaded_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    uploader = db.relationship('User', backref='workproofs')
    def to_dict(self):
        return {
            'id': self.id,
            'grievance_id': self.grievance_id,
            'uploaded_by': self.uploaded_by,
            'uploader': {'id': self.uploader.id, 'name': self.uploader.name} if self.uploader else None,
            'file_path': self.file_path,
            'file_type': self.file_type,
            'file_size': self.file_size,
            'notes': self.notes,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None
        }


class MasterSubjects(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)
    category_id = db.Column(db.Integer, db.ForeignKey('master_categories.id'), nullable=True)
    is_active = db.Column(db.Boolean, default=True)  
    category = db.relationship('MasterCategories', backref='subjects')

class MasterAreas(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)  

class MasterCategories(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)  
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)  

class AuditLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    action = db.Column(db.Text, nullable=False)
    action_type = db.Column(db.String(50), nullable=True)  
    performed_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=True)
    details = db.Column(db.Text, nullable=True)  
    timestamp = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    
    performer = db.relationship('User', backref='audit_logs')



class MasterConfig(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(128), unique=True, nullable=False)
    value = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    description = db.Column(db.Text, nullable=True) 

class Announcement(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(256), nullable=False)
    message = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), default="general")  
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = db.Column(db.DateTime, nullable=True) 
    target_role = db.Column(db.Enum(Role), nullable=True) 
    is_active = db.Column(db.Boolean, default=True) 

class UserPreference(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    notifications_enabled = db.Column(db.Boolean, default=True)  
    language = db.Column(db.String(10), default='en')
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


    user = db.relationship('User', backref='preferences')

# models.py (add near bottom)
class NearbyPlace(db.Model):
    __tablename__ = "nearby_places"

    id = db.Column(db.Integer, primary_key=True)
    category = db.Column(db.String(100), nullable=False)  # hospital, school, etc.
    name = db.Column(db.String(150), nullable=False)
    address = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    contact_no = db.Column(db.String(20), nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=datetime.now(timezone.utc), onupdate=datetime.now(timezone.utc))

class Advertisement(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    image_url = db.Column(db.String(500), nullable=True)
    link_url = db.Column(db.String(500), nullable=True)
    expires_at = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=datetime.now(timezone.utc), onupdate=datetime.now(timezone.utc))
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'image_url': self.image_url,
            'link_url': self.link_url,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
        }
