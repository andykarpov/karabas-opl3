REV = A
REVISION = rev_${REV}

.PHONY: build program release clean

build:
	quartus_sh --no_banner --flow compile karabas_opl3 -c ${REVISION}

program:
	quartus_pgm --no_banner --mode=jtag -o "BVP;output/${REVISION}.pof"

release:
	cp output/rev_A.pof ../../docs/karabas-opl3-revA.pof

clean:
	rm -rf db incremental_db output *.ddb ${REVISION}_description.txt ${REVISION}.qws

report:
	cat output/${REVISION}.*.smsg output/${REVISION}.*.rpt |grep -e Error -e Critical -e Warning |grep -v -e "Family doesn't support jitter analysis" -e "Force Fitter to Avoid Periphery Placement Warnings"

export PATH:=/opt/altera/quartus/bin:${PATH}

-include Makefile.local
