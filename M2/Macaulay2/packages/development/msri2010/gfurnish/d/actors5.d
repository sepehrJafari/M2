--		Copyright 1995 by Daniel R. Grayson

use C;
use system; 
use util;
use evaluate;
use common;
use evaluate;
use common;
use binding;
use nets;
use varnets;
use parser;
use lex;
use xml;
use gmp;
use tokens;
use err;
use stdiop;
use ctype;
use stdio;
use varstrin;
use strings;
use actors;
use actors2;
use basic;
use struct;
use objects;
use actors4;
use xmlactors;
use engine;

--let's see whether this is obsolete, so we can lookup up a method for assignment instead!

-- replaceContents(e:Expr):Expr := (
--      when e is s:Sequence do
--      when s.0 is o:HashTable do (
-- 	  if o.mutable then (
-- 	       when s.1 is p:HashTable do (
-- 		    o.table = copy(p.table);
-- 		    o.numEntries = p.numEntries;
-- 		    s.0)
-- 	       else WrongArg(2,"a hash table"))
-- 	  else WrongArg(1,"a mutable hash table"))
--      is l:List do (
-- 	  if l.mutable then (
-- 	       when s.1
-- 	       is p:List do (
-- 		    l.v = copy(p.v);
-- 		    s.0)
-- 	       is t:Sequence do (
-- 		    l.v = copy(t);
-- 		    s.0)
-- 	       else WrongArg(2,"a list or sequence"))
-- 	  else WrongArg(1,"a mutable list"))
--      else WrongNumArgs(2)
--      else WrongNumArgs(2));
-- setupfun("replaceContents",replaceContents);

getParsing(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:SymbolClosure
     do (
	  x := s.symbol.word.parse;
	  list( Expr(toInteger(x.precedence)), Expr(toInteger(x.binaryStrength)), Expr(toInteger(x.unaryStrength))))
     else nullE);
setupfun("getParsing",getParsing);

dumpdatafun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:string do (
	  o := stdin.insize;
	  p := stdin.eof;
	  q := stdin.inindex;
	  stdin.insize = 0;
	  stdin.eof = false;
	  stdin.inindex = 0;
	  r := dumpdata(s);
	  stdin.insize = o;
	  stdin.eof = p;
	  stdin.inindex = q;
	  if 0 == r then nullE
	  else buildErrorPacket("failed to dump data to '" + s + "'"))
     else WrongArgString(0+1)
     );
setupfun("dumpdata",dumpdatafun);

loaddatafun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do (
	  when s.0 is x:Boolean do
	  when s.1 is s:string do (
	       loaddata(if x == True then 1 else 0, s);			  -- should not return
	       buildErrorPacket("failed to load data from '" + s + "'"))
	  else WrongArgString(2)
	  else WrongArgBoolean(1)
	  )
     is s:string do (
	  notifyYes := 1;
	  loaddata(notifyYes,s);			  -- should not return
	  buildErrorPacket("failed to load data from '" + s + "'"))
     else WrongArg("string, or a pair: boolean value and string")
     );
setupfun("loaddata",loaddatafun);

LongDoubleRightArrowFun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LongDoubleRightArrowS);
setup(LongDoubleRightArrowS,LongDoubleRightArrowFun);

LongLongDoubleRightArrowFun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LongLongDoubleRightArrowS);
setup(LongLongDoubleRightArrowS,LongLongDoubleRightArrowFun);

LongDoubleLeftArrowFun1(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,LongDoubleLeftArrowS);
LongDoubleLeftArrowFun2(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LongDoubleLeftArrowS);
setup(LongDoubleLeftArrowS,LongDoubleLeftArrowFun1,LongDoubleLeftArrowFun2);

LongLongDoubleLeftArrowFun1(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,LongLongDoubleLeftArrowS);
LongLongDoubleLeftArrowFun2(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LongLongDoubleLeftArrowS);
setup(LongLongDoubleLeftArrowS,LongLongDoubleLeftArrowFun1,LongLongDoubleLeftArrowFun2);

LongBiDoubleArrowFun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LongBiDoubleArrowS);
setup(LongBiDoubleArrowS,LongBiDoubleArrowFun);

binaryDeductionFun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,DeductionS);
unaryDeductionFun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,DeductionS);
setup(DeductionS,unaryDeductionFun,binaryDeductionFun);

-- doublePointerfun(lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,DoubleArrowS);
optionFun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := (
     l := eval(localInterpState,lhs);
     when l is Error do l
     else (
     	  r := eval(localInterpState,rhs);
     	  when r is Error do r
	  else list(optionClass,Sequence(l,r))));
setup(DoubleArrowS,optionFun);

prependfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e 
     is a:Sequence do (
	  if length(a) != 2
	  then WrongNumArgs(2)
	  else (
	       elem := a.0;
	       lst := a.1;
	       when lst
	       is y:Sequence do Expr(
		    new Sequence len length(y) + 1 do (
			 provide elem;
			 foreach t in y do provide t;
			 )		    
		    )
	       is y:List do (
		    r := List(
			 y.class,
			 new Sequence len length(y.v) + 1 do (
			      provide elem;
			      foreach t in y.v do provide t;
			      ),
			 0,y.mutable);
		    sethash(r,y.mutable);
		    Expr(r))
	       else WrongArg(1+1,"a list or sequence")
	       )
	  )
     else WrongNumArgs(2));
setupfun("prepend",prependfun);

appendfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e 
     is a:Sequence do (
	  if length(a) != 2
	  then WrongNumArgs(2)
	  else (
	       elem := a.1;
	       lst := a.0;
	       when lst
	       is y:Sequence do Expr(
		    new Sequence len length(y) + 1 do (
			 foreach t in y do provide t;
			 provide elem;
			 )		    
		    )
	       is y:List do (
		    r := List(
			 y.class,
			 new Sequence len length(y.v) + 1 do (
			      foreach t in y.v do provide t;
			      provide elem;
			      ),
			 0,y.mutable);
		    sethash(r,y.mutable);
		    Expr(r))
	       else WrongArg(0+1,"a list or sequence")
	       )
	  )
     else WrongNumArgs(2));
setupfun("append",appendfun);

exitfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is ZZ do (
	  if isInt(e) 
	  then (
	       exit(toInt(e));
	       nullE)
	  else WrongArgSmallInteger(1))
     else WrongArgZZ(1));
setupfun("exit",exitfun).protected = false;

applythem(localInterpState:threadLocalInterp,obj:HashTable,fn:FunctionClosure):void := applyFCE(localInterpState,fn,Expr(obj));

lookupCountFun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:SymbolClosure do Expr(toInteger(s.symbol.lookupCount))
     else WrongArg(1,"a symbol")
     );
setupfun("lookupCount",lookupCountFun);

use GC;
CollectGarbage(localInterpState:threadLocalInterp,e:Expr):Expr := (
     gcollect();
     nullE);
setupfun("collectGarbage",CollectGarbage);

--gcdump(e:Expr):Expr := (
--     dump();
--     nullE);
--setupfun("gcDump",gcdump);

integermod(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do 
     if length(a) == 2 then 
     when a.0 is x:ZZ do 
     when a.1 is y:ZZ do 
     if y === 0 then a.0
     else Expr(x % y)
     else WrongArgZZ(2)
     else WrongArgZZ(1)
     else WrongNumArgs(2)
     else WrongNumArgs(2));
installMethod(PercentS,ZZClass,ZZClass,integermod);

modC(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,PercentS);
setup(PercentS,modC);

AtAtfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,AtAtS);
setup(AtAtS,AtAtfun);

StarStarfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,StarStarS);
setup(StarStarS,StarStarfun);

doubleplusfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,PlusPlusS);
setup(PlusPlusS,doubleplusfun);

lesslessfun2(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LessLessS);
lesslessfun1(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,LessLessS);
setup(LessLessS,lesslessfun1,lesslessfun2);

greatergreaterfun2(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,GreaterGreaterS);
setup(GreaterGreaterS,greatergreaterfun2);

barfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,BarS);
setup(BarS,barfun);

PowerStarStarfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,PowerStarStarS);
setup(PowerStarStarS,PowerStarStarfun);

colonfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,ColonS);
setup(ColonS,colonfun);

ampersandfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,AmpersandS);
setup(AmpersandS,ampersandfun);

hathatfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,HatHatS);
setup(HatHatS,hathatfun);

Tildefun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,TildeS);
setuppostfix(TildeS,Tildefun);

ParenStarParenfun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,ParenStarParenS);
setuppostfix(ParenStarParenS,ParenStarParenfun);

UnderscoreStarfun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,UnderscoreStarS);
setuppostfix(UnderscoreStarS,UnderscoreStarfun);

PowerStarfun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,PowerStarS);
setuppostfix(PowerStarS,PowerStarfun);

Exclamationfun(localInterpState:threadLocalInterp,rhs:Code):Expr := unarymethod(localInterpState,rhs,ExclamationS);
setuppostfix(ExclamationS,Exclamationfun);

factorial(localInterpState:threadLocalInterp,x:Expr):Expr := (
     when x
     is x:RR do Expr(factorial(x))
     is x:QQ do Expr(factorial(toRR(x)))
     is x:ZZ do (
	  if !isULong(x) then return WrongArgSmallInteger();
	  n := toULong(x);
	  if n<2 then return Expr(toInteger(1));
	  Expr(factorial(n)))
     else WrongArg("integral or real number"));
setupfun("factorial",factorial);

installMethod(ExclamationS,RRClass,factorial);
installMethod(ExclamationS,ZZClass,factorial);
installMethod(ExclamationS,QQClass,factorial);

underscorefun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,UnderscoreS);
setup(UnderscoreS,underscorefun);

dotfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := (
     left := eval(localInterpState,lhs);
     when left is Error do left
     is x:HashTable do (
	  when rhs
	  is r:globalSymbolClosureCode do lookup1force(x, Expr(SymbolClosure(globalFrame,r.symbol)))
	  else printErrorMessageE(rhs,"expected a symbol"))
     else WrongArg(1,"a hash table")
     );
setup(DotS,dotfun);

dotQfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := (
     left := eval(localInterpState,lhs);
     when left is Error do left
     is x:HashTable do (
	  when rhs
	  is r:globalSymbolClosureCode do if lookup1Q(x,Expr(SymbolClosure(globalFrame,r.symbol))) then True else False
	  else printErrorMessageE(rhs,"expected a symbol"))
     else False);
