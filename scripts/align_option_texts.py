from pathlib import Path
import re

# Standard descriptions
DESC = {
    "localdisks": "Local drives to mount (e.g., `sda1,sdb1,MYNAS`)",
    "networkdisks": "SMB shares to mount (e.g., `//SERVER/SHARE`)",
    "cifsusername": "SMB username for network shares",
    "cifspassword": "SMB password for network shares",
    "cifsdomain": "SMB domain for network shares",
    "log_level": "Log level (trace|debug|info|notice|warning|error|fatal)",
}

RE_TABLE = re.compile(r"\|\s*`(?P<opt>[^`]+)`\s*\|.*")


def process_file(path: Path):
    text = path.read_text(encoding="utf-8").splitlines()
    changed = False
    new_lines = []
    for line in text:
        m = RE_TABLE.match(line)
        if m:
            opt = m.group("opt")
            if opt in DESC:
                parts = line.split("|")
                if len(parts) >= 5:
                    parts[-2] = f" {DESC[opt]} "
                    new_line = "|".join(parts)
                    if new_line != line:
                        changed = True
                        line = new_line
        # Handle YAML example comments
        for opt, desc in DESC.items():
            if line.strip().startswith(f"{opt}:") and "#" in line:
                before, _ = line.split("#", 1)
                line = f"{before.strip()} # {desc}"
                changed = True
        new_lines.append(line)
    if changed:
        path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        return True
    return False


def main():
    repo_root = Path(__file__).resolve().parents[1]
    changed_files = []
    for config in repo_root.glob('*/config.json'):
        addon_dir = config.parent
        for doc_name in ('DOCS.md', 'README.md'):
            doc_path = addon_dir / doc_name
            if doc_path.exists():
                if process_file(doc_path):
                    changed_files.append(doc_path)
    if changed_files:
        print("Updated descriptions for:")
        for f in changed_files:
            print(f" - {f.relative_to(repo_root)}")
    else:
        print("No changes needed")

if __name__ == '__main__':
    main()
