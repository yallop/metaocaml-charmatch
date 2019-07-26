(*
 * Copyright (c) 2019 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

val ifmem : char code -> ?otherwise:'a code -> (Set.Make(Char).t * 'a code) list -> 'a code
