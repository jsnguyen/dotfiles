#!/usr/bin/env python3
"""Mirror Chosen/Rejected between sibling JPG and RAW folders.

Preview:  python3 sync_photo_choices.py /path/to/photos
Apply:    python3 sync_photo_choices.py /path/to/photos --apply

The path defaults to the current directory. Match exact filename stems;
for example, DSC_1234.NEF matches DSC_1234.JPG. Ignore sidecars such as .xmp.
Files move by renaming, with no copying or checksums.
Leave these folders unchanged while the script runs: destination checks
and renames are separate operations. Cross-filesystem moves stop with an error.
"""

import argparse
from pathlib import Path

EXTENSIONS = {
    "JPG": {".jpg", ".jpeg"},
    "RAW": {".nef", ".nrw", ".dng", ".cr2", ".cr3", ".arw", ".raf",
            ".orf", ".rw2", ".pef", ".srw", ".raw"},
}
LABELS = ("Chosen", "Rejected")


def find_pairs(folder):
    """Find folders containing both JPG and RAW, without following symlinks."""
    children = sorted(folder.iterdir())
    has_pair = {"JPG", "RAW"}.issubset(child.name for child in children)
    if has_pair:
        yield folder
    for child in children:
        if has_pair and child.name in EXTENSIONS:
            continue  # The planner handles these photo folders and their labels.
        if not child.is_symlink() and child.is_dir():
            yield from find_pairs(child)


def file_state(path):
    """Record lightweight metadata to detect changes since the preview."""
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"Expected a regular file, not a symlink: {path}")
    info = path.stat()
    return info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns


def read_photos(folder, extensions):
    """Map each filename stem to its (path, label); an empty label is unsorted."""
    if folder.is_symlink():
        raise ValueError(f"Refusing a linked photo folder: {folder}")
    photos = {}
    for label in ("",) + LABELS:
        directory = folder / label
        if directory.is_symlink():
            raise ValueError(f"Refusing a linked photo folder: {directory}")
        if label and not directory.exists():
            continue  # Chosen and Rejected are optional.
        for path in sorted(directory.iterdir()):
            if path.name.startswith(".") or path.suffix.lower() not in extensions:
                continue
            if path.stem in photos:
                previous, _ = photos[path.stem]
                raise ValueError(f"Ambiguous copies of {path.stem}:\n    {previous}\n    {path}")
            photos[path.stem] = (path, label)
    return photos


def check_destination(destination):
    """Reject an existing destination, including a dangling symlink."""
    if destination.parent.is_symlink():
        raise ValueError(f"Refusing a linked destination folder: {destination.parent}")
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(f"Destination already exists: {destination}")


def build_plan(root):
    """Plan (reference, source, destination) moves from classified photos."""
    moves, snapshot, notices = [], {}, []
    total_images = 0
    pairs = list(find_pairs(root))
    for parent in pairs:
        notices.append(f"[PAIR] {parent.relative_to(root)}")
        jpgs = read_photos(parent / "JPG", EXTENSIONS["JPG"])
        raws = read_photos(parent / "RAW", EXTENSIONS["RAW"])
        image_stems = jpgs.keys() | raws.keys()
        total_images += len(image_stems)  # Count a JPG/RAW match as one image.
        for path, label in list(jpgs.values()) + list(raws.values()):
            snapshot[path] = file_state(path)

        for stem in sorted(image_stems):
            matches = [photos[stem] for photos in (jpgs, raws) if stem in photos]
            labels = {label for path, label in matches if label}
            if not labels:
                continue
            if len(labels) > 1:
                raise ValueError(f"Chosen/Rejected conflict for {stem} in {parent}")
            if len(matches) == 1:
                path, label = matches[0]
                notices.append(f"[SKIP] No matching counterpart: {path.relative_to(root)}")
                continue

            target_label = labels.pop()
            reference = next(path for path, label in matches if label == target_label)
            for source, current_label in matches:
                if not current_label:
                    destination = source.parent / target_label / source.name
                    check_destination(destination)
                    moves.append((reference, source, destination))
    return moves, snapshot, notices, len(pairs), total_images


def move_photo(source, destination, expected_state):
    """Rename one file after rechecking it, then verify its location and size."""
    if file_state(source) != expected_state:
        raise ValueError(f"Source changed since preview: {source}")
    original_size = source.stat().st_size
    check_destination(destination)
    # Create a missing category only when a file is actually moved into it.
    destination.parent.mkdir(exist_ok=True)
    check_destination(destination)
    source.rename(destination)
    if source.exists() or destination.stat().st_size != original_size:
        raise ValueError(f"Move verification failed; inspect: {source} and {destination}")


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("root", nargs="?", default=".", help="Top-level photo folder (default: .)")
    parser.add_argument("--apply", action="store_true", help="Apply after preview and confirmation")
    args = parser.parse_args()
    root = Path(args.root).expanduser().resolve()
    moved = 0
    applying = False
    try:
        if not root.is_dir():
            raise ValueError(f"Not a directory: {root}")
        print(f"Root: {root}\nMode: {'APPLY (confirmation required)' if args.apply else 'PREVIEW ONLY'}", flush=True)
        plan, snapshot, notices, pairs, total_images = build_plan(root)
        for notice in notices:
            print(notice)
        if not plan:
            print("Nothing to move. No changes made.")
        elif not args.apply:
            print("Preview only; no changes made. Run again with --apply to proceed.")

        # Print the complete plan once, after scanning all folder pairs.
        plan_lines = [f"\nPlan ({pairs} JPG/RAW pair(s) scanned):"]
        chosen = 0
        rejected = 0
        for reference, source, destination in plan:
            if destination.parent.name == "Chosen":
                label = "CHOSEN"
                chosen += 1
            else:
                label = "REJECT"
                rejected += 1
            plan_lines.append(
                f"[{label}] {reference.name} | "
                f"{source.relative_to(root)} -> {destination.relative_to(root)}"
            )
        # Total includes sorted and unsorted images, counting each format pair once.
        summary = f"{chosen} Chosen | {rejected} Rejects | {total_images} Total"
        plan_lines.append(f"\n{summary}")
        print("\n".join(plan_lines), flush=True)

        if not plan or not args.apply:
            return 0
        if input("Type MOVE to apply exactly this plan: ").strip() != "MOVE":
            print("Cancelled. No changes made.")
            return 0
        # Re-scan after confirmation so an edited classification invalidates the plan.
        fresh_plan, fresh_snapshot, _, _, _ = build_plan(root)
        if fresh_plan != plan or fresh_snapshot != snapshot:
            raise ValueError("Photos or classifications changed. Run a fresh preview.")
        applying = True
        for reference, source, destination in plan:
            print(f"[MOVING] {source.relative_to(root)}\n      -> {destination.relative_to(root)}", flush=True)
            move_photo(source, destination, snapshot[source])
            moved += 1
            print("[OK] Moved; location and size checked.", flush=True)
        print(f"\nDone. {moved} file(s) moved.")
        print(summary)
        return 0
    except (OSError, ValueError, EOFError, KeyboardInterrupt) as error:
        print(f"\n[STOP] {error or 'Interrupted.'}", flush=True)
        if applying:
            print(f"{moved} completed move(s). Earlier moves are not rolled back.")
            print("Inspect the last [MOVING] paths before running again.")
        else:
            print("No files or folders changed.")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
