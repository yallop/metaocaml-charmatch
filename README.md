## charmatch: pattern-matching generation for characters

[![Charmatch test](https://github.com/yallop/metaocaml-charmatch/actions/workflows/test.yml/badge.svg)](https://github.com/yallop/metaocaml-charmatch/actions/workflows/test.yml)

The following call:

```ocaml
module C = Set.Make(Char)
.< fun x -> .~(ifmem .<x>.
                [C.of_list ['a';'b';'c';'e';'f';'g';'z'], .<1>.;
                 C.of_list ['1';'2';'3';'9'], .<2>.]
                ~otherwise:.<3>.) >.
```

either generates compact code for matching characters:

```ocaml
fun x ->
  match x with
   | 'a'..'c' | 'e'..'g' | 'z' -> 1
   | '1'..'3' | '9' -> 2
   | _ -> 3
```

or, depending on the options passed to `ifmem`, generates equivalent (but typically faster) code based on a table lookup:

```ocaml
fun x ->
  match Char.code
          (String.unsafe_get
             "\002...\002\001\001\001\002\002...\002\002\000\000\000\002\000\000\000\002\002...\002\002"
             (Char.code x))
  with
  | 0 -> 1
  | 1 -> 2
  | _ -> 3
```
