# 📦 Releases - UClip

## Como as releases funcionam

O UClip usa **GitHub Actions** para gerar releases automaticamente quando você faz um push de uma tag no formato `v*` (ex: `v0.1.0`, `v0.2.0`).

### ⚙️ Workflow Automático

Quando você cria uma tag e faz push:

1. **Build** - O GitHub Actions constrói automaticamente:
   - ✅ AppImage (executável único para Linux)
   - ✅ DEB (pacote para Debian/Ubuntu)

2. **Release** - Cria uma release no GitHub com os arquivos

3. **Assets** - Os arquivos ficam disponíveis para download

## 🚀 Guia de Releases do UClip

Este documento explica como criar e publicar releases do UClip.

## 📋 Processo de Release

### 1️⃣ Preparação

Antes de criar uma release, certifique-se de que:

- ✅ Todos os testes estão passando
- ✅ A documentação está atualizada
- ✅ O CHANGELOG.md foi atualizado com as mudanças
- ✅ A versão no `frontend/package.json` está correta

### 2️⃣ Criar uma Tag

```bash
# Atualizar a versão no package.json
cd frontend
npm version patch  # ou minor, ou major

# Criar e publicar a tag
git add package.json package-lock.json
git commit -m "chore: bump version to v0.1.1"
git tag v0.1.1
git push origin main
git push origin v0.1.1
```

### 3️⃣ GitHub Actions (Automático)

Quando você faz push de uma tag começando com `v`, o GitHub Actions automaticamente:

1. **Instala dependências** (Node.js, Python, sistema)
2. **Build do frontend** com Vite
3. **Prepara o app** para empacotamento
4. **Gera os pacotes**:
   - `UClip-{version}.deb` (Debian/Ubuntu)
   - `UClip-{version}.AppImage` (Universal Linux)
5. **Renomeia os arquivos** para o padrão correto
6. **Cria a release** no GitHub com os arquivos anexados
7. **Adiciona descrição** com instruções de instalação

### 4️⃣ Verificar a Release

1. Acesse: `https://github.com/Jonatas-Serra/UClip/releases`
2. Verifique se a release foi criada
3. Confirme que os arquivos `.deb` e `.AppImage` foram anexados
4. Teste os links de download

## 🧪 Testar Localmente

Antes de criar uma tag oficial, você pode testar o processo localmente:

```bash
# Opção 1: Script completo (build + rename)
./scripts/build_deb.sh

# Opção 2: Simular o processo do GitHub Actions
./scripts/test_release_locally.sh
```

Arquivos gerados em: `frontend/dist/`

## 📦 Estrutura de Arquivos

Após o build, os seguintes arquivos são gerados:

```
frontend/dist/
├── UClip-0.1.0.deb          # Pacote Debian (69 MB)
├── UClip-0.1.0.AppImage     # AppImage universal (99 MB)
├── builder-effective-config.yaml
├── linux-unpacked/          # Arquivos descompactados
└── ... (outros arquivos de build)
```

## 🔧 Workflow do GitHub Actions

O arquivo `.github/workflows/release.yml` gerencia o processo:

### Principais etapas:

1. **Checkout do código**
2. **Setup Node.js 18** com cache npm
3. **Setup Python 3.12**
4. **Instalar dependências do sistema** (`libxss1`, `fakeroot`, `dpkg`)
5. **Instalar dependências do frontend** (`npm ci`)
6. **Build frontend** (`npm run build`)
7. **Preparar app** (`npm run prepack`)
8. **Build pacotes** (`electron-builder --linux deb AppImage`)
9. **Renomear arquivos** para padrão `UClip-{version}.{ext}`
10. **Criar release no GitHub** com os arquivos

### Variáveis importantes:

```yaml
VERSION: ${GITHUB_REF#refs/tags/}     # Ex: v0.1.0
VERSION_NUMBER: ${VERSION#v}          # Ex: 0.1.0
```

## 🐛 Troubleshooting

### Arquivos não aparecem na release

**Problema:** A release é criada mas os arquivos não são anexados.

**Solução:** 
- Verifique se o padrão de nome está correto no workflow
- Confirme que os arquivos estão sendo renomeados corretamente
- Verifique os logs do GitHub Actions

### Erro ao fazer build

**Problema:** O electron-builder falha ao gerar os pacotes.

**Solução:**
```bash
# Limpar cache e node_modules
cd frontend
rm -rf node_modules package-lock.json dist app
npm install
npm run build
```

### Permissão negada no AppImage

**Problema:** O AppImage não executa após download.

**Solução:**
```bash
chmod +x UClip-*.AppImage
```

### Dependências faltando no .deb

**Problema:** Erro ao instalar o .deb por falta de dependências.

**Solução:**
```bash
sudo apt-get install -f
```

## 📝 Checklist de Release

Antes de criar uma release:

- [ ] Versão atualizada em `frontend/package.json`
- [ ] CHANGELOG.md atualizado
- [ ] README.md atualizado (se necessário)
- [ ] Todos os testes passando (`npm test`)
- [ ] Build local bem-sucedido
- [ ] Commit das mudanças
- [ ] Tag criada e enviada
- [ ] Release verificada no GitHub
- [ ] Downloads testados
- [ ] Instalação testada em Ubuntu/Debian

