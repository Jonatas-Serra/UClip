#!/bin/bash
# Script para iniciar o backend do UClip

PROJECT_DIR="/home/jonatasserra/Projetos/UClip"
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"

# Verificar se o venv existe
if [ ! -f "$VENV_PYTHON" ]; then
    echo "❌ Erro: Venv não encontrado em $VENV_PYTHON"
    exit 1
fi

# Matar processos antigos se existirem
pkill -9 -f "backend.cli.run_api" 2>/dev/null || true
pkill -9 -f "backend.cli.run_listener" 2>/dev/null || true
sleep 1

# Iniciar API
echo "🚀 Iniciando API..."
cd "$PROJECT_DIR"
nohup env PYTHONPATH="$PROJECT_DIR" "$VENV_PYTHON" backend/cli/run_api.py > /tmp/uclip-api.log 2>&1 &
API_PID=$!
echo "✓ API iniciada (PID: $API_PID)"

# Aguardar API estar pronta
sleep 2

# Verificar se API respondeu
if curl -s http://127.0.0.1:8001/health > /dev/null 2>&1; then
    echo "✓ API respondendo"
else
    echo "❌ API não respondeu em 127.0.0.1:8001"
    tail -20 /tmp/uclip-api.log
    exit 1
fi

# Iniciar Listener
echo "🚀 Iniciando Listener de Clipboard..."
nohup env PYTHONPATH="$PROJECT_DIR" "$VENV_PYTHON" backend/cli/run_listener.py > /tmp/uclip-listener.log 2>&1 &
LISTENER_PID=$!
echo "✓ Listener iniciado (PID: $LISTENER_PID)"

echo ""
echo "✅ Backend iniciado com sucesso!"
echo "   API: http://127.0.0.1:8001"
echo "   Logs:"
echo "   - API: tail -f /tmp/uclip-api.log"
echo "   - Listener: tail -f /tmp/uclip-listener.log"

