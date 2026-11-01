# {{PROJECT}} - entry points. Works without Claude/opencode/MCP. `make help`.
.RECIPEPREFIX = >
SHELL := /bin/bash

PV         := python3 flow/project_value.py
PART       ?= $(shell $(PV) project.part)
PREFIX     := $(shell $(PV) project.prefix)
FEATURE    ?=
CLOCK_MHZ  ?= $(shell $(PV) --feature-clock "$(FEATURE)")
CLOCK_PORT ?= clk
OOC_MODE   ?= impl
BOARD      ?=
VIVADO     ?= vivado

.PHONY: help feature check lint sim ooc trace check-locks env-check project clean
help:
> @echo "make feature NAME=<f> [DIFFICULTY=simple|medium|hard]"
> @echo "make check|lint|sim|ooc FEATURE=<f>   (SIM=xsim|verilator|iverilog)"
> @echo "make trace | check-locks | env-check | project [BOARD=<b>]"
# @if deliverable=ip
> @echo "make ip FEATURE=<f>"
# @end
# @if deliverable=board
> @echo "make impl BOARD=<b>"
# @end
# @if option=wiki
> @echo "make codemap | wiki-lint"
# @end

need-feature:
> @test -n "$(FEATURE)" || (echo "FEATURE=<name> required"; exit 2)

feature:
> @test -n "$(NAME)" || (echo "NAME=<feature> required"; exit 2)
> python3 flow/gen/new_feature.py $(NAME) --difficulty $(or $(DIFFICULTY),medium)

check: need-feature
> flow/checks/check_feature.sh $(FEATURE)

lint: need-feature
> flow/checks/lint.sh $(FEATURE)

sim: need-feature
> flow/sim/run_sim.sh $(FEATURE)

ooc: need-feature
> mkdir -p build/ooc/$(FEATURE)
> $(VIVADO) -mode batch -nojournal -log build/ooc/$(FEATURE)/vivado.log \
>   -source flow/vivado/ooc_synth.tcl -tclargs $(FEATURE) $(PART) $(CLOCK_MHZ) \
>   $(PREFIX)_$(FEATURE) $(CLOCK_PORT) $(OOC_MODE) >build/ooc/$(FEATURE)/stdout.txt 2>&1; \
>   status=$$?; grep -E "^OOC_RESULT" build/ooc/$(FEATURE)/stdout.txt || \
>   echo "OOC_RESULT: FAIL feature=$(FEATURE) no result line (see build/ooc/$(FEATURE)/)"; exit $$status

trace:
> python3 flow/checks/check_trace.py

check-locks:
> python3 flow/checks/check_locked.py

env-check:
> flow/checks/env_check.sh

project:
> mkdir -p build/vivado
> $(VIVADO) -mode batch -nojournal -log build/vivado/create.log \
>   -source flow/vivado/create_project.tcl -tclargs $(PART) $(BOARD)

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

# @if option=wiki
.PHONY: codemap wiki-lint
codemap:
> python3 flow/gen/codemap.py

wiki-lint:
> python3 flow/checks/wiki_lint.py
# @end

clean:
> rm -rf build .Xil xsim.dir obj_dir *.jou *.log

# project:begin (project-specific targets; kept when the kit regenerates this file)
# project:end
