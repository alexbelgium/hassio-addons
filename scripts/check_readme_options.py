import json
import os
from pathlib import Path

def get_schema_options(config_path):
    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    schema = data.get('schema', {})
    return list(schema.keys())

def find_doc_file(addon_dir):
    # Prefer DOCS.md if exists, else README.md
    docs = addon_dir / 'DOCS.md'
    readme = addon_dir / 'README.md'
    if docs.exists():
        return docs
    if readme.exists():
        return readme
    return None

def check_addon(addon_dir):
    config_path = addon_dir / 'config.json'
    if not config_path.exists():
        return []
    options = get_schema_options(config_path)
    doc_file = find_doc_file(addon_dir)
    if not doc_file:
        return [(addon_dir.name, 'NO_DOC_FILE', opt) for opt in options]
    with open(doc_file, 'r', encoding='utf-8') as f:
        content = f.read()
    missing = []
    for opt in options:
        if f'`{opt}`' not in content:
            missing.append((addon_dir.name, str(doc_file.relative_to(Path.cwd())), opt))
    return missing

def main():
    repo_root = Path(__file__).resolve().parents[1]
    missing_all = []
    for config_path in repo_root.glob('*/config.json'):
        addon_dir = config_path.parent
        missing_all.extend(check_addon(addon_dir))
    if missing_all:
        print('Missing options in documentation:')
        for addon, doc, opt in missing_all:
            print(f"{addon}: {opt} not documented in {doc}")
    else:
        print('All addon options documented.')

if __name__ == '__main__':
    main()
