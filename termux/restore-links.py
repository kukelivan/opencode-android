"""Restore Git symlink placeholders only in an internal Termux working copy."""
import os
import pathlib
import subprocess
import sys

source = pathlib.Path(sys.argv[1]).resolve()
target = pathlib.Path(sys.argv[2]).resolve()
if source == target or str(target).startswith(("/storage/", "/sdcard/")):
    raise SystemExit("Restore links only in a separate internal Termux working copy")
git = ["git", "-C", str(source), "-c", f"safe.directory={source}"]
entries = subprocess.check_output(git + ["ls-files", "--stage", "-z"]).split(b"\0")
restored = 0
for entry in entries:
    if not entry.startswith(b"120000 "):
        continue
    metadata, name = entry.split(b"\t", 1)
    file = target / os.fsdecode(name)
    if file.is_symlink() or not file.exists():
        continue
    link = subprocess.check_output(git + ["cat-file", "blob", metadata.split()[1].decode()])
    # A real edited file must not be overwritten as if it were a placeholder.
    if file.read_bytes() != link:
        continue
    file.unlink()
    file.symlink_to(os.fsdecode(link))
    restored += 1
print(f"Restored {restored} Git symbolic links in {target}")
