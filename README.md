# PCMC Grievance System

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

A full-stack web and mobile application designed to manage public grievances efficiently. The system allows citizens to submit complaints, track their status, and provide feedback, while enabling administrators, member heads, and field staff to manage and resolve these grievances.

## 📋 Table of Contents

- [Features](#-features)
- [Project Structure](#-project-structure)
- [Technologies](#-technologies)
- [Setup Instructions](#-setup-instructions)
  - [Backend Setup (Flask)](#backend-setup-flask)
  - [Frontend Setup (Flutter)](#frontend-setup-flutter)
- [Super Admin Features](#-super-admin-features)
- [API Endpoints](#-api-endpoints)
- [Running the Application](#-running-the-application)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### 👥 Citizen Features
- Submit grievances with file attachments (images, PDFs, etc.)
- Track grievance status and view progress
- Provide feedback and ratings for resolved grievances
- Multilingual support (English, Marathi, Hindi)

### 👨‍💼 Member Head Features
- View and assign grievances to field staff
- Escalate grievances to higher levels

### 🛠️ Field Staff Features
- View assigned grievances
- Upload work proof and update grievance status

### 🔧 Admin Features
- Manage users, subjects, areas, and system configurations
- View advanced KPIs, audit logs, and user histories
- Generate reports in Excel and PDF formats

### ⚡ Super Admin Features (Company-Only)
- Full control over all users, including other super admins
- Hidden from non-super-admin users
- Toggle maintenance mode to stop the app for all non-super-admin users

### 🔒 Security
- JWT-based authentication with role-based access control
- Google OAuth for login
- File upload validation (max 10 files, 50MB total, specific formats)

### 🌐 Localization
- Supports English, Marathi, and Hindi via Flutter's localization system

## 📁 Project Structure

```
PCMCApp/
├── grievance-system-backend/      # Flask backend
│   ├── app/
│   │   ├── __init__.py           # Flask app initialization
│   │   ├── config.py             # Configuration settings
│   │   ├── extensions.py         # OAuth initialization
│   │   ├── models.py             # Database models
│   │   ├── routes/               # API routes
│   │   │   ├── superadmin_routes.py  # Super admin routes
│   │   │   └── ...               # Other route files
│   │   ├── services/             # Business logic
│   │   ├── utils/                # Utilities
│   │   └── schemas/              # Data validation schemas
│   ├── addConfig.py              # Script to insert master configurations
│   ├── addData.py                # Script to insert master areas
│   ├── addData_Subject.py        # Script to insert master subjects
│   ├── create_database.py        # Script to reset and create database tables
│   ├── create_super_admin.py     # Script to create super admin
│   ├── run.py                    # Entry point to run Flask app
│   ├── seedData.py               # Script to seed sample data
│   ├── testusers.py              # Script to create test users
│   ├── test_all_routes.py        # Script to test API routes
│   └── uploads/                  # Folder for file uploads
└── main_ui/                      # Flutter frontend
    ├── lib/
    │   ├── firebase_options.dart # Firebase configuration
    │   ├── main.dart             # Flutter app entry point
    │   ├── routes.dart           # App navigation routes
    │   ├── l10n/                 # Localization files
    │   ├── models/               # Data models
    │   ├── providers/            # State management (Riverpod)
    │   ├── screens/              # UI screens
    │   ├── services/             # Services
    │   ├── utils/                # Utilities
    │   └── widgets/              # Reusable UI components
    └── pubspec.yaml              # Flutter dependencies
```

## 🛠️ Technologies

### Backend
- **Flask** - Python web framework
- **SQLAlchemy** - ORM for database management
- **Flask-JWT-Extended** - JWT authentication
- **Authlib** - OAuth for Google login
- **SQLite** - Default database (supports PostgreSQL/MySQL)
- **ReportLab** - PDF generation
- **Pandas** - Excel report generation

### Frontend
- **Flutter** - Cross-platform UI framework
- **Firebase** - Authentication and storage
- **Riverpod** - State management
- **Flutter Localizations** - Multilingual support
- **File Picker** - File uploads

## 🚀 Setup Instructions

### Backend Setup (Flask)

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd PCMCApp/grievance-system-backend
   ```

2. **Create a Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install flask flask-sqlalchemy flask-jwt-extended authlib python-dotenv pandas reportlab
   ```

4. **Set Up Environment Variables**
   
   Create a `.env` file in the `grievance-system-backend` directory:
   ```
   SECRET_KEY=your-secret-key
   JWT_SECRET_KEY=your-jwt-secret-key
   DATABASE_URL=sqlite:///app.db
   GOOGLE_CLIENT_ID=your-google-client-id
   GOOGLE_CLIENT_SECRET=your-google-client-secret
   ```
   
   Generate secure keys using:
   ```bash
   python -c 'import secrets; print(secrets.token_hex(16))'
   ```

5. **Initialize the Database**
   
   Run the following scripts in order:
   ```bash
   python create_database.py
   python addConfig.py
   python addData.py
   python addData_Subject.py
   python seedData.py
   python testusers.py
   python create_super_admin.py
   ```

6. **Run the Flask App**
   ```bash
   python run.py
   ```
   
   The backend runs at http://127.0.0.1:5000.

### Frontend Setup (Flutter)

1. **Install Flutter**
   
   Follow the official [Flutter installation guide](https://flutter.dev/docs/get-started/install).

2. **Navigate to Frontend Directory**
   ```bash
   cd PCMCApp/main_ui
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add your app for Web, Android, iOS, etc.
   - Update `lib/firebase_options.dart` with the generated configuration
   - Enable Firebase Authentication (Email/Password and Google Sign-In) and Firebase Storage

5. **Run the Flutter App**
   ```bash
   flutter run
   ```
   
   Choose a device (browser, emulator, or physical device) to run the app.

## 👑 Super Admin Features

The super admin is a special role (`SUPER_ADMIN`) designed for internal company use:

- **Hidden from Other Users**: Not visible in user listings or histories to non-super-admin users
- **Full User Control**: Can list, edit, and delete all users, including other super admins
- **Maintenance Mode**: Can toggle the app into maintenance mode, blocking all non-super-admin access

### Implementation Details

**Backend Changes:**
- Added `SUPER_ADMIN` to Role enum in `app/models.py`
- Created `app/routes/superadmin_routes.py` with endpoints for maintenance mode and user management
- Modified `app/__init__.py` to register the superadmin blueprint and add maintenance mode enforcement
- Updated admin routes to filter out super admins for non-super-admins
- Added `create_super_admin.py` to create the default super admin

**Usage:**
1. Run `python create_super_admin.py` to create the super admin
2. Login as super admin via `/auth/login` with `superadmin@company.com`
3. Use `/superadmin/toggle_maintenance` to enable/disable maintenance mode

> **Note**: Change the super admin password immediately and store secrets securely in `.env`.

## 📡 API Endpoints

### Authentication
- `POST /auth/login` - Authenticate user and return JWT token
- `POST /auth/register` - Register a new user
- `GET /auth/me` - Get current user details
- `POST /auth/otp/send` - Send OTP for verification
- `POST /auth/otp/verify` - Verify OTP
- `POST /auth/guest-login` - Guest login without credentials

### Grievances
- `POST /grievances/` - Submit a new grievance (citizen)
- `GET /grievances/mine` - List user's grievances (citizen)
- `GET /grievances/assigned` - List assigned grievances (field staff)
- `POST /grievances/<id>/accept` - Accept a grievance (field staff)
- `POST /grievances/<id>/reject` - Reject a grievance with reason
- `POST /grievances/<id>/close` - Close a grievance
- `POST /grievances/<id>/escalate` - Escalate a grievance
- `PUT /grievances/<id>/reassign` - Reassign a grievance
- `POST /grievances/<id>/feedback` - Submit feedback (citizen)
- `POST /grievances/<id>/workproof` - Upload work proof (field staff)

### Admin
- `GET /admins/dashboard` - Admin dashboard with KPIs
- `GET /admins/users` - List users (excludes super admins for non-super-admins)
- `GET /admins/users/<id>/history` - Get user grievance history
- `GET /admins/areas` - List areas
- `POST /admins/areas` - Add a new area
- `GET /admins/subjects` - List subjects
- `POST /admins/subjects` - Add a new subject
- `GET /admins/configs` - List configurations
- `POST /admins/configs` - Add a new configuration
- `PUT /admins/configs/<key>` - Update a configuration
- `GET /admins/reports` - Generate reports (Excel/PDF)
- `GET /admins/audit-logs` - View audit logs

### Super Admin
- `POST /superadmin/toggle_maintenance` - Enable/disable maintenance mode
- `GET /superadmin/users` - List all users (including super admins)
- `PUT /superadmin/users/<id>` - Update any user
- `DELETE /superadmin/users/<id>` - Delete any user

### Other
- `GET /areas` - List master areas (public)
- `GET /subjects` - List master subjects (public)
- `GET /settings/settings` - Get user settings
- `POST /settings/settings` - Update user settings
- `POST /notifications/register` - Register for notifications

## ▶️ Running the Application

1. **Start the Backend**
   ```bash
   cd grievance-system-backend
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   python run.py
   ```

2. **Start the Frontend**
   ```bash
   cd main_ui
   flutter run
   ```

3. **Access the App**
   - Web: Open http://localhost:5000 (backend) and the Flutter app URL
   - Mobile: Use an emulator or physical device via Flutter

## 🧪 Testing

### Backend Testing
Run the test script to test all API endpoints:
```bash
python test_all_routes.py
```

This script tests routes for different roles (citizen, member_head, field_staff, admin).

### Frontend Testing
Use Flutter's testing framework:
```bash
flutter test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a pull request

Please ensure code follows PEP 8 (Python) and Flutter style guidelines. Add tests for new features.

## 📄 License


---

For any questions or support, please contact the development team.
