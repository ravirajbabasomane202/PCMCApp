# app/models.py

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
    password_hash = db.Column(db.String(256), nullable=True)
    role = db.Column(db.Enum(Role), nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey('master_areas.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    # New fields for enhanced user profile
    address = db.Column(db.String(256), nullable=True)  # For user address in settings
    profile_picture = db.Column(db.String(256), nullable=True)  # Path to profile picture
    last_login = db.Column(db.DateTime, nullable=True)  # Track last login for security
    two_factor_enabled = db.Column(db.Boolean, default=False)  # For 2FA in settings
    is_active = db.Column(db.Boolean, default=True)  # For account status (e.g., disable user)

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
    feedback_rating = db.Column(db.Integer, nullable=True)  # 1-5 star rating
    feedback_text = db.Column(db.Text, nullable=True)
    # New field for categorization
    category_id = db.Column(db.Integer, db.ForeignKey('master_categories.id'), nullable=True)  # For grouping subjects

    # Relationships
    citizen = db.relationship('User', backref=db.backref('submitted_grievances', lazy=True), foreign_keys=[citizen_id])
    assignee = db.relationship('User', backref=db.backref('assigned_grievances', lazy=True), foreign_keys=[assigned_to])
    assigner = db.relationship('User', backref=db.backref('assigned_by_grievances', lazy=True), foreign_keys=[assigned_by])
    subject = db.relationship('MasterSubjects')
    area = db.relationship('MasterAreas')
    category = db.relationship('MasterCategories')
    attachments = db.relationship('GrievanceAttachment', backref='grievance', lazy='dynamic', cascade="all, delete-orphan")
    comments = db.relationship('GrievanceComment', backref='grievance', lazy='dynamic', cascade="all, delete-orphan")

class GrievanceAttachment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    file_path = db.Column(db.String(256), nullable=False)
    file_type = db.Column(db.String(10), nullable=False)  # e.g., 'pdf', 'jpeg'
    file_size = db.Column(db.Integer, nullable=True)  # New: Store file size for validation
    uploaded_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

class GrievanceComment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    comment_text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    # New field for comment visibility
    is_public = db.Column(db.Boolean, default=True)  # Public or internal (e.g., for staff only)

    # Relationship to User
    user = db.relationship('User', backref='comments')

class Workproof(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    file_path = db.Column(db.String(256), nullable=False)
    file_type = db.Column(db.String(10), nullable=True)  # New: Store file type
    file_size = db.Column(db.Integer, nullable=True)  # New: Store file size
    notes = db.Column(db.Text, nullable=True)
    uploaded_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationship
    uploader = db.relationship('User', backref='workproofs')

class MasterSubjects(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)
    # New field for categorization
    category_id = db.Column(db.Integer, db.ForeignKey('master_categories.id'), nullable=True)
    is_active = db.Column(db.Boolean, default=True)  # New: Enable/disable subjects

    # Relationship
    category = db.relationship('MasterCategories', backref='subjects')

class MasterAreas(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)  # New: Enable/disable areas

class MasterCategories(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)  # e.g., 'Roads', 'Sanitation'
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)  # New: Enable/disable categories

class AuditLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    action = db.Column(db.Text, nullable=False)
    action_type = db.Column(db.String(50), nullable=True)  # New: e.g., 'create', 'update', 'delete'
    performed_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    grievance_id = db.Column(db.Integer, db.ForeignKey('grievance.id'), nullable=True)
    details = db.Column(db.Text, nullable=True)  # New: Additional context (e.g., JSON of changes)
    timestamp = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationship
    performer = db.relationship('User', backref='audit_logs')

class OtpToken(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    phone_number = db.Column(db.String(15), nullable=False)
    otp = db.Column(db.String(6), nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    used = db.Column(db.Boolean, default=False)  # New: Track if OTP was used
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

class NotificationToken(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    fcm_token = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    is_active = db.Column(db.Boolean, default=True)  # New: Enable/disable token

    # Relationship
    user = db.relationship('User', backref='notification_tokens')

class MasterConfig(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(128), unique=True, nullable=False)
    value = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    description = db.Column(db.Text, nullable=True)  # New: Describe config purpose

class Announcement(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(256), nullable=False)
    message = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), default="general")  # general / emergency
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = db.Column(db.DateTime, nullable=True)  # New: Expiration for announcements
    target_role = db.Column(db.Enum(Role), nullable=True)  # New: Target specific roles
    is_active = db.Column(db.Boolean, default=True)  # New: Enable/disable announcements

class UserPreference(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    notifications_enabled = db.Column(db.Boolean, default=True)  # Notification preference
    language = db.Column(db.String(10), default='en')  # Language (e.g., 'en', 'mr', 'hi')
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationship
    user = db.relationship('User', backref='preferences')