#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_results(path: Path) -> dict[str, dict[str, object]]:
    rows: dict[str, dict[str, object]] = {}
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        row = json.loads(line)
        case = row.get("case")
        if not isinstance(case, str):
            raise RuntimeError(f"{path}:{line_no}: missing string case")
        rows[case] = row
    return rows


def pct(delta: float, base: float) -> float:
    return 100.0 * delta / base if base else 0.0


def rate(row: dict[str, object]) -> tuple[str, float]:
    if "flops" in row:
        return ("tflops", float(row["flops"]) / 1e12)
    if "bandwidth_gb_s" in row:
        return ("gb_s", float(row["bandwidth_gb_s"]))
    return ("rate", 0.0)


def case_name(row: dict[str, object], fallback: str) -> str:
    op = row.get("op")
    dtype = row.get("type")
    ne = row.get("ne")
    src0_type = row.get("src0_type")
    src0_ne = row.get("src0_ne")
    src1_type = row.get("src1_type")
    src1_ne = row.get("src1_ne")
    if isinstance(op, str) and isinstance(dtype, str) and isinstance(ne, list):
        parts = [op, f"dst={dtype}{shape(ne)}"]
        if isinstance(src0_type, str) and isinstance(src0_ne, list):
            parts.append(f"a={src0_type}{shape(src0_ne)}")
        if isinstance(src1_type, str) and isinstance(src1_ne, list):
            parts.append(f"b={src1_type}{shape(src1_ne)}")
        return " ".join(parts)
    return fallback


def shape(values: list[object]) -> str:
    return "[" + "x".join(str(v) for v in values) + "]"


def print_table(rows: list[dict[str, object]]) -> None:
    headers = ["case", "base us", "cand us", "delta", "metric", "base", "cand", "status"]
    widths = [44, 10, 10, 9, 8, 10, 10, 10]
    fmt = "  ".join(f"{{:<{width}}}" for width in widths)
    print(fmt.format(*headers))
    print(fmt.format(*["-" * width for width in widths]))
    for row in rows:
        print(
            fmt.format(
                str(row["case"])[: widths[0]],
                row["base_us"],
                row["cand_us"],
                row["delta"],
                row["metric"],
                row["base_rate"],
                row["cand_rate"],
                row["status"],
            )
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compare op perf JSONL files and fail on timing regressions."
    )
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument(
        "--max-regression-pct",
        type=float,
        default=5.0,
        help="Allowed candidate time_us increase per case before failing",
    )
    parser.add_argument(
        "--require-all-cases",
        action="store_true",
        help="Fail if any baseline case is missing from the candidate",
    )
    args = parser.parse_args()

    baseline = load_results(args.baseline)
    candidate = load_results(args.candidate)

    failures: list[str] = []
    table_rows: list[dict[str, object]] = []
    missing: list[str] = []
    for case in sorted(baseline):
        if case not in candidate:
            message = case_name(baseline[case], case)
            if args.require_all_cases:
                failures.append(f"{message}: missing from candidate")
            missing.append(message)
            continue

        base = baseline[case]
        cand = candidate[case]
        base_us = float(base["time_us"])
        cand_us = float(cand["time_us"])
        delta_pct = pct(cand_us - base_us, base_us)
        base_metric, base_rate = rate(base)
        cand_metric, cand_rate = rate(cand)
        metric = base_metric if base_metric == cand_metric else f"{base_metric}/{cand_metric}"
        status = "ok"

        if delta_pct > args.max_regression_pct:
            status = "regress"
            failures.append(
                f"{case_name(base, case)}: {cand_us:.3f} us vs {base_us:.3f} us "
                f"({delta_pct:+.2f}%, limit +{args.max_regression_pct:.2f}%)"
            )

        table_rows.append(
            {
                "case": case_name(base, case),
                "base_us": f"{base_us:.3f}",
                "cand_us": f"{cand_us:.3f}",
                "delta": f"{delta_pct:+.2f}%",
                "metric": metric,
                "base_rate": f"{base_rate:.3f}",
                "cand_rate": f"{cand_rate:.3f}",
                "status": status,
            }
        )

    print_table(table_rows)

    if missing:
        print("\nMissing candidate cases:")
        for case in missing:
            print(f"  {case}")

    extra = [case_name(candidate[case], case) for case in sorted(set(candidate) - set(baseline))]
    if extra:
        print("\nExtra candidate cases:")
        for case in extra:
            print(f"  {case}")

    if failures:
        print("\nRegressions:")
        for failure in failures:
            print(f"  {failure}")
        raise SystemExit(1)

    print("\nNo timing regressions exceeded the threshold.")


if __name__ == "__main__":
    main()