## 🔄 Versionamento

Seguimos o [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Mudanças incompatíveis com versões anteriores
- **MINOR** (0.2.0): Novas funcionalidades compatíveis
- **PATCH** (0.1.1): Correções de bugs

### Comandos npm:

```bash
npm version patch  # 0.1.0 → 0.1.1
npm version minor  # 0.1.0 → 0.2.0
npm version major  # 0.1.0 → 1.0.0
```

## 📊 Estatísticas

| Versão | Data | Tamanho .deb | Tamanho AppImage |
|--------|------|--------------|------------------|
| 0.1.0  | Out 2025 | 69 MB | 99 MB |

## 🔗 Links Úteis

- [GitHub Releases](https://github.com/Jonatas-Serra/UClip/releases)
- [electron-builder docs](https://www.electron.build/)
- [GitHub Actions docs](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)

---

*Última atualização: 22 de outubro de 2025*

# 🚀 Guia de Releases do UClip

### Passo 1: Atualizar versão

Atualize a versão no `frontend/package.json`:

```json
{
  "name": "uclip-frontend",
  "version": "0.2.0",  // ← Mude aqui
  ...
}
```

### Passo 2: Fazer commit

```bash
git add frontend/package.json
git commit -m "chore: bump version to 0.2.0"
git push origin main
```

### Passo 3: Criar tag e fazer push

```bash
# Criar tag local
git tag -a v0.2.0 -m "Release version 0.2.0"

# Enviar tag para GitHub (isso ativa o workflow)
git push origin v0.2.0
```

Ou de uma única vez:

```bash
git tag -a v0.2.0 -m "Release version 0.2.0" && git push origin v0.2.0
```

### Passo 4: Acompanhar o build

Vá para a aba **Actions** do seu repositório: https://github.com/Jonatas-Serra/UClip/actions

Procure pelo workflow **Release** mais recente.

## ✅ Resultado esperado

Quando o workflow terminar com sucesso, você verá:

- **GitHub Release** em: https://github.com/Jonatas-Serra/UClip/releases
- **Arquivos disponíveis**:
  - `UClip-0.2.0.AppImage`
  - `UClip-0.2.0.deb`

## 📥 Como seus usuários instalam

### Instalação do AppImage (recomendado)

```bash
wget -O ~/UClip.AppImage https://github.com/Jonatas-Serra/UClip/releases/download/v0.2.0/UClip-0.2.0.AppImage
chmod +x ~/UClip.AppImage
~/UClip.AppImage
```

### Instalação do DEB (Ubuntu/Debian)

```bash
wget https://github.com/Jonatas-Serra/UClip/releases/download/v0.2.0/UClip-0.2.0.deb
sudo dpkg -i UClip-0.2.0.deb
uclip  # executar
```

## 🔄 Ciclo de vida das releases

```
Local           GitHub              Download
─────────────────────────────────────────
v0.1.0 (tag)
    ↓
git push origin v0.1.0
    ↓ (ativa workflow)
    ──→ Build AppImage
    ──→ Build DEB
    ──→ Create Release
    ──→ Upload Assets
                ↓ (disponível)
        Release criada em:
        /releases/tag/v0.1.0
                ↓
            Usuários baixam:
            - AppImage
            - DEB
```

## 📋 Versionamento

Use [Semantic Versioning](https://semver.org/):

- **v0.1.0** - Lançamento inicial (0.major.minor)
- **v0.1.1** - Patch/bug fix (incrementa patch)
- **v0.2.0** - Nova feature (incrementa minor)
- **v1.0.0** - Release estável (incrementa major)

## 🔧 Personalizações

### Adicionar mais artifacts

Se quiser adicionar mais formatos (Snap, Flatpak, etc), edite `.github/workflows/release.yml`:

```yaml
- name: Build AppImage and more
  run: |
    cd frontend
    npx electron-builder --linux --publish never
    # Adicione mais formatos aqui
```

### Alterar targets de build

No `frontend/package.json`, na seção `build.linux.target`:

```json
"linux": {
  "target": ["AppImage", "deb", "snap", "flatpak"]
}
```

## ❌ Troubleshooting

### Release não foi criada

1. Verifique se a tag está no formato correto: `v0.1.0`
2. Confirme em **Actions** se o workflow rodou
3. Procure por erros no log do workflow

### Build falhou

1. Clique no workflow na aba **Actions**
2. Veja o passo que falhou
3. Verifique se `npm ci` funcionou
4. Confirme se o `electron-builder` foi instalado

### Assets não aparecem na release

1. Verifique se o build gerou os arquivos em `frontend/dist/`
2. Confirme que os nomes dos arquivos correspondem ao padrão: `UClip-*.AppImage`
3. Verifique as permissões do `GITHUB_TOKEN`

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Electron Builder](https://www.electron.build/)
- [Semantic Versioning](https://semver.org/)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)

---

**Próximo passo?** Crie sua primeira release seguindo os passos acima! 🎉
