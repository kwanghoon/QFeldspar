module QFeldspar.Expression.ADTUntypedNamed
       (Exp(..)) where

import QFeldspar.MyPrelude
import qualified QFeldspar.Type.ADT as TA
import QFeldspar.Literal.ADT

data Exp x = Lit Lit
           | ConB Bool
           | Var x
           | Prm x [Exp x]
           | Abs (x , Exp x)
           | App (Exp x) (Exp x)
           | Cnd (Exp x) (Exp x) (Exp x)
           | Whl (Exp x) (Exp x) (Exp x)
           | Tpl (Exp x) (Exp x)
           | Fst (Exp x)
           | Snd (Exp x)
           | Ary (Exp x) (Exp x)
           | Len (Exp x)
           | Ind (Exp x) (Exp x)
           | AryV (Exp x) (Exp x)
           | LenV (Exp x)
           | IndV (Exp x) (Exp x)
           | LeT (Exp x) (x , Exp x)
           | Cmx (Exp x) (Exp x)
           | Non
           | Som (Exp x)
           | May (Exp x) (Exp x) (Exp x)
           | Typ TA.Typ (Exp x)
           | Mul (Exp x) (Exp x)
           | Add (Exp x) (Exp x)
           | Sub (Exp x) (Exp x)
           | Eql (Exp x) (Exp x)
           | Ltd (Exp x) (Exp x)
           | Int Integer
           | Rat Rational
           | Mem (Exp x)
           | Fix (Exp x)

deriving instance Eq x   => Eq   (Exp x)
deriving instance Show x => Show (Exp x)
deriving instance Functor     Exp
deriving instance Foldable    Exp
deriving instance Traversable Exp
