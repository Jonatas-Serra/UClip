#!/usr/bin/env python3
"""Single source of truth para versão. Roda no create_release antes do commit.

Uso:
    python3 scripts/bump_version.py 0.2.0
"""
import json
import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: bump_version.py <versão>", file=sys.stderr)
        return 1

    version = sys.argv[1].lstrip("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        print(f"Versão inválida: {version} (esperado X.Y.Z)", file=sys.stderr)
        return 1

    root = pathlib.Path(__file__).parent.parent.resolve()

    # 1) frontend/package.json
    pkg_path = root / "frontend" / "package.json"
    pkg = json.loads(pkg_path.read_text())
    pkg["version"] = version
    pkg_path.write_text(json.dumps(pkg, indent=2) + "\n")
    print(f"  ✓ {pkg_path.relative_to(root)}")

    # 2) backend/app.py
    app_path = root / "backend" / "app.py"
    text = app_path.read_text()
    text = re.sub(
        r'(FastAPI\([^)]*version=)"[^"]+"',
        rf'\1"{version}"',
        text,
        count=1,
    )
    app_path.write_text(text)
    print(f"  ✓ {app_path.relative_to(root)}")

    # 3) scripts/install.sh
    install_path = root / "scripts" / "install.sh"
    if install_path.exists():
        text = install_path.read_text()
        text = re.sub(r'APP_VERSION="[^"]+"', f'APP_VERSION="{version}"', text, count=1)
        install_path.write_text(text)
        print(f"  ✓ {install_path.relative_to(root)}")

    # 4) README.md  (atualiza qualquer ocorrência de VERSION=X.Y.Z)
    readme = root / "README.md"
    if readme.exists():
        text = readme.read_text()
        new_text = re.sub(r"VERSION=\d+\.\d+\.\d+", f"VERSION={version}", text)
        if new_text != text:
            readme.write_text(new_text)
            print(f"  ✓ {readme.relative_to(root)}")

    print(f"\nVersão bumpada para {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
