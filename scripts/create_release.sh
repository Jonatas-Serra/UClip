#!/bin/bash
# 📦 Criar e disparar release do UClip
# Uso: ./scripts/create_release.sh v0.2.0

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "${1:-}" ]; then
    echo -e "${RED}❌ Versão não especificada${NC}"
    echo "Uso: $0 v0.2.0"
    exit 1
fi

VERSION=$1
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Formato inválido (esperado vX.Y.Z): $VERSION${NC}"
    exit 1
fi

NUMERIC_VERSION=${VERSION#v}

# 0. workspace tem de estar limpo
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}❌ Workspace sujo. Commit ou stash antes.${NC}"
    git status --short
    exit 1
fi

# 1. tag não pode existir
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo -e "${RED}❌ Tag $VERSION já existe localmente${NC}"
    exit 1
fi

# 2. limpa dados de dev
echo -e "${BLUE}🧹 Limpando dados de desenvolvimento...${NC}"
bash "$(dirname "$0")/clean_dev_data.sh"

# 3. bump version
echo -e "${BLUE}📝 Bumpando versão para $NUMERIC_VERSION...${NC}"
python3 "$(dirname "$0")/bump_version.py" "$NUMERIC_VERSION"

# 4. commit
echo -e "${BLUE}💾 Commit de versionamento...${NC}"
git add -A
git commit -m "chore: bump version to $NUMERIC_VERSION"

# 5. tag
echo -e "${BLUE}🏷️  Criando tag $VERSION...${NC}"
git tag -a "$VERSION" -m "Release $NUMERIC_VERSION"

# 6. push
echo -e "${BLUE}🚀 Push branch + tag...${NC}"
git push origin "$(git rev-parse --abbrev-ref HEAD)"
git push origin "$VERSION"

echo ""
echo -e "${GREEN}✅ Release disparada!${NC}"
echo ""
echo "  Acompanhe:   https://github.com/Jonatas-Serra/UClip/actions"
echo "  Quando OK:   https://github.com/Jonatas-Serra/UClip/releases/tag/$VERSION"
