-- Copyright 1995-2002 by Michael Stillman

MonomialIdeal = new Type of Ideal
MonomialIdeal.synonym = "monomial ideal"
monomialIdeal = method(TypicalValue => MonomialIdeal,SingleArgumentDispatch=>true)
numgens MonomialIdeal := I -> I.numgens
raw MonomialIdeal := I -> I.RawMonomialIdeal
generators MonomialIdeal := (I) -> map(ring I, rawMonomialIdealToMatrix raw I)

ideal MonomialIdeal := (I) -> ideal generators I

newMonomialIdeal := (R,rawI) -> new MonomialIdeal from {
     symbol numgens => rawNumgens rawI,
     symbol RawMonomialIdeal => rawI,
     symbol ring => R
     }

monomialIdealOfRow := (i,m) -> newMonomialIdeal(ring m,rawMonomialIdeal(raw m, i))

codim Module := M -> if M.cache.?codim then M.cache.codim else M.cache.codim = (
     R := ring M;
     if M == 0 then infinity
     else if isField R then 0
     else if R === ZZ then if M ** QQ == 0 then 1 else 0
     else (
	  p := generators gb presentation M;
	  n := rank target p;
	  c := infinity;
	  for i from 0 to n-1 when c > 0 do c = min(c,codim monomialIdealOfRow(i,p));
	  c - codim R)
     )

toString MonomialIdeal := m -> if m.?name then m.name else "monomialIdeal " | toString generators m

UnaryMonomialIdealOperation  := (operation) -> (m) -> newMonomialIdeal(ring m, operation raw m)
BinaryMonomialIdealOperation := (operation) -> (m,n) -> newMonomialIdeal(ring m, operation(raw m, raw n))

-- net MonomialIdeal := I -> if I == 0 then "0" else "monomialIdeal " | net toSequence first entries generators I

MonomialIdeal ^ ZZ := MonomialIdeal => (I,n) -> SimplePowerMethod(I,n)

Ring / MonomialIdeal := (R,I) -> R / ideal I

monomialIdeal MonomialIdeal := I -> (
     if instance(I, MonomialIdeal) then (		    -- this is weird!
          sendgg(ggPush I, ggcopy);
          newMonomialIdeal ring I))

monomialIdeal Matrix := MonomialIdeal => f -> (
     if numgens target f =!= 1 then error "expected a matrix with 1 row";
     monomialIdealOfRow(0,f))

monomialIdeal List := MonomialIdeal => v -> monomialIdeal matrix {splice v}
monomialIdeal Sequence := v -> monomialIdeal toList v

MonomialIdeal == MonomialIdeal := (m,n) -> m === n

MonomialIdeal == ZZ := (m,i) -> (
     if i === 0 then numgens m == 0
     else error "asked to compare monomial ideal to nonzero integer")
ZZ == MonomialIdeal := (i,m) -> m == i

MonomialIdeal + MonomialIdeal := MonomialIdeal => (I,J) -> (
     if ring I =!= ring J then error "expected monomial ideals in the same ring";
     newMonomialIdeal(ring I, raw I + raw J))
MonomialIdeal * MonomialIdeal := MonomialIdeal => (I,J) -> (
     if ring I =!= ring J then error "expected monomial ideals in the same ring";
     newMonomialIdeal(ring I, raw I * raw J))

radical MonomialIdeal := MonomialIdeal => options -> (I) -> (UnaryMonomialIdealOperation rawRadical) I

MonomialIdeal : MonomialIdeal := MonomialIdeal => BinaryMonomialIdealOperation rawColon

saturate(MonomialIdeal, MonomialIdeal) := MonomialIdeal => options -> (I,J) -> (BinaryMonomialIdealOperation rawSaturate) (I,J)

int := (I,J) -> (
     if ring I =!= ring J then error "expected monomial ideals in the same ring";
     newMonomialIdeal(ring I, rawIntersect(raw I, raw J)))

intersect(List) := x -> intersect toSequence x

