from marshmallow import Schema, fields, validate, validates, ValidationError
from marshmallow_enum import EnumField
from .models import Role, GrievanceStatus, Priority

class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    email = fields.Email(required=True)
    phone_number = fields.Str(allow_none=True)
    password = fields.Str(load_only=True, validate=validate.Length(min=6), allow_none=True)
    role = EnumField(Role, by_value=True, required=True)
    department_id = fields.Int(allow_none=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)
    voter_id = fields.String()
    # New fields from updated User model
    address = fields.Str(allow_none=True)
    profile_picture = fields.Str(allow_none=True)
    last_login = fields.DateTime(dump_only=True)
    two_factor_enabled = fields.Boolean(dump_only=True)
    is_active = fields.Boolean(dump_only=True)

    @validates('name')
    def validate_name(self, value):
        if value is None or value.strip() == '':
            raise ValidationError('Name cannot be empty or null')

class GrievanceSchema(Schema):
    id = fields.Int(dump_only=True)
    complaint_id = fields.Str(dump_only=True)
    title = fields.Str(required=True)
    description = fields.Str(required=True)
    # --- Fields for LOADING data (API input from user) ---
    subject_id = fields.Int(required=True, load_only=True)
    area_id = fields.Int(required=True, load_only=True)
    # New field
    category_id = fields.Int(allow_none=True, load_only=True)
    # Location fields
    latitude = fields.Float(allow_none=True)
    longitude = fields.Float(allow_none=True)
    address = fields.Str(allow_none=True)
    # --- Fields for DUMPING data (API output) ---
    status = EnumField(GrievanceStatus, by_value=True, dump_only=True)
    priority = EnumField(Priority, by_value=True, allow_none=True, dump_default=Priority.MEDIUM.value)
    rejection_reason = fields.Str(allow_none=True, dump_only=True)
    resolved_at = fields.DateTime(allow_none=True, dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)
    # Nested objects for richer API output
    citizen = fields.Nested(UserSchema(only=("id", "name")), dump_only=True, dump_default={'id': 0, 'name': 'Unknown User'})
    subject = fields.Nested('MasterSubjectsSchema', dump_only=True)
    area = fields.Nested('MasterAreasSchema', dump_only=True)
    category = fields.Nested('MasterCategoriesSchema', dump_only=True)  # New nested field
    assignee = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)
    assigner = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)  # New: for assigned_by
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
    file_size = fields.Int(dump_only=True)  # Already included
    uploaded_at = fields.DateTime(dump_only=True)


class CommentAttachmentSchema(Schema):
    id = fields.Int(dump_only=True)
    comment_id = fields.Int(required=True)
    file_path = fields.Str(dump_only=True)
    file_type = fields.Str(dump_only=True)
    file_size = fields.Int(dump_only=True)
    uploaded_at = fields.DateTime(dump_only=True)



class GrievanceCommentSchema(Schema):
    id = fields.Int(dump_only=True)
    grievance_id = fields.Int(required=True)
    user_id = fields.Int(dump_only=True)
    comment_text = fields.Str(required=True)
    created_at = fields.DateTime(dump_only=True)
    is_public = fields.Boolean(dump_only=True)  # New field
    attachments = fields.Nested(CommentAttachmentSchema, many=True, dump_only=True)
    user = fields.Nested(UserSchema(only=("name",)), dump_only=True)

class WorkproofSchema(Schema):
    id = fields.Int(dump_only=True)
    grievance_id = fields.Int(required=True)
    uploaded_by = fields.Int(dump_only=True)
    file_path = fields.Str(dump_only=True)
    file_type = fields.Str(dump_only=True)  # New field
    file_size = fields.Int(dump_only=True)  # New field
    notes = fields.Str(allow_none=True)
    uploaded_at = fields.DateTime(dump_only=True)
    uploader = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)  # New nested field

class MasterSubjectsSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)
    category_id = fields.Int(allow_none=True)  # New field
    is_active = fields.Boolean(dump_only=True)  # New field
    category = fields.Nested('MasterCategoriesSchema', dump_only=True)  # New nested field

class MasterAreasSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)
    is_active = fields.Boolean(dump_only=True)  # New field

class MasterCategoriesSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True)
    description = fields.Str(allow_none=True)
    is_active = fields.Boolean(dump_only=True)

class AuditLogSchema(Schema):
    id = fields.Int(dump_only=True)
    action = fields.Str(required=True)
    action_type = fields.Str(allow_none=True)  # New field
    performed_by = fields.Int(required=True)
    grievance_id = fields.Int(allow_none=True)
    details = fields.Str(allow_none=True)  # New field
    timestamp = fields.DateTime(dump_only=True)
    performer = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)  # New nested field

class OtpTokenSchema(Schema):
    id = fields.Int(dump_only=True)
    phone_number = fields.Str(required=True)
    otp = fields.Str(required=True)
    expires_at = fields.DateTime(required=True)
    used = fields.Boolean(dump_only=True)  # New field
    created_at = fields.DateTime(dump_only=True)

class NotificationTokenSchema(Schema):
    id = fields.Int(dump_only=True)
    user_id = fields.Int(required=True)
    fcm_token = fields.Str(required=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)  # New field
    is_active = fields.Boolean(dump_only=True)  # New field
    user = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)  # New nested field

class MasterConfigSchema(Schema):
    id = fields.Int(dump_only=True)
    key = fields.Str(required=True)
    value = fields.Str(required=True)
    description = fields.Str(allow_none=True)  # New field
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)

class AnnouncementSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True)
    message = fields.Str(required=True)
    type = fields.Str(required=True, validate=validate.OneOf(["general", "emergency"]))
    created_at = fields.DateTime(dump_only=True)
    expires_at = fields.DateTime(allow_none=True)  # New field
    target_role = fields.Str(allow_none=True, validate=validate.OneOf([r.value for r in Role]))
    is_active = fields.Boolean()  # New field
    @validates("target_role")
    def validate_role(self, value):
        if value is None:
            return  # allow nulls
        allowed = ["CITIZEN", "MEMBER_HEAD", "FIELD_STAFF", "ADMIN"]
        if value.upper() not in allowed:
            raise ValidationError(f"Invalid target_role. Must be one of {allowed}")

class UserPreferenceSchema(Schema):
    id = fields.Int(dump_only=True)
    user_id = fields.Int(required=True)
    notifications_enabled = fields.Boolean(dump_default=True)
    language = fields.Str(dump_default='en', validate=validate.OneOf(['en', 'mr', 'hi']))
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)
    user = fields.Nested(UserSchema(only=("id", "name")), dump_only=True)