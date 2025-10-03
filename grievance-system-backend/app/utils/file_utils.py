# app/utils/file_utils.py

import os
from werkzeug.utils import secure_filename
from flask import current_app
from mimetypes import guess_type

def allowed_file(filename):
    mime_type, _ = guess_type(filename)
    allowed_mime_types = [
        'image/jpeg',       
        'image/png',       
        'application/pdf',  
        'text/plain',       
        'video/mp4',        
        'video/quicktime'  
    ]
    return (
        '.' in filename and
        filename.rsplit('.', 1)[1].lower() in current_app.config['ALLOWED_EXTENSIONS'] and
        mime_type in allowed_mime_types
    )

def upload_files(files, grievance_id):
    uploaded_paths = []
    base_upload_folder = current_app.config['UPLOAD_FOLDER']
    relative_grievance_folder = f'grievance_{grievance_id}'
    absolute_grievance_folder = os.path.join(base_upload_folder, relative_grievance_folder)
    os.makedirs(absolute_grievance_folder, exist_ok=True)
    
    if len(files) > 10:
        raise ValueError("Maximum 10 files allowed")
    
    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            absolute_file_path = os.path.join(absolute_grievance_folder, filename)
            file.save(absolute_file_path)
            relative_file_path = os.path.join(relative_grievance_folder, filename).replace('\\', '/')
            
            file_size = os.path.getsize(absolute_file_path)
            uploaded_paths.append((relative_file_path, filename.rsplit('.', 1)[1].lower(), file_size))
        else:
            raise ValueError("Invalid file type")
    
    return uploaded_paths

def upload_workproof(file, grievance_id):
    if not allowed_file(file.filename):
        raise ValueError("Invalid file type")
    
    base_upload_folder = current_app.config['UPLOAD_FOLDER']
    relative_workproof_folder = f'workproof_{grievance_id}'
    absolute_workproof_folder = os.path.join(base_upload_folder, relative_workproof_folder)
    os.makedirs(absolute_workproof_folder, exist_ok=True)
    
    filename = secure_filename(file.filename)
    absolute_file_path = os.path.join(absolute_workproof_folder, filename)
    file.save(absolute_file_path)
    return os.path.join(relative_workproof_folder, filename).replace('\\', '/')