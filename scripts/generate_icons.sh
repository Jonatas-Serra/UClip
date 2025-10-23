#!/bin/bash

# Script para gerar ícones em vários tamanhos
# Uso: ./scripts/generate_icons.sh <original_image.png>

if [ -z "$1" ]; then
    echo "Uso: $0 <caminho_da_imagem_original.png>"
    echo "Exemplo: $0 ~/Downloads/uclip-icon.png"
    exit 1
fi

SOURCE_IMAGE="$1"
OUTPUT_DIR="frontend/buildResources"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Arquivo não encontrado: $SOURCE_IMAGE"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "❌ Diretório não encontrado: $OUTPUT_DIR"
    exit 1
fi

echo "🖼️  Gerando ícones a partir de: $SOURCE_IMAGE"
echo ""

# Tamanhos necessários para Electron
SIZES=(16 24 32 48 64 128 256 512 1024)

for size in "${SIZES[@]}"; do
    output_file="$OUTPUT_DIR/icon-${size}x${size}.png"
    echo "⏳ Gerando icon-${size}x${size}.png..."
    convert "$SOURCE_IMAGE" -resize "${size}x${size}!" -background none -gravity center -extent "${size}x${size}" "$output_file"
    if [ $? -eq 0 ]; then
        echo "   ✅ Criado: $output_file"
    else
        echo "   ❌ Erro ao criar: $output_file"
    fi
done

echo ""
echo "✅ Ícones gerados com sucesso!"
echo ""
echo "📍 Arquivos criados em: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/icon-*.png | awk '{print "   " $9 " (" $5 ")"}'
