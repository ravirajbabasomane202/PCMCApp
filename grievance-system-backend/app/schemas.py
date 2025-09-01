# app/schemas.py

from marshmallow import Schema, fields, validate, validates, ValidationError
from marshmallow_enum import EnumField
from .models import Role, GrievanceStatus, Priority

class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    email = fields.Email(required=True)
    password = fields.Str( load_only=True, validate=validate.Length(min=6), allow_none=True)  # Added password field
    role = EnumField(Role, by_value=True, required=True)
    department_id = fields.Int(allow_none=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)

    @validates('name')
    def validate_name(self, value):
        if value is None or value.strip() == '':
            raise ValidationError('Name cannot be empty or null')

class GrievanceSchema(Schema):
    id = fields.Int(dump_only=True)
    complaint_id = fields.Str(dump_only=True)
    title = fields.Str(required=True) # Used for both loading and dumping
    description = fields.Str(required=True) # Used for both loading and dumping

    # --- Fields for LOADING data (API input from user) ---
    subject_id = fields.Int(required=True, load_only=True)
    area_id = fields.Int(required=True, load_only=True)

    # 🔹 Add location fields
    latitude = fields.Float(allow_none=True)
    longitude = fields.Float(allow_none=True)
    address = fields.Str(allow_none=True)

    # --- Fields for DUMPING data (API output) ---
    status = EnumField(GrievanceStatus, by_value=True, dump_only=True)
    priority = EnumField(Priority, by_value=True, allow_none=True,dump_default=Priority.MEDIUM.value)
    rejection_reason = fields.Str(allow_none=True, dump_only=True)
    resolved_at = fields.DateTime(allow_none=True, dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)

    # Nested objects for richer API output
    citizen = fields.Nested(UserSchema(only=("id", "name")), dump_only=True, dump_default={'id': 0, 'name': 'Unknown User'})
    subject = fields.Nested('MasterSubjectsSchema', dump_only=True)
    area = fields.Nested('MasterAreasSchema', dump_only=True)
    assignee = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)
    attachments = fields.Nested('GrievanceAttachmentSchema', many=True, dump_only=True)
    comments = fields.Nested('GrievanceCommentSchema', many=True, dump_only=True)
    @validates('citizen')
    def validate_citizen(self, value):
        if value is None:
            return {'id': 0, 'name': 'Unknown User'}
        
class GrievanceAttachmentSchema(Schema):
    id = fields.Int(dump_only=True)
    grievance_id = fields.Int(required=True)
    file_path = fields.Str(dump_only=True)
    file_type = fields.Str(dump_only=True)
    file_size = fields.Int(dump_only=True)  # New field
    uploaded_at = fields.DateTime(dump_only=True)

class GrievanceCommentSchema(Schema):
    id = fields.Int(dump_only=True)
    grievance_id = fields.Int(required=True)
    user_id = fields.Int(dump_only=True)
    comment_text = fields.Str(required=True)
    created_at = fields.DateTime(dump_only=True)
    user = fields.Nested(UserSchema(only=("name",)), dump_only=True)

class WorkproofSchema(Schema):
    id = fields.Int(dump_only=True)
    grievance_id = fields.Int(required=True)
    uploaded_by = fields.Int(dump_only=True)
    file_path = fields.Str(dump_only=True)
    notes = fields.Str(allow_none=True)
    uploaded_at = fields.DateTime(dump_only=True)

class MasterSubjectsSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)

class MasterAreasSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)

class AuditLogSchema(Schema):
    id = fields.Int(dump_only=True)
    action = fields.Str(required=True)
    performed_by = fields.Int(required=True)
    grievance_id = fields.Int(allow_none=True)
    timestamp = fields.DateTime(dump_only=True)

# app/schemas.py
class AnnouncementSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True)
    message = fields.Str(required=True)
    type = fields.Str(required=True, validate=validate.OneOf(["general", "emergency"]))
    created_at = fields.DateTime(dump_only=True)
