# addConfig.py
from app import create_app, db
from app.models import MasterConfig, Priority
from datetime import datetime

def insert_master_configs():
    configs = [
        ("MAX_ESCALATION_LEVEL", "3"),
        ("SLA_CLOSURE_DAYS", "7"),
        ("DEFAULT_PRIORITY", Priority.MEDIUM.value),  # Use enum value
    ]

    inserted, updated = 0, 0
    for key, value in configs:
        config = MasterConfig.query.filter_by(key=key).first()
        if config:
            config.value = value
            config.updated_at = datetime.utcnow()
            updated += 1
        else:
            new_config = MasterConfig(key=key, value=value)
            db.session.add(new_config)
            inserted += 1

    db.session.commit()
    print(f"✅ Inserted {inserted}, Updated {updated} master_configs successfully!")

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        insert_master_configs()