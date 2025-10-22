# 📖 UClip — Guia de Uso (Português)

Bem-vindo ao UClip! Este guia mostra como usar todos os recursos da aplicação.

**Índice:**
- [Interface Básica](#-interface-básica)
- [Atalhos de Teclado](#-atalhos-de-teclado)
- [Pesquisar Clips](#-pesquisar-clips)
- [Gerenciar Histórico](#-gerenciar-histórico)
- [Configurações](#-configurações)
- [Dicas & Truques](#-dicas--truques)

---

## 🎯 Interface Básica

Quando você abre o UClip (pressionando **Super+V**), verá:

```
┌─────────────────────────────────┐
│ 🔍 Pesquisar clips...           │  ← Caixa de busca
├─────────────────────────────────┤
│ ⚙️ | 📖 | 🌐                    │  ← Menu (Configurações, Sobre, Idioma)
├─────────────────────────────────┤
│ 📄 "Texto copiado há 2 min"     │  ← Clip (clique para copiar)
│ 🖼️ [Imagem] Há 5 min            │  ← Clip de imagem
│ 📄 "Outro texto..." Há 1 hora   │
└─────────────────────────────────┘
```

### Elementos Principais

| Elemento | Função |
|----------|--------|
| 🔍 Caixa de busca | Filtra clips por palavra-chave |
| 📄 Texto | Clip de texto (máx 200 caracteres vistos) |
| 🖼️ Imagem | Clip de imagem com prévia |
| ⏰ Timestamp | Quando o clip foi capturado |
| ⚙️ Ícone | Abre configurações |
| 📖 Ícone | Informações sobre o app |
| 🌐 Ícone | Muda idioma |

---

## ⌨️ Atalhos de Teclado

Quando o UClip está aberto:

| Atalho | Função |
|--------|--------|
| **↑ / ↓** | Navegar entre clips |
| **Enter** | Copiar clip selecionado |
| **Delete** | Deletar clip selecionado |
| **Esc** | Fechar UClip |
| **Ctrl+F** | Focar na caixa de busca |
| **Ctrl+A** | Selecionar todo texto de busca |

### Exemplo: Recuperar um clip antigo

1. Pressione **Super+V** → UClip abre
2. Digite `"palavra-chave"` na busca
3. Use **↑ / ↓** para navegar pelos resultados
4. Pressione **Enter** para copiar
5. Pressione **Esc** para fechar
6. Pressione **Ctrl+V** para colar em qualquer lugar

---

## 🔍 Pesquisar Clips

### Busca por Palavra

```
Digitar: "python"
↓
Resultados: Todos os clips com "python"
```

### Busca por Tipo

```
Digitar: "image" ou "imagem"
↓
Resultados: Apenas clips de imagem
```

### Busca por Data

```
Digitar: "today" ou "hoje"
↓
Resultados: Clips de hoje (em desenvolvimento)
```

### Dicas de Busca

- **Não case-sensitive**: "Python" = "python" = "PYTHON"
- **Palavras parciais**: "clip" encontra "clipboard"
- **Limpar busca**: Pressione Ctrl+A e Delete, ou clique no ❌

---

## 📦 Gerenciar Histórico

### Copiar um Clip

**Forma 1: Com mouse**
1. Abra UClip (Super+V)
2. Encontre o clip desejado (role ou pesquise)
3. Clique no clip
4. ✅ Copiado! O clip agora está na sua área de transferência

**Forma 2: Com teclado**
1. Abra UClip (Super+V)
2. Use **↑ / ↓** para navegar
3. Pressione **Enter**
4. ✅ Copiado!

### Deletar um Clip

**Permanentemente remover do histórico:**

1. Selecione o clip (↑ / ↓)
2. Pressione **Delete** (tecla Delete)
3. ✅ Clip removido

⚠️ **Aviso**: Não há undo! O clip é deletado para sempre.

### Limpar Todo o Histórico

**Remover todos os clips de uma vez:**

1. Abra UClip
2. Clique em **Menu** (⚙️) → **Limpar Histórico**
3. Confirme na dialog
4. ✅ Histórico limpo

---

## ⚙️ Configurações

### Acessar Configurações

1. Abra UClip (Super+V)
2. Clique em **⚙️ Configurações** no menu
3. Você verá as opções abaixo

### Opções Disponíveis

#### 🌐 Idioma
- **Português (Brasil)** → 🇧🇷
- **English** → 🇺🇸
- Mais idiomas em breve!

#### 🎨 Tema (em desenvolvimento)
- [ ] Claro (Light)
- [ ] Escuro (Dark)
- [ ] Automático (segue tema do sistema)

#### 📋 Copiar Automaticamente
- ☑️ Quando você seleciona um clip, copia automaticamente
- ☐ Você precisa clicar explicitamente em "Copiar"

#### 🗜️ Minimizar ao Copiar
- ☑️ UClip fecha automaticamente após copiar
- ☐ UClip fica aberto para mais ações

#### 🚀 Iniciar com o Sistema
- ☑️ UClip (backend) inicia quando você liga o PC
- ☐ Você precisa iniciar manualmente

#### ⌨️ Atalhos de Teclado
- Visualizar/customizar atalhos (em desenvolvimento)

---

## 💡 Dicas & Truques

### 1️⃣ Atalho Personalizado

Se não gosta de **Super+V**, pode mudar:

**GNOME:**
```bash
# Remova o atalho antigo
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[]"

# Crie um novo
# Settings → Keyboard → Custom Shortcuts
```

**KDE:**
```bash
# System Settings → Shortcuts → Custom Shortcuts
# Criar novo → Command → /usr/local/bin/uclip
```

### 2️⃣ Iniciar o Backend Automaticamente

Se esquece de iniciar o backend, configure como serviço:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/uclip-backend.service
```

Cole isso (ajuste USERNAME):

```ini
[Unit]
Description=UClip Backend
After=network.target

[Service]
Type=simple
User=USERNAME
WorkingDirectory=/home/USERNAME/Projetos/UClip
ExecStart=/home/USERNAME/Projetos/UClip/.venv/bin/python3 /home/USERNAME/Projetos/UClip/scripts/run_local.sh
Restart=on-failure

[Install]
WantedBy=default.target
```

Depois:
```bash
systemctl --user enable uclip-backend.service
systemctl --user start uclip-backend.service
```

### 3️⃣ Máximo de Clips no Histórico

O UClip armazena quantos clips você quiser (limitado por espaço em disco). Para limitar:

Edite `~/.local/share/uclip/config.json` (se existir):

```json
{
  "max_clips": 1000,
  "cleanup_days": 30
}
```

⚠️ Clips com mais de 30 dias serão deletados automaticamente.

### 4️⃣ Pasta de Backup

Seus clips são armazenados em:

```bash
~/.local/share/uclip/clipboard.db
```

Para fazer backup:

```bash
cp ~/.local/share/uclip/clipboard.db ~/Documentos/uclip-backup.db
```

### 5️⃣ Desabilitar Captura Temporariamente

Se precisa copiar algo sensível (senha, token), desabilite:

```bash
# Parar o backend
systemctl --user stop uclip-backend.service

# Fazer o que precisa (copiar senha, etc)

# Reiniciar
systemctl --user start uclip-backend.service
```

---

## 🐛 Problemas Comuns

### "O UClip não captura meu clip"

**Soluções:**

1. Verifique se o backend está rodando:
   ```bash
   curl http://127.0.0.1:8000/api/clips
   ```

2. Teste clipboard manualmente:
   ```bash
   echo "test" | xclip -selection clipboard
   xclip -selection clipboard -o
   ```

3. Reinicie backend:
   ```bash
   systemctl --user restart uclip-backend.service
   ```

### "O UClip fecha sozinho"

Pode ser a opção **"Minimizar ao Copiar"** ativa. Desative em Configurações.

### "Não encontro um clip antigo"

O clip pode ter sido deletado (>30 dias ou manual). Verifique:

1. Abra UClip
2. Pesquise por palavra-chave
3. Se não achar, foi deletado

### "UClip tá lento"

Se tem muitos clips (>5000), ele pode ficar lento.

Solução:

```bash
# Limpar histórico antigo
sqlite3 ~/.local/share/uclip/clipboard.db "DELETE FROM clips WHERE created_at < datetime('now', '-90 days')"
```

---

## 📞 Suporte

- 🐛 **Bug?** → [GitHub Issues](https://github.com/Jonatas-Serra/UClip/issues)
- 💬 **Dúvida?** → [GitHub Discussions](https://github.com/Jonatas-Serra/UClip/discussions)
- 📧 **Email** → jonatasserra@outlook.com

---

## 🎓 Próximos Passos

- Leia [docs/BUILD.md](BUILD.md) se quer contribuir
- Leia [docs/I18N_GUIDE.md](I18N_GUIDE.md) para adicionar novo idioma
- Veja [README.md](../README.md) para mais informações

---

*Última atualização: Outubro 2025*  
*Versão: 0.1.0*
