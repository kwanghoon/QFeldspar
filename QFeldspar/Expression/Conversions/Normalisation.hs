{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module QFeldspar.Expression.Conversions.Normalisation () where

import QFeldspar.MyPrelude
import QFeldspar.Expression.Utils.Common
import qualified QFeldspar.Expression.GADTHigherOrder as GHO
import qualified QFeldspar.Expression.MiniFeldspar  as MFS

import qualified QFeldspar.Type.GADT                  as TG

-- import QFeldspar.Variable.Typed
-- import QFeldspar.Environment.Typed hiding (fmap)

import QFeldspar.Conversion
import QFeldspar.Singleton

instance (HasSin TG.Typ t , t ~ t' , r ~ r') =>
         Cnv (GHO.Exp r t , rr) (MFS.Exp r' t') where
  cnv (ee , r) = let t = (sin :: TG.Typ t) in case ee of
    GHO.Abs _                -> fail "Normalisation Error!"
    GHO.App _ _              -> fail "Normalisation Error!"
    GHO.Non                  -> fail "Normalisation Error!"
    GHO.Som _                -> fail "Normalisation Error!"
    GHO.May _ _ _            -> fail "Normalisation Error!"
    GHO.AryV _ _             -> fail "Normalisation Error!"
    GHO.LenV _               -> fail "Normalisation Error!"
    GHO.IndV _ _             -> fail "Normalisation Error!"
    GHO.Int  _               -> fail "Normalisation Error!"
    GHO.Fix  _               -> fail "Normalisation Error!"
    GHO.Prm x ns             -> MFS.Prm x <$> TG.mapMC (cnvWth r) ns
    _                         -> $(biGenOverloadedMW 'ee ''GHO.Exp "MFS"
     ['GHO.Prm,'GHO.Abs,'GHO.App,'GHO.Non,'GHO.Som,'GHO.May
     ,'GHO.AryV,'GHO.LenV,'GHO.IndV,'GHO.Int,'GHO.Fix] (trvWrp 't) (const [| cnvWth r |]))

instance (HasSin TG.Typ a , HasSin TG.Typ b, a ~ a' , b ~ b' , r ~ r') =>
    Cnv (GHO.Exp r' (a' -> b') , rr) (MFS.Exp r a -> MFS.Exp r b)  where
    cnv (ee , r) = case ee of
      GHO.Abs e -> cnv (e , r)
      _          -> fail "Normalisation Error!"

instance (HasSin TG.Typ ta , HasSin TG.Typ tb , r ~ r' , ta ~ ta' ,tb ~ tb') =>
         Cnv (GHO.Exp r  ta  -> GHO.Exp r  tb , rr)
             (MFS.Exp r' ta' -> MFS.Exp r' tb')
         where
  cnv (ee , r) =
    pure (frmRgtZro . cnvWth r . ee . frmRgtZro . cnvWth r)

instance (HasSin TG.Typ t , t' ~ t , r' ~ r) =>
         Cnv (MFS.Exp r' t' , rr) (GHO.Exp r t)  where
  cnv (ee , r) = let t = sin :: TG.Typ t in
    case ee of
      MFS.Prm x ns -> GHO.Prm x <$> TG.mapMC (cnvWth r) ns
      _             -> $(biGenOverloadedMW 'ee ''MFS.Exp "GHO" ['MFS.Prm]
                            (trvWrp 't) (const [| cnvWth r |]))

instance (HasSin TG.Typ a , HasSin TG.Typ b, a ~ a' , b ~ b' , r ~ r') =>
    Cnv (MFS.Exp r a -> MFS.Exp r b , rr) (GHO.Exp r' (a' -> b')) where
    cnv (ee , r) = fmap GHO.Abs (cnv (ee , r))

instance (HasSin TG.Typ ta , HasSin TG.Typ tb, ta ~ ta' , tb ~ tb' , r ~ r') =>
         Cnv (MFS.Exp r  ta  -> MFS.Exp r  tb , rr)
             (GHO.Exp r' ta' -> GHO.Exp r' tb')
         where
  cnv (ee , r) = pure (frmRgtZro . cnvWth r . ee . frmRgtZro . cnvWth r)
{-

fldApp :: forall r t ta tb . (t ~ (ta -> tb) , HasSin TG.Typ t) =>
          GHO.Exp r t ->
          Env (MFS.Exp r) (ta ': TG.Arg tb) ->
          NamM ErrM (Exs1 (GHO.Exp r) TG.Typ)
fldApp e ess = let ?r = () in case TG.getPrfHasSinArr (T :: T t) of
  (PrfHasSin , PrfHasSin) -> case (sin :: TG.Typ t , ess) of
    (TG.Arr _ (TG.Arr _ _) , Ext ea es@(Ext _ _)) -> do
      ea' <- cnvImp ea
      fldApp (GHO.App e ea') es
    (TG.Arr _ tb            , Ext ea Emp)          -> do
      ea' <- cnvImp ea
      pure (Exs1 (GHO.App e ea') tb)
    _                                               ->
      impossibleM

getVar :: forall r t. HasSin TG.Typ t =>
          GHO.Exp r t -> NamM ErrM (Exs1 (Var r) TG.Typ)
getVar e = case e of
  GHO.App (GHO.Var v)       _ -> pure (Exs1 v (sinTyp v))
  GHO.App ef@(GHO.App _  _) _ -> getVar ef
  _                             -> fail "Normalisation Error!"

data DblExsSin :: (ka -> kb -> *) -> ka -> ka -> * where
  DblExsSin :: c2 tf1 t -> c2 tf2 t -> DblExsSin c2 tf1 tf2

getArg :: forall r t. GHO.Exp r t -> DblExsSin Env (MFS.Exp r) TG.Typ ->
          NamM ErrM (DblExsSin Env (MFS.Exp r) TG.Typ)
getArg e (DblExsSin args tys) = let ?r = () in case e of
  GHO.App (GHO.Var _)       ea -> do
    ea' <- cnvImp ea
    pure (DblExsSin (Ext ea' args) (Ext (sinTyp ea) tys))
  GHO.App ef@(GHO.App _ _) ea -> do
    ea' <- cnvImp ea
    getArg ef (DblExsSin (Ext ea' args) (Ext (sinTyp ea) tys))
  _                              ->
    fail "Normalisation Error!"
-}
