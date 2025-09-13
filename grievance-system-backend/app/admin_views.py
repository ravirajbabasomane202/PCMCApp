# app/admin_views.py
from flask_admin.contrib.sqla import ModelView
from flask_admin import BaseView, expose
from flask_security import current_user
from .models import User, Grievance, MasterSubjects, MasterAreas, MasterCategories, AuditLog, Announcement
from . import db

class SecureModelView(ModelView):
    """Base view with access checks."""
    def is_accessible(self):
        return current_user.is_authenticated and current_user.role == Role.ADMIN
    
    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for('security.login', next=request.url))

# Custom Dashboard View (example: show KPIs)
class DashboardView(BaseView):
    @expose('/')
    def index(self):
        # Fetch some stats (reuse your kpi_utils if needed)
        total_grievances = Grievance.query.count()
        return self.render('admin/dashboard.html', total_grievances=total_grievances)  # Create this template later

# Model Views
class UserAdmin(SecureModelView):
    column_exclude_list = ['password_hash']  # Hide sensitive fields
    column_searchable_list = ['name', 'email']
    column_filters = ['role']
    form_excluded_columns = ['password_hash']  # Don't edit hash directly
    can_export = True  # Allow CSV export

class GrievanceAdmin(SecureModelView):
    column_list = ['id', 'title', 'status', 'priority', 'created_at']
    column_searchable_list = ['title', 'description']
    column_filters = ['status', 'priority', 'area.name']
    form_excluded_columns = ['attachments', 'comments']  # Handle separately if needed
    can_export = True

# Add more for other models...
class SubjectAdmin(SecureModelView):
    pass

class AreaAdmin(SecureModelView):
    pass

class CategoryAdmin(SecureModelView):
    pass

class AuditLogAdmin(SecureModelView):
    can_edit = False  # Read-only
    can_delete = False

class AnnouncementAdmin(SecureModelView):
    pass