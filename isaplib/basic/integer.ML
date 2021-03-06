(*  Title:      Pure/General/integer.ML
    Author:     Florian Haftmann, TU Muenchen

Unbounded integers.
*)

signature INTEGER =
sig
  val sign: int -> order
  val sum: int list -> int
  val div_mod: int -> int -> int * int
  val square: int -> int
  val pow: int -> int -> int (* exponent -> base -> result *)
  val gcd: int -> int -> int
  val gcds: int list -> int
  val lcm: int -> int -> int
  val lcms: int list -> int
end;

structure Integer : INTEGER =
struct

fun sign x = int_ord (x, 0);

fun sum xs = fold (curry op +) xs 0;

fun div_mod x y = IntInf.divMod (x, y);

fun square x = x * x;

fun pow k l =
  let
    fun pw 0 _ = 1
      | pw 1 l = l
      | pw k l =
          let
            val (k', r) = div_mod k 2;
            val l' = pw k' (l * l);
          in if r = 0 then l' else l' * l end;
  in
    if k < 0
    then error "pow: negative exponent"
    else pw k l
  end;

fun gcd x y =
  let
    fun gxd x y = if y = 0 then x else gxd y (x mod y)
  in if x < y then gxd y x else gxd x y end;

fun gcds xs = fold gcd xs 0;

fun lcm x y = (x * y) div (gcd x y);
fun lcms xs = fold lcm xs 1;

end;