setup(DotQuestionS,dotQfun);

atfun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,AtS);
setup(AtS,atfun);

leftDividefun(localInterpState:threadLocalInterp,lhs:Code,rhs:Code):Expr := binarymethod(localInterpState,lhs,rhs,LeftDivideS);
setup(LeftDivideS,leftDividefun);

import WindowWidth(fd:int):int;
import WindowHeight(fd:int):int;
fileWidth(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is o:file do (
	  if o.infd == -1 && o.outfd == -1
	  then WrongArg("an open file")
	  else Expr(toInteger(WindowWidth(if o.infd != -1 then o.infd else o.outfd)))
	  )
     else WrongArg("a file"));
setupfun("fileWidth",fileWidth);
fileHeight(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is o:file do (
	  if o.infd == -1 && o.outfd == -1
	  then WrongArg("an open file")
	  else Expr(toInteger(WindowHeight(if o.infd != -1 then o.infd else o.outfd)))
	  )
     else WrongArg("a file"));
setupfun("fileHeight",fileHeight);

horizontalJoin(localInterpState:threadLocalInterp,s:Sequence):Expr := (
     s = deepsplice(localInterpState,s);
     ln := 0;
     foreach f at i in s do (
	  when f 
	  is Nothing do nothing
	  is n:Net do (ln = ln + 1;)
	  is s:string do (ln = ln + 1;)
	  else return WrongArg(i+1,"a net, string, or null"));
     v := new array(Net) len ln do (
	  foreach f in s do (
	       when f 
	       is Nothing do nothing
	       is n:Net do provide n
	       is s:string do provide toNet(s)
	       else nothing));
     Expr(HorizontalJoin(v)));
horizontalJoin(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do horizontalJoin(localInterpState,s)
     is s:List do horizontalJoin(localInterpState,s.v)
     is n:Net do e
     is s:string do Expr(toNet(s))
     is Nothing do horizontalJoin(localInterpState,emptySequence)
     else WrongArg("a net, a string, or a list or sequence of nets and strings"));
setupfun("horizontalJoin",horizontalJoin);

stack(localInterpState:threadLocalInterp,s:Sequence):Expr := (
     s = deepsplice(localInterpState,s);
     ln := 0;
     foreach f at i in s do (
	  when f 
	  is Nothing do nothing
	  is n:Net do (ln = ln + 1;)
	  is s:string do (ln = ln + 1;)
	  else return WrongArg(i+1,"a net, string, or null"));
     v := new array(Net) len ln do (
	  foreach f in s do (
	       when f 
	       is Nothing do nothing
	       is n:Net do provide n
	       is s:string do provide toNet(s)
	       else nothing));
     Expr(VerticalJoin(v)));
stack(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do stack(localInterpState,s)
     is s:List do stack(localInterpState,s.v)
     is n:Net do e
     is s:string do Expr(toNet(s))
     is Nothing do stack(localInterpState,emptySequence)
     else WrongArg("a sequence of nets and strings"));
setupfun("stack",stack);

raisef(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do (
	  if length(s) == 2 then
	  when s.0 is n:Net do
	  when s.1 is i:ZZ do
	  if isInt(i) then Expr(RaiseNet(n,toInt(i)))
	  else WrongArgSmallInteger()
	  else WrongArgZZ()
	  else WrongArg("a net")
	  else WrongNumArgs(2))
     else WrongNumArgs(2));
setupfun("raise",raisef);

replicate(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is a:Sequence do (
	  if length(a) == 2 then (
	       when a.0 is n:ZZ do (
		    if isInt(n) then (
			 x := a.1;
			 m := toInt(n);
			 if m<0 then m=0;
			 Expr(new Sequence len m do provide x))
		    else WrongArgSmallInteger(1))
	       else WrongArgZZ(1))
	  else WrongNumArgs(2))
     else WrongNumArgs(2));
installMethod(ColonS,ZZClass,thingClass,replicate);

bitorfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do (
     	  if length(a) == 2 then (
     	       when a.0 is x:ZZ do (
     		    when a.1 is y:ZZ do Expr(x | y) 
     		    else WrongArgZZ(2)
		    )
	       else WrongArgZZ(1))
	  else WrongNumArgs(2))
     else WrongNumArgs(2));
installMethod(BarS,ZZClass,ZZClass,bitorfun);

bitandfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do (
     	  if length(a) == 2 then (
	       when a.0 is x:ZZ do (
		    when a.1 is y:ZZ do Expr(x & y)
		    else WrongArgZZ(2))
	       else WrongArgZZ(1))
 	  else WrongNumArgs(2))
     else WrongNumArgs(2));
installMethod(AmpersandS,ZZClass,ZZClass,bitandfun);

newNetFile(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do (
	  if length(a) == 0 then Expr(newNetFile())
	  else WrongNumArgs(0))
     else WrongNumArgs(0));
setupfun("newNetFile",newNetFile);

getNetFile(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is n:NetFile do (
	  v := tonets(n);
	  Expr(new Sequence len length(v) do foreach n in v do provide Expr(n)))
     else WrongArg("a net file"));
setupfun("getNetFile",getNetFile);

NetFileAppend(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do (
	  if length(a) == 2 then (
	       when a.0 is n:NetFile do (
		    when a.1 is s:string do Expr(n << s)
		    is x:Net do Expr(n << x)
		    else WrongArg(2,"a string or a net"))
	       else WrongArg(1,"a net file"))
	  else WrongNumArgs(2))
     else WrongNumArgs(2));
installMethod(LessLessS,netFileClass,stringClass,NetFileAppend);
installMethod(LessLessS,netFileClass,netClass,NetFileAppend);
		   
showFrames(localInterpState:threadLocalInterp,f:Frame):void := (
     stdout << " frames bound :";
     while (
	  stdout << " " << f.frameID;
	  if f.notrecyclable then stdout << " (NR)";
	  stdout << " [" << f.valuesUsed;
	  if f.valuesUsed != length(f.values) then stdout << "<" << length(f.values);
	  stdout << "]";
	  f != f.outerFrame ) do (
	  stdout << ",";
	  f = f.outerFrame;
	  );
     stdout << endl;
     );

examine(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is sc:SymbolClosure do (
	  f := sc.frame;
	  s := sc.symbol;
	  stdout
	  << "symbol : " << present(s.word.name) << endl
	  << " position : " << s.position << endl
	  << " frameID : " << s.frameID << endl
	  << " frameindex : " << s.frameindex << endl
	  << " lookupCount : " << s.lookupCount << endl
	  << " protected : " << s.protected << endl;
     	  showFrames(localInterpState,f);
          if s.frameID != f.frameID then stdout << " -- warning: incorrect frameID on first frame" << endl;
	  nullE)
     is c:CodeClosure do (
	  f := c.frame;
     	  showFrames(localInterpState,f);
	  nullE)
     is fc:FunctionClosure do (
	  f := fc.frame;
	  model := fc.model;
	  desc := model.desc;
	  stdout
     	  << "function closure :" << endl
     	  << " body hash : " << model.hash << endl
	  << " restargs : " << desc.restargs << endl
	  << " frameID : " << desc.frameID << endl
	  << " framesize : " << desc.framesize << endl
	  << " numparms : " << desc.numparms << endl;
     	  showFrames(localInterpState,f);
	  nullE)
     is model:functionCode do (
	  desc := model.desc;
	  stdout
     	  << "function closure :" << endl
     	  << " hash : " << model.hash << endl
	  << " restargs : " << desc.restargs << endl
	  << " frameID : " << desc.frameID << endl
	  << " framesize : " << desc.framesize << endl
	  << " numparms : " << desc.numparms << endl;
	  nullE)
     is fn:CompiledFunction do (
	  stdout
	  << "compiled function:" << endl
	  << " hash : " << fn.hash << endl;
	  nullE)
     is fnc:CompiledFunctionClosure do (
	  stdout
	  << "compiled function closure:" << endl
	  << " hash : " << fnc.hash << endl
	  << " env : [" << length(fnc.env) << "]" << endl;
	  nullE)
     is dc:DictionaryClosure do (
	  f := dc.frame;
	  d := dc.dictionary;
	  stdout
	  << "dictionary closure:" <<endl
	  << " hash : " << d.hash << endl
	  << " frameID : " << d.frameID << endl
	  << " framesize : " << d.framesize << endl
	  << " transient : " << d.transient << endl
	  << " protected : " << d.protected << endl
	  << " symboltable size : " << d.symboltable.numEntries << endl;
     	  showFrames(localInterpState,f);
          if d.frameID != f.frameID then stdout << " -- warning: incorrect frameID on first frame" << endl;
	  nullE)
     is s:Sequence do (
	  if length(s) == 0 then (
     	       showFrames(localInterpState,localInterpState.localFrame);
	       nullE)
	  else WrongNumArgs(1))
     is s:List do (
	  stdout
	  << "basic list:" << endl
	  << " length: " << length(s.v) << endl
	  << " hash: " << s.hash << endl
	  << " mutable: " << s.mutable << endl;
	  nullE)
     is s:SpecialExpr do (
	  stdout
	  << "special expr:" << endl;
	  examine(localInterpState,s.e);
	  nullE)
     is x:xmlNode do (examine(x); nullE)
     else WrongArg("(), a function, a symbol, or a basic list"));
setupfun("examine",examine);

numparms(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is fc:FunctionClosure do Expr(toInteger(if fc.model.desc.restargs then -1 else fc.model.desc.numparms))
     is fn:CompiledFunction do Expr(toInteger(-1))
     is fnc:CompiledFunctionClosure do Expr(toInteger(-1))
     is s:SpecialExpr do numparms(localInterpState,s.e)
     else WrongArg("a function"));
setupfun("numparms",numparms);

netWidth(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is n:Net do Expr(toInteger(n.width))
     else WrongArg("a net"));
setupfun("netWidth",netWidth);

netHeight(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is n:Net do Expr(toInteger(n.height))
     else WrongArg("a net"));
setupfun("netHeight",netHeight);

netDepth(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is n:Net do Expr(toInteger(length(n.body)-n.height))
     else WrongArg("a net"));
setupfun("netDepth",netDepth);

unstack(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is n:Net do list(new Sequence len length(n.body) do foreach s in n.body do provide Expr(s))
     is s:string do list(e)
     else WrongArg("a net"));
