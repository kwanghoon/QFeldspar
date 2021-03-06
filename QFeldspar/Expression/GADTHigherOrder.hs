module QFeldspar.Expression.GADTHigherOrder
       (Exp(..)) where

import QFeldspar.MyPrelude
import QFeldspar.Environment.Typed
import QFeldspar.Variable.Typed
import QFeldspar.Type.GADT
import QFeldspar.Literal.GADT
import QFeldspar.Magic

data Exp :: [*] -> * -> * where
  Lit :: Lit a    -> Exp s a
  ConB :: Bool     -> Exp s Bool
  Prm  :: (Match a as b , Types as) =>
          Var s a -> Env (Exp s) as -> Exp s b
  Abs  :: (Type a , Type b) => (Exp s a -> Exp s b) -> Exp s (a -> b)
  App  :: Type a =>
          Exp s (a -> b) -> Exp s a -> Exp s b
  Cnd  :: Exp s Bool -> Exp s a -> Exp s a -> Exp s a
  Whl  :: Exp s (a -> Bool) -> Exp s (a -> a) -> Exp s a -> Exp s a
  Tpl  :: (Type a , Type b) => Exp s a -> Exp s b -> Exp s (a , b)
  Fst  :: Type b => Exp s (a , b) -> Exp s a
  Snd  :: Type a => Exp s (a , b) -> Exp s b
  Ary  :: Type a => Exp s Word32 -> Exp s (Word32 -> a) -> Exp s (Ary a)
  Len  :: Type a => Exp s (Ary a) -> Exp s Word32
  Ind  :: Exp s (Ary a) -> Exp s Word32 -> Exp s a
  AryV :: Type a => Exp s Word32 -> Exp s (Word32 -> a) -> Exp s (Vec a)
  LenV :: Type a => Exp s (Vec a) -> Exp s Word32
  IndV :: Exp s (Vec a) -> Exp s Word32 -> Exp s a
  LeT  :: Type a =>
          Exp s a -> (Exp s a -> Exp s b) -> Exp s b
  Cmx  :: Exp s Float -> Exp s Float -> Exp s (Complex Float)
  Non  :: Exp s (Maybe a)
  Som  :: Type a => Exp s a -> Exp s (Maybe a)
  May  :: Type a =>
          Exp s (Maybe a) -> Exp s b -> Exp s (a -> b) -> Exp s b
  Mul  :: Exp s a  -> Exp s a -> Exp s a
  Add  :: Exp s a  -> Exp s a -> Exp s a
  Sub  :: Exp s a  -> Exp s a -> Exp s a
  Eql  :: Type a => Exp s a  -> Exp s a -> Exp s Bool
  Ltd  :: Type a => Exp s a  -> Exp s a -> Exp s Bool
  Tmp  :: String  -> Exp s a
  Int  :: Integer -> Exp s a
  Rat  :: Rational -> Exp s a
  Tag  :: String  -> Exp s a -> Exp s a
  Mem  :: Exp s a -> Exp s a
  Fix  :: Exp s (a -> a) -> Exp s a
