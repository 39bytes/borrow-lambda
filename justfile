run:
    dune exec borrow_lambda

build:
    dune build

test:
    dune runtest

utop:
    TM=$(mktemp) && dune ocaml top > "$TM" && cat init.ml >> "$TM" && utop -init "$TM"

present:
    presenterm --present paper/slides.md