setupfun("unstack",unstack);

alarm(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is i:ZZ do 
     if isInt(i)
     then Expr(toInteger(int(alarm(uint(toInt(i))))))
     else WrongArgSmallInteger()
     else WrongArgZZ()
     );
setupfun("alarm",alarm);

endlfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e 
     is o:file do if o.output then Expr(o << endl) else WrongArg("an output file")
     is n:NetFile do Expr(endlnetfile(n))
     else WrongArg("a file or a net file")
     );
setupfun("endl",endlfun).protected = false;

import CCVERSION:string;
import VERSION:string;
-- import configargs:array(string);
import configargs:string;
import OS:string;
import ARCH:string;
import ISSUE:string;
import MACHINE:string;
import NODENAME:string;
import REL:string;
import timestamp:string;
import LIBFACVERSION:string;
import FROBBYVERSION:string;
import PARIVERSION:string;
import SCSCPVERSION:string;
import GCVERSION:string;
import GMPVERSION:string;
import MPIRVERSION:string;
import MysqlVERSION:string;
import PYTHONVERSION:string;
import NTLVERSION:string;
import FACTORYVERSION:string;
import READLINEVERSION:string;
import MPFRVERSION:string;
import DUMPDATA:bool;
import M2SUFFIX:string;
import EXEEXT:string;
import startupString:string;
import startupFile:string;
import endianness:string;
import packages:string;
import build:string;
import host:string;
import pointersize:int;
setupconst("newline", Expr(newline));

x := newHashTable(hashTableClass,nothingClass);
storeInHashTable(x,Expr("VERSION"),Expr(VERSION));
storeInHashTable(x,Expr("architecture"),Expr(ARCH));
storeInHashTable(x,Expr("issue"),Expr(ISSUE));
storeInHashTable(x,Expr("machine"),Expr(MACHINE));
storeInHashTable(x,Expr("operating system"),Expr(OS));
storeInHashTable(x,Expr("operating system release"),Expr(REL));
storeInHashTable(x,Expr("compiler"),Expr(CCVERSION));
-- storeInHashTable(x,Expr("configure arguments"),Expr(toExpr(configargs)));
storeInHashTable(x,Expr("configure arguments"),Expr(configargs));
storeInHashTable(x,Expr("compile time"),Expr(timestamp));
storeInHashTable(x,Expr("compile node name"),Expr(NODENAME));
storeInHashTable(x,Expr("dumpdata"),Expr(if DUMPDATA then True else False));
storeInHashTable(x,Expr("gc version"),Expr(GCVERSION));
storeInHashTable(x,Expr("mysql version"),Expr(MysqlVERSION));
storeInHashTable(x,Expr("python version"),Expr(PYTHONVERSION));
storeInHashTable(x,Expr("gmp version"),Expr(GMPVERSION));
storeInHashTable(x,Expr("mpir version"),Expr(MPIRVERSION));
storeInHashTable(x,Expr("ntl version"),Expr(NTLVERSION));
storeInHashTable(x,Expr("libfac version"),Expr(LIBFACVERSION));
storeInHashTable(x,Expr("frobby version"),Expr(FROBBYVERSION));
storeInHashTable(x,Expr("pari version"),Expr(PARIVERSION));
storeInHashTable(x,Expr("scscp version"),Expr(SCSCPVERSION));
storeInHashTable(x,Expr("factory version"),Expr(FACTORYVERSION));
storeInHashTable(x,Expr("readline version"),Expr(READLINEVERSION));
storeInHashTable(x,Expr("mpfr version"),Expr(MPFRVERSION));
storeInHashTable(x,Expr("M2 suffix"),Expr(M2SUFFIX));
storeInHashTable(x,Expr("executable extension"),Expr(EXEEXT));
storeInHashTable(x,Expr("M2 name"),Expr("M2" + M2SUFFIX + EXEEXT));
storeInHashTable(x,Expr("endianness"),Expr(endianness));
storeInHashTable(x,Expr("pointer size"),Expr(toInteger(pointersize)));
storeInHashTable(x,Expr("packages"),Expr(packages));
storeInHashTable(x,Expr("build"),Expr(build));
storeInHashTable(x,Expr("host"),Expr(host));
sethash(x,false);
setupconst("version", Expr(x));
setupconst("startupString", Expr(startupString));

remove(x:Sequence,i:int):Sequence := (
     n := length(x);
     if i < 0 then i = i + n;
     if 0 <= i && i < n then (
	  new Sequence len n-1 do foreach y at j in x do if i != j then provide y
	  )
     else x
     );

remove(x:List,i:int):List := (
     v := remove(x.v,i);
     if v == x.v then return x;
     r := List(x.class, v, 0, x.mutable);
     r.hash = hash(r);
     r);

removefun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is args:Sequence do (
	  if length(args) != 2
	  then WrongNumArgs(2)
	  else (
	       when args.0
	       is x:List do (
		    when args.1 is i:ZZ do
		     if isInt(i) then Expr(remove(x,toInt(i))) else WrongArgSmallInteger(2)
		    else WrongArgZZ(2))
	       is x:Sequence do (
		    when args.1 is i:ZZ do
		    if isInt(i) then Expr(remove(x,toInt(i))) else WrongArgSmallInteger(2)
		    else WrongArgZZ(2))
	       is f:Database do (
		    when args.1 is key:string do (
	       		 if !f.isopen then return buildErrorPacket("database closed");
	       		 if !f.mutable then return buildErrorPacket("database not mutable");
	       		 if 0 == dbmdelete(f.handle,key) then nullE
	       		 else buildErrorPacket(dbmstrerror() + " : " + f.filename))
		    else WrongArgString(2))
	       is o:HashTable do (
		    ret := remove(o,args.1);
		    when ret is Error do ret else nullE)
	       else WrongArg(1,"a hash table or database")))
     else WrongNumArgs(2));
setupfun("remove",removefun);

erase(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is t:SymbolClosure do (
	  s := t.symbol;
	  d := globalDictionary;
	  if t.frame != globalFrame then return WrongArg("a global symbol");
	  while (
	       table := d.symboltable;
	       i := s.word.hash & (length(table.buckets)-1);
	       entryList := table.buckets.i;
	       when entryList
	       is entryListCell:SymbolListCell do (
		    if entryListCell.entry == s
		    then (
     	       	    	 if d.protected then return buildErrorPacket("symbol is in a protected dictionary");
			 table.numEntries = table.numEntries - 1;
			 table.buckets.i = entryListCell.next;
			 return nullE;
			 );
		    lastCell := entryListCell;
		    entryList = entryListCell.next;
		    while true do (
			 when entryList
			 is entryListCell:SymbolListCell do (
			      if entryListCell.entry == s
			      then (
     	       	    	 	   if d.protected then return buildErrorPacket("symbol is in a protected dictionary");
				   table.numEntries = table.numEntries - 1;
				   lastCell.next = entryListCell.next;
				   return nullE;
				   );
			      lastCell = entryListCell;
			      entryList = entryListCell.next;
			      )
			 is null do break;
			 );
		    )
	       is null do nothing;
	       d != d.outerDictionary ) do d = d.outerDictionary;
	  buildErrorPacket("symbol has already been erased: "+s.word.name))
     else WrongArg("a symbol")
     );
setupfun("erase", erase);

factorInt(localInterpState:threadLocalInterp,n:int):Expr := (
     facs := newHashTable(Tally,nothingClass);
     if n == 0 then (
	  storeInHashTable(facs,Expr(toInteger(n)),Expr(toInteger(1)));
	  )
     else (
	  d := 2;
	  hadone := false;
	  while (n % d) == 0 && n != -1 && n != 1 do (
	       key := Expr(toInteger(d));
	       storeInHashTable(facs,key, 
		    if hadone 
		    then RealPlus(localInterpState,lookup1(facs,key),Expr(toInteger(1)))
		    else Expr(toInteger(1)));
	       n = n / d;
	       hadone = true;
	       );
	  if n < 0 then (
	       n = -n;
	       storeInHashTable(facs,Expr(toInteger(-1)),Expr(toInteger(1)));
	       );
	  d = 3;
	  while n > 1 do (
	       hadodd := false;
	       while n > 1 && (n % d) == 0 do (
	       	    key := Expr(toInteger(d));
		    storeInHashTable(facs,key, 
			 if hadodd
			 then RealPlus(localInterpState,lookup1(facs,key),Expr(toInteger(1)))
			 else Expr(toInteger(1)));
		    n = n / d;
		    hadodd = true;
		    );
	       d = d+2;
	       if d > n/d then d = n;
	       );
	  );
     Expr(facs));

factorInteger(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is i:ZZ do (
	  if isInt(i) then factorInt(localInterpState,toInt(i))
	  else WrongArgSmallInteger())
     else WrongArgSmallInteger());
setupfun("factorInteger",factorInteger);

