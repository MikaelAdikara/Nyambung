"""Ukur latensi dan kualitas kandidat scene AI pada foto uji yang tidak sensitif.

Manifest JSON adalah array berisi:
{"id":"main-mobil","image":"fixtures/mobil.jpg","allowed_symbols":[...],
 "expected":[{"word_id":"mobil","box":{"x":.1,"y":.2,"width":.3,"height":.4}}]}
"""

from __future__ import annotations

import argparse
import base64
import json
import statistics
import time
import urllib.error
import urllib.request
from pathlib import Path


def iou(a: dict, b: dict) -> float:
    ax1, ay1, ax2, ay2 = a["x"], a["y"], a["x"] + a["width"], a["y"] + a["height"]
    bx1, by1, bx2, by2 = b["x"], b["y"], b["x"] + b["width"], b["y"] + b["height"]
    intersection = max(0.0, min(ax2, bx2) - max(ax1, bx1)) * max(0.0, min(ay2, by2) - max(ay1, by1))
    union = a["width"] * a["height"] + b["width"] * b["height"] - intersection
    return intersection / union if union else 0.0


def score(expected: list[dict], candidates: list[dict]) -> tuple[int, int, int]:
    """Greedy one-to-one match: kata sama dan IoU >= 0,5."""
    available = set(range(len(candidates)))
    matches = 0
    for target in expected:
        ranked = sorted(
            ((iou(target["box"], candidates[index]["box"]), index) for index in available if candidates[index].get("word_id") == target["word_id"]),
            reverse=True,
        )
        if ranked and ranked[0][0] >= 0.5:
            matches += 1
            available.remove(ranked[0][1])
    return matches, len(expected), len(candidates)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    parser.add_argument("--child", required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--out", type=Path, default=Path("tools/.sim/scene-ai-benchmark.json"))
    args = parser.parse_args()

    rows = json.loads(args.manifest.read_text(encoding="utf-8"))
    results: list[dict] = []
    total_matches = total_expected = total_candidates = 0
    for row in rows:
        image_path = (args.manifest.parent / row["image"]).resolve()
        payload = json.dumps(
            {
                "consent": True,
                "image_mime": "image/jpeg",
                "image_base64": base64.b64encode(image_path.read_bytes()).decode(),
                "allowed_symbols": row["allowed_symbols"],
            }
        ).encode()
        request = urllib.request.Request(
            f"{args.base_url.rstrip('/')}/v1/children/{args.child}/scene-ai/analyze",
            data=payload,
            headers={"Authorization": f"Bearer {args.token}", "Content-Type": "application/json"},
        )
        started = time.perf_counter()
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                output = json.loads(response.read())
            elapsed_ms = round((time.perf_counter() - started) * 1000)
            matches, expected_count, candidate_count = score(row["expected"], output["candidates"])
            total_matches += matches
            total_expected += expected_count
            total_candidates += candidate_count
            results.append({"id": row["id"], "latency_ms": elapsed_ms, "matches": matches, "expected": expected_count, "candidates": candidate_count})
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            results.append({"id": row["id"], "error": type(exc).__name__})

    latencies = [row["latency_ms"] for row in results if "latency_ms" in row]
    report = {
        "cases": results,
        "successful_cases": len(latencies),
        "median_latency_ms": round(statistics.median(latencies)) if latencies else None,
        "word_box_recall_iou_0_5": total_matches / total_expected if total_expected else None,
        "matched": total_matches,
        "expected": total_expected,
        "candidates": total_candidates,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
