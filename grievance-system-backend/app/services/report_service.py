
# app/services/report_service.py
import pandas as pd
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from io import BytesIO
from sqlalchemy import func, and_
from datetime import datetime, timedelta
from flask import current_app
from sqlalchemy import func, case
from ..models import Grievance, GrievanceStatus, User, MasterAreas, AuditLog, Role
from .. import db
from .notification_service import send_notification

def generate_report(filter_type='all', format='pdf', user_id=None, area_id=None):
    """
    Generate reports in various formats with filtering options.

    Args:
        filter_type (str): Time period filter ('all', 'day', 'week', 'month', 'year').
        format (str): Output format ('csv', 'excel', 'pdf').
        user_id (int, optional): Filter by specific user ID.
        area_id (int, optional): Filter by specific area ID.

    Returns:
        bytes: Report content in the requested format.

    Raises:
        ValueError: If filter_type or format is invalid.
    """
    valid_filters = ['all', 'day', 'week', 'month', 'year']
    valid_formats = ['csv', 'excel', 'pdf']
    if filter_type not in valid_filters:
        raise ValueError(f"Invalid filter_type. Must be one of {valid_filters}")
    if format not in valid_formats:
        raise ValueError(f"Invalid format. Must be one of {valid_formats}")

    # Build query based on filters
    query = Grievance.query
    
    # Apply time filters
    now = datetime.utcnow()
    if filter_type == 'day':
        query = query.filter(Grievance.created_at >= now - timedelta(days=1))
    elif filter_type == 'week':
        query = query.filter(Grievance.created_at >= now - timedelta(weeks=1))
    elif filter_type == 'month':
        query = query.filter(Grievance.created_at >= now - timedelta(days=30))
    elif filter_type == 'year':
        query = query.filter(Grievance.created_at >= now - timedelta(days=365))
    
    # Apply user filter
    if user_id:
        query = query.filter(Grievance.citizen_id == user_id)
    
    # Apply area filter
    if area_id:
        query = query.filter(Grievance.area_id == area_id)
    
    # Execute query and convert to DataFrame
    try:
        data = pd.read_sql(query.statement, db.engine)
    except Exception as e:
        raise Exception(f"Failed to fetch grievance data: {str(e)}")
    
    # Generate report in requested format
    if format == 'csv':
        return data.to_csv(index=False).encode('utf-8')
    
    elif format == 'excel':
        output = BytesIO()
        with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
            data.to_excel(writer, index=False, sheet_name='Grievance Report')
            # Add summary statistics
            summary_data = get_summary_statistics(query)
            summary_df = pd.DataFrame(list(summary_data.items()), columns=['Metric', 'Value'])
            summary_df.to_excel(writer, index=False, sheet_name='Summary')
        return output.getvalue()
    
    elif format == 'pdf':
        return generate_pdf_report(data, filter_type, user_id, area_id)
    
    return None

