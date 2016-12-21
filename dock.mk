ifndef W
  $(error "W" is empty!)
endif

S := $W/source

configure: $S/Makefile ; test $(<D)/Makefile
$S/Makefile: $S/configure
	cd $(<D) && ./configure \
	  --with-incompatible-bdb

autogen: $S/configure ; test $<
$S/configure: $S/configure.ac $S/autogen.sh
	cd $(<D) && ./autogen.sh

.PHONY: autogen configure
