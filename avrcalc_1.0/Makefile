#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
AVRASM    = avra
FILE      = avrcalc.asm
INSTALDIR = /mnt/avr/Projects
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

all: ${FILE}
	${AVRASM} ${FILE}

install: all
	PWD=`pwd`; cp -fr ${PWD} ${INSTALDIR}

clean:
	rm -f *.hex *.list *.map *.obj
