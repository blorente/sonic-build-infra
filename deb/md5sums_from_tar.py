#!/usr/bin/env python3
"""Compute a dpkg `md5sums` control file by streaming a data tar.

Usage: md5sums_from_tar.py <data_tar> <out>
"""
import hashlib
import sys
import tarfile

_CHUNK = 1 << 20


def main():
    data_tar, out = sys.argv[1], sys.argv[2]
    lines = []
    with tarfile.open(data_tar, "r:*") as tf:
        for member in tf:
            if not (member.isfile() or member.islnk()):
                continue
            src = tf.extractfile(member)  # follows hardlinks to the target data
            digest = hashlib.md5()
            for chunk in iter(lambda: src.read(_CHUNK), b""):
                digest.update(chunk)
            rel = member.name[2:] if member.name.startswith("./") else member.name
            lines.append((rel, digest.hexdigest()))
    lines.sort()
    with open(out, "w") as fh:
        for rel, digest in lines:
            fh.write("%s  %s\n" % (digest, rel))


if __name__ == "__main__":
    main()
