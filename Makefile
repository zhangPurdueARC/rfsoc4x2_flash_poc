# Eric Villasenor
# evillase@gmail.com
#
# Makefile for system verilog or vhdl designs.
#
# you DON'T TOUCH THIS FILE!!!
# I jest, you can mess with SIMTIME.
# AND THAT IS IT!
#

# list of grid hosts
GRIDHOSTS = ecegrid-lnx

###############################because GRID is funny###########################
ifneq (,$(findstring $(GRIDHOSTS), $(HOST)))
%:
	@$(if \
		$(findstring $@, $(word 1, $(MAKECMDGOALS))), \
		grid $(MAKE) $(MAKECMDGOALS) -$(MAKEFLAGS), \
		echo "do nothing" > /dev/null)
else
###############################and i'm not laughing############################

################################################################################
# variables                                                                    #
################################################################################

# course libs and such
COURSELIBS  = /home/ecegrid/a/ece437l/libs

# directories
SRCDIR          = source
INCDIR          = include
TBDIR               = testbench
MAPDIR          = mapped
FPGADIR         = fpga
SCRDIR          = scripts
LIBDIR          = work
DEPDIR          = .deps

# commands and flags. 1/9/2020 mcj, added -suppress 12110 so simulation will run with -novopt
#   novopt is deprecated in Questa 10.7a and later. Need to find better solution.
SYN                 = synthesize
SYNX                = synthesize_xilinx
MAKEDEP         = hdldep
VSIM                = vsim -coverage -suppress 12110
VLOG                = vlog
VCOM                = vcom
VERFLAGS        = +acc -sv12compat -mfcu -lint +incdir+$(INCDIR) -suppress 12110
VHDFLAGS        = -93 +acc -lint
SIMTIME         = -all

