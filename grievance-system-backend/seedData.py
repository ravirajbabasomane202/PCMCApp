# seed_data.py

from datetime import datetime, timedelta, timezone
from app import create_app, db
from app.models import (
    User, Role, Grievance, GrievanceStatus, Priority,
    MasterSubjects, MasterAreas, MasterCategories
)

# Create Flask app context
app = create_app()

with app.app_context():
    # Drop & recreate (⚠️ optional – remove drop_all if you want to keep data)
    # db.drop_all()
    # db.create_all()

    # --- Master Data ---
    roads = MasterCategories(name="Roads", description="Road-related issues")
    sanitation = MasterCategories(name="Sanitation", description="Garbage, sewage, etc.")
    db.session.add_all([roads, sanitation])
    db.session.commit()

    subject_potholes = MasterSubjects(name="Potholes", description="Report potholes on roads", category=roads)
    subject_garbage = MasterSubjects(name="Garbage", description="Uncollected garbage", category=sanitation)
    db.session.add_all([subject_potholes, subject_garbage])
    db.session.commit()

    area_central = MasterAreas(name="Central Ward", description="Main city area")
    area_north = MasterAreas(name="North Ward", description="Northern side of the city")
    db.session.add_all([area_central, area_north])
    db.session.commit()

    # --- Users ---
    # admin = User(name="Admin User", email="admin@test.com", role=Role.ADMIN, department_id=area_central.id)
    # admin.set_password("admin123")

    # citizen = User(name="John Citizen", email="citizen@test.com", role=Role.CITIZEN, department_id=area_north.id)
    # citizen.set_password("citizen123")

    # staff = User(name="Field Staff", email="staff@test.com", role=Role.FIELD_STAFF, department_id=area_central.id)
    # staff.set_password("staff123")

    # db.session.add_all([admin, citizen, staff])
    # db.session.commit()

    # --- Grievances ---
    grievance1 = Grievance(
        citizen_id=1,
        subject_id=subject_potholes.id,
        area_id=area_central.id,
        title="Big pothole near market",
        description="A large pothole causing traffic jams.",
        ward_number="12",
        status=GrievanceStatus.NEW,
        priority=Priority.HIGH,
        latitude=18.5204,
        longitude=73.8567,
        address="Market Road, Central Ward",
        escalation_level=0
    )

    grievance2 = Grievance(
        citizen_id=1,
        subject_id=subject_garbage.id,
        area_id=area_north.id,
        title="Garbage not collected",
        description="Garbage has been piling up for 3 days.",
        ward_number="7",
        status=GrievanceStatus.IN_PROGRESS,
        priority=Priority.MEDIUM,
        assigned_to=3,
        assigned_by=4,
        latitude=18.5304,
        longitude=73.8667,
        address="Street 21, North Ward",
        escalation_level=1,
        created_at=datetime.now(timezone.utc) - timedelta(days=2)
    )

    db.session.add_all([grievance1, grievance2])
    db.session.commit()

    print("✅ Sample data inserted successfully!")
