# app/utils/kpi_utils.py

from datetime import datetime, timedelta
from ..models import Grievance, GrievanceStatus, MasterAreas
from .. import db
from sqlalchemy import func

def calculate_resolution_rate():
    total_resolved = Grievance.query.filter_by(status=GrievanceStatus.CLOSED).count()
    total_grievances = Grievance.query.count()
    return (total_resolved / total_grievances * 100) if total_grievances > 0 else 0

def calculate_pending_aging():
    pending = Grievance.query.filter(Grievance.status.notin_([GrievanceStatus.CLOSED, GrievanceStatus.REJECTED]))
    aging = db.session.query(func.avg(func.julianday(datetime.utcnow()) - func.julianday(Grievance.created_at))).filter(Grievance.status.notin_([GrievanceStatus.CLOSED, GrievanceStatus.REJECTED])).scalar()
    return {
        'pending_count': pending.count(),
        'average_aging_days': aging or 0
    }

def calculate_sla_compliance():
    resolved = Grievance.query.filter_by(status=GrievanceStatus.CLOSED)
    compliant = resolved.filter(Grievance.updated_at - Grievance.created_at <= timedelta(days=30)).count()
    total_resolved = resolved.count()
    return (compliant / total_resolved * 100) if total_resolved > 0 else 0

def calculate_dept_wise_resolution():
    return db.session.query(MasterAreas.name, func.avg(Grievance.updated_at - Grievance.created_at)).join(MasterAreas).group_by(MasterAreas.id).all()