-- method functions for use in closures
method1(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := (
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     f := lookup(Class(e),env.0);
     if recursionDepth > recursionLimit then return InternalRecursionLimit();
     recursionDepth = recursionDepth + 1;
     r := applyEE(localInterpState,if f == nullE then env.1 else f,e);
     recursionDepth = recursionDepth - 1;
     r);
method1c(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := (
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     when e is c:HashTable do (
     	  f := lookup(c,env.0);
     	  applyEE(localInterpState,if f == nullE then env.1 else f,e))
     else WrongArg("a class")
     );
newmethod1(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do if length(s) != 2 then WrongNumArgs(2) else (
	  f := s.0;
	  output := s.1;
	  env := Sequence(nullE,f);
	  cfc := Expr(CompiledFunctionClosure(if output == True then method1c else method1,nextHash(),env));
	  env.0 = cfc;
	  cfc)
     else WrongNumArgs(2));
setupfun("newmethod1",newmethod1);

applyEOS(localInterpState:threadLocalInterp,f:Expr,o:Expr,s:Sequence):Expr := (
     if o == nullE then applyES(localInterpState,f,s)
     else (
     	  g := applyEE(localInterpState,f,o);
     	  when g is Error do g else applyES(localInterpState,g,s)));

applyEOE(localInterpState:threadLocalInterp,f:Expr,o:Expr,x:Expr):Expr := (
     if o == nullE then applyEE(localInterpState,f,x)
     else (
     	  g := applyEE(localInterpState,f,o);
     	  when g is Error do g else applyEE(localInterpState,g,x)));

method1234(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := (
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     when e is args:Sequence do (
	  if length(args) == 2 then (
	       f := lookupBinaryMethod(Class(args.0),Class(args.1),env.0);
	       if f == nullE then f = env.1;
	       applyES(localInterpState,f, args))
	  else if length(args) == 3 then (
	       f := lookupTernaryMethod(Class(args.0),Class(args.1),Class(args.2),env.0);
	       if f == nullE then f = env.1;
	       applyES(localInterpState,f, args))
	  else if length(args) == 1 then (
	       f := lookup(Class(args.0),env.0);
	       if f == nullE then f = env.1;
	       applyEE(localInterpState,f, args.0))
	  else if length(args) == 0 then (
	       f := lookup(env.0);
	       if f == nullE then f = env.1;
	       applyES(localInterpState,f, emptySequence))
	  else if length(args) == 4 then (
	       f := lookupQuaternaryMethod(Class(args.0),Class(args.1),Class(args.2),Class(args.3),env.0);
	       if f == nullE then f = env.1;
	       applyES(localInterpState,f, args))
	  else applyES(localInterpState,env.1, args))
     else (
	  f := lookup(Class(e),env.0);
	  if f == nullE then applyEE(localInterpState,env.1,e)
	  else applyEE(localInterpState,f,e)));

method1234o(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := (
     -- e is (opt,arg);
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     when e is s:Sequence do if length(s) != 2 then return WrongNumArgs(2) else (
	  opt := s.0;
	  arg := s.1;
	  when arg is args:Sequence do (
	       if length(args) == 2 then (
		    f := lookupBinaryMethod(Class(args.0),Class(args.1),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args)
		    else applyEOS(localInterpState,f, opt, args))
	       else if length(args) == 3 then (
		    f := lookupTernaryMethod(Class(args.0),Class(args.1),Class(args.2),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args)
		    else applyEOS(localInterpState,f, opt, args))
	       else if length(args) == 1 then (
		    f := lookup(Class(args.0),env.0);
		    if f == nullE then applyEE(localInterpState,env.1, args.0)
		    else applyEOE(localInterpState,f, opt, args.0))
	       else if length(args) == 0 then (
		    f := lookup(env.0);
		    if f == nullE then applyES(localInterpState,env.1, args)
		    else applyEOS(localInterpState,f, opt, args))
	       else if length(args) == 4 then (
		    f := lookupQuaternaryMethod(Class(args.0),Class(args.1),Class(args.2),Class(args.3),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args)
		    else applyEOS(localInterpState,f, opt, args))
	       else applyES(localInterpState,env.1, args))
	  else (
	       f := lookup(Class(arg),env.0);
	       if f == nullE then applyEE(localInterpState,env.1,arg)
	       else applyEOE(localInterpState,f,opt,arg)) )
     else WrongNumArgs(2));

method1234p(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := ( -- just like method1234o, except we call the method function f as f(opt,arg)
     -- e is (opt,arg);
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     when e is s:Sequence do if length(s) != 2 then return WrongNumArgs(2) else (
	  opt := s.0;
	  arg := s.1;
	  when arg is args:Sequence do (
	       if length(args) == 2 then (
		    f := lookupBinaryMethod(Class(args.0),Class(args.1),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args) else applyES(localInterpState,f,s))
	       else if length(args) == 3 then (
		    f := lookupTernaryMethod(Class(args.0),Class(args.1),Class(args.2),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args) else applyES(localInterpState,f,s))
	       else if length(args) == 1 then (
		    f := lookup(Class(args.0),env.0);
		    if f == nullE then applyEE(localInterpState,env.1, args.0) else applyEOE(localInterpState,f, opt, args.0))
	       else if length(args) == 0 then (
		    f := lookup(env.0);
		    if f == nullE then applyES(localInterpState,env.1, args) else applyES(localInterpState,f,s))
	       else if length(args) == 4 then (
		    f := lookupQuaternaryMethod(Class(args.0),Class(args.1),Class(args.2),Class(args.3),env.0);
		    if f == nullE then applyES(localInterpState,env.1, args) else applyES(localInterpState,f,s))
	       else applyES(localInterpState,env.1, args))
	  else (
	       f := lookup(Class(arg),env.0);
	       if f == nullE then applyEE(localInterpState,env.1,arg) else applyES(localInterpState,f,s)) )
     else WrongNumArgs(2));

method1234c(localInterpState:threadLocalInterp,e:Expr,env:Sequence):Expr := (
     -- ClassArgument version
     -- env.0 : the primary method function, used as key for lookup
     -- env.1 : the function to call if no method found
     -- env.2 : the function to call with the (i,args) if i-th output argument isn't even a hashtable, or (-1,) if args is not a sequence
     -- env.3 : a list {false,true,...} telling whether to treat
     --         the corresponding argument as the type.  Otherwise, use
     --         its class.  Assumed to be 'false' for arguments off
     --         the end of the list.
     -- env.4 :  null means: we dispatch on e  , and call the resulting method function f as f e
     --	    	 true means: we dispatch on e.1, and call the resulting method function f as (f e.0) e.1
     --         false means: we dispatch on e.1, and call the resulting method function f as f e
     opt := nullE;
     arg := e;
     disp:= e;
     if env.4 != nullE then (
     	  when e is s:Sequence do
	  if length(s) != 2 then return WrongNumArgs(2)
	  else (
	       if env.4 == True then ( disp = s.1; opt = s.0; arg = s.1; ) else
	       if env.4 == False then ( disp = s.1; ) else
	       return WrongArg(5,"true, false, or null");
	       )
	  else return WrongNumArgs(2));
     when env.3 is u:List do (
	  outputs := u.v;
	  when disp is dispseq:Sequence do
	  if length(dispseq) == 2 then (
	       a0 := (
		    if length(outputs) <= 0 || outputs.0 == False
		    then Class(dispseq.0)
		    else when dispseq.0 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(0)),disp))));
	       a1 := (
		    if length(outputs) <= 1 || outputs.1 == False
		    then Class(dispseq.1)
		    else when dispseq.1 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(1)),disp))));
	       f := lookupBinaryMethod(a0,a1,env.0);
	       if f == nullE then applyES(localInterpState,env.1, dispseq) else applyEOE(localInterpState,f,opt,arg))
	  else if length(dispseq) == 3 then (
	       a0 := (
		    if length(outputs) <= 0 || outputs.0 == False
		    then Class(dispseq.0)
		    else when dispseq.0 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(0)),disp))));
	       a1 := (
		    if length(outputs) <= 1 || outputs.1 == False
		    then Class(dispseq.1)
		    else when dispseq.1 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(1)),disp))));
	       a2 := (
		    if length(outputs) <= 2 || outputs.2 == False
		    then Class(dispseq.2)
		    else when dispseq.2 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(2)),disp))));
	       f := lookupTernaryMethod(a0,a1,a2,env.0);
	       if f == nullE then applyES(localInterpState,env.1, dispseq) else applyEOE(localInterpState,f,opt,arg))
	  else if length(dispseq) == 1 then (
	       a0 := (
		    if length(outputs) <= 0 || outputs.0 == False
		    then Class(dispseq.0)
		    else when dispseq.0 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(0)),disp))));
	       f := lookup(a0,env.0);
	       if f == nullE then applyEE(localInterpState,env.1, dispseq.0) else applyEOE(localInterpState,f,opt,arg))
	  else if length(dispseq) == 4 then (
	       a0 := (
		    if length(outputs) <= 0 || outputs.0 == False
		    then Class(dispseq.0)
		    else when dispseq.0 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(0)),disp))));
	       a1 := (
		    if length(outputs) <= 1 || outputs.1 == False
		    then Class(dispseq.1)
		    else when dispseq.1 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(1)),disp))));
	       a2 := (
		    if length(outputs) <= 2 || outputs.2 == False
		    then Class(dispseq.2)
		    else when dispseq.2 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(2)),disp))));
	       a3 := (
		    if length(outputs) <= 3 || outputs.3 == False
		    then Class(dispseq.3)
		    else when dispseq.3 is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(3)),disp))));
	       f := lookupQuaternaryMethod(a0,a1,a2,a3,env.0);
	       if f == nullE then applyES(localInterpState,env.1, dispseq) else applyEOE(localInterpState,f,opt,arg))
	  else if length(dispseq) == 0 then (
	       f := lookup(env.0);
	       if f == nullE then applyES(localInterpState,env.1, dispseq) else applyEOE(localInterpState,f,opt,arg))
	  else applyES(localInterpState,env.1, dispseq)			    -- it's too long!
	  else (
	       a0 := (
		    if length(outputs) <= 0 || outputs.0 == False
		    then Class(disp)
		    else when disp is o:HashTable do o else return applyEE(localInterpState,env.2, Expr(Sequence(Expr(toInteger(-1)),disp))));
	       f := lookup(a0,env.0);
	       if f == nullE then applyEE(localInterpState,env.1,disp) else applyEOE(localInterpState,f,opt,arg)))
     else buildErrorPacket("env.3: not a list"));
newmethod1234c(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is env:Sequence do (
	  -- see above for description of elements of env, except that env.0 is supplanted by us if it is null or a type of CompiledFunctionClosure
	  if length(env) == 5
	  then (
	       when env.0
	       is Nothing do nothing
	       is typ:HashTable do (
		    if !ancestor(typ,compiledFunctionClosureClass) then return WrongArg(1,"a function or a type of CompiledFunctionClosure");
		    )
	       is CompiledFunction do nothing
	       is CompiledFunctionClosure do nothing
	       is FunctionClosure do nothing
	       is s:SpecialExpr do if ancestor(s.class,functionClass) then nothing else return WrongArg(1,"a function")
	       else return WrongArg(1,"a function or null");
	       when env.1
	       is CompiledFunction do nothing
	       is CompiledFunctionClosure do nothing
	       is FunctionClosure do nothing
	       is s:SpecialExpr do if ancestor(s.class,functionClass) then nothing else return WrongArg(2,"a function")
	       else return WrongArg(2,"a function");
	       when env.2
	       is CompiledFunction do nothing
	       is CompiledFunctionClosure do nothing
	       is FunctionClosure do nothing
	       is s:SpecialExpr do if ancestor(s.class,functionClass) then nothing else return WrongArg(3,"a function")
	       else return WrongArg(3,"a function");
	       when env.3 is u:List do (
		    useClass := u.v;
		    foreach i in useClass do if !(i == True || i == False) 
		    then return  WrongArg(4,"a list of boolean values") ;
		    allFalse := true;
		    foreach i in useClass do if i != False then allFalse = false;
		    env = copy(env);
		    cfc :=
		    if allFalse
		    then (
			 if env.4 == nullE
		    	 then Expr(CompiledFunctionClosure(method1234,nextHash(),env))
			 else if env.4 == True
			 then Expr(CompiledFunctionClosure(method1234o,nextHash(),env))
		    	 else Expr(CompiledFunctionClosure(method1234p,nextHash(),env))
			 )
		    else Expr(CompiledFunctionClosure(method1234c,nextHash(),env));
		    if env.0 == nullE then env.0 = cfc
		    else when env.0 is typ:HashTable do (
			 if typ != compiledFunctionClosureClass then cfc = SpecialExpr(typ,cfc);
			 env.0 = cfc;
			 )
		    else nothing;
		    cfc)
	       else WrongArg(4,"a list of boolean values")
	       )
	  else WrongNumArgs(5))
     else WrongNumArgs(5));
