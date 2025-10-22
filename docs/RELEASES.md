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

## 🚀 Como criar uma nova release

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
