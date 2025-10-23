VENV=.venv
PYTHON=$(VENV)/bin/python
PIP=$(VENV)/bin/pip

.PHONY: setup run-backend run-listener run-local test package clean clean-dev-data

setup:
	@test -d $(VENV) || python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r backend/requirements.txt

run-backend:
	$(PYTHON) backend/cli/run_api.py

run-listener:
	$(PYTHON) backend/cli/run_listener.py

run-local:
	bash scripts/run_local.sh

test:
	PYTHONPATH="$(shell pwd)" $(VENV)/bin/pytest -q backend/tests

package:
	bash scripts/build_electron_local.sh

clean-dev-data:
	@echo "🧹 Limpando dados de desenvolvimento..."
	@bash scripts/clean_dev_data.sh

clean: clean-dev-data
	@echo "🧹 Limpando arquivos de build..."
	@rm -rf frontend/dist frontend/app frontend/node_modules
	@rm -rf $(VENV)
	@echo "✅ Limpeza completa!"
