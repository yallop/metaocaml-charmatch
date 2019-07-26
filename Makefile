OCAMLBUILD=ocamlbuild -use-ocamlfind -ocamlc '-toolchain metaocaml ocamlc' \
                                     -ocamlopt '-toolchain metaocaml ocamlopt' \
                                     -ocamldep 'ocamldep -as-map'

all: precheck lib
lib:
	$(OCAMLBUILD) charmatch.cma charmatch.cmxa

%.native %.cma %.cmxa:
	$(OCAMLBUILD) $@

install: lib
	ocamlfind install charmatch META		\
	   _build/lib/charmatch.cmi			\
           _build/lib/charmatch.cma			\
           _build/lib/charmatch.cmxa

uninstall:
	ocamlfind remove charmatch

precheck:
	@echo -n "checking OPAM compiler switch ... "
	@test $$(opam switch  show) = "4.07.1+BER"  \
      || test $$(opam switch  show) = "4.04.0+BER"  \
      || (echo 1>&2 "Please use OPAM switch 4.04.0+BER or 4.07.1+BER"; exit 1)
	@echo "ok"

clean:
	$(OCAMLBUILD) -clean

.PHONY: all lib install uninstall precheck
