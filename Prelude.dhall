-- Avoid dependency on the Dhall prelude.
let map =
        λ(a : Type)
      → λ(b : Type)
      → λ(f : a → b)
      → λ(xs : List a)
      → List/build
        b
        (   λ(l : Type)
          → λ(cons : b → l → l)
          → λ(nil : l)
          → List/fold a xs l (λ(y : a) → λ(ys : l) → cons (f y) ys) nil
        )

let concat =
        λ(a : Type)
      → λ(xss : List (List a))
      → List/build
        a
        (   λ(l : Type)
          → λ(finCons : a → l → l)
          → λ(finNil : l)
          → List/fold
            (List a)
            xss
            l
            (   λ(y : List a)
              → λ(ys : l)
              → List/fold a y l (λ(z : a) → λ(zs : l) → finCons z zs) ys
            )
            finNil
        )

in  { map = map, concat = concat }
