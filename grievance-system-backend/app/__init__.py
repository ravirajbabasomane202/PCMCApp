# app/__init__.py

from flask import Flask, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_mail import Mail
from .config import Config
from flask_cors import CORS
from .extensions import oauth

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
mail = Mail()
import logging
# oauth is defined in extensions.py

def create_app():
    logging.basicConfig(level=logging.DEBUG)
    logger = logging.getLogger(__name__)
    app = Flask(__name__)
    
    app.config.from_object(Config)

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    mail.init_app(app)
    oauth.init_app(app)
    cors_origins = ["http://localhost:*", "http://127.0.0.1:*", "http://localhost:5500", "http://127.0.0.1:5500", "https://pcmcapp.onrender.com"]
    CORS(app, resources={r"/*": {
        "origins": cors_origins,
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Authorization", "Content-Type"],
        "expose_headers": ["*"],
        "supports_credentials": True
    }})
    logger.debug(f"CORS configured for origins: {', '.join(cors_origins)}")
    # Register Google OAuth client
    oauth.register(
        name='google',
        client_id=app.config.get('GOOGLE_CLIENT_ID'),
        client_secret=app.config.get('GOOGLE_CLIENT_SECRET'),
        server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
        client_kwargs={'scope': 'openid email profile'}
    )

    # Create upload folder if not exists
    import os
    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])

    # Add a route to serve uploaded files
    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename, as_attachment=False)

    # Import and register blueprints
    from .routes.auth_routes import auth_bp
    from .routes.grievance_routes import grievance_bp
    from .routes.user_routes import user_bp
    from .routes.admin_routes import admin_bp
    # from .routes.notification_routes import notification_bp
    from .routes.public import public_bp
    from .routes.settings_routes import settings_bp
    from .routes.field_routes import fieldStaff
    app.register_blueprint(fieldStaff)
    app.register_blueprint(public_bp)
    # app.register_blueprint(notification_bp, url_prefix='/notifications')

    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(grievance_bp, url_prefix='/grievances')
    app.register_blueprint(user_bp, url_prefix='/users')
    app.register_blueprint(admin_bp, url_prefix='/admins')
    app.register_blueprint(settings_bp, url_prefix='/settings')
    return app