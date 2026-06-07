#!/usr/bin/env python3

import importlib.util
import json
import os
import sys
from pathlib import Path


def main() -> None:
    hrx_src_dir = Path(os.environ["HRX_SRC_DIR"])
    rocm_root = Path(os.environ["HRX_ROCM_ROOT"])
    cache_dir = Path(os.environ["HRX_DOWNLOAD_CACHE_DIR"])
    extra_artifacts = os.environ["HRX_EXTRA_ROCM_ARTIFACTS"].split()

    spec = importlib.util.spec_from_file_location(
        "hrx_ci_core_linux", hrx_src_dir / "build_tools" / "ci_core_linux.py"
    )
    ci = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = ci
    spec.loader.exec_module(ci)

    manifest_path = rocm_root / ".hrx-rocm-artifacts.json"
    manifest = json.loads(manifest_path.read_text())
    bucket = manifest["bucket"]
    prefix = f"{manifest['run_id']}-{manifest['platform']}/"

    s3 = ci.create_s3_client()
    available = ci.list_prefix(s3, bucket, prefix)
    selected, missing = ci.select_available(available, prefix, extra_artifacts)
    if missing:
        raise RuntimeError(
            "Missing required extra ROCm artifacts:\n  " + "\n  ".join(missing)
        )

    print("Extra ROCm artifacts selected:")
    for obj in selected:
        print(f"  {obj.key} ({obj.size / 1024 / 1024:.1f} MiB)")

    cache_dir.mkdir(parents=True, exist_ok=True)
    for obj in selected:
        archive_path = ci.download_one(s3, bucket, obj, cache_dir)
        checksum = ci.download_checksum(s3, bucket, obj.key, archive_path)
        ci.verify_checksum(archive_path, checksum)
        ci.log(f"  ++ Flattening {archive_path.name}")
        ci.flatten_therock_artifact(archive_path, rocm_root)


if __name__ == "__main__":
    main()