setupfun("newmethod1234c",newmethod1234c);

drop(v:Sequence,b:Expr):Expr := (
     when b
     is n:ZZ do (
	  if isInt(n) then (
	       m := toInt(n);
	       if m < 0 then (
		    m = -m;
		    if m >= length(v) 
		    then Expr(emptySequence)
		    else Expr(new Sequence len length(v)-m at i do provide v.i))
	       else if m == 0 then Expr(v)
	       else (
		    if m >= length(v) 
		    then Expr(emptySequence)
		    else Expr(new Sequence len length(v)-m at i do provide v.(i+m))))
	  else WrongArgSmallInteger())
     is w:List do (
	  if length(w.v) == 2 then (
	       when w.v.0
	       is ii:ZZ do (
		    if isInt(ii) then (
			 i := toInt(ii);
			 if i < 0 then i = 0;
			 when w.v.1
			 is jj:ZZ do (
			      if isInt(jj) then (
				   j := toInt(jj);
				   if j > length(v)-1 then j = length(v)-1;
				   if i > j 
				   then Expr(v)
				   else Expr(
					new Sequence len length(v)-(j-i+1) do (
					     for k from 0 to i-1 
					     do provide v.k;
					     for k from j+1 to length(v) 
					     do provide v.k)))
			      else WrongArg("a list of small integers"))
			 else WrongArg("a list of integers"))
		    else WrongArg("a list of small integers"))
	       else WrongArg("a list of integers"))
	  else WrongArg("a list of two integers"))
     else WrongArg(2,"an integer or list of integers"));
drop(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is args:Sequence do 
     if length(args) == 2 then (
	  when args.0
	  is x:List do (
	       vv := drop(x.v,args.1);
	       when vv
	       is v:Sequence do (
	       	    if v == x.v && x.mutable then v = copy(v);
	       	    list(x.class,v,x.mutable))
	       else vv)
	  is v:Sequence do drop(v,args.1)
	  else WrongArg(1,"a list or sequence"))
     else WrongNumArgs(2)
     else WrongNumArgs(2));
setupfun("drop",drop);

take(localInterpState:threadLocalInterp,v:Sequence,b:Expr):Expr := (
     when b
     is n:ZZ do (
	  if isInt(n) then (
	       m := toInt(n);
	       if m < 0 then (
		    m = -m;
		    if m >= length(v) 
		    then Expr(v)
		    else (
			 k := length(v)-m;
			 Expr(new Sequence len m at i do provide v.(i+k))
			 )
		    )
	       else if m == 0 then Expr(emptySequence)
	       else (
		    if m >= length(v) 
		    then Expr(v)
		    else Expr(new Sequence len m at i do provide v.i)))
	  else WrongArgSmallInteger())
     is w:List do (
	  if length(w.v) == 2 then (
	       when w.v.0
	       is ii:ZZ do (
		    if isInt(ii) then (
			 i := toInt(ii);
			 if i < 0 then i = 0;
			 when w.v.1
			 is jj:ZZ do (
			      if isInt(jj) then (
				   j := toInt(jj);
				   if j > length(v)-1 then j = length(v)-1;
				   if i > j 
				   then Expr(emptySequence)
				   else Expr(
					new Sequence len j-i+1 do (
					     for k from i to j do provide v.k)))
			      else WrongArg("a list of small integers"))
			 else WrongArg("a list of integers"))
		    else WrongArg("a list of small integers"))
	       else WrongArg("a list of integers"))
	  else WrongArg("a list of two integers"))
     else WrongArg(2,"an integer or list of integers"));
take(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is args:Sequence do 
     if length(args) == 2 then (
	  when args.0
	  is x:List do (
	       vv := take(localInterpState,x.v,args.1);
	       when vv
	       is v:Sequence do (
	       	    if v == x.v && x.mutable then v = copy(v);
	       	    list(x.class,v,x.mutable))
	       else vv)
	  is v:Sequence do take(localInterpState,v,args.1)
	  else WrongArg(1,"a list or sequence"))
     else WrongNumArgs(2)
     else WrongNumArgs(2));
setupfun("take",take);

anyhex(s:string):bool := (
     foreach c in s do if c == '+' || c == '%' then return true;
     false);
lengthUnhexed(s:string):int := (
     n := 0;
     foreach c in s do if c == '%' then n=n-1 else n=n+1;
     if n < 0 then 0 else n);
hex(c:char):int := (
     i := int(c);
     if i >= int('0') && i <= int('9') then i - int('0')
     else if i >= int('A') && i <= int('F') then i + (10 - int('A'))
     else if i >= int('a') && i <= int('f') then i + (10 - int('a'))
     else 0);
unhex(s:string):string := (
     if !anyhex(s) then s
     else new string len lengthUnhexed(s) do (
	  hexing := 0;
	  hexval := 0;
	  foreach c in s 
	  do   if hexing == 2 then (hexing = 1; hexval = hex(c); ) 
	  else if hexing == 1 then (hexing = 0; provide char(hexval * 16 + hex(c))) 
	  else if c == '%'    then (hexing = 2;)
	  else if c == '+'    then (provide ' ';)
	  else (provide c;);
	  while true do provide ' '			    -- shouldn't happen
	  ));
unhex(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:string do Expr(unhex(s))
     else WrongArgString());
setupfun("unhex",unhex);

echo(f:file,v:bool):Expr := (
     if f.input then ( f.echo = v; nullE)
     else WrongArg("an input file"));
echoOn(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do
     if length(s) == 0 then echo(stdIO,true)
     else WrongArg("a file or ()")
     is f:file do echo(f,true)
     else WrongArg("a file or ()")
     );
setupfun("echoOn",echoOn);
echoOff(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do
     if length(s) == 0 then echo(stdIO,false)
     else WrongArg("a file or ()")
     is f:file do echo(f,false)
     else WrongArg("a file or ()")
     );
setupfun("echoOff",echoOff);
kill(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e 
     is pid:ZZ do if !isInt(pid) then WrongArgSmallInteger() else (
	  id := toInt(pid);
	  if kill(id,9) == ERROR then buildErrorPacket("can't kill process")
	  else if wait(id) == ERROR then buildErrorPacket("process killed, but wait fails") 
	  else nullE
	  )
     is f:file do (
	  if f.pid != 0 then (
	       if kill(f.pid,9) == ERROR then buildErrorPacket("can't kill process")
	       else if wait(f.pid) == ERROR  then buildErrorPacket("process killed, but wait fails")
	       else (
		    f.pid = 0;
		    nullE
		    )
	       )
	  else WrongArg("a file with a process associated to it")
	  )
     else WrongArg("a file"));
setupfun("kill",kill);

setEcho(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is f:file do (
	  f.echo = true;
	  nullE
	  )
     else nullE);
setupfun("setEcho",setEcho);
clearEcho(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is f:file do (
	  f.echo = false;
	  nullE
	  )
     else nullE);
setupfun("clearEcho",clearEcho);

readlinkfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
	  v := readlink(expandFileName(filename));
	  if length(v) == 0 then nullE else Expr(v))
     else WrongArgString());
setupfun("readlink",readlinkfun);

changeDirectory(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do if chdir(filename) == -1 then buildErrorPacket(syscallErrorMessage("changing directory")) else nullE
     else WrongArgString());
setupfun("changeDirectory",changeDirectory);

realpathfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is f:string do (
     	  when realpath(expandFileName(f))
     	  is null do buildErrorPacket(syscallErrorMessage("realpath"))
     	  is p:string do Expr(p)
     	  )
     else WrongArgString());
setupfun("realpath",realpathfun);

setupconst("typicalValues", Expr(typicalValues));
setupconst("flexibleBinaryOperators", Expr(new array(Expr) len length(opsWithBinaryMethod)   do foreach s in opsWithBinaryMethod do provide Expr(s)));
setupconst("flexiblePrefixOperators", Expr(new array(Expr) len length(opsWithUnaryMethod)    do foreach s in opsWithUnaryMethod do provide Expr(s)));
setupconst("flexiblePostfixOperators",Expr(new array(Expr) len length(opsWithPostfixMethod)  do foreach s in opsWithPostfixMethod do provide Expr(s)));
setupconst("fixedBinaryOperators",    Expr(new array(Expr) len length(fixedBinaryOperators)  do foreach s in fixedBinaryOperators do provide Expr(s)));
setupconst("fixedPrefixOperators",    Expr(new array(Expr) len length(fixedPrefixOperators)  do foreach s in fixedPrefixOperators do provide Expr(s)));
setupconst("fixedPostfixOperators",   Expr(new array(Expr) len length(fixedPostfixOperators) do foreach s in fixedPostfixOperators do provide Expr(s)));

fileExists(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is name:string do toExpr(fileExists(expandFileName(name)))
     else WrongArgString()
     );
setupfun("fileExists",fileExists);

removeDirectory(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is name:string do
     if rmdir(expandFileName(name)) == ERROR 
     then buildErrorPacket(syscallErrorMessage("removing a directory"))
     else nullE
     else WrongArgString()
     );
setupfun("removeDirectory",removeDirectory);

removeFile(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is name:string do
     if unlink(expandFileName(name)) == ERROR 
     then buildErrorPacket(syscallErrorMessage("removing a file"))
     else nullE
     else WrongArgString()
     );