# modelsim viewing options
ifneq (0,$(words $(filter %.wav %.wavx,$(MAKECMDGOALS))))
# view waveform in graphical mode and load do file if there is one
DOFILES         = $(notdir $(basename $(wildcard $(SCRDIR)/*.do)))
DOFILE          = $(filter $(MAKECMDGOALS:%.wav=%) $(MAKECMDGOALS:%_tb.wav=%) $(MAKECMDGOALS:%.wavx=%) $(MAKECMDGOALS:%_tb.wavx=%), $(DOFILES))
ifeq (1, $(words  $(DOFILE)))
WAVDO               = do $(SCRDIR)/$(DOFILE).do
else
WAVDO               = add wave *
endif
SIMDO               = "view objects; $(WAVDO); run $(SIMTIME);" -onfinish stop
else
# view text output in cmdline mode
SIMTERM         = -c
SIMDO       = "run $(SIMTIME); exit;"
endif

# mapped files for Quartus flow
SYNTH               = $(filter $(MAKECMDGOALS:%.wav=%) \
							$(MAKECMDGOALS:%.sim=%) $(MAKECMDGOALS:%_tb.sim=%) \
							$(MAKECMDGOALS:%_tb.wav=%) $(MAKECMDGOALS:%_tb=%), \
							$(notdir $(basename $(wildcard $(MAPDIR)/*.sv $(MAPDIR)/*.v $(MAPDIR)/*.vhd))))

ifneq (,$(filter $(SYNTH), \
	$(MAKECMDGOALS:%_tb=%) $(MAKECMDGOALS:%_tb.sim=%) \
	$(MAKECMDGOALS:%_tb.wav=%) $(MAKECMDGOALS:%.wav=%) $(MAKECMDGOALS:%.sim=%)))
SYNDEF      =   +define+MAPPED
#SIMSYN         = -sdftyp /=mapped/$(SYNTH)_v.sdo
endif

# mapped files for Xilinx flow (checks if a synthesized netlist exists in MAPDIR)
SYNTHX              = $(filter $(MAKECMDGOALS:%.wavx=%) \
							$(MAKECMDGOALS:%.simx=%) $(MAKECMDGOALS:%_tb.simx=%) \
							$(MAKECMDGOALS:%_tb.wavx=%) $(MAKECMDGOALS:%_tb=%), \
							$(notdir $(basename $(wildcard $(MAPDIR)/*.sv $(MAPDIR)/*.v $(MAPDIR)/*.vhd))))

# find GLBL_PATH
VIVADO_EXECUTABLE := $(shell which vivado)
ifeq ($(VIVADO_EXECUTABLE),)
    $(warning "Could not find 'vivado' in PATH. Using default VIVADO_ROOT_PATH.")
    VIVADO_ROOT_PATH ?= /package/eda/xilinx/Vivado/2023.2
else
    VIVADO_ROOT_PATH := $(shell dirname $(shell dirname $(VIVADO_EXECUTABLE)))
endif
GLBL_PATH := $(VIVADO_ROOT_PATH)/data/verilog/src/glbl.v

# Set all Xilinx-specific simulation flags if a Xilinx target is invoked
ifneq (0, $(words $(filter %.sim %.wav %_tb.sim %_tb.wav, $(MAKECMDGOALS))))
VIVADO_SIM_FLAGS += +define+USE_VIVADO
VIVADO_SIM_FLAGS += -L unisim 

# Conditionally add VIVADO_MAPPED define if a mapped file from SYNTHX was found
ifneq (,$(filter $(SYNTHX), \
	$(MAKECMDGOALS:%_tb=%) $(MAKECMDGOALS:%_tb.sim=%) \
	$(MAKECMDGOALS:%_tb.wav=%) $(MAKECMDGOALS:%.wav=%) $(MAKECMDGOALS:%.sim=%)))
VIVADO_SIM_FLAGS += +define+VIVADO_MAPPED
endif
endif

# v, sv or vhdl stems
VLSTEM          = $(notdir $(basename $(wildcard $(SRCDIR)/*.v $(TBDIR)/*.v)))
SVSTEM          = $(notdir $(basename $(wildcard $(SRCDIR)/*.sv $(TBDIR)/*.sv)))
VHSTEM          = $(notdir $(basename $(wildcard $(SRCDIR)/*.vhd $(TBDIR)/*.vhd)))
HDSTEM          = $(notdir $(basename $(wildcard $(INCDIR)/*.vh)))
SRCSTEM         = $(VLSTEM) $(SVSTEM) $(VHSTEM)
SRCS                = $(addsuffix .v,$(VLSTEM)) $(addsuffix .sv,$(SVSTEM)) $(addsuffix .vhd,$(VHSTEM))
HDRS                = $(addsuffix .vh,$(HDSTEM))

# dep files
DEPS                = $(addsuffix .d, $(VLSTEM) $(SVSTEM) $(VHSTEM) $(HDSTEM))

# no target files are made
NODEPS          = help clean clean_asm clean_sim clean_map clean_deps clean_fpga

################################################################################
# config                                                                       #
################################################################################

# rules with no output file
.PHONY:         $(NODEPS)

# clear and set suffixes
.SUFFIXES:
.SUFFIXES: .vh .sv .vhd .d .v

# set search paths
vpath %.vh  $(INCDIR)/
vpath %.v       $(MAPDIR)/ $(SRCDIR)/ $(TBDIR)/
vpath %.sv  $(MAPDIR)/ $(SRCDIR)/ $(TBDIR)/
vpath %.vhd $(SRCDIR)/ $(TBDIR)/
vpath %.d       $(DEPDIR)/
vpath %         $(DEPDIR)/

# set default rule
default: help

# v,sv library search paths for Quartus
ifneq (0,$(words $(VLSTEM) $(SVSTEM)))
SIMLIBS=$(addprefix -L ,$(filter %_ver,$(shell ls $(COURSELIBS))))
endif

# include dependencies
ifeq (0,$(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
-include $(addprefix $(DEPDIR)/,$(DEPS))
endif

################################################################################
# Linter support                                                               #
################################################################################

# lint command
LINT = svlint

# Linter target
lint:
	@echo "+incdir+$(INCDIR)/" > filelist.f
	@echo "$(SOURCE_FILE)" >> filelist.f
	@-$(LINT) -f filelist.f | sed -r 'w /dev/stderr' | sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]|\x1B\(B//g' >> lint.log
	@rm -f filelist.f

%.lint: %.sv | $(LIBDIR)
	@$(MAKE) -s lint SOURCE_FILE=$<

################################################################################
# auto make rules                                                              #
################################################################################

# dependency rules
$(DEPDIR):
	@test -d $(DEPDIR) || mkdir $(DEPDIR)
$(LIBDIR):
	@test -d $(LIBDIR) || vlib $(LIBDIR)
%.d: | $(DEPDIR)
	@$(SHELL) -ec '$(MAKEDEP) ${*F} $(SRCDIR) $(TBDIR) $(INCDIR) \
		| sed \
		-e "s/$$/ $(filter ${*F}.v ${*F}.sv ${*F}.vhd ${*F}.vh,$(SRCS) $(HDRS))/" \
		-e "s/\.[a-z]\+/&o/g" \
		-e "s/^/${*F}: /" \
		> $@'

# header rules
%.vho: %.vh | $(LIBDIR)
	@$(MAKE) SOURCE_FILE=$<
	$(VLOG) $(VERFLAGS) $(SYNDEF) $(VIVADO_SIM_FLAGS) $<
	@touch $(DEPDIR)/$@

# verilog rules
%.vo: %.v | $(LIBDIR)
	@$(MAKE) SOURCE_FILE=$<
	$(VLOG) $(VERFLAGS) $(SYNDEF) $(VIVADO_SIM_FLAGS) $<
	@touch $(DEPDIR)/$@

# system verilog rules
%.svo: %.sv | $(LIBDIR)
	@$(MAKE) SOURCE_FILE=$<
	$(VLOG) $(VERFLAGS) $(SYNDEF) $(VIVADO_SIM_FLAGS) $<
	@touch $(DEPDIR)/$@

# vhdl rules
%.vhdo: %.vhd | $(LIBDIR)
	@$(MAKE) SOURCE_FILE=$<
	$(VCOM) $(VHDFLAGS) $<
	@touch $(DEPDIR)/$@

# Quartus simulation rules
%_tb.simq %_tb.wavq %.simq %.wavq: %_tb
	@$(VSIM) $(SIMTERM) -do $(SIMDO) $(SIMLIBS) $(SIMSYN) -wlf $(addsuffix _tb,$*).wlf $(LIBDIR).$(addsuffix _tb,$*)

# Xilinx simulation rules
%_tb.sim %_tb.wav %.sim %.wav: %_tb
	@test -f meminit.hex && /home/ecegrid/a/ece437l/tools/vivado_extra/hex_to_mem meminit.hex > meminit.mem || true
	@$(VIVADO_LIB_MAP)
	@$(VLOG) -work $(LIBDIR) $(VERFLAGS) $(VIVADO_SIM_FLAGS) $(GLBL_PATH)
	@$(VSIM) $(SIMTERM) -do $(SIMDO) \
		$(VIVADO_SIM_FLAGS) -wlf $(addsuffix _tb,$*).wlf \
		$(LIBDIR).$(addsuffix _tb,$*) \
		glbl
	@test -f memcpu.mem && /home/ecegrid/a/ece437l/tools/vivado_extra/mem_to_hex memcpu.mem > memcpu.hex || true

# Quartus synthesis rules for mapped simulation
%_tb.synfq %.synfq %_tb.syntq %.syntq %_tb.synq %.synq:
	@$(SYN) $(if $(filter %.syntq, $@),-t) $*
	-@rm -f $(DEPDIR)/${*F}_tb.svo

# Xilinx synthesis rules
%_tb.syn %.syn:
	@$(SYNX) -c $*
	@sed -i 's|\.EN_ECC_READ("FALSE")|\.EN_ECC_READ(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_READ("TRUE")|\.EN_ECC_READ(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("FALSE")|\.EN_ECC_WRITE(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("TRUE")|\.EN_ECC_WRITE(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	-@rm -f $(DEPDIR)/${*F}_tb.svo

%_tb.synt %.synt:
	@echo "--- Running Xilinx Timing Synthesis for '$*' (200 MHz) ---"
	@$(SYNX) -t -c -f 200 $*
	@sed -i 's|\.EN_ECC_READ("FALSE")|\.EN_ECC_READ(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_READ("TRUE")|\.EN_ECC_READ(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("FALSE")|\.EN_ECC_WRITE(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("TRUE")|\.EN_ECC_WRITE(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	-@rm -f $(DEPDIR)/${*F}_tb.svo

%_tb.syntp %.syntp:
	@echo "--- Running Xilinx Timing Synthesis on Project Mode for '$*' (200 MHz) ---"
	@$(SYNX) -p -t -c -f 200 $*
	@sed -i 's|\.EN_ECC_READ("FALSE")|\.EN_ECC_READ(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_READ("TRUE")|\.EN_ECC_READ(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("FALSE")|\.EN_ECC_WRITE(0)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	@sed -i 's|\.EN_ECC_WRITE("TRUE")|\.EN_ECC_WRITE(1)|g' mapped/$*.sv mapped/$*_tb.sv 2>/dev/null || true
	-@rm -f $(DEPDIR)/${*F}_tb.svo

################################################################################
# info clean up rules                                                          #
################################################################################

# cleaning rules
clean: clean_sim clean_asm clean_map clean_deps clean_fpga

clean_sim: clean_deps
	@rm -rf $(LIBDIR) *.log *.wlf transcript

clean_asm:
	@rm -rf *.hex *.ver *.diff *.log *.mem

clean_map:
	@rm -rf $(MAPDIR)/* ._* *.summary *.log

clean_fpga:
	@rm -rf $(FPGADIR)/* ._*

clean_deps:
	@rm -rf $(DEPDIR) *.d

help:
	@echo ""
	@echo "Hello $(USER)@$(HOST), you forgot some targets."
	@echo " If you need instructions to use this Makefile:"
	@echo "--- Xilinx/Vivado Flow ---"
	@echo "     'make <module_name>.sim' to sim tb on cmd line"
	@echo "     'make <module_name>.wav' to sim tb with gui"
	@echo "     'make <module_name>.syn' to synthesize functional net list"
	@echo "     'make <module_name>.synt' to synthesize timing net list"
	@echo "     'make <module_name>.syntp' to synthesize timing net list on project mode"
	@echo ""
	@echo "--- Quartus Flow ---"
	@echo "     'make <module_name>' to build module"
	@echo "     'make <module_name>_tb' to build module + testbench"
	@echo "     'make <module_name>.simq' to sim tb on cmd line"
	@echo "     'make <module_name>.wavq' to sim tb with gui"
	@echo "     'make <module_name>.synq' to synthesize functional net list"
	@echo "     'make <module_name>.syntq' to synthesize timing net list"
	@echo ""
	@echo "--- Linter Rules ---"
	@echo "     'make <module_name>.lint' to run the linter on module"
	@echo "     'make <module_name>_tb.lint' to run the linter on module testbench"
	@echo ""
	@echo "--- Clean Rules ---"
	@echo "     'make clean' to clean everything"
	@echo "     'make clean_sim' to clean simulation logs and work lib"
	@echo "     'make clean_asm' to clean hex and testasm output"
	@echo "     'make clean_map' to clean mapped dir"
	@echo "     'make clean_fpga' to clean fpga dir"
	@echo " Obviously a testbench file must exist for some options."
	@echo ""

################################################################################
endif # end GRID nonsense                                                      #
################################################################################