import os
import sys

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.readlines()

def write_file(file_path, content):
    with open(file_path, 'w') as file:
        file.writelines(content)

def process_code(lines, max_files):
    processed_lines = []
    for line in lines:
        # Add the import statement for shutil if it's not already there
        if 'import os.path' in line and 'import shutil' not in lines:
            processed_lines.append('import shutil\n')
        processed_lines.append(line)

        # Modify the process_file function to include the conf parameter
        if 'def process_file(file_name, report_queue):' in line:
            processed_lines[-1] = 'def process_file(file_name, report_queue, conf):\n'

        # Modify the handle_reporting_queue function to include the conf parameter and the new logic
        if 'def handle_reporting_queue(queue):' in line:
            processed_lines[-1] = 'def handle_reporting_queue(queue, conf):\n'
        if 'os.remove(file.file_name)' in line:
            indent = ' ' * (len(line) - len(line.lstrip()))
            processed_lines.append(f"{indent}# Move the file to the 'Processed' folder\n")
            processed_lines.append(f"{indent}processed_dir = os.path.join(conf['RECS_DIR'], 'Processed')\n")
            processed_lines.append(f"{indent}if not os.path.exists(processed_dir):\n")
            processed_lines.append(f"{indent}    os.makedirs(processed_dir)\n")
            processed_lines.append(f"{indent}shutil.move(file.file_name, processed_dir)\n")
            processed_lines.append(f"{indent}\n")
            processed_lines.append(f"{indent}# Maintain the file count in the 'Processed' folder\n")
            processed_lines.append(f"{indent}maintain_file_count(processed_dir, max_files)\n")
            processed_lines.append(f"{indent}\n")
            continue  # Skip the original line that removes the file

        # Add the new maintain_file_count function at the end of the file
        if 'if __name__' in line and not any('def maintain_file_count' in l for l in processed_lines):
            processed_lines.append('\n')
            processed_lines.append('def maintain_file_count(directory, max_files):\n')
            processed_lines.append('    files = [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith(\'.wav\')]\n')
            processed_lines.append('    files.sort(key=lambda x: os.path.getmtime(x))\n')
            processed_lines.append('\n')
            processed_lines.append('    while len(files) > max_files:\n')
            processed_lines.append('        os.remove(files.pop(0))\n')
            processed_lines.append('\n')

    return processed_lines

# Hardcoded path to the birdnet_analysis.py file
file_path = os.path.expanduser('~/BirdNET-Pi/scripts/birdnet_analysis.py')

# Get the maximum number of processed files from the environment variable
max_files = int(os.environ.get('Processed_Files', 15))

# If the environment variable is set to 0, exit the script
if max_files == 0:
    print("The 'Processed_Files' environment variable is set to 0. Exiting without making changes.")
    sys.exit(0)

# Read the original code
original_lines = read_file(file_path)

# Process the code
modified_lines = process_code(original_lines, max_files)

# Write the modified code back to the same file
write_file(file_path, modified_lines)

# Ensure the 'Processed' directory exists and is owned by the user
processed_dir = os.path.join(os.path.dirname(file_path), 'Processed')
if not os.path.exists(processed_dir):
    os.makedirs(processed_dir)
os.chown(processed_dir, os.getuid(), os.getgid())

print(f"The code has been modified and saved to {file_path}")
