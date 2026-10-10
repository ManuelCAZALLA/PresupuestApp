#!/usr/bin/env bash
# Prepara Claude Code a partir de la configuración neutral del repositorio.
# Codex lee AGENTS.md, .agents/skills y .codex/agents directamente: no necesita nada más.
# Uso: bash scripts/setup-agents.sh   (desde cualquier carpeta)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1) Skills: .claude/skills apunta a .agents/skills
mkdir -p .claude
if [ -e .claude/skills ] && [ ! -L .claude/skills ]; then
  echo "Aviso: .claude/skills ya existe y no es un enlace; no lo toco." >&2
else
  ln -sfn ../.agents/skills .claude/skills
fi

# 2) Subagentes: genera .claude/agents/*.md desde .codex/agents/*.toml
python3 - <<'PY'
import pathlib, sys
try:
    import tomllib
except ModuleNotFoundError:
    sys.exit("Hace falta Python 3.11 o superior (tomllib).")

src = pathlib.Path(".codex/agents")
dst = pathlib.Path(".claude/agents")
dst.mkdir(parents=True, exist_ok=True)
for f in sorted(src.glob("*.toml")):
    d = tomllib.loads(f.read_text(encoding="utf-8"))
    name = d["name"].replace("_", "-")
    desc = d["description"].replace("\n", " ").strip()
    lines = ["---", f"name: {name}", f"description: {desc}"]
    if d.get("sandbox_mode") == "read-only":
        lines.append("tools: Read, Grep, Glob")
    lines += ["---", "", d["developer_instructions"].strip(), ""]
    (dst / f"{name}.md").write_text("\n".join(lines), encoding="utf-8")
    print("generado", dst / f"{name}.md")
PY
echo "Listo. Revisa .claude/agents y .claude/skills."
