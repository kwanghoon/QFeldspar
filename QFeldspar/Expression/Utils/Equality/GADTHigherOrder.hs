module QFeldspar.Expression.Utils.Equality.GADTHigherOrder (eql,eqlF) where

import QFeldspar.MyPrelude

import QFeldspar.Expression.GADTHigherOrder
import QFeldspar.Conversion
import QFeldspar.Environment.Typed
import QFeldspar.Singleton
import QFeldspar.Expression.Conversions.Lifting (cnvHOFOF)
import qualified QFeldspar.Type.GADT as TG
import qualified QFeldspar.Expression.GADTFirstOrder as GFO
import qualified QFeldspar.Expression.Utils.Equality.GADTFirstOrder as GFO

eql :: forall a s.
       (TG.Type a , TG.Types s) =>
       Exp s a -> Exp s a -> Bool
eql e1 e2 = let g = sin :: Env TG.Typ s
                e1' :: GFO.Exp s '[] a = frmRgtZro (cnv (e1 , g))
                e2' :: GFO.Exp s '[] a = frmRgtZro (cnv (e2 , g))
            in  GFO.eql e1' e2'

eqlF :: forall a b s.
        (TG.Type a , TG.Type b , TG.Types s) =>
        (Exp s a -> Exp s b) -> (Exp s a -> Exp s b) -> Bool
eqlF f1 f2 = let g = sin :: Env TG.Typ s
                 f1' :: GFO.Exp s '[a] b = cnvHOFOF g f1
                 f2' :: GFO.Exp s '[a] b = cnvHOFOF g f2
             in  GFO.eql f1' f2'
