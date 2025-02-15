import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Linear
import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv

import SciLean.Core.FunctionPropositions.DifferentiableAt

namespace SciLean


variable 
  (R : Type _) [NontriviallyNormedField R]
  {X : Type _} [NormedAddCommGroup X] [NormedSpace R X]
  {Y : Type _} [NormedAddCommGroup Y] [NormedSpace R Y]
  {Z : Type _} [NormedAddCommGroup Z] [NormedSpace R Z]


-- Basic rules -----------------------------------------------------------------
--------------------------------------------------------------------------------

namespace Differentiable

variable 
  {R : Type _} [NontriviallyNormedField R]
  {X : Type _} [NormedAddCommGroup X] [NormedSpace R X]
  {Y : Type _} [NormedAddCommGroup Y] [NormedSpace R Y]
  {Z : Type _} [NormedAddCommGroup Z] [NormedSpace R Z]
  {ι : Type _} [Fintype ι]
  {E : ι → Type _} [∀ i, NormedAddCommGroup (E i)] [∀ i, NormedSpace R (E i)]
  

theorem id_rule
  : Differentiable R (fun x : X => x)
  := by simp
  

theorem const_rule (x : X)
  : Differentiable R (fun _ : Y => x)
  := by simp


theorem comp_rule
  (g : X → Y) (hg : Differentiable R g)
  (f : Y → Z) (hf : Differentiable R f)
  : Differentiable R (fun x => f (g x))
  := Differentiable.comp hf hg


theorem let_rule
  (g : X → Y) (hg : Differentiable R g)
  (f : X → Y → Z) (hf : Differentiable R (fun (xy : X×Y) => f xy.1 xy.2))
  : Differentiable R (fun x => let y := g x; f x y) 
  := by apply fun x => DifferentiableAt.let_rule x g (hg x) f (hf (x, g x))


theorem pi_rule
  (f : (i : ι) → X → E i) (hf : ∀ i, Differentiable R (f i))
  : Differentiable R (fun x i => f i x)
  := fun x => DifferentiableAt.pi_rule x f (fun i => hf i x)

theorem proj_rule
  (i : ι)
  : Differentiable R (fun x : (i : ι) → E i => x i):= 
by 
  apply DifferentiableAt.proj_rule


end SciLean.Differentiable


--------------------------------------------------------------------------------
-- Register Diferentiable ------------------------------------------------------
--------------------------------------------------------------------------------

open Lean Meta SciLean FProp
def Differentiable.fpropExt : FPropExt where
  fpropName := ``Differentiable
  getFPropFun? e := 
    if e.isAppOf ``Differentiable then

      if let .some f := e.getArg? 8 then
        some f
      else 
        none
    else
      none

  replaceFPropFun e f := 
    if e.isAppOf ``Differentiable then
      e.setArg 8  f
    else          
      e

  identityRule    e :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``Differentiable.id_rule 
      origin := .decl ``Differentiable.id_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  constantRule    e :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``Differentiable.const_rule 
      origin := .decl ``Differentiable.const_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  compRule e f g := do
    let .some R := e.getArg? 0
      | return none

    let HF ← mkAppM ``Differentiable #[R, f]
    let .some hf ← FProp.fprop HF
      | trace[Meta.Tactic.fprop.discharge] "Differentiable.comp_rule, failed to discharge hypotheses{HF}"
        return none

    let HG ← mkAppM ``Differentiable #[R, g]
    let .some hg ← FProp.fprop HG
      | trace[Meta.Tactic.fprop.discharge] "Differentiable.comp_rule, failed to discharge hypotheses{HG}"
        return none

    mkAppM ``Differentiable.comp_rule #[g,hg,f,hf]

  lambdaLetRule e f g := do
    -- let thm : SimpTheorem :=
    -- {
    --   proof  := mkConst ``Differentiable.let_rule 
    --   origin := .decl ``Differentiable.let_rule 
    --   rfl    := false
    -- }
    -- FProp.tryTheorem? e thm (fun _ => pure none)
    let .some R := e.getArg? 0
      | return none

    let HF ← mkAppM ``Differentiable #[R, (← mkUncurryFun 2 f)]
    let .some hf ← FProp.fprop HF
      | trace[Meta.Tactic.fprop.discharge] "Differentiable.let_rule, failed to discharge hypotheses{HF}"
        return none

    let HG ← mkAppM ``Differentiable #[R, g]
    let .some hg ← FProp.fprop HG
      | trace[Meta.Tactic.fprop.discharge] "Differentiable.let_rule, failed to discharge hypotheses{HG}"
        return none

    mkAppM ``Differentiable.let_rule #[g,hg,f,hf]

  lambdaLambdaRule e _ :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``Differentiable.pi_rule 
      origin := .decl ``Differentiable.pi_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  projRule e :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``DifferentiableAt.proj_rule 
      origin := .decl ``DifferentiableAt.proj_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)


  discharger _ := return none