def generate_pdf_report(data, filter_type, user_id, area_id):
    """
    Generate a detailed PDF report.

    Args:
        data (pd.DataFrame): Grievance data.
        filter_type (str): Time period filter.
        user_id (int, optional): User ID filter.
        area_id (int, optional): Area ID filter.

    Returns:
        bytes: PDF content.
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter)
    elements = []
    styles = getSampleStyleSheet()
    
    # Add title
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=16,
        spaceAfter=30,
        alignment=1  # Center
    )
    
    title_text = f"Grievance Report - {filter_type.capitalize()}"
    if user_id:
        user = User.query.get(user_id)
        title_text += f" - User: {user.name if user else 'Unknown'}"
    if area_id:
        area = MasterAreas.query.get(area_id)
        title_text += f" - Area: {area.name if area else 'Unknown'}"
    
    elements.append(Paragraph(title_text, title_style))
    
    # Add summary statistics
    summary_style = ParagraphStyle(
        'Summary',
        parent=styles['Normal'],
        fontSize=12,
        spaceAfter=12
    )
    
    query = Grievance.query
    if filter_type != 'all':
        now = datetime.utcnow()
        if filter_type == 'day':
            query = query.filter(Grievance.created_at >= now - timedelta(days=1))
        elif filter_type == 'week':
            query = query.filter(Grievance.created_at >= now - timedelta(weeks=1))
        elif filter_type == 'month':
            query = query.filter(Grievance.created_at >= now - timedelta(days=30))
        elif filter_type == 'year':
            query = query.filter(Grievance.created_at >= now - timedelta(days=365))
    
    if user_id:
        query = query.filter(Grievance.citizen_id == user_id)
    if area_id:
        query = query.filter(Grievance.area_id == area_id)
    
    try:
        summary_data = get_summary_statistics(query)
        summary_text = (
            f"Total Grievances: {summary_data.get('total_grievances', 0)} | "
            f"Resolved: {summary_data.get('resolved_count', 0)} | "
            f"Pending: {summary_data.get('pending_count', 0)}"
        )
        elements.append(Paragraph(summary_text, summary_style))
        elements.append(Spacer(1, 12))
    except Exception as e:
        elements.append(Paragraph(f"Error fetching summary: {str(e)}", summary_style))
        elements.append(Spacer(1, 12))
    
    # Add data table if there's data
    if not data.empty:
        # Prepare table data
        table_data = [list(data.columns)]
        for _, row in data.iterrows():
            table_data.append([str(val) for val in row])  # Convert all values to strings
        
        # Create table
        table = Table(table_data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        elements.append(table)
    
    # Build PDF
    try:
        doc.build(elements)
        pdf_content = buffer.getvalue()
    except Exception as e:
        buffer.close()
        raise Exception(f"Failed to generate PDF: {str(e)}")
    
    buffer.close()
    return pdf_content

def get_summary_statistics(query):
    """
    Get summary statistics for a query.

    Args:
        query: SQLAlchemy query object for grievances.

    Returns:
        dict: Summary statistics (total_grievances, resolved_count, pending_count).

    Raises:
        Exception: If query execution fails.
    """
    try:
        total_grievances = query.count()
        resolved_count = query.filter(Grievance.status == GrievanceStatus.CLOSED).count()
        pending_count = query.filter(Grievance.status.notin_([
            GrievanceStatus.CLOSED, 
            GrievanceStatus.REJECTED
        ])).count()
        
        return {
            'total_grievances': total_grievances or 0,
            'resolved_count': resolved_count or 0,
            'pending_count': pending_count or 0
        }
    except Exception as e:
        raise Exception(f"Failed to compute summary statistics: {str(e)}")

def get_advanced_kpis(time_period='all'):
    """
    Get advanced KPIs for the system.

    Args:
        time_period (str): Time period filter ('day', 'week', 'month', 'year', 'all').

    Returns:
        dict: Dictionary containing various KPIs (total_complaints, status_overview,
              dept_wise, sla_metrics, staff_performance).

    Raises:
        ValueError: If time_period is invalid.
        Exception: If database queries fail.
    """
    valid_periods = ['day', 'week', 'month', 'year', 'all']
    if time_period not in valid_periods:
        raise ValueError(f"Invalid time_period. Must be one of {valid_periods}")

    try:
        # Calculate time filter
        now = datetime.utcnow()
        if time_period == 'day':
            time_filter = Grievance.created_at >= now - timedelta(days=1)
        elif time_period == 'week':
            time_filter = Grievance.created_at >= now - timedelta(weeks=1)
        elif time_period == 'month':
            time_filter = Grievance.created_at >= now - timedelta(days=30)
        elif time_period == 'year':
            time_filter = Grievance.created_at >= now - timedelta(days=365)
        else:
            time_filter = True  # No filter for 'all'
        
        # Total complaints by time period
        total_complaints = {
            'day': db.session.query(func.count(Grievance.id))
                    .filter(Grievance.created_at >= now - timedelta(days=1))
                    .scalar() or 0,
            'week': db.session.query(func.count(Grievance.id))
                    .filter(Grievance.created_at >= now - timedelta(weeks=1))
                    .scalar() or 0,
            'month': db.session.query(func.count(Grievance.id))
                    .filter(Grievance.created_at >= now - timedelta(days=30))
                    .scalar() or 0,
            'year': db.session.query(func.count(Grievance.id))
                    .filter(Grievance.created_at >= now - timedelta(days=365))
                    .scalar() or 0,
            'all': db.session.query(func.count(Grievance.id))
                    .scalar() or 0
        }
        
        # Status overview
        status_counts = db.session.query(
            Grievance.status, 
            func.count(Grievance.id)
        ).filter(time_filter).group_by(Grievance.status).all()
        status_overview = {status.value: count for status, count in status_counts}
        
        # Ensure all possible statuses are included
        for status in GrievanceStatus:
            if status.value not in status_overview:
                status_overview[status.value] = 0
        
        # Department-wise distribution
        dept_wise = dict(db.session.query(
            MasterAreas.name, 
            func.count(Grievance.id)
        ).join(Grievance, MasterAreas.id == Grievance.area_id)
        .filter(time_filter)
        .group_by(MasterAreas.id, MasterAreas.name).all())
        
        # SLA compliance metrics
        resolved_grievances = Grievance.query.filter(
            and_(Grievance.status == GrievanceStatus.CLOSED, time_filter)
        )
        
        sla_days = current_app.config.get('SLA_CLOSURE_DAYS', 7)
        sla_compliant = resolved_grievances.filter(
            Grievance.updated_at - Grievance.created_at <= timedelta(days=sla_days)
        ).count()
        
        total_resolved = resolved_grievances.count()
        sla_compliance_rate = (sla_compliant / total_resolved * 100) if total_resolved > 0 else 0
        
        # Staff performance
        staff_performance = dict(db.session.query(
            User.name, 
            func.count(Grievance.id)
        ).join(Grievance, User.id == Grievance.assigned_to)
        .filter(and_(Grievance.status == GrievanceStatus.CLOSED, time_filter))
        .group_by(User.id, User.name).all())
        
        # Average resolution time
        avg_resolution_time = db.session.query(
            func.avg(func.julianday(Grievance.updated_at) - func.julianday(Grievance.created_at))
        ).filter(and_(Grievance.status == GrievanceStatus.CLOSED, time_filter)).scalar() or 0
        
        return {
            'total_complaints': total_complaints,
            'status_overview': status_overview,
            'dept_wise': dept_wise or {},
            'sla_metrics': {
                'sla_days': sla_days,
                'sla_compliant': sla_compliant or 0,
                'total_resolved': total_resolved or 0,
                'sla_compliance_rate': round(sla_compliance_rate, 2),
                'avg_resolution_time_days': round(avg_resolution_time, 2)
            },
            'staff_performance': staff_performance or {}
        }
    except Exception as e:
        raise Exception(f"Failed to compute KPIs: {str(e)}")

def get_citizen_history(user_id):
    """
    Get grievance history for a specific citizen.

    Args:
        user_id (int): ID of the citizen.

    Returns:
        list: List of grievance records.

    Raises:
        Exception: If query execution fails.
    """
    try:
        return Grievance.query.filter_by(citizen_id=user_id).all()
    except Exception as e:
        raise Exception(f"Failed to fetch citizen history: {str(e)}")

def escalate_grievance(grievance_id, escalated_by , new_assignee_id=None):
    """
    Escalate a grievance to a higher level.

    Args:
        grievance_id (int): ID of the grievance to escalate.
        escalated_by (int): ID of the user performing the escalation.

    Returns:
        dict: Result of the escalation operation.

    Raises:
        Exception: If the grievance is not found or escalation fails.
    """
    try:
        grievance = Grievance.query.get(grievance_id)
        if not grievance:
            return {"success": False, "message": "Grievance not found"}
        
        # Increment escalation level
        grievance.escalation_level = (grievance.escalation_level or 0) + 1
        
        # Update status
        grievance.status = GrievanceStatus.ON_HOLD
        
        # Optionally reassign to a new user
        if new_assignee_id:
            grievance.assigned_to = new_assignee_id
        
        # Log the escalation
        log_audit(f'Grievance escalated to level {grievance.escalation_level}', escalated_by, grievance_id)
        
        db.session.commit()
        
        # Notify administrators and new assignee (if applicable)
        admins = User.query.filter_by(role='admin').all()
        for admin in admins:
            send_notification(
                admin.email, 
                'Grievance Escalated', 
                f'Grievance #{grievance_id} has been escalated to level {grievance.escalation_level}'
            )
        if new_assignee_id:
            assignee = User.query.get(new_assignee_id)
            if assignee:
                send_notification(
                    assignee.email,
                    'Grievance Assigned',
                    f'You have been assigned escalated grievance #{grievance_id} (Level {grievance.escalation_level})'
                )
        
        return {"success": True, "message": f"Grievance escalated to level {grievance.escalation_level}"}
    except Exception as e:
        db.session.rollback()
        raise Exception(f"Failed to escalate grievance: {str(e)}")

def log_audit(action, user_id, grievance_id=None):
    """
    Log an audit action.

    Args:
        action (str): Description of the action.
        user_id (int): ID of the user performing the action.
        grievance_id (int, optional): ID of the related grievance.

    Raises:
        Exception: If audit logging fails.
    """
    try:
        log = AuditLog(action=action, performed_by=user_id, grievance_id=grievance_id)
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise Exception(f"Failed to log audit: {str(e)}")

def get_staff_performance():
    """
    Generate staff performance metrics:
    - Total complaints assigned
    - Complaints resolved
    - Avg resolution time (hours)
    - Avg citizen feedback rating
    """

    query = (
        db.session.query(
            User.id.label("staff_id"),
            User.name.label("staff_name"),
            func.count(Grievance.id).label("total_assigned"),
            func.sum(case((Grievance.status == GrievanceStatus.CLOSED, 1), else_=0)).label("resolved_count"),
            func.avg(case((Grievance.status == GrievanceStatus.CLOSED,
                           func.strftime('%s', Grievance.resolved_at) - func.strftime('%s', Grievance.created_at)))).label("avg_resolution_time_seconds"),
            func.avg(Grievance.feedback_rating).label("avg_feedback_rating")
        )
        .join(User, User.id == Grievance.assigned_to)
        .filter(User.role == Role.EMPLOYER)
        .group_by(User.id, User.name)
    ).all()

    results = []
    for row in query:
        results.append({
            "staff_id": row.staff_id,
            "staff_name": row.staff_name,
            "total_assigned": int(row.total_assigned or 0),
            "resolved_count": int(row.resolved_count or 0),
            "avg_resolution_time_hours": round((row.avg_resolution_time_seconds or 0) / 3600, 2),
            "avg_feedback_rating": round(row.avg_feedback_rating or 0, 2)
        })
    return results

def get_location_reports():
    """
    Location-based grievance reports:
    - Complaints per ward
    - Complaints per geo-location cluster
    """
    ward_data = (
        db.session.query(
            Grievance.ward_number,
            func.count(Grievance.id).label("total_complaints"),
            func.sum(case((Grievance.status == GrievanceStatus.CLOSED, 1), else_=0)).label("resolved"),
            func.sum(case((Grievance.status.notin_([GrievanceStatus.CLOSED, GrievanceStatus.REJECTED]), 1), else_=0)).label("pending")
        )
        .group_by(Grievance.ward_number)
        .all()
    )

    return [
        {
            "ward_number": row.ward_number or "Unknown",
            "total_complaints": int(row.total_complaints or 0),
            "resolved": int(row.resolved or 0),
            "pending": int(row.pending or 0)
        }
        for row in ward_data
    ]