intersect(Sequence) := args -> (
    -- first check that all modules have the same target
    -- and the same base ring
    if #args === 0 then error "expected at least one argument";
    M := args#0;
    R := ring M;
    if class M === MonomialIdeal then (
	 if not all(args, M -> class M === MonomialIdeal and R === ring M)
	 then error "expected monomial ideals over the same ring";
	 i := 1;
	 while i < #args do (
	      M = int(M,args#i);
	      i = i+1;
	      );
	 M)
    else if class M === Module then (
    	 F := ambient args#0;
	 if not all(args, N -> ambient N == F)
	 or M.?relations 
	 and not all(args, N -> 
	      N.?relations 
	      and (N.relations == M.relations
		   or
		   image N.relations == image M.relations
		   )
	      )
    	 then error "all modules must be submodules of the same module";
    	 relns := directSum apply(args, N -> (
		   if N.?relations 
		   then generators N | N.relations
		   else generators N
		   )
	      );
    	 g := map(R^(#args),R^1, table(#args,1,x->1)) ** id_F;
	 h := modulo(g, relns);
	 if M.?relations then h = compress( h % M.relations );
    	 subquotient( h, if M.?relations then M.relations )
	 )
    else if class M === Ideal then (
	 ideal intersect apply(args,module)
	 )
    else error "expected modules, ideals, or monomial ideals"
    )

borel MonomialIdeal := MonomialIdeal => UnaryMonomialIdealOperation rawStronglyStableClosure
isBorel MonomialIdeal := m -> UnaryMonomialIdealOperation rawIsStronglyStable
codim MonomialIdeal := m -> rawCodimension raw m
poincare MonomialIdeal := M -> ( --poincare matrix m
     R := ring M;
     ZZn := degreesRing(R);
     if not M.?poincare then (
	if not M.cache.?poincareComputation then (
	    sendgg(ggPush ZZn, ggPush M, gghilb);
	    M.cache.poincareComputation = newHandle());
        sendgg(ggPush M.cache.poincareComputation, ggPush (-1), ggcalc);
	sendgg(ggPush M.cache.poincareComputation, gggetvalue);
        M.poincare = ZZn.pop());
     M.poincare)

minprimes MonomialIdeal := MonomialIdeal => m -> (
     sendgg(ggPush m, ggprimes);
     newMonomialIdeal ring m)

-----------------------------------------------------------------------------
-- this code below here is by Greg Smith
-----------------------------------------------------------------------------

expression MonomialIdeal := (I) -> (
     new FunctionApplication from {
     	  monomialIdeal, (
	       v := expression toSequence first( entries generators I);
     	       if #v === 1 then v#0 else v
	       )
     	  }
     )

net MonomialIdeal := (I) -> (
     if numgens I === 0 then "0"
     else net expression I
     )

MonomialIdeal.AfterPrint = MonomialIdeal.AfterNoPrint = (I) -> (
     << endl;				  
     << concatenate(interpreterDepth:"o") << lineNumber << " : MonomialIdeal of " 
     << ring I << endl;
     )

monomialIdeal Ideal :=  MonomialIdeal => (I) -> monomialIdeal generators gb I

monomialIdeal Module := MonomialIdeal => (M) -> (
     if isSubmodule M and rank ambient M === 1 
     then monomialIdeal generators M
     else error "expected a submodule of a free module of rank 1"
     )

monomialIdeal RingElement := MonomialIdeal => v -> monomialIdeal {v}
monomialIdeal Ring := MonomialIdeal => R -> monomialIdeal {0_R}
ring MonomialIdeal := I -> I.ring
numgens MonomialIdeal := I -> I.numgens
MonomialIdeal _ ZZ := (I,n) -> (generators I)_(0,n)
module MonomialIdeal := Module => (I) -> image generators I

isMonomialIdeal = method(TypicalValue => Boolean)
isMonomialIdeal Thing := x -> false
isMonomialIdeal MonomialIdeal := (I) -> true
isMonomialIdeal Ideal := (I) -> isPolynomialRing ring I and all(first entries generators I, r -> size r === 1)

MonomialIdeal == Ideal := (I,J) -> ideal I == J
Ideal == MonomialIdeal := (I,J) -> I == ideal J

MonomialIdeal == Ring := (I,R) -> (
     if ring I =!= R then error "expected ideals in the same ring";
     1_R % I == 0)
Ring == MonomialIdeal := (R,I) -> I == R

MonomialIdeal + Ideal := Ideal => (I,J) -> ideal I + J
Ideal + MonomialIdeal := Ideal => (I,J) -> I + ideal J

RingElement * MonomialIdeal := MonomialIdeal => (r,I) -> monomialIdeal (r * generators I)
ZZ * MonomialIdeal := MonomialIdeal => (r,I) -> monomialIdeal (r * generators I)

MonomialIdeal * Ideal := Ideal => (I,J) -> ideal I * J
Ideal * MonomialIdeal := Ideal => (I,J) -> I * ideal J

MonomialIdeal * Module := Module => (I,M) -> ideal I * M

MonomialIdeal * Ring := Ideal => (I,S) -> if ring I === S then I else monomialIdeal(I.generators ** S)
Ring * MonomialIdeal := Ideal => (S,I) -> if ring I === S then I else monomialIdeal(I.generators ** S)

Matrix % MonomialIdeal := Matrix => (f,I) -> f % forceGB generators I
RingElement % MonomialIdeal := (r,I) -> r % forceGB generators I
ZZ % MonomialIdeal := (r,I) -> r_(ring I) % forceGB generators I

Matrix // MonomialIdeal := Matrix => (f,I) -> f // forceGB generators I
RingElement // MonomialIdeal := (r,I) -> r // forceGB generators I
ZZ // MonomialIdeal := (r,I) -> r_(ring I) // forceGB generators I

dim MonomialIdeal := I -> dim ring I - codim I

degree MonomialIdeal := I -> degree cokernel generators I   -- maybe it's faster with 'poincare'

jacobian MonomialIdeal := Matrix => (I) -> jacobian generators I

resolution MonomialIdeal := ChainComplex => options -> I -> resolution ideal I
betti MonomialIdeal := I -> betti ideal I


lcmOfGens := (I) -> if I#?(local lcm) then I#(local lcm) else I#(local lcm) = (
     max \ transpose apply(first entries generators I, i -> first exponents i)
     )



 -- We use E. Miller's definition for nonsquare 
 -- free monomial -- ideals.

dual(MonomialIdeal, List) := (I,a) -> ( -- Alexander dual
     R := ring I;
     X := generators R;
     aI := lcmOfGens I;
     if aI =!= a then (
     	  if #aI =!= #a 
	  then error (
	       "expected list of length ",
	       toString (#aI));
	  scan(a, aI, 
	       (b,c) -> (
		    if b<c then
		    error "exponent vector not large enough"
		    ));
	  ); 
     S := R/(I + monomialIdeal apply(#X, i -> X#i^(a#i+1)));
     monomialIdeal contract(
	  lift(syz transpose vars S, R), 
	  product(#X, i -> X#i^(a#i))))

dual(MonomialIdeal,RingElement) := (I,r) -> dual(I,first exponents r)

dual MonomialIdeal := (I) -> dual(I, lcmOfGens(I))    

--  PRIMARY DECOMPOSITION  ---------------------------------
primaryDecomposition MonomialIdeal := List => o -> (I) -> (
     R := ring I;
     aI := lcmOfGens I;
     M := first entries generators dual I;
     L := unique apply(#M, i -> first exponents M_i);
     apply(L, i -> monomialIdeal apply(#i, j -> ( 
		    if i#j === 0 then 0_R 
		    else R_j^(aI#j+1-i#j)
		    )))
     )



--  ASSOCIATED PRIMES  -------------------------------------
ass MonomialIdeal := List => o -> (I) -> (
     R := ring I;
     a := lcmOfGens I + toList(numgens R:1);
     L := first entries generators dual I;
     L = apply(L, i -> a - first exponents i);
     L = unique apply(L, i -> apply(#i, j -> if i#j === 0 or i#j === a#j then 0 else 1));
     apply(L, i -> monomialIdeal flatten apply(#i, j -> if i#j === 0 then 0_R else R_j )))


--  TESTING IF A THING IS A SQUARE FREE MONOMIAL IDEAL  ----
isSquareFree = method(TypicalValue => Boolean)		    -- could be isRadical?
-- isSquareFree Thing := x -> false
isSquareFree MonomialIdeal := (I) -> all(first entries generators I, m -> all(first exponents m, i -> i<2))

--  STANDARD PAIR DECOMPOSITION  ---------------------------
-- algorithm 3.2.5 in Saito-Sturmfels-Takayama
standardPairs = method()
standardPairs(MonomialIdeal, List) := (I,D) -> (
     R := ring I;
     X := generators R;
     S := {};
     k := coefficientRing R;
     scan(D, L -> ( 
     	       Y := X;
     	       m := vars R;
	       Lset := set L;
	       Y = select(Y, r -> not Lset#?r);
     	       m = substitute(m, apply(L, r -> r => 1));
	       -- using monoid to create ring to avoid 
	       -- changing global ring.
     	       A := k (monoid [Y]);
     	       phi := map(A, R, substitute(m, A));
     	       J := ideal mingens ideal phi generators I;
     	       Jsat := saturate(J, ideal vars A);
     	       if Jsat != J then (
     	  	    B := flatten entries super basis (
			 trim (Jsat / J));
		    psi := map(R, A, matrix{Y});
		    S = join(S, apply(B, b -> {psi(b), L}));
	       	    )));
     S)

Delta := (I) -> (
     X := generators ring I;
     d := #X - pdim cokernel generators I;
     select( apply(ass I, J -> set X - set first entries generators J), Y -> #Y >= d ) / toList
     )

standardPairs MonomialIdeal := (I) -> standardPairs(I,Delta I)

--  LARGEST MONOMIAL IDEAL CONTAINED IN A GIVEN IDEAL  -----
monomialSubideal = method();				    -- needs a new name?
monomialSubideal Ideal := (I) -> (
     t := local t;
     R := ring I;
     X := generators R;
     k := coefficientRing R;
     S := k( monoid [t, X, MonomialOrder => Eliminate 1]);
     J := substitute(I, S);
     scan(#X, i -> (
	       w := {1} | toList(i:0) | {1} | toList(#X-i-1:0);
	       J = ideal homogenize(generators gb J, (generators S)#0, w);
	       J = saturate(J, (generators S)#0);
	       J = ideal selectInSubring(1, generators gb J);
	       ));
     monomialIdeal substitute(J, R)
     )

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/m2 "
-- End:
