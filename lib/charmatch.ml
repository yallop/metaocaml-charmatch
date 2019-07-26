(*
 * Copyright (c) 2019 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

module CharSet = Set.Make(Char)
type interval = char * char

module Mk =
struct
  open Parsetree

  let pattern : pattern_desc -> pattern =
    fun ppat_desc ->
    { ppat_desc; ppat_loc = Location.none; ppat_attributes = [] }

  let expression : expression_desc -> expression =
    fun pexp_desc ->
    { pexp_desc; pexp_loc = Location.none; pexp_attributes = [] }

  let interval : char -> char -> pattern =
    fun l h -> if l <> h then pattern @@ Ppat_interval (Pconst_char l, Pconst_char h)
               else pattern @@ Ppat_constant (Pconst_char l)

  let intervals : interval list -> pattern = function
    | [] -> failwith "empty interval list not supported"
    | (l,h)::is ->
       List.fold_left (fun p (l,h) -> pattern @@ Ppat_or (interval l h, p))
         (interval l h) is

  let case : 'a. pattern -> 'a code -> (char -> 'a) pat_code =
    fun pat code ->
    let fv, rhs = Obj.magic code in
    (Obj.magic (fv, expression (Pexp_fun (Asttypes.Nolabel, None, pat, rhs))))
end

let intervals : CharSet.t -> interval list =
  let add c = function
    | (l,h) :: tail when Char.code c = succ (Char.code h) -> (l, c) :: tail
    | l -> (c, c) :: l
  in fun c -> List.rev (CharSet.fold add c [])

let ipat c = Mk.intervals (intervals c)


let ifmem : 'a. char code -> ?otherwise:'a code -> (Set.Make(Char).t * 'a code) list -> 'a code =
  fun c ?otherwise cases ->
   make_match c
   @@ (List.map (fun (lhs, rhs) -> Mk.case (ipat lhs) rhs) cases
       @ match otherwise with None -> []
                            | Some e -> [.< fun _ -> .~e >. [@metaocaml.functionliteral] ])
