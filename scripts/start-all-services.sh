#!/bin/bash
# Script para iniciar todos os serviços do UClip em paralelo
# Uso: ./start-all-services.sh

set -e

UCLIP_ROOT="/home/jonatasserra/Projetos/UClip"
FRONTEND_ROOT="$UCLIP_ROOT/frontend"
LOG_DIR="/tmp"

echo "🚀 Iniciando UClip - Todos os Serviços"
echo "═══════════════════════════════════════"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar porta
check_port() {
    if lsof -i ":$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Função para matar processos antigos
cleanup_old() {
    echo "🧹 Limpando processos antigos..."
    pkill -f "run_api.py" || true
    pkill -f "run_listener.py" || true
    sleep 1
}

# Verificar se já está rodando
if check_port 8001; then
    echo -e "${YELLOW}⚠️  Porta 8001 (API) já em uso${NC}"
    read -p "Deseja usar a instância já rodando? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        cleanup_old
    fi
fi

# 1. Iniciar API
echo -e "${GREEN}▶ Iniciando API...${NC}"
cd "$UCLIP_ROOT"
nohup env PYTHONPATH="$UCLIP_ROOT" python backend/cli/run_api.py > "$LOG_DIR/uclip-api.log" 2>&1 &
API_PID=$!
echo -e "${GREEN}✓ API iniciada (PID: $API_PID)${NC}"

# Aguardar API ficar pronta
echo "⏳ Esperando API ficar pronta..."
for i in {1..30}; do
    if check_port 8001; then
        echo -e "${GREEN}✓ API respondendo${NC}"
        break
    fi
    sleep 1
done

# 2. Iniciar Listener
echo -e "${GREEN}▶ Iniciando Listener...${NC}"
nohup env PYTHONPATH="$UCLIP_ROOT" python backend/cli/run_listener.py > "$LOG_DIR/uclip-listener.log" 2>&1 &
LISTENER_PID=$!
echo -e "${GREEN}✓ Listener iniciado (PID: $LISTENER_PID)${NC}"

# 3. Iniciar Vite (se não estiver rodando)
if ! check_port 5173; then
    echo -e "${GREEN}▶ Iniciando Vite Dev Server...${NC}"
    cd "$FRONTEND_ROOT"
    nohup npm run dev > "$LOG_DIR/uclip-vite.log" 2>&1 &
    VITE_PID=$!
    echo -e "${GREEN}✓ Vite iniciado (PID: $VITE_PID)${NC}"
    echo "⏳ Esperando Vite ficar pronto..."
    sleep 5
else
    echo -e "${YELLOW}✓ Vite já rodando na porta 5173${NC}"
fi

# 4. Iniciar Electron (no terminal atual para melhor visualização)
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Serviços Backend Iniciados!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "📋 Resumo:"
echo -e "  API: ${GREEN}http://127.0.0.1:8001${NC}"
echo -e "  Vite: ${GREEN}http://localhost:5173${NC}"
echo -e "  Listener: ${GREEN}Rodando${NC}"
echo ""
echo "🖥️  Iniciando Electron Frontend..."
echo -e "${YELLOW}Procure o ícone na bandeja do sistema (canto superior)${NC}"
echo ""

export UCLIP_DEV=1
export DISPLAY=:0

cd "$FRONTEND_ROOT"
npx electron . 2>&1 | tee "$LOG_DIR/uclip-frontend-main.log"

# Se chegou aqui, o Electron fechou
echo ""
echo -e "${YELLOW}Electron foi fechado${NC}"
echo "Deseja encerrar os outros serviços? (s/n)"
read -n 1 -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "🛑 Encerrando serviços..."
    kill $API_PID 2>/dev/null || true
    kill $LISTENER_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Serviços encerrados${NC}"
else
    echo ""
    echo "✓ Serviços continuando rodando em background"
    echo "Logs disponíveis em:"
    echo "  - $LOG_DIR/uclip-api.log"
    echo "  - $LOG_DIR/uclip-listener.log"
    echo "  - $LOG_DIR/uclip-vite.log"
fi
