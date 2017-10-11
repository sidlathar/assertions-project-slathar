# 18-341 Assertion Project

# ========================================================
#
#    ADD YOUR FILES HERE
#
#    For example:
#      STUDENT_FILES=top.sv assertions.sv inputs.sv
#
# ========================================================

STUDENT_FILES=top.sv

# ========================================================
#
#    DON'T CHANGE ANYTHING BELOW HERE
#
# ========================================================

VCSFLAGS=-sverilog -debug

golden: $(STUDENT_FILES) TA_calc_golden.svp
		vcs $(VCSFLAGS) $^

broken: $(STUDENT_FILES) TA_calc_broken.svp
		vcs $(VCSFLAGS) $^
