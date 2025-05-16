(*
 * Copyright (c) 2019 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

type interval = char * char

type options = { match_type: [`table | `ranges] }
let default_options = { match_type = `table }

module Mk =
struct
  open Parsetree

  let pattern : pattern_desc -> pattern =
    Ast_helper.Pat.mk

  let interval : char -> char -> pattern =
    fun l h -> if l <> h
               then pattern @@ Ppat_interval (Ast_helper.Const.char l, Ast_helper.Const.char h)
               else pattern @@ Ppat_constant (Ast_helper.Const.char l)

  let int_pattern : int -> pattern =
    fun i -> pattern @@ Ppat_constant (Ast_helper.Const.int i)

  let intervals : interval list -> pattern = function
    | [] -> failwith "empty interval list not supported"
    | (l,h)::is ->
       List.fold_left (fun p (l,h) -> pattern @@ Ppat_or (interval l h, p))
         (interval l h) is

  let case : 'a. pattern -> 'a code -> (_ -> 'a) pat_code =
    fun pat code ->
    let fv, rhs = Obj.magic code in
    (Obj.magic (fv, Ast_helper.Exp.function_ [{ pparam_loc = Location.none;
                                                pparam_desc = Pparam_val (Nolabel, None, pat) } ]
                      None (Pfunction_body rhs)))
end

module Make(Charset : Set.S with type elt = char) =
struct

  let intervals : Charset.t -> interval list =
    let add c = function
      | (l,h) :: tail when Char.code c = succ (Char.code h) -> (l, c) :: tail
      | l -> (c, c) :: l
    in fun c -> List.rev (Charset.fold add c [])

  let ipat c = Mk.intervals (intervals c)

  let covering : (Charset.t * _) list -> bool =
    fun cases ->
    Charset.(cardinal (List.fold_left (fun s (c,_) -> union s c) empty cases) = 256)

  let table : (Charset.t * _) list -> string =
    fun cases ->
    let n = List.length cases in
    let b = Bytes.make 256 (Char.chr (min n 255)) (* There may be 256 cases *)  in
    ListLabels.iteri cases
      ~f:(fun i (cs,_) -> Charset.iter (fun c -> Bytes.set b (Char.code c) (Char.chr i)) cs);
    Bytes.unsafe_to_string b

  let ifmem_match : 'a. char code -> ?otherwise:'a code -> (Charset.t * 'a code) list -> 'a code =
    fun c ?otherwise cases ->
     make_match c
       (List.map (fun (lhs, rhs) -> Mk.case (ipat lhs) rhs) cases
        @ match otherwise with None -> []
                             | Some e -> [.< fun _ -> .~e >. [@metaocaml.functionliteral] ])

  let default_otherwise = .< raise (Match_failure ("charmatch-generated", 0, 0)) >.

  let ifmem_table : 'a. char code -> ?otherwise:'a code -> (Charset.t * 'a code) list -> 'a code =
    fun c ?otherwise cases ->
    let len = List.length cases in
    let covered = covering cases in
    let t = table cases in
    make_match .<Char.code (String.unsafe_get t (Char.code .~c))>.
      (List.mapi (fun i (_,rhs) -> if i+1 = len && covered then .< fun _ -> .~rhs >. [@metaocaml.functionliteral]
                                   else Mk.case (Mk.int_pattern i) rhs) cases
       @ if covered then []
         else [.< fun _ -> .~(Option.value otherwise ~default:default_otherwise) >. [@metaocaml.functionliteral]])

  let ifmem ?(options=default_options) c ?otherwise l =
    (match options.match_type with `table -> ifmem_table | `ranges -> ifmem_match) c ?otherwise l
end

include Make(Set.Make(Char))
