import os

def save_py_files_and_structure(root_dir, output_file):
    with open(output_file, "w", encoding="utf-8") as out:
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Write folder structure header
            relative_path = os.path.relpath(dirpath, root_dir)
            out.write(f"\n\n=== Folder: {relative_path} ===\n")
            
            # Write .py file contents (ignore .pyc)
            for file in filenames:
                if file.endswith(".py") and not file.endswith(".pyc"):
                    file_path = os.path.join(dirpath, file)
                    out.write(f"\n--- File: {file_path} ---\n")
                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            out.write(f.read())
                    except Exception as e:
                        out.write(f"\n[Error reading {file_path}: {e}]\n")


if __name__ == "__main__":
    # Change these paths before running
    source_folder = r"D:\Company_Data\PCMCApp\grievance-system-backend"   # folder to search
    output_file = r"output_py_files.txt"                 # single text file
    
    save_py_files_and_structure(source_folder, output_file)
    print(f"✅ All .py contents and folder structure saved to {output_file}")
