import os

def save_dart_files_and_structure(root_dir, output_file):
    with open(output_file, "w", encoding="utf-8") as out:
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Write folder structure header
            relative_path = os.path.relpath(dirpath, root_dir)
            out.write(f"\n\n=== Folder: {relative_path} ===\n")
            
            # Write .dart file contents
            for file in filenames:
                if file.endswith(".dart"):
                    file_path = os.path.join(dirpath, file)
                    out.write(f"\n--- File: {file_path} ---\n")
                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            out.write(f.read())
                    except Exception as e:
                        out.write(f"\n[Error reading {file_path}: {e}]\n")


if __name__ == "__main__":
    # Change these paths before running
    source_folder = r"D:\Company_Data\PCMCApp\main_ui\lib"   # folder to search
    output_file = r"output.txt"      # single text file
    
    save_dart_files_and_structure(source_folder, output_file)
    print(f"✅ All .dart contents and folder structure saved to {output_file}")
