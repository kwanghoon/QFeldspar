module QFeldspar.Normalisation (nrm) where

import QFeldspar.MyPrelude hiding (fmap,foldl)

import QFeldspar.Expression.GADTFirstOrder
import QFeldspar.Expression.Utils.GADTFirstOrder
    (sucAll,sbs,replaceOne,cntVar,pattern TF,pattern V,pattern NV,isVal)
import QFeldspar.Variable.Typed
import QFeldspar.Singleton
import QFeldspar.ChangeMonad
import qualified QFeldspar.Type.GADT as TG
import QFeldspar.Environment.Typed
import QFeldspar.Magic

nrm :: TG.Type a => Exp s g a -> Exp s g a
nrm = tilNotChg nrmOne

cmt :: forall a s g d d' as c.
       (Match c as a , TG.Type a , as ~ Add d d' , TG.Types d , TG.Types d') =>
       Var s c -> Env (Exp s g) d -> Env (Exp s g) d' -> Chg (Exp s g a)
cmt x d d' = do
  let tsd  = sin :: Env TG.Typ d
  let tsd' = sin :: Env TG.Typ d'
  PrfHasSin <- getPrfHasSinM (add tsd tsd')
  case d' of
    Emp           -> return (Prm x (add d d'))
    Ext (NV e) es -> case TG.getPrfHasSinEnvOf d' of
     (PrfHasSin,PrfHasSin) -> chg (LeT e (Prm x (add (fmap sucAll d) (Ext (Var Zro) (fmap sucAll es)))))
    Ext (e :: Exp s g te) (es :: Env (Exp s g) tes) -> case TG.getPrfHasSinEnvOf d' of
     (PrfHasSin,PrfHasSin) -> case obvious :: Add (Add d (te ': '[])) tes :~: Add d (te ': tes) of
         Rfl -> do PrfHasSin <- getPrfHasSinM (add tsd (Ext (sinTyp e) Emp))
                   cmt x (add d (Ext e Emp)) es

hasNV :: Env (Exp s g) d -> Bool
hasNV = foldl (\ b e -> b || (not (isVal e))) False

nrmOne :: forall s g a. TG.Type a => Exp s g a -> Chg (Exp s g a)
nrmOne ee = case ee of
    Prm x es
      | hasNV es    -> cmt x Emp es
      | otherwise   -> Prm x <$> TG.mapMC nrmOne es

    App ef                      (NV ea) -> chg (LeT ea (App (sucAll ef) (Var Zro)))
    App (TF (Abs eb))           (V  ea) -> chg (sbs ea eb)
    App (TF (Cnd (V ec) et ef)) (V  ea) -> chg (Cnd ec (App et ea) (App ef ea))
    App (TF (LeT (NV el) eb))   (V  ea) -> chg (LeT el (App eb (sucAll ea)))

    Cnd (NV ec)           et ef -> chg (LeT ec (Cnd (Var Zro) (sucAll et) (sucAll ef)))
    Cnd (TF (ConB True))  et _  -> chg et
    Cnd (TF (ConB False)) _  ef -> chg ef

    Whl (NV ec) eb      ei      -> chg (LeT ec (Whl (Var Zro) (sucAll eb) (sucAll ei)))
    Whl (V  ec) (NV eb) ei      -> chg (LeT eb (Whl (sucAll ec) (Var Zro)  (sucAll ei)))
    Whl (V  ec) (V  eb) (NV ei) -> chg (LeT ei (Whl (sucAll ec) (sucAll eb) (Var Zro)))

    Tpl (NV ef) es               -> chg (LeT ef (Tpl (Var Zro) (sucAll es)))
    Tpl (V ef)  (NV es)          -> chg (LeT es (Tpl (sucAll ef) (Var Zro)))

    Fst (NV e)                   -> chg (LeT e (Fst (Var Zro)))
    Fst (TF (Tpl (V ef) (V _)))  -> chg  ef

    Snd (NV e)                   -> chg (LeT e (Snd (Var Zro)))
    Snd (TF (Tpl (V _)  (V es))) -> chg  es

    Ary (NV el) ef               -> chg (LeT el (Ary (Var Zro) (sucAll ef)))
    Ary (V  el) (NV ef)          -> chg (LeT ef (Ary (sucAll el) (Var Zro)))

    Len (NV ea)                  -> chg (LeT ea (Len (Var Zro)))
    Len (TF (Ary (V el) _))      -> chg  el

    Ind (NV ea)        ei        -> chg (LeT ea (Ind (Var Zro) (sucAll ei)))
    Ind (V ea)         (NV ei)   -> chg (LeT ei (Ind (sucAll ea) (Var Zro)))
    Ind (TF (Ary (V _) ef)) (V ei) -> chg (App ef ei)

    AryV (NV el) ef              -> chg (LeT el (AryV (Var Zro) (sucAll ef)))
    AryV (V  el) (NV ef)         -> chg (LeT ef (AryV (sucAll el) (Var Zro)))

    LenV (NV ea)                 -> chg (LeT ea (LenV (Var Zro)))
    LenV (TF (AryV (V el) _))    -> chg  el

    IndV (NV ea)              ei      -> chg (LeT ea (IndV (Var Zro)  (sucAll ei)))
    IndV (V ea)               (NV ei) -> chg (LeT ei (IndV (sucAll ea) (Var Zro)))
    IndV (TF (AryV (V _) ef)) (V ei)  -> chg (App ef ei)

    Cmx (NV er) ei               -> chg (LeT er (Cmx  (Var Zro)  (sucAll ei)))
    Cmx (V er)  (NV ei)          -> chg (LeT ei (Cmx  (sucAll er) (Var Zro) ))

    LeT (TF (LeT (NV el') eb'))  eb   -> chg (LeT el' (LeT eb' (replaceOne eb)))
    LeT (TF (Cnd ec et ef))      eb   -> chg (Cnd ec (LeT et eb) (LeT ef eb))
    LeT (V v)               eb   -> chg (sbs v eb)
    LeT (NV v)         eb
      | cntVar Zro eb == 0       -> chg (sbs v eb)

    Som (NV e)                   -> chg (LeT e  (Som (Var Zro)))

    May (NV em) en      es       -> chg (LeT em (May (Var Zro)   (sucAll en) (sucAll es)))
    May (V  em) (NV en) es       -> chg (LeT en (May (sucAll em) (Var Zro)   (sucAll es)))
    May (V  em) (V  en) (NV es)  -> chg (LeT es (May (sucAll em) (sucAll en) (Var Zro)))
    May (TF Non) en      _       -> chg en
    May (TF (Som e)) _       es  -> chg (App es e)

    Mul er  (NV ei)              -> chg (LeT ei (Mul (sucAll er) (Var Zro)))
    Mul (NV er) (V ei)           -> chg (LeT er (Mul (Var Zro)   (sucAll ei)))

    Add er  (NV ei)              -> chg (LeT ei (Add (sucAll er) (Var Zro)))
    Add (NV er) (V ei)           -> chg (LeT er (Add (Var Zro)   (sucAll ei)))

    Sub er  (NV ei)              -> chg (LeT ei (Sub (sucAll er) (Var Zro)))
    Sub (NV er) (V ei)           -> chg (LeT er (Sub (Var Zro)   (sucAll ei)))

    Eql er  (NV ei)              -> chg (LeT ei (Eql (sucAll er) (Var Zro)))
    Eql (NV er) (V ei)           -> chg (LeT er (Eql (Var Zro)   (sucAll ei)))

    Ltd er  (NV ei)              -> chg (LeT ei (Ltd (sucAll er) (Var Zro)))
    Ltd (NV er) (V ei)           -> chg (LeT er (Ltd (Var Zro)   (sucAll ei)))

    Mem (NV e)                   -> chg (LeT e (Mem (Var Zro)))

    _                            -> $(genOverloadedM 'ee ''Exp  ['Prm]
     (\ tt -> if
      | matchQ tt [t| Exp a a a |] -> [| nrmOne |]
      | otherwise                  -> [| pure   |]))
