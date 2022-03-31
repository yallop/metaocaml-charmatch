(*
 * Copyright (c) 2019 Jeremy Yallop
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

type options =
  { match_type: [`table | `ranges]
    (** Whether to generate a lookup table or a collection range patterns 
        for the character match (default [`table]) *) }

val default_options : options

module Make(Charset: Set.S with type elt = char) :
sig
  val ifmem : ?options:options -> char code -> ?otherwise:'a code -> (Charset.t * 'a code) list -> 'a code
end

include module type of Make(Set.Make(Char))
