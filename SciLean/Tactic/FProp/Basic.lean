import SciLean.Tactic.FProp.Init
import SciLean.Tactic.AnalyzeLambda

open Lean Meta Qq

namespace SciLean.FProp

set_option linter.unusedVariables false

open Elab Term in
def tacticToDischarge (tacticCode : Syntax) : Expr → MetaM (Option Expr) := fun e => do
    let mvar ← mkFreshExprSyntheticOpaqueMVar e `simp.discharger
    let runTac? : TermElabM (Option Expr) :=
      try
        /- We must only save messages and info tree changes. Recall that `simp` uses temporary metavariables (`withNewMCtxDepth`).
           So, we must not save references to them at `Term.State`. -/
        withoutModifyingStateWithInfoAndMessages do
          instantiateMVarDeclMVars mvar.mvarId!

          let _ ←
            withSynthesize (mayPostpone := false) do Tactic.run mvar.mvarId! (Tactic.evalTactic tacticCode *> Tactic.pruneSolvedGoals)

          let result ← instantiateMVars mvar
          if result.hasExprMVar then
            return none
          else
            return some result
      catch _ =>
        return none
    let (result?, _) ← runTac?.run {} {} 
    
    return result?



def synthesizeInstance (thmId : Origin) (x type : Expr) : MetaM Bool := do
  match (← trySynthInstance type) with
  | LOption.some val =>
    -- if (← withReducibleAndInstances <| isDefEq x val) then
    if (← withReducibleAndInstances <| isDefEq x val) then
      return true
    else
      trace[Meta.Tactic.fprop.discharge] "{← ppOrigin thmId}, failed to assign instance{indentExpr type}\nsythesized value{indentExpr val}\nis not definitionally equal to{indentExpr x}"
      return false
  | _ =>
    trace[Meta.Tactic.fprop.discharge] "{← ppOrigin thmId}, failed to synthesize instance{indentExpr type}"
    return false


def synthesizeArgs (thmId : Origin) (xs : Array Expr) (bis : Array BinderInfo) 
  (discharge? : Expr → FPropM (Option Expr)) (fprop : Expr → FPropM (Option Expr)) 
  : FPropM Bool := do
  for x in xs, bi in bis do
    let type ← inferType x
    if bi.isInstImplicit then
      unless (← synthesizeInstance thmId x type) do
        return false
    else if (← instantiateMVars x).isMVar then

      -- try type class
      if (← isClass? type).isSome then
        if (← synthesizeInstance thmId x type) then
          continue

      -- try function property
      if (← getFProp? type.getForallBody).isSome then
        if let .some proof ← fprop (← instantiateMVars type) then
          if (← isDefEq x proof) then
            continue
          else do
            trace[Meta.Tactic.fprop.discharge] "{← ppOrigin thmId}, failed to assign proof{indentExpr type}"
            return false

      -- try discharger
      if (← isProp type) then
        if let .some proof ← discharge? type then
          if (← isDefEq x proof) then
            continue 
          else do
            trace[Meta.Tactic.fprop.discharge] "{← ppOrigin thmId}, failed to assign proof{indentExpr type}"
            return false

      trace[Meta.Tactic.fprop.discharge] "{← ppOrigin thmId}, failed to discharge hypotheses{indentExpr type}"
      return false

  return true


def tryTheoremCore (xs : Array Expr) (bis : Array BinderInfo) (val : Expr) (type : Expr) (e : Expr) (thm : SimpTheorem) 
  (discharge? : Expr → FPropM (Option Expr)) (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) := do
  if (← isDefEq type e) then
    unless (← synthesizeArgs thm.origin xs bis discharge? fprop) do
      return none
    let proof ← instantiateMVars (mkAppN val xs)
    if (← hasAssignableMVar proof) then
      trace[Meta.Tactic.fprop.apply] "{← ppSimpTheorem thm}, has unassigned metavariables after unification"
      return none
    trace[Meta.Tactic.fprop.apply] "{← ppSimpTheorem thm}, \n{e}"
    return proof
  else
    trace[Meta.Tactic.fprop.unify] "failed to unify {← ppSimpTheorem thm}\n{type}\nwith\n{e}"
    return none


def tryTheorem?' (e : Expr) (thm : SimpTheorem) 
  (discharge? : Expr → FPropM (Option Expr)) (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) := do
  withNewMCtxDepth do
    let val  ← thm.getValue
    let type ← instantiateMVars (← inferType val)
    let (xs, bis, type) ← forallMetaTelescope type
    let type ← instantiateMVars type
    tryTheoremCore xs bis val type e thm discharge? fprop


def getLocalRules (fpropName : Name) : MetaM (Array SimpTheorem) := do
  let mut arr : Array SimpTheorem := #[]

  let lctx ← getLCtx
  for var in lctx do
    let type ← instantiateMVars var.type
    
    -- TODO: maybe beta reduce type or call whnf
    if (type.getForallBody.getAppFn.constName? == .some fpropName) &&
       (var.kind ≠ Lean.LocalDeclKind.auxDecl) then
       arr := arr.push {
         proof := var.toExpr
         origin := .fvar var.fvarId
         rfl := false
       }

  return arr

structure LocalRule where
  fvar  : FVarId
  proof : Expr
  mainIds : ArraySet Nat
  trailingIds : ArraySet Nat

def toFullyAppliedForm (f : Expr) : MetaM Expr := do
  lambdaTelescope f fun xs b => do
    let b ← whnf b
    withDefault do forallTelescopeReducing (← inferType b) fun xs' _ => 
      mkLambdaFVars (xs++xs') (mkAppN b xs').headBeta

private def getLocalDef? (id : FVarId) : MetaM (Option LocalDecl) := do
  return (← getLCtx).findDecl?
    fun decl => Id.run do
     if let .some (_,lhs,_) := decl.type.app3? ``Eq then
       if lhs == .fvar id then
         return .some decl
     return none

/-- Does `e` contain fvar that has local definition? i.e. local hypothesis that 
`fvar id = ...`

If it contains such fvar, replace it with its definition and return modified
expression `e'` and proof that `e = e'`
-/
def unfoldFVar? (e : Expr) : MetaM (Option (Expr × Expr)) := do
  let state := collectFVars {} (← instantiateMVars e)
  let fvarIds := state.fvarIds

  for id in fvarIds do
    if let .some decl ← getLocalDef? id then
      let f ← mkLambdaFVars #[.fvar id] e
      -- proof that `e = e'`
      let he ← mkCongrArg f decl.toExpr
      let rhs := decl.type.getArg! 2
      trace[Meta.Tactic.fprop.step] "unfolding fvar {← ppExpr decl.toExpr}\n==>\n{← ppExpr rhs}"
      let e' := f.beta #[rhs]
      return .some (e', he)

  return none

/-- If `e` contains fvar with local definition then expand it and run `fprop` again
-/
def tryAfterFVarUnfold? (e : Expr) (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) := do

  let .some (e',he) ← unfoldFVar? e | return none

  let .some prf ← fprop e' | return none
  
  return ← mkEqMPR he prf

    
def tryLocalTheorems (e : Expr) (fpropName : Name) (ext : FPropExt) 
  (fprop : Expr → FPropM (Option Expr))
  : FPropM (Option Expr) := do

  let candidates ← getLocalRules fpropName

  for thm in candidates do
    if let some proof ← tryTheorem?' e thm ext.discharger fprop then
      return proof

  return ← tryAfterFVarUnfold? e fprop

def getLocalRulesForFVar (fId : FVarId) (fpropName : Name) (ext : FPropExt) : MetaM (Array LocalRule) := do

  let mut arr : Array LocalRule := #[]

  let lctx ← getLCtx
  for var in lctx do
    if (var.kind = Lean.LocalDeclKind.auxDecl) then
      continue

    let type ← instantiateMVars var.type

    let rule? : Option LocalRule ← 
      forallTelescopeReducing var.type fun xs type => do
        if ¬(type.isAppOf' fpropName) then
          return none
        let .some f := ext.getFPropFun? type
          | return none
        let f ← toFullyAppliedForm f
        let info ← analyzeLambda f
        if (info.headFunInfo.isFVar fId) then
          return .some {
            fvar := var.fvarId
            proof := var.toExpr
            mainIds := info.mainIds
            trailingIds := info.trailingIds
          }
        pure none
    
    let .some rule := rule?
      | continue

    arr := arr.push rule

  return arr


def unfoldFunHead? (e : Expr) : MetaM (Option Expr) := do
  lambdaLetTelescope e fun xs b => do
    if let .some b' ← withTransparency .instances <| unfoldDefinition? b then
      trace[Meta.Tactic.fprop.step] s!"unfolding\n{← ppExpr b}\n==>\n{← ppExpr b'}"
      return .some (← mkLambdaFVars xs b')
    else if let .some b' ← reduceRecMatcher? b then
      trace[Meta.Tactic.fprop.step] s!"unfolding\n{← ppExpr b}\n==>\n{← ppExpr b'}"
      return .some (← mkLambdaFVars xs b')

    return none

def bvarAppCase (e : Expr) (fpropName : Name) (ext : FPropExt) (f : Expr) : FPropM (Option Expr) := do

  let .lam n t (.app g x) bi := f
    | trace[Meta.Tactic.fprop.step] "bvar app case can't handle functions like {← ppExpr f}"
      return none

  if x.hasLooseBVars then
    trace[Meta.Tactic.fprop.step] "bvar app case can't handle functions like {← ppExpr f}"
    return none
  
  if g == .bvar 0 then
    ext.projRule e
  else
    let g := .lam n t g bi
    let gType ← inferType g
    let .some (_,fType) := gType.arrow?
      | trace[Meta.Tactic.fprop.step] "bvar app step can't handle dependent functions of type {← ppExpr gType} appearing in {← ppExpr f}"
        return none

    let h := .lam n fType ((Expr.bvar 0).app x) bi
    trace[Meta.Tactic.fprop.step] "bvar app step composition\n{←ppExpr h}\n\n{← ppExpr g}"
    ext.compRule e h g

def evalSplit (e : Expr) : MetaM (Option (Expr×Expr)) := do
  match e with
  | .lam xName xType (.app f x) xBi => 
    if x.hasLooseBVars then
      return none
    withLocalDecl xName xBi xType fun xVar => do
      let f := f.instantiate1 xVar
      let F ← inferType f
      -- can't handle dependent types right now
      if F.containsFVar xVar.fvarId! then
        return none
      let f' := Expr.lam `y F ((Expr.bvar 0).app x) .default
      let g' ← mkLambdaFVars #[xVar] f
      return (f', g')
  | _ => return none

def fvarAppCase (e : Expr) (fpropName : Name) (ext : FPropExt) (f : Expr) 
  (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) := do
  let (f', g') ← splitLambdaToComp f

  -- trivial case, this prevents an infinite loop
  if (← isDefEq f' f) then

    -- -- this is a bit of a hack
    -- if let .some (f', g') ← evalSplit f then
    --   trace[Meta.Tactic.fprop.step] "fvar app case: decomposed into `({← ppExpr f'}) ∘ ({← ppExpr g'})`"
    --   let step? ← 
    --     try
    --       ext.compRule e f' g'
    --     catch e => 
    --       pure none
    --   let .some step := step? | pure ()
    --   return step
      
    trace[Meta.Tactic.fprop.step] "fvar app case: trivial"
    let step? ← tryLocalTheorems e fpropName ext fprop
    
    if let .some step := step? then
      return step

    if let .some (_,Y) := (← inferType f).arrow? then
      if Y.isForall then
        return ← fprop (ext.replaceFPropFun e (← etaExpand f))

    return ← tryAfterFVarUnfold? e fprop
  else
    trace[Meta.Tactic.fprop.step] "fvar app case: decomposed into `({← ppExpr f'}) ∘ ({← ppExpr g'})`"
    ext.compRule e f' g'


def letCase (e : Expr) (fpropName : Name) (ext : FPropExt) (f : Expr) (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) :=
  match f with
  | .lam xName xType (.letE yName yType yValue yBody _) xBi => do
    let yType  := yType.consumeMData
    let yValue := yValue.consumeMData
    let yBody  := yBody.consumeMData
    -- We perform reduction because the type is quite often of the form 
    -- `(fun x => Y) #0` which is just `Y` 
    -- Usually this is caused by the usage of `FunLike`
    let yType := yType.headBeta
    if (yType.hasLooseBVar 0) then
      throwError "dependent type encountered {← ppExpr (Expr.forallE xName xType yType default)}"

    if ¬(yValue.hasLooseBVar 0) then
      let body := yBody.swapBVars 0 1
      let e' := (.letE yName yType yValue (ext.replaceFPropFun e (.lam xName xType body xBi)) false)
      return ← fprop e'

    match (yBody.hasLooseBVar 0), (yBody.hasLooseBVar 1) with
    | true, true =>
      trace[Meta.Tactic.fprop.step] "case let\n{← ppExpr e}"
      let f := Expr.lam xName xType (.lam yName yType yBody default) xBi
      let g := Expr.lam xName xType yValue default
      ext.lambdaLetRule e f g

    | true, false => 
      trace[Meta.Tactic.fprop.step] "case let simple\n{← ppExpr e}"
      let f := Expr.lam yName yType yBody default
      let g := Expr.lam xName xType yValue default
      ext.compRule e f g

    | false, _ => 
      let f := Expr.lam xName xType (yBody.lowerLooseBVars 1 1) xBi
      fprop (ext.replaceFPropFun e f)


  | _ => throwError "expected expression of the form `fun x => lam y := ..; ..`"


def constAppCase (e : Expr) (fpropName : Name) (ext : FPropExt) (funName : Name) 
  (fprop : Expr → FPropM (Option Expr))
  : FPropM (Option Expr) := do

  let candidates ← FProp.getFPropRules funName fpropName

  if candidates.size ≠ 0 then

    for thm in candidates do
      if let some proof ← tryTheorem?' e thm ext.discharger fprop then
        return proof

    -- if all fails try local rules
    tryLocalTheorems e fpropName ext fprop

  else
    if let .some proof ← tryLocalTheorems e fpropName ext fprop then
      return proof
    else 
      -- unfold definition if there are for candidate 
      trace[Meta.Tactic.fprop.step] "no theorems found for {funName}"
      let unfoldProof? : Option Expr ← do
        let .some f := ext.getFPropFun? e | return none
        let .some f' ← unfoldFunHead? f | return none
        let e' := ext.replaceFPropFun e f'
        fprop e'

      if let .some unfoldProof := unfoldProof? then
        return unfoldProof
      else
        tryAfterFVarUnfold? e fprop

/-- Try to prove `FProp fun x => f x i` as composition `fun f => f i` `fun x => f x`
-/
def tryRemoveArg (e : Expr) (fpropName : Name) (ext : FPropExt) (f : Expr) 
  (fprop : Expr → FPropM (Option Expr)) : FPropM (Option Expr) := do
  match f with
  | .lam xName xType (.app g a) xBi => do

    if a.hasLooseBVars then 
      return none

    withLocalDecl xName xBi xType fun x => do
      let g := g.instantiate1 x

      let f' := Expr.lam `f (← inferType g) ((Expr.bvar 0).app a) default
      let g' ← mkLambdaFVars #[x] g

      ext.compRule e f' g'

  | _ => throwError "expected expression of the form `fun x => f x i`"

def cache (e : Expr) (proof? : Option Expr) : FPropM (Option Expr) := -- return proof?
  match proof? with
  | .none => return none
  | .some proof => do
    modify (fun s => { s with cache := s.cache.insert e { expr := q(True), proof? := proof} })
    return proof


-- returns proof of expression like given expression like `Differentiable K fun x => f x`
mutual 
  partial def fprop (e : Expr) : FPropM (Option Expr) := do

    -- this is for testing whether mdata cause problems or not
    -- let e := e.purgeMData

    if let .some { expr := _, proof? := .some proof } := (← get).cache.find? e then
      trace[Meta.Tactic.fprop.cache] "cached result for {e}"
      return proof
    else
      match e with
      | .letE .. => 
        letTelescope e fun xs b => do
          let .some proof ← fprop b
            | return none
          cache e (← mkLambdaFVars xs proof)
      | .forallE .. => 
        forallTelescope e fun xs b => do
          let .some proof ← fprop b
            | return none
          cache e (← mkLambdaFVars xs proof)
      | .mdata _ e' => fprop e'
      | .mvar _ => instantiateMVars e >>= fprop
      | _ => 
        let .some proof ← main e
          | return none
        cache e proof
        

  partial def main (e : Expr) : FPropM (Option Expr) := do

    let .some (fpropName, ext, f) ← getFProp? e
      | return none

    let f := f.consumeMData

    match f with
    | .letE .. => letTelescope f fun xs b => do 
      trace[Meta.Tactic.fprop.step] "case let x := ..; ..\n{← ppExpr e}"
      let e' := ext.replaceFPropFun e b
      fprop (← mkLambdaFVars xs e')

    | .lam xName xType xBody xBi => 

      match xBody.consumeMData.headBeta.consumeMData with
      | (.bvar 0) => 
        trace[Meta.Tactic.fprop.step] "case id\n{← ppExpr e}"
        ext.identityRule e

      | .letE .. => 
        letCase e fpropName ext f fprop

      | .lam  .. => 
        trace[Meta.Tactic.fprop.step] "case pi\n{← ppExpr e}"
        ext.lambdaLambdaRule e f

      | .mvar .. => fprop (← instantiateMVars e)

      | xBody => do
        if !(xBody.hasLooseBVar 0) then
          trace[Meta.Tactic.fprop.step] "case const\n{← ppExpr e}"
          ext.constantRule e
        else 
          let f' := Expr.lam xName xType xBody xBi
          let g := xBody.getAppFn'

          match g with 
          | .fvar .. => 
            trace[Meta.Tactic.fprop.step] "case fvar app `{← ppExpr g}`\n{← ppExpr e}"
            fvarAppCase e fpropName ext f' fprop
          | .bvar .. => 
            trace[Meta.Tactic.fprop.step] "case bvar app\n{← ppExpr e}"
            bvarAppCase e fpropName ext f'
          | .proj typeName idx _ => do
            let .some info := getStructureInfo? (← getEnv) typeName | return none
            let .some projName := info.getProjFn? idx | return none
            constAppCase e fpropName ext projName fprop
          | .const funName _ =>
            let numArgs := xBody.getAppNumArgs
            let arity ← getConstArity funName
            if numArgs > arity then
              trace[Meta.Tactic.fprop.step] s!"const app step, try projection rule as number of arguments({numArgs}) is bigger then constant's({funName}) arity ({arity})"
              let .some proof ← tryRemoveArg e fpropName ext f' fprop | pure ()
              return proof

            trace[Meta.Tactic.fprop.step] "case const app `{← ppExpr g}`.\n{← ppExpr e}"
            constAppCase e fpropName ext funName fprop
          | .mvar .. => 
            fprop (← instantiateMVars e)
          | _ => 
            trace[Meta.Tactic.fprop.step] "unknown case, app function {← ppExpr g} has constructor: {g.ctorName} \n{← ppExpr e}\n"
            tryLocalTheorems e fpropName ext fprop

    | .mvar _ => do
      fprop (← instantiateMVars e)

    | .fvar _ => do
      fprop (ext.replaceFPropFun e (← etaExpand f))

    | .proj typeName idx _ => do
      let .some info := getStructureInfo? (← getEnv) typeName | return none
      let .some projName := info.getProjFn? idx | return none
      constAppCase e fpropName ext projName fprop

    | f => 
      match f.getAppFn.consumeMData with
      | .const funName _ => 
        -- do we have to worry about overly applied constants here? and try to apply tryRemoveArg
        trace[Meta.Tactic.fprop.step] "case const app `{funName}.\n{← ppExpr e}"
        constAppCase e fpropName ext funName fprop
      | .mvar _ => do
        fprop (← instantiateMVars e)
      | g => 
        trace[Meta.Tactic.fprop.step] "unknown case, expression app fn {← ppExpr g} has constructor: {g.ctorName}  \n{← ppExpr e}\n"
        tryLocalTheorems e fpropName ext fprop

end


def tryTheorem? (e : Expr) (thm : SimpTheorem) (discharge? : Expr → FPropM (Option Expr)) 
  : FPropM (Option Expr) := tryTheorem?' e thm discharge? fprop
