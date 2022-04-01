(*
 * Copyright (c) 2019 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

module Make(Charset: Set.S with type elt = char) :
sig
  val ifmem : char code -> ?otherwise:'a code -> (Charset.t * 'a code) list -> 'a code
end

include module type of Make(Set.Make(Char))
