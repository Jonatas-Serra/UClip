#!/bin/bash

# 📦 Script para criar e fazer push de uma release do UClip
# Uso: ./create_release.sh v0.1.0

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then
    echo -e "${RED}❌ Erro: Versão não especificada${NC}"
    echo "Uso: $0 v0.1.0"
    exit 1
fi

VERSION=$1

# Validar formato de versão
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Erro: Versão deve estar no formato v0.0.0${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Criando release ${VERSION}...${NC}\n"

# 0. Limpar dados de desenvolvimento
echo -e "${BLUE}0️⃣  Limpando dados de desenvolvimento...${NC}"
if [ -f "uclip.db" ]; then
    echo "   Removendo banco de dados de desenvolvimento"
    rm -f uclip.db uclip.db-shm uclip.db-wal
fi
if [ -d "images" ]; then
    echo "   Removendo diretório de imagens de desenvolvimento"
    rm -rf images
fi
if [ -d "backend/images" ]; then
    echo "   Removendo diretório de imagens do backend"
    rm -rf backend/images
fi
echo -e "${GREEN}   ✓ Dados de desenvolvimento limpos${NC}\n"

# 1. Atualizar package.json
NUMERIC_VERSION=${VERSION#v}
echo -e "${BLUE}1️⃣  Atualizando version em package.json...${NC}"
sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$NUMERIC_VERSION\"/" frontend/package.json

# 2. Fazer commit de versionamento
echo -e "${BLUE}2️⃣  Fazendo commit de versionamento...${NC}"
git add frontend/package.json
git commit -m "chore: bump version to $NUMERIC_VERSION" || true

# 3. Criar tag
echo -e "${BLUE}3️⃣  Criando tag ${VERSION}...${NC}"
git tag -a $VERSION -m "Release version $NUMERIC_VERSION" || {
    echo -e "${RED}❌ Tag já existe. Removendo e recriando...${NC}"
    git tag -d $VERSION
    git tag -a $VERSION -m "Release version $NUMERIC_VERSION"
}

# 4. Push da branch
echo -e "${BLUE}4️⃣  Fazendo push da branch main...${NC}"
git push origin main

# 5. Push da tag (isso ativa o workflow)
echo -e "${BLUE}5️⃣  Fazendo push da tag ${VERSION} (ativa GitHub Actions)...${NC}"
git push origin $VERSION

echo -e "${GREEN}✅ Release criada com sucesso!${NC}\n"
echo -e "${BLUE}📍 Acompanhe o build em:${NC}"
echo "   https://github.com/Jonatas-Serra/UClip/actions"
echo ""
echo -e "${BLUE}📦 Quando pronto, download de:${NC}"
echo "   https://github.com/Jonatas-Serra/UClip/releases/tag/${VERSION}"
echo ""
echo -e "${BLUE}💾 Seus usuários podem instalar com:${NC}"
echo "   wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/${VERSION}/UClip-${NUMERIC_VERSION}.AppImage"
echo "   chmod +x ~/UClip.AppImage"
echo "   ~/UClip.AppImage"
