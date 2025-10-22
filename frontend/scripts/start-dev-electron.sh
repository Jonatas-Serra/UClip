#!/bin/bash
# Script para iniciar o Electron em modo desenvolvimento com todas as dependências

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
UCLIP_ROOT="$( cd "$PROJECT_ROOT/.." && pwd )"

echo "🚀 Iniciando UClip Frontend (Modo Desenvolvimento)"
echo "─────────────────────────────────────────────────"

# Verificar se o Vite está rodando
if ! lsof -i :5173 > /dev/null 2>&1; then
    echo "⚠️  Vite não está rodando na porta 5173"
    echo "📝 Execute em outro terminal:"
    echo "   cd $PROJECT_ROOT && npm run dev"
    echo ""
fi

# Verificar se a API está rodando
if ! lsof -i :8001 > /dev/null 2>&1; then
    echo "⚠️  API não está rodando na porta 8001"
    echo "📝 Execute em outro terminal:"
    echo "   cd $UCLIP_ROOT && PYTHONPATH=\$(pwd) python backend/cli/run_api.py"
    echo ""
fi

# Verificar se o listener está rodando
if ! pgrep -f "run_listener.py" > /dev/null; then
    echo "⚠️  Listener não está rodando"
    echo "📝 Execute em outro terminal:"
    echo "   cd $UCLIP_ROOT && PYTHONPATH=\$(pwd) python backend/cli/run_listener.py"
    echo ""
fi

echo "✓ Iniciando Electron com System Tray..."
export UCLIP_DEV=1
export DISPLAY=:0

cd "$PROJECT_ROOT"

# Usar xvfb-run se disponível para melhor compatibilidade
if command -v xvfb-run &> /dev/null; then
    xvfb-run -a npx electron . 2>&1 | tee /tmp/uclip-frontend-dev.log
else
    npx electron . 2>&1 | tee /tmp/uclip-frontend-dev.log
fi
