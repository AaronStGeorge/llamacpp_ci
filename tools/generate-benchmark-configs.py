#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXPORT_GRAPH_OPS = REPO_ROOT / "build-llama-hrx" / "bin" / "export-graph-ops"
DEFAULT_CONFIG_ROOT = REPO_ROOT / "benchmark-configs"
MUL_MAT_OP = 29


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"\.gguf$", "", value)
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def parse_op_line(line: str) -> dict[str, object]:
    parts = line.split()
    if len(parts) < 24:
        raise RuntimeError(f"Malformed graph-op line: {line}")

    op = int(parts[0])
    dst_type = int(parts[1])
    dst_ne = [int(v) for v in parts[2:6]]
    dst_nb = [int(v) for v in parts[6:10]]
    op_params = [int(v) for v in parts[10:23]]
    n_src = int(parts[23])

    src_start = 24
    sources = []
    for index in range(n_src):
        base = src_start + index * 9
        if len(parts) < base + 9:
            raise RuntimeError(f"Malformed source block in graph-op line: {line}")
        sources.append(
            {
                "type": int(parts[base]),
                "ne": [int(v) for v in parts[base + 1 : base + 5]],
                "nb": [int(v) for v in parts[base + 5 : base + 9]],
            }
        )

    name = " ".join(parts[src_start + n_src * 9 :])
    if name == "-":
        name = ""

    return {
        "op": op,
        "type": dst_type,
        "ne": dst_ne,
        "nb": dst_nb,
        "op_params": op_params,
        "sources": sources,
        "name": name,
    }


def write_jsonl(path: Path, rows: list[dict[str, object]]) -> None:
    path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n")


def run_export(args: argparse.Namespace, ops_path: Path) -> None:
    cmd = [
        str(args.export_graph_ops),
        "-m",
        str(args.model),
        "-p",
        args.prompt,
        "-n",
        str(args.n_predict),
        "-o",
        str(ops_path),
    ]
    if args.extra_arg:
        cmd.extend(args.extra_arg)

    subprocess.run(cmd, cwd=REPO_ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate benchmark config files from a GGUF using export-graph-ops."
    )
    parser.add_argument("model", type=Path)
    parser.add_argument("--name", default=None, help="Model config directory name")
    parser.add_argument("--config-root", type=Path, default=DEFAULT_CONFIG_ROOT)
    parser.add_argument("--export-graph-ops", type=Path, default=DEFAULT_EXPORT_GRAPH_OPS)
    parser.add_argument("--prompt", default="hello")
    parser.add_argument("--n-predict", type=int, default=1)
    args, extra_arg = parser.parse_known_args()
    if extra_arg and extra_arg[0] == "--":
        extra_arg = extra_arg[1:]
    args.extra_arg = extra_arg

    model_name = args.name or slugify(args.model.name)
    out_dir = args.config_root / model_name
    out_dir.mkdir(parents=True, exist_ok=True)

    ops_txt = out_dir / "ops.txt"
    ops_jsonl = out_dir / "ops.jsonl"
    mul_mat_txt = out_dir / "mul_mat.txt"
    mul_mat_jsonl = out_dir / "mul_mat.jsonl"

    run_export(args, ops_txt)

    lines = [line for line in ops_txt.read_text().splitlines() if line.strip()]
    rows = [parse_op_line(line) for line in lines]
    mul_mat_pairs = [(line, row) for line, row in zip(lines, rows) if row["op"] == MUL_MAT_OP]

    write_jsonl(ops_jsonl, rows)
    mul_mat_txt.write_text("\n".join(line for line, _ in mul_mat_pairs) + "\n")
    write_jsonl(mul_mat_jsonl, [row for _, row in mul_mat_pairs])

    print(f"wrote {ops_txt}")
    print(f"wrote {ops_jsonl}")
    print(f"wrote {mul_mat_txt}")
    print(f"wrote {mul_mat_jsonl}")


if __name__ == "__main__":
    main()