setupfun("removeFile",removeFile);

readDirectory(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
	  filename = expandFileName(filename);
	  r := readDirectory(filename);
	  when r is null do buildErrorPacket("can't read directory '" + filename + "' : " + syserrmsg())
	  is x:array(string) do Expr(list(new Sequence len length(x) do foreach i in x do provide Expr(i))))
     else WrongArgString());
setupfun("readDirectory",readDirectory);

isDirectory(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
	  filename = expandFileName(filename);
	  if !fileExists(filename) then return False;
	  r := isDirectory(filename);
	  if r == -1 then buildErrorPacket("can't see file '" + filename + "' : " + syserrmsg())
	  else if r == 1 then True else False)
     else WrongArgString()
     );
setupfun("isDirectory",isDirectory);

isRegularFile(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
     	  filename = expandFileName(filename);
	  r := isRegularFile(filename);
	  if r == -1 then buildErrorPacket("can't see file '" + filename + "' : " + syserrmsg())
	  else if r == 1 then True else False)
     else WrongArgString()
     );
setupfun("isRegularFile",isRegularFile);

linkfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do if length(s) != 2 then WrongNumArgs(2) else
     when s.0 is oldfilename:string do
     when s.1 is newfilename:string do (
	  oldfilename = expandFileName(oldfilename);
	  newfilename = expandFileName(newfilename);
     	  if -1 == link(oldfilename,newfilename)
	  then buildErrorPacket("failed to link file " + oldfilename + " to " + newfilename + " : " + syserrmsg()) else nullE     
	  )
     else WrongArgString(2)
     else WrongArgString(1)
     else WrongNumArgs(2));
setupfun("linkFile",linkfun);

symlinkfun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do if length(s) != 2 then WrongNumArgs(2) else
     when s.0 is oldfilename:string do
     when s.1 is newfilename:string do (
	  oldfilename = expandFileName(oldfilename);
	  newfilename = expandFileName(newfilename);
     	  if -1 == symlink(oldfilename,newfilename)
	  then buildErrorPacket("failed to symbolically link file " + oldfilename + " to " + newfilename + " : " + syserrmsg()) else nullE
	  )
     else WrongArgString(2)
     else WrongArgString(1)
     else WrongNumArgs(2));
setupfun("symlinkFile",symlinkfun);

fileTime(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
	  filename = expandFileName(filename);
	  r := fileTime(filename);
	  if r == -1
	  then buildErrorPacket("can't see file '" + filename + "' : " + syserrmsg())
	  else Expr(toInteger(r))
	  )
     is args:Sequence do if length(args) != 2 then WrongNumArgs(2) else (
	  when args.0 is modtime:ZZ do if !isInt(modtime) then WrongArgSmallInteger(2) else (
	       when args.1 is filename:string do (
	  	    filename = expandFileName(filename);
		    r := setFileTime(filename,toInt(modtime));
		    if r == -1 then buildErrorPacket("can't set modification time of file '" + filename + "' : " + syserrmsg())
	  	    else nullE
		    )
	       else WrongArgString(1)
	       )
	  else WrongArgZZ(2)
	  )
     else WrongArg("string, or integer and string"));
setupfun("fileTime",fileTime);

currentTime(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is a:Sequence do
     if length(a) == 0 then Expr(toInteger(currentTime()))
     else WrongNumArgs(0)
     else WrongNumArgs(0));
setupfun("currentTime",currentTime);

mkdir(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is filename:string do (
	  filename = expandFileName(filename);
	  r := mkdir(filename);
	  if r == -1 then buildErrorPacket("can't make directory \"" + filename + "\": " + syserrmsg())
	  else nullE)
     else WrongArgString());
setupfun("mkdir",mkdir);

export printWidth := 0;

wrap(localInterpState:threadLocalInterp,e:Expr):Expr := (
     wid := printWidth;
     sep := char(0);
     net := dummyNet;
     when e
     is s:Sequence do (
	  if length(s) == 3 then (
	       when s.0 
	       is Wid:ZZ do if !isInt(Wid) then return WrongArgSmallInteger(1) else wid = toInt(Wid)
	       is Sep:string do if length(Sep) == 0 then sep = char(0) else if length(Sep) == 1 then sep = Sep.0 else return WrongArg(1,"a string of length 0 or 1")
	       else return WrongArg(1,"a string or an integer");
	       when s.1
	       is Wid:ZZ do if !isInt(Wid) then return WrongArgSmallInteger(1) else wid = toInt(Wid)
	       is Sep:string do if length(Sep) == 0 then sep = char(0) else if length(Sep) == 1 then sep = Sep.0 else return WrongArg(1,"a string of length 0 or 1")
	       else return WrongArg(1,"a string or an integer");
	       when s.2
	       is t:Net do net = t 
	       is s:string do net = toNet(s)
	       else return WrongArg(3,"a net or a string");
	       )
	  else if length(s) == 2 then (
	       when s.0 
	       is Wid:ZZ do if !isInt(Wid) then return WrongArgSmallInteger(1) else wid = toInt(Wid)
	       is Sep:string do if length(Sep) == 0 then sep = char(0) else if length(Sep) == 1 then sep = Sep.0 else return WrongArg(1,"a string of length 0 or 1")
	       else return WrongArg(1,"a string or an integer");
	       when s.1
	       is t:Net do net = t 
	       is s:string do net = toNet(s)
	       else return WrongArg(2,"a net or a string");
	       )
	  else return WrongNumArgs(1,3))
     is s:string do net = toNet(s)
     is n:Net do net = n
     else return WrongArg("a string or a net");
     if wid <= 0 then return Expr(net);
     Expr(wrap(wid,sep,net)));
setupfun("wrap",wrap);

dillyDallyFun(localInterpState:threadLocalInterp,e:Expr):Expr := (				    -- for debugging interrupts in compiled code
     while true do (
	  sleep(1);
	  if interruptedFlag then return buildErrorPacket("dillyDally: interrupted");
	  ));
setupfun("dillyDally",dillyDallyFun);

minimizeFilename(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:string do Expr(minimizeFilename(s))
     else WrongArgString()
     );
setupfun("minimizeFilename",minimizeFilename);

relativizeFilename(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is t:Sequence do
     if length(t) == 2 then
     when t.0 is cwd:string do
     when t.1 is filename:string do Expr(relativizeFilename(cwd,filename))
     else WrongArgString(2)
     else WrongArgString(1)
     else WrongArg("a string or a pair of strings")
     is filename:string do Expr(relativizeFilename(filename))
     else WrongArg("a string or a pair of strings")
     );
setupfun("relativizeFilename",relativizeFilename);

nodecount := 0;
countnodes(n:LexNode):void := (
     when n.word is w:Word do nodecount = nodecount + 1 else nothing;
     when n.next is m:LexNode do countnodes(m) else nothing;
     when n.further is m:LexNode do countnodes(m) else nothing;
     );
countnodes(baseLexNode);
operatorNames := new Sequence len nodecount do provide nullE;
nodecount = 0;
fillnodes(n:LexNode):void := (
     when n.word is w:Word do (
	  operatorNames.nodecount = Expr(w.name);
	  nodecount = nodecount + 1;
	  ) else nothing;
     when n.next is m:LexNode do fillnodes(m) else nothing;
     when n.further is m:LexNode do fillnodes(m) else nothing;
     );
fillnodes(baseLexNode);
setupconst("operatorNames",Expr(operatorNames));

issym(d:Dictionary,s:string):Expr := when lookup(makeUniqueWord(s,parseWORD),d) is x:Symbol do True is null do False;

getglobalsym(localInterpState:threadLocalInterp,d:Dictionary,s:string):Expr := (
     w := makeUniqueWord(s,parseWORD);
     when lookup(w,d.symboltable) is x:Symbol do Expr(SymbolClosure(globalFrame,x))
     is null do (
	  if d.protected then return buildErrorPacket("attempted to create symbol in protected dictionary");
	  t := makeSymbol(localInterpState,w,dummyPosition,d);
	  globalFrame.values.(t.frameindex)));

getglobalsym(localInterpState:threadLocalInterp,s:string):Expr := (
     w := makeUniqueWord(s,parseWORD);
     when globalLookup(w)
     is x:Symbol do Expr(SymbolClosure(globalFrame,x))
     is null do (
	  if globalDictionary.protected then return buildErrorPacket("attempted to create symbol in protected dictionary");
	  t := makeSymbol(localInterpState,w,dummyPosition,globalDictionary);
	  globalFrame.values.(t.frameindex)));

getGlobalSymbol(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e 
     is s:string do getglobalsym(localInterpState,s)
     is z:Sequence do if length(z) != 2 then WrongNumArgs(2) else (
	  when z.0
	  is dc:DictionaryClosure do (
	       d := dc.dictionary;
	       if !isglobaldict(d) then WrongArg(1,"a global dictionary") else
	       when z.1
	       is s:string do getglobalsym(localInterpState,d,s)
	       else WrongArgString(2)
	       )
	  else WrongArg(1,"a dictionary")
	  )
     else WrongArg("a string or a dictionary and a string"));
setupfun("getGlobalSymbol",getGlobalSymbol);

isglobalsym(s:string):Expr := when globalLookup(makeUniqueWord(s,parseWORD)) is x:Symbol do True is null do False;

isGlobalSymbol(localInterpState:threadLocalInterp,e:Expr):Expr := when e is s:string do isglobalsym(s) else WrongArgString();
setupfun("isGlobalSymbol",isGlobalSymbol);

-- history(e:Expr):Expr := (
--      when e
--      is s:Sequence do (
-- 	  if length(s) == 0 then (
-- 	       r := history();
-- 	       Expr(list(new Sequence len length(r) do foreach s in r do provide Expr(s))))
--      	  else WrongNumArgs(0))
--      else WrongNumArgs(0));
-- setupfun("history",history);

toPairs(r:array(int)):Expr := Expr( 
     list (
	  new Sequence len length(r)/2 at i do 
	  provide new Sequence len 2 at j do 
	  provide toExpr(r.(2*i+j))
	  )
     );

