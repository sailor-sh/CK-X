#!/usr/bin/env python3
"""
Validate a generated lab directory structure and assessment references.

Checks:
- Required files exist: config.json, assessment.json, answers.md
- Verification steps reference script filenames (not paths)
- Referenced validation scripts exist under scripts/validation
"""

import json
import os
import sys
import argparse


def eprint(*args):
    print(*args, file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="kubelingo/out", help="Output root (default: kubelingo/out)")
    ap.add_argument("--lab-category", required=True, help="Lab category (ckad|cka|cks|other)")
    ap.add_argument("--lab-id", required=True, help="Lab numeric id, e.g. 003")
    args = ap.parse_args()

    base = os.path.join(args.root, "facilitator", "assets", "exams", args.lab_category, args.lab_id)
    ok = True

    print(f"Validating lab at: {base}")
    if not os.path.isdir(base):
        eprint("- ERROR: lab directory not found")
        return 2

    # Required files
    req = [
        os.path.join(base, "config.json"),
        os.path.join(base, "assessment.json"),
        os.path.join(base, "answers.md"),
    ]
    for p in req:
        if not os.path.exists(p):
            eprint(f"- ERROR: missing required file: {p}")
            ok = False
        else:
            print(f"- OK: {os.path.relpath(p, base)}")

    # Scripts
    val_dir = os.path.join(base, "scripts", "validation")
    if not os.path.isdir(val_dir):
        eprint("- ERROR: validation directory missing: scripts/validation")
        ok = False
    else:
        print("- OK: scripts/validation present")

    # Check assessment verification references
    assessment_path = os.path.join(base, "assessment.json")
    try:
        with open(assessment_path, "r") as f:
            assessment = json.load(f)
    except Exception as e:
        eprint(f"- ERROR: cannot read assessment.json: {e}")
        return 2

    questions = assessment.get("questions", [])
    if not isinstance(questions, list) or not questions:
        eprint("- ERROR: assessment.json has no questions[]")
        return 2

    for q in questions:
        vlist = q.get("verification", [])
        if not isinstance(vlist, list) or not vlist:
            eprint("- ERROR: question has no verification steps")
            ok = False
            continue
        for v in vlist:
            fname = str(v.get("verificationScriptFile", "")).strip()
            if not fname:
                eprint("- ERROR: empty verificationScriptFile")
                ok = False
                continue
            # Must be a filename, not a path
            if os.path.basename(fname) != fname:
                eprint(f"- ERROR: verificationScriptFile should be a filename, got: {fname}")
                ok = False
            fpath = os.path.join(val_dir, os.path.basename(fname))
            if not os.path.exists(fpath):
                eprint(f"- ERROR: missing script under scripts/validation: {os.path.basename(fname)}")
                ok = False
            else:
                print(f"- OK: verification script present: {os.path.basename(fname)}")

    if ok:
        print("Validation: SUCCESS")
        return 0
    else:
        eprint("Validation: FAILED")
        return 1


if __name__ == "__main__":
    sys.exit(main())