-- register fderiv
#eval show Lean.CoreM Unit from do
  modifyEnv (λ env => FProp.fpropExt.addEntry env (``Differentiable, Differentiable.fpropExt))


--------------------------------------------------------------------------------
-- Function Rules --------------------------------------------------------------
--------------------------------------------------------------------------------

open SciLean Differentiable 

variable 
  {R : Type _} [NontriviallyNormedField R]
  {X : Type _} [NormedAddCommGroup X] [NormedSpace R X]
  {Y : Type _} [NormedAddCommGroup Y] [NormedSpace R Y]
  {Z : Type _} [NormedAddCommGroup Z] [NormedSpace R Z]
  {ι : Type _} [Fintype ι]
  {E : ι → Type _} [∀ i, NormedAddCommGroup (E i)] [∀ i, NormedSpace R (E i)]


-- Id --------------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem id.arg_a.Differentiable_rule
  : Differentiable R (fun x : X => id x) := by simp


-- Prod ------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Prod.mk --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.mk.arg_fstsnd.Differentiable_rule
  (g : X → Y) (hg : Differentiable R g)
  (f : X → Z) (hf : Differentiable R f)
  : Differentiable R fun x => (g x, f x)
  := Differentiable.prod hg hf


-- Prod.fst --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.fst.arg_self.Differentiable_rule 
  (f : X → Y×Z) (hf : Differentiable R f)
  : Differentiable R (fun x => (f x).1)
  := Differentiable.fst hf


-- Prod.snd --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.snd.arg_self.Differentiable_rule 
  (f : X → Y×Z) (hf : Differentiable R f)
  : Differentiable R (fun x => (f x).2)
  := Differentiable.snd hf


-- Function.comp ---------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Function.comp.arg_a0.Differentiable_rule
  (f : Y → Z) (hf : Differentiable R f)
  (g : X → Y) (hg : Differentiable R g)
  : Differentiable R (fun x => (f ∘ g) x)
  := Differentiable.comp hf hg



-- Neg.neg ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Neg.neg.arg_a0.Differentiable_rule
  (f : X → Y) (hf : Differentiable R f) 
  : Differentiable R fun x => - f x 
  := fun x => Neg.neg.arg_a0.DifferentiableAt_rule x f (hf x)



-- HAdd.hAdd -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem HAdd.hAdd.arg_a0a1.Differentiable_rule
  (f g : X → Y) (hf : Differentiable R f) (hg : Differentiable R g)
  : Differentiable R fun x => f x + g x
  := fun x => HAdd.hAdd.arg_a0a1.DifferentiableAt_rule x f g (hf x) (hg x)



-- HSub.hSub -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem HSub.hSub.arg_a0a1.Differentiable_rule
  (f g : X → Y) (hf : Differentiable R f) (hg : Differentiable R g)
  : Differentiable R fun x => f x - g x
  := fun x => HSub.hSub.arg_a0a1.DifferentiableAt_rule x f g (hf x) (hg x)



-- HMul.hMul -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HMul.hMul.arg_a0a1.Differentiable_rule
  {Y : Type _} [TopologicalSpace Y] [NormedRing Y] [NormedAlgebra R Y] 
  (f g : X → Y) (hf : Differentiable R f) (hg : Differentiable R g)
  : Differentiable R (fun x => f x * g x)
  := Differentiable.mul hf hg



-- SMul.sMul -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HSMul.hSMul.arg_a0a1.Differentiable_rule
  {Y : Type _} [TopologicalSpace Y] [NormedRing Y] [NormedAlgebra R Y]
  (f : X → R) (g : X → Y) (hf : Differentiable R f) (hg : Differentiable R g)
  : Differentiable R (fun x => f x • g x)
  := Differentiable.smul hf hg



-- HDiv.hDiv -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HDiv.hDiv.arg_a0a1.Differentiable_rule
  {R : Type _} [NontriviallyNormedField R]
  {K : Type _} [NontriviallyNormedField K] [NormedAlgebra R K]
  (f : R → K) (g : R → K) 
  (hf : Differentiable R f) (hg : Differentiable R g) (hx : ∀ x, g x ≠ 0)
  : Differentiable R (fun x => f x / g x)
  := Differentiable.div hf hg hx



-- HPow.hPow -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HPow.hPow.arg_a0.Differentiable_rule
  (n : Nat) (f : X → R) (hf : Differentiable R f) 
  : Differentiable R (fun x => f x ^ n)
  := Differentiable.pow hf n
