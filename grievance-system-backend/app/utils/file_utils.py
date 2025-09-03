# app/utils/file_utils.py

import os
from werkzeug.utils import secure_filename
from flask import current_app
from mimetypes import guess_type

def allowed_file(filename):
    # Get MIME type of the file
    mime_type, _ = guess_type(filename)
    
    # Define allowed MIME types
    allowed_mime_types = [
        'image/jpeg',       # jpg/jpeg
        'image/png',        # png
        'application/pdf',  # pdf
        'text/plain',       # txt
        'video/mp4',        # mp4
        'video/quicktime'   # mov
    ]
    
    # Check file extension and MIME type
    return (
        '.' in filename and
        filename.rsplit('.', 1)[1].lower() in current_app.config['ALLOWED_EXTENSIONS'] and
        mime_type in allowed_mime_types
    )

def upload_files(files, grievance_id):
    uploaded_paths = []
    upload_folder = os.path.join(current_app.config['UPLOAD_FOLDER'], f'grievance_{grievance_id}')
    os.makedirs(upload_folder, exist_ok=True)
    
    if len(files) > 10:
        raise ValueError("Maximum 10 files allowed")
    
    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file_path = os.path.join(upload_folder, filename)
            file.save(file_path)
            file_size = os.path.getsize(file_path)
            uploaded_paths.append((file_path, filename.rsplit('.', 1)[1].lower(), file_size))
        else:
            raise ValueError("Invalid file type")
    
    return uploaded_paths

def upload_workproof(file, grievance_id):
    if not allowed_file(file.filename):
        raise ValueError("Invalid file type")
    
    upload_folder = os.path.join(current_app.config['UPLOAD_FOLDER'], f'workproof_{grievance_id}')
    os.makedirs(upload_folder, exist_ok=True)
    
    filename = secure_filename(file.filename)
    file_path = os.path.join(upload_folder, filename)
    file.save(file_path)
    return file_path