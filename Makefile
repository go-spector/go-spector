PYTHON ?= python3
PLANTUML ?= plantuml
DIAGRAMS_DIR ?= docs/diagrams
DIAGRAMS_SRC_FILES := $(wildcard $(DIAGRAMS_DIR)/*.puml)
DIAGRAMS_SVG_FILES := $(patsubst %.puml,%.svg,$(DIAGRAMS_SRC_FILES))
DIAGRAMS_PNG_FILES := $(patsubst %.puml,%.png,$(DIAGRAMS_SRC_FILES))

# diagrams
.PHONY: diagrams
diagrams: $(DIAGRAMS_SVG_FILES) $(DIAGRAMS_PNG_FILES)

# docs targets
.PHONY: docs-sync
docs-sync: Pipfile.lock

. PHONY: docs-build
docs-build: docs-sync
	$(PYTHON) -m pipenv run mkdocs build

. PHONY: docs-serve
docs-serve: docs-sync
	$(PYTHON) -m pipenv run mkdocs serve

# rules
$(DIAGRAMS_DIR)/%.svg: $(DIAGRAMS_DIR)/%.puml
	$(info generating $@ from $<...)
	@$(PLANTUML) -tsvg $<

$(DIAGRAMS_DIR)/%.png: $(DIAGRAMS_DIR)/%.puml
	$(info generating $@ from $<...)
	@$(PLANTUML) -tpng $<

Pipfile.lock: Pipfile
