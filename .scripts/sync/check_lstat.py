import os

root = "/Volumes/QNDB"

with open("bad_paths.txt", "w") as out:
    for dirpath, dirnames, filenames in os.walk(root, onerror=lambda e: out.write(f"WALK ERROR: {e}\n")):
        for name in dirnames + filenames:
            path = os.path.join(dirpath, name)

            try:
                os.lstat(path)
            except Exception as e:
                out.write(f"{path}\n")
                out.write(f"    {repr(e)}\n")
