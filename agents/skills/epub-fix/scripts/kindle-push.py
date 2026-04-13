#!/usr/bin/env python3
"""
Push files to Kindle via MTP using calibre's library.
Run with: calibre-debug kindle-push.py -- <file1> [file2] ... [--dest fonts|documents]

Requires: Calibre installed, Kindle connected via USB, Calibre GUI closed.
"""
import sys
import os
from io import BytesIO


def main():
    args = sys.argv[1:]

    # Parse --dest flag
    dest_folder = "documents"
    if "--dest" in args:
        idx = args.index("--dest")
        dest_folder = args[idx + 1]
        args = args[:idx] + args[idx + 2:]

    files = args
    if not files:
        print("Usage: calibre-debug kindle-push.py -- <file1> [file2] ... [--dest fonts|documents]")
        sys.exit(1)

    # Validate files exist and warn about EPUBs
    has_epub = False
    for f in files:
        if not os.path.isfile(f):
            print(f"File not found: {f}")
            sys.exit(1)
        if f.lower().endswith('.epub') and dest_folder == "documents":
            has_epub = True

    if has_epub:
        print("WARNING: Kindle does not natively read EPUB. Use Calibre to convert")
        print("to AZW3/KFX and push via Calibre GUI instead. Only use this script")
        print("for fonts and non-book files.")
        print("Continue anyway? [y/N] ", end="", flush=True)
        if input().strip().lower() != "y":
            sys.exit(0)

    from calibre.devices.mtp.driver import MTP_DEVICE
    from calibre.devices.scanner import DeviceScanner

    s = DeviceScanner()
    s.scan()
    if not s.devices:
        print("No USB devices found. Is Kindle plugged in?")
        sys.exit(1)

    dev = MTP_DEVICE(None)
    dev.startup()
    devs = dev.detect_managed_devices(s.devices, force_refresh=True)
    if devs is None:
        print("No MTP device found. Is Calibre GUI closed?")
        sys.exit(1)

    dev.open(devs, "calibre")
    storage = list(dev.filesystem_cache.entries)[0]
    folder = dev.create_folder(storage, dest_folder)

    print(f"Connected to {devs}. Uploading to /{dest_folder}/...")

    for filepath in files:
        filename = os.path.basename(filepath)
        with open(filepath, "rb") as f:
            stream = BytesIO(f.read())
        dev.put_file(folder, filename, stream, stream.getbuffer().nbytes)
        print(f"  Uploaded: {filename}")

    dev.shutdown()
    print(f"Done. {len(files)} file(s) pushed.")


if __name__ == "__main__":
    main()
