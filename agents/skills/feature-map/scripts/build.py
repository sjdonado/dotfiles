#!/usr/bin/env python3
"""Render a feature map from a framework-independent source inventory and evidence."""

import argparse
import base64
import json
import re
import struct
from html import escape
from pathlib import Path

TEMPLATE = Path(__file__).resolve().parents[1] / "assets" / "report.template.html"
PNG = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR"


def closure(roots, nodes):
    seen = set()
    stack = list(roots)
    while stack:
        file = stack.pop()
        if file not in seen:
            seen.add(file)
            stack.extend(edge["target"] for edge in nodes[file]["edges"])
    return sorted(seen)


def build_map(inventory, evidence):
    nodes = inventory["nodes"]
    consumers = {file: set() for file in nodes}
    for source, node in nodes.items():
        for edge in node["edges"]:
            target = edge["target"]
            if target not in nodes:
                raise ValueError(f"Unknown component target {target} from {source}")
            consumers[target].add(source)
        node["directConsumers"] = []
        node["affectedRoutes"] = []
        node["affectedThroughShell"] = []

    routes = inventory["routes"]
    route_ids = set()
    for route in routes:
        route_id, file, shell = route["id"], route["file"], route["shell"]
        if route_id in route_ids:
            raise ValueError(f"Repeated route ID: {route_id}")
        route_ids.add(route_id)
        if file not in nodes or any(item not in nodes for item in shell):
            raise ValueError(f"Unknown source or shell in route {route_id}")
        dependencies = [item for item in closure([file], nodes) if item != file]
        shell_dependencies = [item for item in closure(shell, nodes) if item not in shell]
        route["dependencies"] = dependencies
        route["shellDependencies"] = shell_dependencies
        route["library"] = [item for item in dependencies if nodes[item]["kind"] == "library"]
        for item in dependencies:
            nodes[item]["affectedRoutes"].append(route_id)
        if not route["layout"]:
            for item in set(shell + shell_dependencies):
                nodes[item]["affectedThroughShell"].append(route_id)

    for file, node in nodes.items():
        node["directConsumers"] = [item for item in nodes if item in consumers[file]]

    for file in inventory.get("auditedModules", []):
        if file not in nodes:
            raise ValueError(f"Unknown audited module: {file}")

    return {
        "schemaVersion": 1,
        "target": inventory["target"],
        "baseline": inventory["baseline"],
        "routes": routes,
        "nodes": nodes,
        "evidence": evidence,
        "existingCases": inventory.get("existingCases", []),
        "auditedModules": inventory.get("auditedModules", []),
    }


def render_gallery(report, output, presentation):
    routes = {route["id"]: route for route in report["routes"]}
    groups = {}
    cases = set()
    observed = set()
    labels = presentation.get("phaseLabels", {})

    for entry in report["evidence"]:
        case = entry["id"]
        if not re.fullmatch(r"[a-z0-9-]+", case) or case in cases:
            raise ValueError(f"Invalid or repeated evidence case: {case}")
        cases.add(case)
        route_id = entry["route"]
        if route_id not in routes:
            raise ValueError(f"Unmapped evidence route: {route_id}")
        route = routes[route_id]
        observed.add(route_id)
        relative_path = f"screens/{case}.png"
        if entry["image"] != relative_path:
            raise ValueError(f"Unexpected evidence image: {entry['image']}")
        image_path = output / relative_path
        if not image_path.resolve().is_relative_to(output.resolve()):
            raise ValueError(f"Evidence image escapes the output directory: {relative_path}")
        data = image_path.read_bytes()
        if len(data) < 24 or not data.startswith(PNG):
            raise ValueError(f"Expected a PNG: {relative_path}")
        width, height = struct.unpack_from(">II", data, 16)
        if not width or not height:
            raise ValueError(f"Invalid PNG dimensions: {relative_path}")
        preview = base64.b64encode(data).decode("ascii")
        phase = entry.get("phase", "")
        label = labels.get(phase, presentation.get("defaultPhaseLabel", phase))
        context = " · ".join(part for part in (route_id, label, "Before fix" if phase == "before-fix" else "") if part)
        groups.setdefault(route["feature"], []).append(f'''    <figure id="{escape(case)}">
      <img src="data:image/png;base64,{preview}" alt="{escape(entry["state"])}" width="{width}" height="{height}" decoding="async">
      <figcaption>
        <h3>{escape(entry["state"])}</h3>
        <p>{escape(entry["review"])}</p>
        <p class="context">{escape(context)}</p>
      </figcaption>
    </figure>''')

    sections = []
    for name, figures in groups.items():
        screenshots = "\n".join(figures)
        sections.append(f'''  <section>
    <h2>{escape(name)}</h2>
    <div class="screenshots">
{screenshots}
    </div>
  </section>''')
    summary = (
        f'{len(cases)} {report["target"]} observations across {len(observed)} screen entries, '
        "grouped by feature. The screen inventory and dependency graph are in the companion JSON."
    )
    return (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("<!-- TITLE -->", escape(presentation.get("title", "Feature map")))
        .replace("<!-- HEADING -->", escape(presentation.get("heading", "Feature map")))
        .replace("<!-- SUMMARY -->", escape(summary))
        .replace("<!-- SCREENSHOTS -->", "\n".join(sections))
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True, help="Directory containing evidence.json and screens/")
    args = parser.parse_args()
    try:
        inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
        evidence = json.loads((args.output / "evidence.json").read_text(encoding="utf-8"))
        report = build_map(inventory, evidence)
        html = render_gallery(report, args.output, inventory.get("presentation", {}))
        (args.output / "feature-map.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (args.output / "feature-map.html").write_text(html, encoding="utf-8")
    except (ValueError, TypeError, KeyError, OSError) as error:
        parser.exit(1, f"Feature map: {error}\n")
    print(f"{len(evidence)} captures, {len(report['routes'])} route entries, {len(report['nodes'])} source modules")


if __name__ == "__main__":
    main()
