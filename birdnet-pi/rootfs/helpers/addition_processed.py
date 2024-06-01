# Code to modify the birdnet_analysis.py and restore the Processed folder
# The last 30 wav files are stored in a dynamic manner in the Processed folder

import re

def modify_code(original_file, modified_file):
    with open(original_file, 'r') as f:
        lines = f.readlines()

    # Define the modifications
    modifications = {
        'os.remove(file.file_name)': 'move_to_processed(file.file_name)',
        'def handle_reporting_queue(queue):': 'def handle_reporting_queue(queue):\n    conf = get_settings()\n    processed_dir = os.path.join(conf[\'RECS_DIR\'], \'Processed\')\n    os.makedirs(processed_dir, exist_ok=True)\n    user_id = pwd.getpwnam(os.getenv(\'USER\')).pw_uid\n    os.chown(processed_dir, user_id, user_id)',
        'import threading\nfrom queue import Queue\nfrom subprocess import CalledProcessError': 'import threading\nfrom queue import Queue\nfrom subprocess import CalledProcessError\nimport glob\nimport time\nimport pwd',
        'def move_to_processed(file_name):': 'def move_to_processed(file_name):\n    conf = get_settings()\n    processed_dir = os.path.join(conf[\'RECS_DIR\'], \'Processed\')\n    os.rename(file_name, os.path.join(processed_dir, os.path.basename(file_name)))\n    files = glob.glob(os.path.join(processed_dir, \'*\'))\n    files.sort(key=os.path.getmtime)\n    buffer_size = int(os.getenv(\'Processed_Buffer\', 30))\n    while len(files) > buffer_size:\n        os.remove(files.pop(0))'
    }

    # Apply the modifications
    modified_lines = []
    for line in lines:
        for original, modified in modifications.items():
            line = line.replace(original, modified)
        modified_lines.append(line)

    # Write the modified code to the new file
    with open(modified_file, 'w') as f:
        f.writelines(modified_lines)

# Use the function
modify_code('original.py', 'modified.py')
