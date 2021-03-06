{-# OPTIONS_GHC -fno-warn-unused-binds -fno-warn-name-shadowing #-}
module QFeldspar.QDSL
  (Qt,FO,Type,Num,Eq,Ord,C,String,Rep,

   Word32,Float,
   (*),(+),(-),(==),(<),div,(/),mod,i2f,round,
   sqrt,sin,cos,atan2,cis,ilog2,

   Bool(..),
   -- ifThenElse

   Complex(..),
   realPart,imagPart,

   -- abstraction and application

   -- ((,)),
   fst,snd,

   Maybe(..),
   maybe,

   Array,
   Ary,
   mkArr,lnArr,ixArr,

   Vec(..),

   (.&.),(.|.),xor,shfRgt,shfLft,complement,


   return,(>>=),(.),

   hashTable,

   while, save,

   qdsl,evaluate,translate,translateF,compile,compileF,
   dbg1,dbg15,dbg2,dbg3,dbg4,dbg45,dbg5,dbg6,
   dbgw1,dbgw15,dbgw2,dbgw3,dbgw4,dbgw45,dbgw5,dbgw6,
   testQt,testNrmQt,testNrmSmpQt,testDpF,toDp,wrp,
   ghoF{-,nghoF-}{-,ngho-},trmEql,CDSL.makeIP,CDSL.makeIPAt,
   compileFunction,
   translateWith,translateFWith) where

import QFeldspar.MyPrelude
import qualified QFeldspar.MyPrelude as MP

import QFeldspar.Expression.Utils.Show.GADTFirstOrder()
import QFeldspar.Expression.Utils.Show.GADTHigherOrder()
import QFeldspar.Expression.Utils.Show.MiniFeldspar()

import QFeldspar.CDSL (Dp)
import qualified QFeldspar.CDSL as CDSL

import qualified QFeldspar.Singleton as S

import QFeldspar.Expression.Utils.TemplateHaskell
    (trmEql,stripNameSpace)

import QFeldspar.Conversion
import QFeldspar.Expression.Conversion ()
import QFeldspar.Expression.Conversions.Evaluation.MiniFeldspar ()
import QFeldspar.Expression.Conversions.Lifting(cnvFOHO)

import qualified QFeldspar.Expression.ADTUntypedNamed as AUN
import qualified QFeldspar.Expression.ADTUntypedDebruijn as AUD
import qualified QFeldspar.Expression.GADTTyped as GTD
import qualified QFeldspar.Expression.GADTFirstOrder as GFO
import qualified QFeldspar.Expression.GADTHigherOrder as GHO
import qualified QFeldspar.Expression.MiniFeldspar as MWS
import qualified Language.Haskell.TH.Syntax as TH

import qualified QFeldspar.Expression.Utils.ADTUntypedNamed as AUN

import qualified QFeldspar.Type.ADT as TA
import qualified QFeldspar.Type.GADT as TG

import qualified QFeldspar.Environment.Scoped as ES
import qualified QFeldspar.Environment.Typed as ET

import qualified QFeldspar.Nat.ADT as NA

import qualified QFeldspar.Normalisation as GFO
import QFeldspar.Prelude.Haskell hiding (save,while)
import qualified QFeldspar.Prelude.Haskell as PH
import QFeldspar.Prelude.Environment (etTG)
import qualified QFeldspar.Prelude.HaskellEnvironment as PHE
import QFeldspar.Expression.Conversions.EtaPrims(etaPrms)


type Data a = TH.Q (TH.TExp a)
type Qt a = Data a
type C    = String
type Type a = S.HasSin TG.Typ a
type Rep a = (Type a , FO a)

class    FO a                              where {}
instance FO MP.Bool                        where {}
instance FO MP.Word32                      where {}
instance FO MP.Float                       where {}
instance (FO a , FO b) => FO (a , b)       where {}
instance FO a => FO (MP.Ary a)             where {}
instance FO (MP.Complex MP.Float)          where {}

while :: FO a => (a -> MP.Bool) -> (a -> a) -> a -> a
while = PH.while

save :: FO a => a -> a
save = PH.save

dn :: TH.Name
dn = (TH.Name (TH.OccName "dummyy") TH.NameS)

dummy :: Data a
dummy = MP.return (TH.TExp (TH.VarE dn))

wrp :: Type a => Data a -> AUN.Exp TH.Name
wrp = expand
        ['(>>=)      := [|| \m -> \k ->
                              case m of
                              {Nothing -> Nothing ; Just x -> k x} ||],
         'maybe      := [|| \x -> \g -> \m ->
                               case m of
                               {Nothing -> x ; Just y -> g y} ||],
         'return     := [|| \x -> Just x ||],
         '(.)        := [|| \f -> \g -> \x -> f (g x) ||],
         'realPart   := [|| \x -> PHE.realPart x ||],
         'imagPart   := [|| \x -> PHE.imagPart x ||],
         'div        := [|| \x -> \y -> PHE.divWrd x y ||],
         '(/)        := [|| \x -> \y -> PHE.divFlt x y ||],
         '(.&.)      := [|| \x -> \y -> PHE.andWrd x y ||],
         '(.|.)      := [|| \x -> \y -> PHE.orWrd  x y ||],
         'xor        := [|| \x -> \y -> PHE.xorWrd x y ||],
         'shfRgt     := [|| \x -> \y -> PHE.shrWrd x y ||],
         'shfLft     := [|| \x -> \y -> PHE.shlWrd x y ||],
         'complement := [|| \x -> PHE.cmpWrd   x ||],
         'i2f        := [|| \x -> PHE.i2f  x ||],
         'cis        := [|| \x -> PHE.cis      x ||],
         'ilog2      := [|| \x -> PHE.ilog2    x ||],
         'sqrt       := [|| \x -> PHE.sqrtFlt  x ||],
         'hashTable  := [|| PHE.hshTbl ||]]
        . wrpTyp