regexmatch(localInterpState:threadLocalInterp,e:Expr):Expr := (
     ignorecase := false;
     when e is a:Sequence do
     if length(a) == 2 then
     when a.0 is regexp:string do
     when a.1 is text:string do (
	  r := regexmatch(regexp,0,length(text),text,ignorecase);
	  if regexmatchErrorMessage != noErrorMessage then buildErrorPacket("regex: "+regexmatchErrorMessage)
     	  else if length(r) != 0 then toPairs(r) 
	  else nullE)
     else WrongArgString(2)
     else WrongArgString(1)
     else if length(a) == 3 then
     when a.0 is regexp:string do
     when a.1 is start:ZZ do if !isInt(start) then WrongArgSmallInteger(2) else
     when a.2 is text:string do (
	  istart := toInt(start);
	  r := regexmatch(regexp,istart,length(text)-istart,text,ignorecase);
	  if length(r) != 0 then toPairs(r) 
	  else if regexmatchErrorMessage == noErrorMessage
	  then nullE
	  else buildErrorPacket("regex: "+regexmatchErrorMessage))
     else WrongArgString(3)
     else WrongArgZZ(2)
     else WrongArgString(1)
     else if length(a) == 4 then
     when a.0 is regexp:string do
     when a.1 is start:ZZ do if !isInt(start) then WrongArgSmallInteger(2) else
     when a.2 is range:ZZ do if !isInt(range) then WrongArgSmallInteger(3) else
     when a.3 is text:string do (
	  r := regexmatch(regexp,toInt(start),toInt(range),text,ignorecase);
	  if length(r) != 0 then toPairs(r) 
	  else if regexmatchErrorMessage == noErrorMessage
	  then nullE
	  else buildErrorPacket("regex: "+regexmatchErrorMessage))
     else WrongArgString(4)
     else WrongArgZZ(3)
     else WrongArgZZ(2)
     else WrongArgString(1)
     else WrongNumArgs(2,3)
     else WrongNumArgs(2,3));
setupfun("regex",regexmatch);

foo := "foo";
replace(localInterpState:threadLocalInterp,e:Expr):Expr := (
     ignorecase := false;
     when e is a:Sequence do
     if length(a) == 3 then
     when a.0 is regexp:string do
     when a.1 is replacement:string do
     when a.2 is text:string do (
	  r := regexreplace(regexp,replacement,text,foo,ignorecase);
	  if r == foo then buildErrorPacket("replace: "+regexmatchErrorMessage)
	  else Expr(r))
     else WrongArgString(3)
     else WrongArgString(2)
     else WrongArgString(1)
     else WrongNumArgs(3)
     else WrongNumArgs(3));
setupfun("replaceStrings",replace);
     
listFrame(s:Sequence):Expr := Expr(List(mutableListClass, s, nextHash(), true));	  
listFrame(f:Frame):Expr := if f.frameID == 0 then listFrame(emptySequence) else listFrame(f.values); -- refuse to defeat the protection of global variables
frame(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is s:Sequence do 
     if length(s) == 0 then Expr(listFrame(localInterpState.localFrame)) else WrongNumArgs(1,2)
     is sc:SymbolClosure do Expr(listFrame(sc.frame))
     is c:CodeClosure do Expr(listFrame(c.frame))
     is fc:FunctionClosure do Expr(listFrame(fc.frame))
     is cfc:CompiledFunctionClosure do Expr(listFrame(cfc.env))
     is CompiledFunction do Expr(listFrame(emptySequence))
     is s:SpecialExpr do frame(localInterpState,s.e)
     else WrongNumArgs(1,2));
setupfun("frame", frame);

numFrames(f:Frame):int := (
     n := 0;
     while ( n = n+1; f != f.outerFrame ) do f = f.outerFrame;
     n);

listFrames(localInterpState:threadLocalInterp,f:Frame):Expr := Expr( list( new Sequence len numFrames(f) do while (provide listFrame(f) ; f != f.outerFrame ) do f = f.outerFrame));     

frames(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is a:Sequence do if length(a) == 0 then listFrames(localInterpState,localInterpState.localFrame) else WrongNumArgs(0,1) 
     is sc:SymbolClosure do Expr(listFrames(localInterpState,sc.frame))
     is c:CodeClosure do Expr(listFrames(localInterpState,c.frame))
     is fc:FunctionClosure do Expr(listFrames(localInterpState,fc.frame))
     is cfc:CompiledFunctionClosure do Expr(list(listFrame(cfc.env)))
     is CompiledFunction do Expr(list(listFrame(emptySequence)))
     is s:SpecialExpr do frames(localInterpState,s.e)
     else WrongArg("a function, a symbol, or ()"));
setupfun("frames", frames);

localDictionaries(f:Frame):Expr := Expr( list( new Sequence len numFrames(f) do ( while ( provide Expr(localDictionaryClosure(f)); f != f.outerFrame ) do f = f.outerFrame)));

localDictionaries(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is x:Sequence do if length(x) != 0 then WrongNumArgs(0,1) else localDictionaries(noRecycle(localInterpState.localFrame))
     is x:DictionaryClosure do localDictionaries(x.frame)
     is x:SymbolClosure do localDictionaries(x.frame)
     is x:CodeClosure do localDictionaries(x.frame)
     is x:FunctionClosure do localDictionaries(x.frame)
     is CompiledFunctionClosure do localDictionaries(emptyFrame)	    -- some values are there, but no symbols
     is CompiledFunction do localDictionaries(emptyFrame)			    -- no values or symbols are there
     is s:SpecialExpr do localDictionaries(localInterpState,s.e)
     else WrongArg("a function, a symbol, or ()"));
setupfun("localDictionaries", localDictionaries);


-----------------------------------------------------------------------------

globalDictionaryList():Expr := (		    -- get the current globalDictionary list
     g := globalDictionary;
     n := 0;
     while ( n = n+1; g != g.outerDictionary ) do g = g.outerDictionary;
     g = globalDictionary;
     Expr(list(new Sequence len n do while true do ( provide Expr(DictionaryClosure(globalFrame,g)); g = g.outerDictionary ))));

dictionaryPath(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is a:Sequence do (
	  if length(a) == 0 then globalDictionaryList()
     	  else WrongNumArgs(0))
     is t:List do (					    -- set the current globalDictionary list
	  s := t.v;
	  n := length(s);
	  if n == 0 then return WrongArg("expected a nonempty list of dictionaries");
          sawUnprotected := false;
	  foreach x in s do 
	  when x is dc:DictionaryClosure do (
	       d := dc.dictionary;
	       if !d.protected then sawUnprotected = true;
	       if d.frameID != 0 || d.transient then return WrongArg("expected a list of global dictionaries")
	       )
	  else return WrongArg("expected a list of dictionaries");
	  for i from 0 to n-2 do for j from i+1 to n-1 do if s.i == s.j then return WrongArg("expected a list of dictionaries with no duplicate entries");
          if !sawUnprotected then return WrongArg("expected a list of dictionaries, not all protected");
     	  a := new array(Dictionary) len n do foreach x in s do when x is d:DictionaryClosure do provide d.dictionary else nothing;
     	  a.(n-1).outerDictionary = a.(n-1);
     	  for i from 0 to n-2 do a.i.outerDictionary = a.(i+1);
	  globalDictionary = a.0;
	  e)
     else WrongNumArgs(0));
dictionaryPathS := setupvar("dictionaryPath",globalDictionaryList());
setupfun("internalDictionaryPathFunction",dictionaryPath);
storeGlobalDictionaries(localInterpState:threadLocalInterp,e:Expr):Expr := (			    -- called with (symbol,newvalue)
     when e
     is s:Sequence do if length(s) != 2 then WrongNumArgs(2) else (
	  sym := s.0;
	  if !(sym === dictionaryPathS)
	  then buildErrorPacket("global assignment hook encountered unknown symbol")
	  else dictionaryPath(localInterpState,s.1))
     else WrongNumArgs(2));
storeInHashTable(globalAssignmentHooks,Expr(SymbolClosure(globalFrame,dictionaryPathS)),Expr(CompiledFunction(storeGlobalDictionaries,nextHash())));

getcwdfun(localInterpState:threadLocalInterp,e:Expr):Expr := (				    -- this has to be a function, because getcwd may fail
     when e is s:Sequence do
     if length(s) == 0 then cwd() else WrongNumArgs(0)
     else WrongNumArgs(0));
setupfun("currentDirectory",getcwdfun);

export debuggerHook := nullE;

backtraceS := dummySymbol;
debugLevelS := dummySymbol;
engineDebugLevelS := dummySymbol;
debuggingModeS := dummySymbol;
errorDepthS := dummySymbol;
gbTraceS := dummySymbol;
debuggerHookS := dummySymbol;
lineNumberS := dummySymbol;
loadDepthS := dummySymbol;
randomSeedS := dummySymbol;
randomHeightS := dummySymbol;
printingPrecisionS := dummySymbol;
printingAccuracyS := dummySymbol;
printingLeadLimitS := dummySymbol;
printingTrailLimitS := dummySymbol;
printingSeparatorS := dummySymbol;
defaultPrecisionS := dummySymbol;
recursionLimitS := dummySymbol;
nLimitS := dummySymbol;
stopIfErrorS := dummySymbol;
handleInterruptsS := dummySymbol;
printWidthS := dummySymbol;
notifyS := dummySymbol;

setupconst("minExponent",Expr(toInteger(minExponent)));
setupconst("maxExponent",Expr(toInteger(maxExponent)));

StandardS := makeProtectedSymbolClosure("Standard");
export StandardE := Expr(StandardS);
export topLevelMode := Expr(StandardS);
topLevelModeS := dummySymbol;

initialRandomSeed := toInteger(0);
initialRandomHeight := toInteger(10);

