all: finpar.patched parboil parboil.patched

finpar.patched: finpar.patch
	patch -p1 -d finpar < $<
	touch $@

parboil:
	tar xf pb2.5driver.tgz
	tar xf pb2.5benchmarks.tgz
	mv benchmarks parboil
	tar xf pb2.5datasets_standard.tgz
	mv datasets parboil

parboil.patched: parboil.patch parboil
	patch -p1 -d parboil < $<
	touch $@
