# # create_users.py
# from app import create_app, db
# from app.models import User, Role
# from datetime import datetime, timezone

# def create_test_users():
#     users = [
#         {
#             "name": "Test Citizen",
#             "email": "citizen@test.com",
#             "phone_number": "+1234567890",
#             "password": "password123",
#             "role": Role.CITIZEN,
#             "department_id": None
#         },
#         {
#             "name": "Test Member Head",
#             "email": "memberhead@test.com",
#             "phone_number": "+1234567891",
#             "password": "password123",
#             "role": Role.MEMBER_HEAD,
#             "department_id": 1  # Assumes area ID 1 exists
#         },
#         {
#             "name": "Test Field Staff",
#             "email": "fieldstaff@test.com",
#             "phone_number": "+1234567892",
#             "password": "password123",
#             "role": Role.FIELD_STAFF,
#             "department_id": 1
#         },
#         {
#             "name": "Test Admin",
#             "email": "admin@test.com",
#             "phone_number": "+1234567893",
#             "password": "password123",
#             "role": Role.ADMIN,
#             "department_id": None
#         }
#     ]

#     for user_data in users:
#         # Check if user already exists
#         if User.query.filter_by(email=user_data["email"]).first():
#             print(f"User {user_data['email']} already exists, skipping.")
#             continue
        
#         user = User(
#             name=user_data["name"],
#             email=user_data["email"],
#             phone_number=user_data["phone_number"],
#             role=user_data["role"],
#             department_id=user_data["department_id"],
#             created_at=datetime.now(timezone.utc),
#             updated_at=datetime.now(timezone.utc)
#         )
#         user.set_password(user_data["password"])
#         db.session.add(user)
#         print(f"Created user: {user_data['name']} ({user_data['role'].value})")
    
#     db.session.commit()
#     print("✅ All users created successfully!")

# if __name__ == "__main__":
#     app = create_app()
#     with app.app_context():
#         create_test_users()








# create_users.py
from app import create_app, db
from app.models import User, Role
from datetime import datetime, timezone

def create_test_users():
    users = [
        {
            "name": "Gest Staff2",
            "email": "Gest@test.com2",
            "phone_number": "+2234567898",
            "password": "password123",
            "role": Role.FIELD_STAFF,
            "department_id": 1
        },
        {
            "name": "Gest Staff3",
            "email": "Gest@test.com3",
            "phone_number": "+3234567894",
            "password": "password123",
            "role": Role.FIELD_STAFF,
            "department_id": 1
        },
        {
            "name": "Gest Staff4",
            "email": "Gest@test.com4",
            "phone_number": "+4234567895",
            "password": "password123",
            "role": Role.FIELD_STAFF,
            "department_id": 1
        }
    ]

    for user_data in users:
        # Check if user already exists
        if User.query.filter_by(email=user_data["email"]).first():
            print(f"User {user_data['email']} already exists, skipping.")
            continue
        
        user = User(
            name=user_data["name"],
            email=user_data["email"],
            phone_number=user_data["phone_number"],
            role=user_data["role"],
            department_id=user_data["department_id"],
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        user.set_password(user_data["password"])
        db.session.add(user)
        print(f"Created user: {user_data['name']} ({user_data['role'].value})")
    
    db.session.commit()
    print("✅ All users created successfully!")

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        create_test_users()