{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module QFeldspar.Expression.Conversions.Evaluation.MiniFeldspar () where

import QFeldspar.MyPrelude
import QFeldspar.Expression.MiniFeldspar
import qualified QFeldspar.Expression.GADTValue as FGV
import qualified QFeldspar.Type.GADT            as TFG
import QFeldspar.Environment.Typed hiding (fmap)
import QFeldspar.Conversion
import QFeldspar.Variable.Conversion ()
import QFeldspar.Singleton
import QFeldspar.Expression.Utils.Common

instance (HasSin TFG.Typ a, a ~ a') =>
         Cnv (Exp s a , Env FGV.Exp s) (FGV.Exp a')
         where
  cnv (ee , s) = let t = sin :: TFG.Typ a in case ee of
    Tmp _    -> impossibleM
    Prm x es -> FGV.prm (get x s) <$> TFG.mapMC (cnvWth s) es
    _        -> $(biGenOverloadedMWL 'ee ''Exp "FGV" ['Tmp,'Prm]
                  (trvWrp 't)
                  (\ tt -> if
                       | matchQ tt [t| Exp a a -> Exp a a |] ->
                           [| \ f -> pure
                                     (FGV.Exp
                                             (FGV.getTrm
                                              . frmRgtZro
                                              . cnvWth s
                                              . f
                                              . frmRgtZro
                                              . cnvWth s
                                              . FGV.Exp )) |]
                       | matchQ tt [t| Exp a a |] ->
                           [|cnvWth s |]
                       | otherwise                -> [| pure |]))

instance (HasSin TFG.Typ t , r ~ r' , t ~ t') =>
         Cnv (FGV.Exp t' , Env FGV.Exp r') (Exp r t)
         where
  cnv (FGV.Exp v , r) = let t = sin :: TFG.Typ t in case t of
    TFG.Wrd                   -> pure (ConI v)
    TFG.Bol                   -> pure (ConB v)
    TFG.Flt                   -> pure (ConF v)
    TFG.Tpl _ _               -> case TFG.getPrfHasSinTpl t of
     (PrfHasSin , PrfHasSin)  -> Tpl  <$> cnv (FGV.Exp (fst v) , r)
                                      <*> cnv (FGV.Exp (snd v) , r)
    TFG.Ary ta                -> case TFG.getPrfHasSinAry t of
      PrfHasSin
        | fst (bounds v) == 0 -> Ary  <$> cnv ((FGV.Exp . (+ 1) . snd . bounds) v , r)
                                      <*> cnv (samTyp (TFG.Arr TFG.Wrd ta)
                                                (FGV.Exp (fromJust
                                                   . flip lookup (assocs v))) , r)
        | otherwise           -> fail "Bad Array!"
    TFG.Cmx                   -> Cmx <$> cnv (FGV.Exp (realPart v) , r)
                                     <*> cnv (FGV.Exp (imagPart v) , r)
    TFG.Arr _ _               -> fail "Type Error!"
    TFG.May _                 -> fail "Type Error!"
    TFG.Vct _                 -> fail "Type Error!"


instance (HasSin TFG.Typ ta , HasSin TFG.Typ tb , r ~ r' , ta ~ ta' , tb ~ tb')=>
         Cnv (FGV.Exp (ta' -> tb') , Env FGV.Exp r') (Exp r ta -> Exp r tb)
         where
  cnv (FGV.Exp f , r) =
    pure ( frmRgtZro
           . cnvWth r
           . (fmap :: (a -> b) -> FGV.Exp a -> FGV.Exp b)  f
           . frmRgtZro
           . cnvWth r)