wrpTyp :: forall a. Type a => Data a -> Data a
wrpTyp ee = do e <- ee
               return (TH.TExp (TH.SigE (TH.unType e)
                         (frmRgtZro (cnv (S.sin :: TG.Typ a , ())))))

translate :: forall a.
             (Type a , FO a) =>
             Qt a -> Dp a
translate f = frmRgtZro (cnv (wrp f , etTG , PHE.esTH))

translateF :: forall a b.
             (Type a , Type b) =>
             Qt (a -> b) -> Dp a -> Dp b
translateF f = let e :: GFO.Exp PHE.Prelude '[] (a -> b) =
                    frmRgtZro (cnv (wrp f , etTG , PHE.esTH))
                   e' :: GHO.Exp PHE.Prelude (a -> b)    =
                    cnvFOHO (GFO.nrm e)
               in frmRgtZro (cnv (e' , ()))

evaluate ::  forall a.
             (Type a , FO a) =>
             Qt a -> a
evaluate = CDSL.evaluate . translate

compileFunction :: (FO a , Type a , Type b) => Qt (a -> b) -> C
compileFunction = CDSL.compileF' False True True . translateF

compile :: forall a.
             (Type a, FO a) =>
             Bool -> Bool -> Qt a -> C
compile b1 b2 = CDSL.compile b1 b2 . translate

compileF :: forall a b.
             (Type a , Type b , FO a) =>
             Bool -> Bool -> Qt (a -> b) -> C
compileF b1 b2 = CDSL.compileF b1 b2 . translateF

dbg1 :: Type a => Qt a -> AUN.Exp TH.Name
dbg1 e = frmRgtZro (cnv (e,etTG , PHE.esTH))

dbg15 :: Type a => Qt a -> AUN.Exp TH.Name
dbg15 e = let e' = frmRgtZro (cnv (e,etTG , PHE.esTH))
          in frmRgtZro (etaPrms etTG PHE.esTH e')

dbg2 :: Type a => Qt a -> AUD.Exp
dbg2 e = frmRgtZro (cnv(e,etTG , PHE.esTH))

dbg3 :: Type a => Qt a -> GTD.Exp (S.Len PHE.Prelude) 'NA.Zro TA.Typ
dbg3 e = frmRgtZro (cnv(e,etTG , PHE.esTH))

dbg4 :: Type a => Qt a -> GFO.Exp PHE.Prelude '[] a
dbg4 e = frmRgtZro (cnv(e,etTG , PHE.esTH))

dbg45 :: Type a => Qt a -> GFO.Exp PHE.Prelude '[] a
dbg45 e = let e' = frmRgtZro (cnv(e,etTG , PHE.esTH))
          in GFO.nrm e'

dbg5 :: Type a => Qt a -> GHO.Exp PHE.Prelude a
dbg5 e = frmRgtZro (cnv(e,etTG , PHE.esTH))

dbg6 :: Type a => Qt a -> Dp a
dbg6 e = frmRgtZro (cnv(e,etTG , PHE.esTH))

dbgw1 :: Type a => Qt a -> AUN.Exp TH.Name
dbgw1 e = frmRgtZro (cnv (wrp e,etTG , PHE.esTH))

dbgw15 :: Type a => Qt a -> AUN.Exp TH.Name
dbgw15 e = let e' = frmRgtZro (cnv (wrp e,etTG , PHE.esTH))
          in frmRgtZro (etaPrms etTG PHE.esTH e')

dbgw2 :: Type a => Qt a -> AUD.Exp
dbgw2 e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

dbgw3 :: Type a => Qt a -> GTD.Exp (S.Len PHE.Prelude) 'NA.Zro TA.Typ
dbgw3 e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

dbgw4 :: Type a => Qt a -> GFO.Exp PHE.Prelude '[] a
dbgw4 e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

dbgw45 :: Type a => Qt a -> GFO.Exp PHE.Prelude '[] a
dbgw45 e = let e' = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))
          in GFO.nrm e'

dbgw5 :: Type a => Qt a -> GHO.Exp PHE.Prelude a
dbgw5 e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

dbgw6 :: Type a => Qt a -> Dp a
dbgw6 e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

ghoF :: (Type a , Type b) =>
        Qt (a -> b) -> GHO.Exp PHE.Prelude (a -> b)
ghoF e = frmRgtZro (cnv(wrp e,etTG , PHE.esTH))

-- nghoF :: (Type a , Type b) => Qt (a -> b) -> GHO.Exp Prelude (a -> b)
-- nghoF e = nrm (ghoF e)

-- ngho :: Type a => Qt a -> GHO.Exp Prelude a
-- ngho e = nrm (gho e)

qdsl :: (FO a , Type a , Type b) => Qt (a -> b) -> C
qdsl = compileF True True

-- For paper
testQt :: Qt a -> Qt a -> Bool
testQt = trmEql

toDp :: (Type a , Type b) => Qt (a -> b) -> Dp a -> Dp b
toDp = translateF

testNrmQt :: (Type a , Type b) => Qt (a -> b) -> Qt (a -> b) -> Bool
testNrmQt x y = testDpF (toDp x) (toDp y)

testNrmSmpQt :: (Type a , Type b) => Qt (a -> b) -> Qt (a -> b) -> Bool
testNrmSmpQt x y = testDpF (CDSL.simplifyF (toDp x)) (CDSL.simplifyF (toDp y))


testDpF :: (Type a , Type b) => (Dp a -> Dp b) -> (Dp a -> Dp b) -> Bool
testDpF = CDSL.trmEqlF

toAUN :: Qt a -> MP.ErrM (AUN.Exp TH.Name)
toAUN ee = MP.evalStateT
            (cnv (ee,etTG , PHE.esTH)) 0

data Sbs where
  (:=) :: TH.Name -> Qt a -> Sbs

expand :: [Sbs] -> Qt a -> AUN.Exp TH.Name
expand sbs ee = MP.frmRgt
                (do ee' <- toAUN ee
                    MP.foldM
                     (\ e (n := es) -> do es' <- toAUN es
                                          MP.return (AUN.sbs (stripNameSpace n) es' e))
                     ee' sbs)

translateWith :: (Type a , FO a) => ET.Env TG.Typ s -> ES.Env (S.Len s) TH.Name -> TH.Q (TH.TExp a) -> MWS.Exp s a
translateWith et es e = frmRgtZro (cnv (e , et , es))

translateFWith :: forall a b s. (Type a , FO a , Type b , FO b) =>
                   ET.Env TG.Typ s -> ES.Env (S.Len s) TH.Name ->
                   TH.Q (TH.TExp (a -> b)) -> (MWS.Exp s a -> MWS.Exp s b)
translateFWith et es f = let e  :: GFO.Exp s '[] (a -> b) = frmRgtZro (cnv (f , et , es))
                             e' :: GHO.Exp s (a -> b)     = cnvFOHO (GFO.nrm e)
                         in frmRgtZro (cnv (e' , ()))