syms := SymbolSequence(
     (  backtraceS = setupvar("backtrace",toExpr(backtrace));  backtraceS  ),
     (  debugLevelS = setupvar("debugLevel",toExpr(debugLevel));  debugLevelS  ),
     (  engineDebugLevelS = setupvar("engineDebugLevel",toExpr(engineDebugLevel));  engineDebugLevelS  ),
     (  debuggingModeS = setupvar("debuggingMode",toExpr(debuggingMode));  debuggingModeS  ),
     (  defaultPrecisionS = setupvar("defaultPrecision",toExpr(defaultPrecision));  defaultPrecisionS  ),
     (  errorDepthS = setupvar("errorDepth",toExpr(errorDepth));  errorDepthS  ),
     (  gbTraceS = setupvar("gbTrace",toExpr(gbTrace));  gbTraceS  ),
     (  debuggerHookS = setupvar("debuggerHook",debuggerHook);  debuggerHookS  ),
     (  lineNumberS = setupvar("lineNumber",toExpr(lineNumber));  lineNumberS  ),
     (  loadDepthS = setupvar("loadDepth",toExpr(loadDepth));  loadDepthS  ),
     (  printingPrecisionS = setupvar("printingPrecision",toExpr(printingPrecision));  printingPrecisionS  ),
     (  printingAccuracyS = setupvar("printingAccuracy",toExpr(printingAccuracy));  printingAccuracyS  ),
     (  printingLeadLimitS = setupvar("printingLeadLimit",toExpr(printingLeadLimit));  printingLeadLimitS ),
     (  printingTrailLimitS = setupvar("printingTrailLimit",toExpr(printingTrailLimit));  printingTrailLimitS  ),
     (  printingSeparatorS = setupvar("printingSeparator",Expr(printingSeparator));  printingSeparatorS  ),
     (  randomSeedS = setupvar("randomSeed",Expr(initialRandomSeed));  randomSeedS  ),
     (  randomHeightS = setupvar("randomHeight",Expr(initialRandomHeight));  randomHeightS  ),
     (  recursionLimitS = setupvar("recursionLimit",toExpr(recursionLimit));  recursionLimitS  ),
     (  stopIfErrorS = setupvar("stopIfError",toExpr(stopIfError));  stopIfErrorS  ),
     (  handleInterruptsS = setupvar("handleInterrupts",toExpr(handleInterrupts));  handleInterruptsS  ),
     (  printWidthS = setupvar("printWidth",toExpr(printWidth));  printWidthS  ),
     (  notifyS = setupvar("notify",toExpr(notify));  notifyS  ),
     (  topLevelModeS = setupvar("topLevelMode",topLevelMode); topLevelModeS  )
     );

export setDebuggingMode(b:bool):void := (
     debuggingMode = b;
     setGlobalVariable(debuggingModeS,toExpr(b));
     );
export setLoadDepth(b:ushort):void := (
     loadDepth = b;
     setGlobalVariable(loadDepthS,toExpr(b));
     );
export setErrorDepth(b:ushort):void := (
     errorDepth = b;
     setGlobalVariable(errorDepthS,toExpr(b));
     );
export setLineNumber(b:int):void := (
     lineNumber = b;
     setGlobalVariable(lineNumberS,toExpr(b));
     );
export setstopIfError(b:bool):void := (
     stopIfError = b;
     setGlobalVariable(stopIfErrorS,toExpr(b));
     );
export sethandleInterrupts(b:bool):void := (
     handleInterrupts = b;
     handleInterruptsSetup(b);
     setGlobalVariable(handleInterruptsS,toExpr(b));
     );
msg := "internal assignment hook encountered unknown symbol/value combination";
store(localInterpState:threadLocalInterp,e:Expr):Expr := (			    -- called with (symbol,newvalue)
     when e
     is s:Sequence do if length(s) != 2 then WrongNumArgs(2) else (
	  sym := s.0;
	  if sym === topLevelModeS then (topLevelMode = s.1; e)
	  else if ancestor(Class(s.1),functionClass) then (
	       if sym === debuggerHookS then (debuggerHook = s.1; e)
	       else buildErrorPacket(msg))
	  else when s.1
	  is Nothing do (
	       if sym === debuggerHookS then (debuggerHook = s.1; e)
	       else buildErrorPacket(msg))
	  is b:Boolean do (
	       n := b.v;
	       if sym === debuggingModeS then (debuggingMode = n; e)
	       else if sym === stopIfErrorS then (stopIfError = n; e)
	       else if sym === handleInterruptsS then (handleInterrupts = n; handleInterruptsSetup(n); e)
	       else if sym === backtraceS then (backtrace = n; e)
	       else if sym === notifyS then (notify = n; e)
	       else buildErrorPacket(msg))
	  is s:string do (
	       if sym === printingSeparatorS then (printingSeparator = s; e)
	       else buildErrorPacket(msg))
	  is i:ZZ do (
	       if sym === randomSeedS then ( Ccode(void, "rawSetRandomSeed(", "(M2_Integer)", i, ")"); e )
	       else if sym === randomHeightS then ( Ccode(void, "rawSetRandomMax((M2_Integer)", i, ")"); e )
	       else if sym === defaultPrecisionS then (
		    if !isULong(i) then return buildErrorPacket(msg);
		    prec := toULong(i);
		    if prec < minprec || prec > maxprec
		    then return buildErrorPacket("value for defaultPrecision out of range");
		    defaultPrecision = prec;
		    e)
	       else if sym === loadDepthS then (
		    if !isUShort(i) then return buildErrorPacket("loadDepth: expected integer in range 0 .. 255");
		    loadDepth = toUShort(i);
		    e)
	       else if sym === errorDepthS then (
		    if !isUShort(i) then return buildErrorPacket("errorDepth: expected integer in range 0 .. 255");
		    errorDepth = toUShort(i);
		    e)
	       else if isInt(i) then (
		    n := toInt(i);
		    if sym === debugLevelS then (debugLevel = n; e)
		    else if sym === engineDebugLevelS then (engineDebugLevel = n; e)
		    else if sym === recursionLimitS then (recursionLimit = n; e)
		    else if sym === lineNumberS then (lineNumber = n; e)
		    else if sym === printingPrecisionS then (
			 if n < 0 then return buildErrorPacket("printingPrecision can not be set to negative value");
			 printingPrecision = n;
			 e)
		    else if sym === printingAccuracyS then (
			 if n < -1 then return buildErrorPacket("printingAccuracy can not be set to value < -1");
			 printingAccuracy = n;
			 e)
		    else if sym === printingLeadLimitS then (printingLeadLimit = n; e)
		    else if sym === printingTrailLimitS then (printingTrailLimit = n; e)
		    else if sym === gbTraceS then (gbTrace = n; e)
		    else if sym === printWidthS then (printWidth = n; e)
		    else buildErrorPacket(msg))
	       else buildErrorPacket(msg))
	  else buildErrorPacket(msg))
     else WrongNumArgs(2));
storeE := Expr(CompiledFunction(store,nextHash()));
foreach s in syms do storeInHashTable(globalAssignmentHooks,Expr(SymbolClosure(globalFrame,s)),storeE);
storeE = nullE;
syms = SymbolSequence();

export fileDictionaries := newHashTable(mutableHashTableClass,nothingClass); sethash(fileDictionaries,true);
setupconst("fileDictionaries",Expr(fileDictionaries));

export newStaticLocalDictionaryClosure(filename:string):DictionaryClosure := (
     d := newStaticLocalDictionaryClosure();
     storeInHashTable(fileDictionaries,Expr(filename),Expr(d));
     d);

fileMode(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do (
	  if length(s) != 2 
	  then WrongNumArgs(2) 
	  else (
	       when s.1 
	       is o:file do (
	  	    when s.0
		    is mode:ZZ do (
	  		 if !isInt(mode)
			 then WrongArgSmallInteger(1)
			 else (
	       		      r := fchmod(o,toInt(mode));
	       		      if r == -1
			      then buildErrorPacket(syscallErrorMessage("fchmod")) 
			      else nullE))
	  	    else WrongArgZZ(1))
	       is filename:string do (
		    when s.0 
		    is mode:ZZ do (
			 if !isInt(mode)
			 then WrongArgSmallInteger(1)
			 else (
			      r := chmod(expandFileName(filename),toInt(mode));
			      if r == -1
			      then buildErrorPacket(syscallErrorMessage("chmod"))
			      else nullE))
		    else WrongArgZZ(1))
	       else WrongArg(2,"a file")))
     is f:file do (
	  fd := -1;
	  if f.input then fd = f.infd
	  else if f.output then fd = f.outfd
	  else if f.listener then fd = f.listenerfd
	  else return WrongArg("an open file");
	  r := fileModeFD(fd);
	  if r == -1 then buildErrorPacket(syscallErrorMessage("fstat"))
	  else Expr(toInteger(r)))
     is fn:string do (
	  r := fileMode(expandFileName(fn));
	  if r == -1 then buildErrorPacket(syscallErrorMessage("stat"))
	  else Expr(toInteger(r)))
     else WrongArg("string, integer and string or file"));
setupfun("fileMode",fileMode);

rawRandomInitializeFun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do if length(s) == 0 then (
	  Ccode(void, "rawRandomInitialize()");
	  nullE
	  )
     else WrongNumArgs(0)
     else WrongNumArgs(0));
setupfun("rawRandomInitialize",rawRandomInitializeFun);

recursionDepthFun(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is s:Sequence do if length(s) == 0 then Expr(toInteger(recursionDepth))
     else WrongNumArgs(0)
     else WrongNumArgs(0));
setupfun("recursionDepth",recursionDepthFun);

fileLength(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is f:file do (
	  if f.input && f.infd != -1 then (
	       ret := fileLength(f.infd);
	       if ret == ERROR
	       then Expr(buildErrorPacket(syscallErrorMessage("getting the length of a file")))
	       else Expr(toInteger(ret)))
	  else if f.output then Expr(toInteger(f.bytesWritten + f.outindex))
     	  else buildErrorPacket("file not open"))
     is filename:string do (
	  filename = expandFileName(filename);
	  ret := fileLength(filename);
	  if ret == ERROR
	  then Expr(buildErrorPacket(syscallErrorMessage("length of a file: \"" + present(filename) + "\"")))
     	  else Expr(toInteger(ret)))
     else WrongArg("a string or a file"));     
setupfun("fileLength",fileLength);

functionBody(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e is f:FunctionClosure do Expr(f.model)
     is f:CompiledFunction do e
     is f:CompiledFunctionClosure do Expr(CompiledFunctionBody(f.fn))
     is s:SpecialExpr do functionBody(localInterpState,s.e)
     else WrongArg("a function")
     );
setupfun("functionBody",functionBody);

dumpNodes(localInterpState:threadLocalInterp,e:Expr):Expr := (dumpNodes(); nullE);
setupfun("dumpNodes",dumpNodes);

toExternalString(localInterpState:threadLocalInterp,e:Expr):Expr := (
     when e
     is x:RR do Expr(toExternalString(x))
     is x:CC do Expr(toExternalString(x))
     else WrongArg("a real or complex number")
     );
setupfun("toExternalString0",toExternalString);

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/d "
-- End: