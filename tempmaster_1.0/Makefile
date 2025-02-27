#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
AVRASM    = avra
FILE      = tempmaster.asm
INSTALDIR = /const/vmware/win98/mnt/avr/Projects
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

all: ${FILE}
	${AVRASM} ${FILE}

install: all
	PWD=`pwd`; cp -fr ${PWD} ${INSTALDIR}

clean:
	rm -f *.hex *.list *.map *.obj
