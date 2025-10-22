# Scripts

run_local.sh
- Cria (se necessário) um virtualenv em `.venv` e instala dependências Python.
- Inicia o backend (uvicorn) e o listener em background, gravando logs em `run_backend.log` e `run_listener.log`.
- Uso:

```bash
bash scripts/run_local.sh
```

Makefile
- `make setup` - cria venv e instala dependências
- `make run-backend` - inicia backend no foreground
- `make run-listener` - inicia listener no foreground
- `make run-local` - invoca `scripts/run_local.sh`
- `make test` - executa pytest

Electron (dev)
- Para rodar a aplicação com Electron em modo dev:

```bash
# no terminal 1 (frontend dev server)
cd frontend
npm install
npm run dev

# no terminal 2 (opcional: backend + listener)
bash scripts/run_local.sh

# no terminal 3 (iniciar electron)
cd frontend
npm run dev:electron
```

Nota: `dev:electron` usa `cross-env` para setar `UCLIP_DEV=1` e carrega `electron/main.js`.
