(*
 * Copyright (c) 2022 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open OUnit2

module M = Charmatch.Make(Charset)

(* NB: For now overlapping cases and empty cases both have unspecified behaviour, and we won't test them *)

let rec split_at n l =
  match n, l with
  | 0, _ -> [], l
  | _, [] -> invalid_arg "split_at"
  | n, x::xs -> let xs, ys = split_at (pred n) xs in x :: xs, ys

let shuffle arr =
  for i = pred (Array.length arr) downto 1 do
    let j = Random.int i in
    let ai, aj = arr.(i), arr.(j) in
    arr.(i) <- aj; arr.(j) <- ai
  done

let all_chars = Array.init 256 Char.chr

let randomized_items arr = let arr = Array.copy arr in shuffle arr; Array.to_list arr

let random_covering_partition arr n =
  let rec loop elems nelems parts n =
    if n < 1 then assert false
    else if n = 1 then Charset.of_list elems :: parts
    else let size = succ (Random.int (nelems - n + 1)) in
         let part, elems' = split_at size elems in
         loop elems' (nelems - size) (Charset.of_list part :: parts) (n - 1)
    in loop (randomized_items arr) (Array.length arr) [] n

let random_non_covering_partition arr n =
  let arr = Array.copy arr in 
  shuffle arr;
  let bound = n + Random.int (Array.length arr - n) in
  random_covering_partition (Array.sub arr 0 bound) n

let check_covering_partition ~options partition =
  let code_cases = List.mapi (fun (i : int) p -> (p, .<i>.)) partition in
  let int_cases = List.mapi (fun i p -> (p, i)) partition in
  let code = .< fun c -> .~(M.ifmem ~options .<c>. code_cases) >. in
  let f = Runnative.run code in
  for i = 0 to 255 do
    let c = Char.chr i in
    assert_equal (Some (f c))
      (List.find_map (fun (set,x) -> if Charset.mem c set then Some x else None) int_cases)
  done

let check_non_covering_partition ~options partition =
  let code_cases = List.mapi (fun (i : int) p -> (p, .<i>.)) partition in
  let int_cases = List.mapi (fun i p -> (p, i)) partition in
  let code = .< fun c -> .~(M.ifmem ~options .<c>. code_cases ~otherwise:.<-1>.) >. in
  let f = Runnative.run code in
  for i = 0 to 255 do
    let c = Char.chr i in
    assert_equal (f c)
      (match List.find_map (fun (set,x) -> if Charset.mem c set then Some x else None) int_cases with
       | None -> -1
       | Some x -> x)
  done


let test_covering_table _ =
  for i = 1 to 256 do
    check_covering_partition ~options:{match_type=`table} (random_covering_partition all_chars i)
  done

let test_covering_match _ =
  for i = 1 to 256 do
    check_covering_partition ~options:{match_type=`ranges} (random_covering_partition all_chars i)
  done

let test_non_covering_table _ =
  for i = 1 to 255 do
    check_non_covering_partition ~options:{match_type=`table} (random_non_covering_partition all_chars i)
  done

let test_non_covering_match _ =
  for i = 1 to 255 do
    check_non_covering_partition ~options:{match_type=`ranges} (random_non_covering_partition all_chars i)
  done


let suite = "Charmatch tests" >::: [
      "covering tests (table)"     >:: test_covering_table;
      "covering tests (match)"     >:: test_covering_match;
      "non-covering tests (table)" >:: test_non_covering_table;
      "non-covering tests (match)" >:: test_non_covering_match;
    ]

let _ =
  run_test_tt_main suite
