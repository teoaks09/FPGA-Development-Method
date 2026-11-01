# {{PROJECT}} - flow entry points. Works without Claude/opencode/MCP.
.RECIPEPREFIX = >
SHELL := /bin/bash

PV        := python3 flow/project_value.py
PART      ?= $(shell $(PV) project.part)
FEATURE   ?=
PREFIX    := $(shell $(PV) project.prefix)
CLOCK_MHZ ?= $(shell $(PV) --feature-clock "$(FEATURE)")
CLOCK_PORT ?= clk
OOC_MODE  ?= impl
BOARD     ?=
VIVADO    ?= vivado

.PHONY: help lint sim ooc gates check-locks env-check clean
help:
> @echo "make lint|sim|ooc|gates FEATURE=<f>   make check-locks | env-check"
# @if weight=standard,comprehensive
> @echo "make trace | doc-check | codemap | wiki-lint | regress | project"
# @end
# @if deliverable=ip
> @echo "make ip FEATURE=<f>"
# @end
# @if deliverable=board
> @echo "make impl BOARD=<b>"
# @end

need-feature:
> @test -n "$(FEATURE)" || (echo "FEATURE=<name> required"; exit 2)

lint: need-feature
> flow/checks/lint.sh $(FEATURE)

sim: need-feature
> flow/sim/run_xsim.sh $(FEATURE)

ooc: need-feature
> mkdir -p build/ooc/$(FEATURE)
> $(VIVADO) -mode batch -nojournal -log build/ooc/$(FEATURE)/vivado.log \
>   -source flow/vivado/ooc_synth.tcl -tclargs $(FEATURE) $(PART) $(CLOCK_MHZ) \
>   $(PREFIX)_$(FEATURE) $(CLOCK_PORT) $(OOC_MODE) >build/ooc/$(FEATURE)/stdout.txt 2>&1; \
>   status=$$?; grep -E "^OOC_RESULT" build/ooc/$(FEATURE)/stdout.txt || echo "OOC_RESULT: FAIL feature=$(FEATURE) no result line (see build/ooc/$(FEATURE)/)"; exit $$status

gates: need-feature
> flow/checks/run_gates.sh $(FEATURE)

check-locks:
> python3 flow/checks/check_locked.py

env-check:
> flow/checks/env_check.sh

# @if weight=standard,comprehensive
.PHONY: trace doc-check codemap wiki-lint regress project
trace:
> python3 flow/checks/check_trace.py

doc-check:
> python3 flow/checks/check_doc_names.py

codemap:
> python3 flow/gen/codemap.py

wiki-lint:
> python3 flow/checks/wiki_lint.py

regress:
> flow/checks/run_gates.sh --all

project:
> $(VIVADO) -mode batch -nojournal -log build/vivado/create.log \
>   -source flow/vivado/create_project.tcl -tclargs $(PART) $(BOARD)
# @end

# @if deliverable=ip
.PHONY: ip
ip: need-feature
> mkdir -p build/ip
> $(VIVADO) -mode batch -nojournal -log build/ip/package.log \
>   -source hw/ip_package/package_ip.tcl -tclargs $(FEATURE) $(PART)
# @end

# @if deliverable=board
.PHONY: impl
impl:
> @test -n "$(BOARD)" || (echo "BOARD=<name> required"; exit 2)
> mkdir -p build/impl/$(BOARD)
> $(VIVADO) -mode batch -nojournal -log build/impl/$(BOARD)/vivado.log \
>   -source flow/vivado/build_board.tcl -tclargs $(BOARD) $(PART)
# @end

clean:
> rm -rf build .Xil xsim.dir obj_dir *.jou *.log

# project:begin (project-specific targets; kept when the profile is regenerated)
# project:end
