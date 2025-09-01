from app import create_app, db  # adjust if your app factory is named differently

app = create_app()

with app.app_context():
    db.drop_all()
    db.create_all()
    print("Database reset and tables created successfully!")
