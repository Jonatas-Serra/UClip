#!/bin/bash

# 🧹 Script para limpar dados de desenvolvimento do UClip
# Uso: ./scripts/clean_dev_data.sh

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Limpando dados de desenvolvimento do UClip...${NC}\n"

CLEANED=0

# Limpar banco de dados
if [ -f "uclip.db" ] || [ -f "uclip.db-shm" ] || [ -f "uclip.db-wal" ]; then
    echo -e "${YELLOW}📂 Removendo arquivos de banco de dados...${NC}"
    rm -f uclip.db uclip.db-shm uclip.db-wal
    echo -e "${GREEN}   ✓ uclip.db* removidos${NC}"
    CLEANED=1
fi

# Limpar diretório de imagens na raiz
if [ -d "images" ]; then
    echo -e "${YELLOW}📂 Removendo diretório de imagens (raiz)...${NC}"
    rm -rf images
    echo -e "${GREEN}   ✓ images/ removido${NC}"
    CLEANED=1
fi

# Limpar diretório de imagens no backend
if [ -d "backend/images" ]; then
    echo -e "${YELLOW}📂 Removendo diretório de imagens (backend)...${NC}"
    rm -rf backend/images
    echo -e "${GREEN}   ✓ backend/images/ removido${NC}"
    CLEANED=1
fi

# Limpar __pycache__
if find . -type d -name "__pycache__" | grep -q .; then
    echo -e "${YELLOW}📂 Removendo diretórios __pycache__...${NC}"
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    echo -e "${GREEN}   ✓ __pycache__/ removidos${NC}"
    CLEANED=1
fi

# Limpar arquivos .pyc
if find . -type f -name "*.pyc" | grep -q .; then
    echo -e "${YELLOW}📂 Removendo arquivos .pyc...${NC}"
    find . -type f -name "*.pyc" -delete
    echo -e "${GREEN}   ✓ *.pyc removidos${NC}"
    CLEANED=1
fi

echo ""

if [ $CLEANED -eq 1 ]; then
    echo -e "${GREEN}✅ Limpeza concluída!${NC}"
else
    echo -e "${BLUE}ℹ️  Nenhum dado de desenvolvimento encontrado para limpar.${NC}"
fi

echo ""
echo -e "${BLUE}💡 Dica:${NC} Execute este script antes de fazer build ou commit de release."
