## charmatch: pattern-matching generation for characters

The following call:

```ocaml
module C = Set.Make(Char)
.< fun x -> .~(ifmem .<x>.
                [C.of_list ['a';'b';'c';'e';'f';'g';'z'], .<1>.;
                 C.of_list ['1';'2';'3';'9'], .<2>.]
                ~otherwise:.<3>.) >.
```

generates compact code for matching characters:

```ocaml
fun x ->
  match x with
   | 'a'..'c' | 'e'..'g' | 'z' -> 1
   | '1'..'3' | '9' -> 2
   | _ -> 3
```
