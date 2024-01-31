import SciLean.Core.FunctionPropositions.HasAdjDiffAt
import SciLean.Core.FunctionPropositions.HasAdjDiff

import SciLean.Core.FunctionTransformations.SemiAdjoint

import SciLean.Data.Curry

set_option linter.unusedVariables false

namespace SciLean

variable
  (K : Type _) [IsROrC K]
  {X : Type _} [SemiInnerProductSpace K X]
  {Y : Type _} [SemiInnerProductSpace K Y]
  {Y₁ : Type _} [SemiInnerProductSpace K Y₁]
  {Y₂ : Type _} [SemiInnerProductSpace K Y₂]
  {Z : Type _} [SemiInnerProductSpace K Z]
  {W : Type _} [SemiInnerProductSpace K W]
  {ι : Type _} [EnumType ι]
  {κ : Type _} [EnumType κ]
  {E : ι → Type _} [∀ i, SemiInnerProductSpace K (E i)]


noncomputable
def revCDeriv
  (f : X → Y) (x : X) : Y×(Y→X) :=
  (f x, semiAdjoint K (cderiv K f x))

--@[ftrans_unfold]
noncomputable
def revCDerivEval
  (f : X → Y) (x : X) (dy : Y) : Y×X :=
  let ydf := revCDeriv K f x
  (ydf.1, ydf.2 dy)

@[ftrans_simp]
noncomputable
def gradient
  (f : X → Y) (x : X) : Y→X := (revCDeriv K f x).2

@[ftrans_simp]
noncomputable
def scalarGradient
  (f : X → K) (x : X) : X := (revCDeriv K f x).2 1

@[simp, ftrans_simp]
theorem revCDeriv_fst (f : X → Y) (x : X)
  : (revCDeriv K f x).1 = f x :=
by
  rfl

@[simp, ftrans_simp]
theorem revCDeriv_snd_zero (f : X → Y) (x : X)
  : (revCDeriv K f x).2 0 = 0 :=
by
  simp[revCDeriv]


@[ftrans]
theorem semiAdjoint.arg_y.cderiv_rule
  (f : X → Y) (a0 : W → Y) (ha0 : IsDifferentiable K a0)
  : cderiv K (fun w => semiAdjoint K f (a0 w))
    =
    fun w dw =>
      let dy := cderiv K a0 w dw
      semiAdjoint K f dy :=
by
  -- derivative of linear map is the map itself
  -- but this needs a bit more careful reasoning because we do not assume
  -- (hf : HasSemiAdjoint K f) and realy that `semiAdjoint K f = 0` if `f` does
  -- not have adjoint
  sorry_proof


theorem SciLean.cderiv.arg_a3.semiAdjoint_rule
  (f : X → Y) (x : X) (a0 : W → X) (ha0 : HasSemiAdjoint K a0)
  : semiAdjoint K (fun w => cderiv K f x (a0 w))
    =
    fun dy =>
      let dx := semiAdjoint K (cderiv K f x) dy
      semiAdjoint K a0 dx :=
by
  sorry_proof



namespace revCDeriv



-- Basic lambda calculus rules -------------------------------------------------
--------------------------------------------------------------------------------

-- this one is dangerous as it can be applied to rhs again with g = fun x => x
-- we need ftrans guard or something like that
theorem _root_.SciLean.cderiv.arg_dx.semiAdjoint_rule
  (f : Y → Z) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasSemiAdjoint K g)
  : semiAdjoint K (fun dx => cderiv K f y (g dx))
    =
    fun dz =>
      semiAdjoint K g (semiAdjoint K (cderiv K f y) dz) :=
by
  apply semiAdjoint.comp_rule K (cderiv K f y) g (hf.2 y) hg

theorem _root_.SciLean.cderiv.arg_dx.semiAdjoint_rule_at
  (f : Y → Z) (g : X → Y) (y : Y)
  (hf : HasAdjDiffAt K f y) (hg : HasSemiAdjoint K g)
  : semiAdjoint K (fun dx => cderiv K f y (g dx))
    =
    fun dz =>
      semiAdjoint K g (semiAdjoint K (cderiv K f y) dz) :=
by
  apply semiAdjoint.comp_rule K (cderiv K f y) g hf.2 hg


-- Basic lambda calculus rules -------------------------------------------------
--------------------------------------------------------------------------------

variable (X)
theorem id_rule
  : revCDeriv K (fun x : X => x) = fun x => (x, fun dx => dx) :=
by
  unfold revCDeriv
  funext _; ftrans; ftrans


theorem const_rule (y : Y)
  : revCDeriv K (fun _ : X => y) = fun x => (y, fun _ => 0) :=
by
  unfold revCDeriv
  funext _; ftrans; ftrans
variable{X}

variable(E)
theorem proj_rule (i : ι)
  : revCDeriv K (fun (x : (i:ι) → E i) => x i)
    =
    fun x =>
      (x i, fun dxi j => if h : i=j then h ▸ dxi else 0) :=
by
  unfold revCDeriv
  funext _; ftrans; ftrans
variable {E}


theorem comp_rule
  (f : Y → Z) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : revCDeriv K (fun x : X => f (g x))
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K f ydg.1
      (zdf.1,
       fun dz =>
         let dy := zdf.2 dz
         ydg.2 dy)  :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext _; ftrans; ftrans
  rfl


theorem comp_rule'
  (f : Y → Z) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : revCDeriv K (fun x : X => f (g x))
    =
    fun x =>
      let ydg := revCDeriv K g x
      revCDeriv K (fun x' => f (ydg.1 + semiAdjoint K ydg.2 (x' - x))) x :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext _; simp; ftrans;


theorem let_rule
  (f : X → Y → Z) (g : X → Y)
  (hf : HasAdjDiff K (fun (xy : X×Y) => f xy.1 xy.2)) (hg : HasAdjDiff K g)
  : revCDeriv K (fun x : X => let y := g x; f x y)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K (fun (xy : X×Y) => f xy.1 xy.2) (x,ydg.1)
      (zdf.1,
       fun dz =>
         let dxdy := zdf.2 dz
         let dx := ydg.2 dxdy.2
         dxdy.1 + dx)  :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext _; ftrans; ftrans; rfl


theorem let_rule'
  (f : X → Y → Z) (g : X → Y)
  (hf : HasAdjDiff K (fun (x,y) => f x y)) (hg : HasAdjDiff K g)
  : revCDeriv K (fun x : X => f x (g x))
    =
    fun x =>
      let ydg := revCDeriv K g x
      revCDeriv K (fun x' => f (x+x') (ydg.1 + semiAdjoint K ydg.2 x')) 0 :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext _; simp; ftrans


theorem pi_rule
  (f :  X → (i : ι) → E i) (hf : ∀ i, HasAdjDiff K (f · i))
  : (revCDeriv K fun (x : X) (i : ι) => f x i)
    =
    fun x =>
      let xdf := fun i =>
        (revCDeriv K fun (x : X) => f x i) x
      (fun i => (xdf i).1,
       fun dy => ∑ i, (xdf i).2 (dy i))
       :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  unfold revCDeriv
  funext _; ftrans; ftrans


theorem comp_rule_at
  (f : Y → Z) (g : X → Y) (x : X)
  (hf : HasAdjDiffAt K f (g x)) (hg : HasAdjDiffAt K g x)
  : revCDeriv K (fun x : X => f (g x)) x
    =
    let ydg := revCDeriv K g x
    let zdf := revCDeriv K f ydg.1
    (zdf.1,
     fun dz =>
       let dy := zdf.2 dz
       ydg.2 dy)  :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; ftrans; simp
  rw[cderiv.arg_dx.semiAdjoint_rule_at K f (cderiv K g x) (g x) (by fprop) (by fprop)]


example (g : X → Y) (x : X)
  (hg : HasAdjDiffAt K g x)
  : IsDifferentiableAt K (fun x' => g x + cderiv K g x (x' - x)) x :=
by
  have ⟨_,_⟩ := hg
  fprop

theorem comp_rule_at'
  (f : Y → Z) (g : X → Y) (x : X)
  (hf : HasAdjDiffAt K f (g x)) (hg : HasAdjDiffAt K g x)
  : revCDeriv K (fun x : X => f (g x)) x
    =
    let ydg := revCDeriv K g x
    revCDeriv K (fun x' => f (ydg.1 + semiAdjoint K ydg.2 (x' - x))) x :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; simp
  rw[cderiv.arg_dx.semiAdjoint_rule_at K f (cderiv K g x) (g x) (by fprop) (by fprop)]
  rw[cderiv.comp_rule_at K f (fun x' => g x + cderiv K g x (x' - x)) x (by simp; fprop) (by sorry_proof)]
  ftrans; simp
  rw[SciLean.cderiv.arg_a3.semiAdjoint_rule _ _ _ (cderiv K g x) (by fprop)]


theorem let_rule_at
  (f : X → Y → Z) (g : X → Y) (x : X)
  (hf : HasAdjDiffAt K (fun (xy : X×Y) => f xy.1 xy.2) (x, g x)) (hg : HasAdjDiffAt K g x)
  : revCDeriv K (fun x : X => let y := g x; f x y)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K (fun (xy : X×Y) => f xy.1 xy.2) (x,ydg.1)
      (zdf.1,
       fun dz =>
         let dxdy := zdf.2 dz
         let dx := ydg.2 dxdy.2
         dxdy.1 + dx)  :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext _; simp; sorry_proof


theorem let_rule_at'
  (f : X → Y → Z) (g : X → Y) (x : X)
  (hf : HasAdjDiffAt K (fun (x,y) => f x y) (x, g x)) (hg : HasAdjDiffAt K g x)
  : revCDeriv K (fun x : X => f x (g x)) x
    =
    let ydg := revCDeriv K g x
    revCDeriv K (fun x' => f x' (ydg.1 + semiAdjoint K ydg.2 (x' - x))) x :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; simp
  rw[cderiv.arg_dx.semiAdjoint_rule_at K _ (fun dx => (dx, cderiv K g x dx)) (x, g x) (by fprop) (by fprop)]
  let f' := fun (x,y) => f x y
  rw[cderiv.comp_rule_at K f' (fun x' => (x', g x + cderiv K g x (x' - x))) x (by simp; fprop) (by fprop)]
  conv =>
    rhs
    ftrans
    rw[SciLean.cderiv.arg_a3.semiAdjoint_rule _ _ _ (fun dx => (dx, cderiv K g x dx)) (by fprop)]


theorem pi_rule_at
  (f : X → (i : ι) → E i) (x : X) (hf : ∀ i, HasAdjDiffAt K (f · i) x)
  : (revCDeriv K fun (x : X) (i : ι) => f x i)
    =
    fun x =>
      let xdf := fun i =>
        (revCDeriv K fun (x : X) => f x i) x
      (fun i => (xdf i).1,
       fun dy => ∑ i, (xdf i).2 (dy i))
       :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  unfold revCDeriv
  funext _; ftrans; ftrans
  sorry_proof

-- few more specialized rules for function types

variable (X ι)
theorem pi_id_rule
  : (revCDeriv K fun (x : ι → X) i => x i)
    =
    fun x =>
      (x,
       fun dx => dx) :=
by
  unfold revCDeriv
  funext _; ftrans -- ftrans -- semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof
variable {X ι}


variable (ι)
theorem pi_const_rule
  (f : X → Y)
  (hf : HasAdjDiff K f)
  : (revCDeriv K fun x (i : ι) => f x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      (fun i => ydf.1,
       fun dy => ∑ i, ydf.2 (dy i)) :=
by
  unfold revCDeriv
  funext _; ftrans -- ftrans -- semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof
variable {ι}


theorem pi_uncurry_rule
  (f : X → ι → κ → Y)
  (hf : ∀ i j, HasAdjDiff K (f · i j))
  : (revCDeriv K fun x i j => f x i j)
    =
    fun x =>
      let ydf := revCDeriv K (fun x (ij : ι×κ) => f x ij.1 ij.2) x
      (fun i j => ydf.1 (i,j),
       fun dy => ydf.2 (fun ij => dy ij.1 ij.2)) :=
by
  unfold revCDeriv
  funext _; ftrans -- ftrans -- semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


variable (X)
theorem pi_curryn_rule {IX : Type _} (Is : Type _) (n : Nat) [UncurryN n IX Is X] [CurryN n Is X IX] [SemiInnerProductSpace K IX] [EnumType Is]
  (f : W → IX) (hf : HasAdjDiff K f)
  : revCDeriv K (fun (w : W) (i : Is) => uncurryN n (f w) i)
    =
    fun w =>
      let ydf := revCDeriv K f w
      (uncurryN n ydf.1,
       fun dx => ydf.2 (curryN n dx)) :=
by
  sorry_proof
variable {X}

theorem pi_comp_rule_simple
  (f : Y → Z) (g : X → ι → Y)
  (hf : HasAdjDiff K f)
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => f (g x i))
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := fun i => let y := ydg.1 i; revCDeriv K f y
      (fun i => (zdf i).1,
       fun dz =>
         let dy := fun i => (zdf i).2 (dz i)
         ydg.2 dy) :=
by
  have ⟨_,_⟩ := hf
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof

theorem pi_comp_rule
  (f : Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (f · i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y:= g x i; f y i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := fun i => let y := ydg.1 i; revCDeriv K f y
      (fun i =>
        (zdf i).1 i,
       fun dz =>
         let dy := fun i => (zdf i).2 dz
         ydg.2 dy) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof

theorem pi_comp_rule'
  (f : Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (f · i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y := g x i; f y i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K (fun (y' : ι → Y) i => f (y' i) i) (fun i => let y := ydg.1 i; y)
      (zdf.1,
       fun dz =>
         let dy := zdf.2 dz
         ydg.2 dy) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; -- ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


theorem pi_let_rule
  (f : X → Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (fun xy : X×Y => f xy.1 xy.2 i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y := g x i; f x y i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf₁ := revCDeriv K (fun (x : X) i => f x (ydg.1 i) i) x
      let zdf₂ := fun i => let y := ydg.1 i; revCDeriv K (fun y => f x y i) y
      (fun i => (zdf₂ i).1,
       fun dz =>
         let dy := fun i => (zdf₂ i).2 (dz i)
         zdf₁.2 dz + ydg.2 dy) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


theorem pi_let_rule''
  (f : X → Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (fun xy : X×Y => f xy.1 xy.2 i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y := g x i; f x y i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K (fun (xy : X×(ι →Y)) i => f xy.1 (xy.2 i) i) (x, fun i => let y := ydg.1 i; y)
      (zdf.1,
       fun dz =>
         let dxy := zdf.2 dz
         dxy.1 + ydg.2 dxy.2) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; -- ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof

theorem pi_let_rule'
  (f : X → Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (fun xy : X×Y => f xy.1 xy.2 i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y := g x i; f x y i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := fun i => let y := ydg.1 i; revCDeriv K (fun (xy : X×Y) i => f xy.1 xy.2 i) (x, y)
      (fun i => (zdf i).1 i,
       fun dz =>
         let dxy := fun i => (zdf i).2 dz
         ∑ i, (dxy i).1 + ydg.2 fun i => (dxy i).2) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; -- ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof

theorem pi_let_rule_simple
  (f : X → Y → Z) (g : X → ι → Y)
  (hf : HasAdjDiff K (fun xy : X×Y => f xy.1 xy.2))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => let y := g x i; f x y)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := fun i => revCDeriv K (fun (xy : X×Y) => f xy.1 xy.2) (x, ydg.1 i)
      (fun i => (zdf i).1,
       fun dz =>
         let dxy := fun i => (zdf i).2 (dz i)
         ∑ i, (dxy i).1 + ydg.2 fun i => (dxy i).2) :=
by
  have ⟨_,_⟩ := hf
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


theorem pi_elem_wise_comp_rule
  (f : Y → ι → Z) (g : X → ι → Y)
  (hf : ∀ i, HasAdjDiff K (f · i))
  (hg : ∀ j, HasAdjDiff K (g · j))
  : (revCDeriv K fun x i => f (g x i) i)
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := fun i => let y := ydg.1 i; revCDeriv K (f · i) y
      (fun i =>
        (zdf i).1,
       fun dz =>
         let dy := fun i => (zdf i).2 (dz i)
         ydg.2 dy) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  have _ := fun i => (hg i).1
  have _ := fun i => (hg i).2
  unfold revCDeriv
  funext _; ftrans -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


theorem pi_prod_rule
  (g₁ : W → ι → Y₁) (g₂ : W → ι → Y₂)
  (hg₁ : ∀ i, HasAdjDiff K (g₁ · i)) (hg₂ : ∀ i, HasAdjDiff K (g₂ · i))
  : (revCDeriv K fun w i => (g₁ w i, g₂ w i))
    =
    fun w =>
      let ydg₁ := revCDeriv K g₁ w
      let ydg₂ := revCDeriv K g₂ w
      (fun i => (ydg₁.1 i, ydg₂.1 i),
       fun dy =>
         ydg₁.2 (fun i => (dy i).1) + ydg₂.2 (fun i => (dy i).2)) :=
by
  have _ := fun i => (hg₁ i).1
  have _ := fun i => (hg₁ i).2
  have _ := fun i => (hg₂ i).1
  have _ := fun i => (hg₂ i).2
  unfold revCDeriv
  funext _; ftrans; -- ftrans - semiAdjoint.pi_rule fails because of some universe issues
  simp
  sorry_proof


theorem pi_inv_rule
  (f : X → κ → Y) (h : ι → κ) (h' : κ → ι) (hh : Function.Inverse h' h)
  (hf : ∀ j, HasAdjDiff K (f · j))
  : (revCDeriv K fun x i => f x (h i))
    =
    fun x =>
      let ydf := revCDeriv K f x
      (fun i => ydf.1 (h i),
       fun dy =>
         ydf.2 (fun j => dy (h' j))) :=
by
  sorry_proof


-- TODO these are not sufficient conditions for this to be true, we need that `h'` induces isomorphism `ι≃ι₁×κ`
theorem pi_rinv_rule {ι₁ : Type _} [EnumType ι₁]
  (f : X → κ → Y) (h : ι → κ) (h' : ι₁ → κ → ι) (hh : ∀ i₁, Function.RightInverse (h' i₁) h)
  (hf : ∀ j, HasAdjDiff K (f · j))
  : (revCDeriv K fun x i => f x (h i))
    =
    fun x =>
      let ydf := revCDeriv K f x
      (fun i => ydf.1 (h i),
       fun dy =>
         ydf.2 (fun j => ∑ i, dy (h' i j))) :=
by
  sorry_proof


-- Register `revCDeriv` as function transformation ------------------------------
--------------------------------------------------------------------------------

open Lean Meta Qq in
def discharger (e : Expr) : SimpM (Option Expr) := do
  withTraceNode `revDeriv_discharger (fun _ => return s!"discharge {← ppExpr e}") do
  let cache := (← get).cache
  let config : FProp.Config := {}
  let state  : FProp.State := { cache := cache }
  let (proof?, state) ← FProp.fprop e |>.run config |>.run state
  modify (fun simpState => { simpState with cache := state.cache })
  if proof?.isSome then
    return proof?
  else
    if let .some prf ← Lean.Meta.findLocalDeclWithType? e then
      return .some (.fvar prf)
    else
      if e.isAppOf ``fpropParam then
        trace[Meta.Tactic.fprop.unsafe] s!"discharging with sorry: {← ppExpr e}"
        return .some <| ← mkAppOptM ``sorryProofAxiom #[e.appArg!]
      else
        return none


open Lean Meta FTrans in
def ftransExt : FTransExt where
  ftransName := ``revCDeriv

  getFTransFun? e :=
    if e.isAppOf ``revCDeriv then

      if let .some f := e.getArg? 6 then
        some f
      else
        none
    else
      none

  replaceFTransFun e f :=
    if e.isAppOf ``revCDeriv then
      e.setArg 6 f
    else
      e

  idRule  e X := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``id_rule #[K, X], origin := .decl ``id_rule, rfl := false} ]
      discharger e

  constRule e X y := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``const_rule #[K, X, y], origin := .decl ``const_rule, rfl := false} ]
      discharger e

  projRule e X i := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``proj_rule #[K, X, i], origin := .decl ``proj_rule, rfl := false} ]
      discharger e

  compRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``comp_rule #[K, f, g], origin := .decl ``comp_rule, rfl := false},
         { proof := ← mkAppM ``comp_rule_at #[K, f, g], origin := .decl ``comp_rule_at, rfl := false} ]
      discharger e

  letRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``let_rule #[K, f, g], origin := .decl ``let_rule, rfl := false},
         { proof := ← mkAppM ``let_rule_at #[K, f, g], origin := .decl ``let_rule_at, rfl := false} ]
      discharger e

  piRule  e f := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_rule #[K, f], origin := .decl ``pi_rule, rfl := false},
         { proof := ← mkAppM ``pi_rule_at #[K, f], origin := .decl ``pi_rule_at, rfl := false} ]
      discharger e

  useRefinedPiRules := true

  piIdRule e X I := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_id_rule #[K, X, I], origin := .decl ``pi_id_rule, rfl := false} ]
      discharger e

  piConstRule e f I := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_const_rule #[K, I, f], origin := .decl ``pi_const_rule, rfl := false} ]
      discharger e

  piUncurryRule e f := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_uncurry_rule #[K, f], origin := .decl ``pi_uncurry_rule, rfl := false} ]
      discharger e

  piCurryNRule e f Is Y n := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_curryn_rule #[K, Y, Is, mkNatLit n, f], origin := .decl ``pi_curryn_rule, rfl := false} ]
      discharger e

  piCompRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_comp_rule #[K, f, g], origin := .decl ``pi_comp_rule, rfl := false} ]
      discharger e

  piElemWiseCompRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_elem_wise_comp_rule #[K, f, g], origin := .decl ``pi_elem_wise_comp_rule, rfl := false} ]
      discharger e

  piProdRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_prod_rule #[K, f, g], origin := .decl ``pi_prod_rule, rfl := false} ]
      discharger e

  piLetRule e f g := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_let_rule #[K, f, g], origin := .decl ``pi_let_rule, rfl := false} ]
      discharger e

  piInvRule e f inv := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_inv_rule #[K, f, inv.f, inv.invFun, inv.is_inv], origin := .decl ``pi_inv_rule, rfl := false} ]
      discharger e

  piRInvRule e f rinv := do
    let .some K := e.getArg? 0 | return none
    tryTheorems
      #[ { proof := ← mkAppM ``pi_rinv_rule #[K, f, rinv.f, rinv.invFun, rinv.right_inv], origin := .decl ``pi_rinv_rule, rfl := false} ]
      discharger e

  discharger := discharger


-- register revCDeriv
open Lean in
#eval show CoreM Unit from do
  modifyEnv (λ env => FTrans.ftransExt.addEntry env (``revCDeriv, ftransExt))

end revCDeriv

end SciLean

--------------------------------------------------------------------------------
-- Function Rules --------------------------------------------------------------
--------------------------------------------------------------------------------

open SciLean

variable
  {K : Type _} [IsROrC K]
  {X : Type _} [SemiInnerProductSpace K X]
  {Y : Type _} [SemiInnerProductSpace K Y]
  {Z : Type _} [SemiInnerProductSpace K Z]
  {W : Type _} [SemiInnerProductSpace K W]
  {ι : Type _} [EnumType ι]
  {E : ι → Type _} [∀ i, SemiInnerProductSpace K (E i)]


-- Prod.mk ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.mk.arg_fstsnd.revCDeriv_rule_at
  (g : X → Y) (f : X → Z) (x : X)
  (hg : HasAdjDiffAt K g x) (hf : HasAdjDiffAt K f x)
  : revCDeriv K (fun x => (g x, f x)) x
    =
    let ydg := revCDeriv K g x
    let zdf := revCDeriv K f x
    ((ydg.1,zdf.1), fun dyz => ydg.2 dyz.1 + zdf.2 dyz.2) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


@[ftrans]
theorem Prod.mk.arg_fstsnd.revCDeriv_rule
  (g : X → Y) (f : X → Z)
  (hg : HasAdjDiff K g) (hf : HasAdjDiff K f)
  : revCDeriv K (fun x => (g x, f x))
    =
    fun x =>
      let ydg := revCDeriv K g x
      let zdf := revCDeriv K f x
      ((ydg.1,zdf.1), fun dyz => ydg.2 dyz.1 + zdf.2 dyz.2) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- Prod.fst --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.fst.arg_self.revCDeriv_rule_at
  (f : X → Y×Z) (x : X) (hf : HasAdjDiffAt K f x)
  : revCDeriv K (fun x => (f x).1) x
    =
    let yzdf := revCDeriv K f x
    (yzdf.1.1, fun dy => yzdf.2 (dy,0)) :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv; ftrans; ftrans; simp

@[ftrans]
theorem Prod.fst.arg_self.revCDeriv_rule
  (f : X → Y×Z) (hf : HasAdjDiff K f)
  : revCDeriv K (fun x => (f x).1)
    =
    fun x =>
      let yzdf := revCDeriv K f x
      (yzdf.1.1, fun dy => yzdf.2 (dy,0)) :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv; ftrans; ftrans; simp


-- Prod.snd --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Prod.snd.arg_self.revCDeriv_rule_at
  (f : X → Y×Z) (x : X) (hf : HasAdjDiffAt K f x)
  : revCDeriv K (fun x => (f x).2) x
    =
    let yzdf := revCDeriv K f x
    (yzdf.1.2, fun dz => yzdf.2 (0,dz)) :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv; simp; ftrans; ftrans; simp

@[ftrans]
theorem Prod.snd.arg_self.revCDeriv_rule
  (f : X → Y×Z) (hf : HasAdjDiff K f)
  : revCDeriv K (fun x => (f x).2)
    =
    fun x =>
      let yzdf := revCDeriv K f x
      (yzdf.1.2, fun dz => yzdf.2 (0,dz)) :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv; ftrans; ftrans; simp


-- Function.comp ---------------------------------------------------------------
--------------------------------------------------------------------------------

-- @[ftrans]
-- theorem Function.comp.arg_fga0.revCDeriv_rule
--   (f : W → Y → Z) (g : W → X → Y) (a0 : W → X)
--   (hf : HasAdjDiff K (fun wy : W×Y => f wy.1 wy.2))
--   (hg : HasAdjDiff K (fun wx : W×X => g wx.1 wx.2))
--   (ha0 : HasAdjDiff K a0)
--   : revCDeriv K (fun w => ((f w) ∘ (g w)) (a0 w))
--     =
--     fun w =>
--       let xda0 := revCDeriv K a0 w
--       let ydg := revCDeriv K (fun wx : W×X => g wx.1 wx.2) (w,xda0.1)
--       let zdf := revCDeriv K (fun wy : W×Y => f wy.1 wy.2) (w,ydg.1)
--       (zdf.1,
--        fun dz =>
--          let dwy := zdf.2 dz
--          let dwx := ydg.2 dwy.2
--          let dw  := xda0.2 dwx.2
--          dwy.1 + dwx.1 + dw):=

-- by
--   unfold Function.comp; ftrans; simp[add_assoc]


-- HAdd.hAdd -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HAdd.hAdd.arg_a0a1.revCDeriv_rule_at
  (f g : X → Y) (x : X) (hf : HasAdjDiffAt K f x) (hg : HasAdjDiffAt K g x)
  : (revCDeriv K fun x => f x + g x) x
    =
    let ydf := revCDeriv K f x
    let ydg := revCDeriv K g x
    (ydf.1 + ydg.1, fun dy => ydf.2 dy + ydg.2 dy) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


@[ftrans]
theorem HAdd.hAdd.arg_a0a1.revCDeriv_rule
  (f g : X → Y) (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : (revCDeriv K fun x => f x + g x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      let ydg := revCDeriv K g x
      (ydf.1 + ydg.1, fun dy => ydf.2 dy + ydg.2 dy) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- HSub.hSub -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HSub.hSub.arg_a0a1.revCDeriv_rule_at
  (f g : X → Y) (x : X) (hf : HasAdjDiffAt K f x) (hg : HasAdjDiffAt K g x)
  : (revCDeriv K fun x => f x - g x) x
    =
    let ydf := revCDeriv K f x
    let ydg := revCDeriv K g x
    (ydf.1 - ydg.1, fun dy => ydf.2 dy - ydg.2 dy) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


@[ftrans]
theorem HSub.hSub.arg_a0a1.revCDeriv_rule
  (f g : X → Y) (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : (revCDeriv K fun x => f x - g x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      let ydg := revCDeriv K g x
      (ydf.1 - ydg.1, fun dy => ydf.2 dy - ydg.2 dy) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- Neg.neg ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem Neg.neg.arg_a0.revCDeriv_rule
  (f : X → Y) (x : X)
  : (revCDeriv K fun x => - f x) x
    =
    let ydf := revCDeriv K f x
    (-ydf.1, fun dy => - ydf.2 dy) :=
by
  unfold revCDeriv; simp; ftrans; ftrans


-- HMul.hmul -------------------------------------------------------------------
--------------------------------------------------------------------------------
open ComplexConjugate

@[ftrans]
theorem HMul.hMul.arg_a0a1.revCDeriv_rule_at
  (f g : X → K) (x : X)
  (hf : HasAdjDiffAt K f x) (hg : HasAdjDiffAt K g x)
  : (revCDeriv K fun x => f x * g x) x
    =
    let ydf := revCDeriv K f x
    let zdg := revCDeriv K g x
    (ydf.1 * zdg.1, fun dx' =>  conj ydf.1 • zdg.2 dx' + conj zdg.1 • ydf.2 dx') :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp

@[ftrans]
theorem HMul.hMul.arg_a0a1.revCDeriv_rule
  (f g : X → K)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : (revCDeriv K fun x => f x * g x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      let zdg := revCDeriv K g x
      (ydf.1 * zdg.1, fun dx' => conj ydf.1 • zdg.2 dx' + conj zdg.1 • ydf.2 dx') :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- SMul.smul -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HSMul.hSMul.arg_a0a1.revCDeriv_rule_at
  (f : X → K) (g : X → Y) (x : X)
  (hf : HasAdjDiffAt K f x) (hg : HasAdjDiffAt K g x)
  : (revCDeriv K fun x => f x • g x) x
    =
    let ydf := revCDeriv K f x
    let zdg := revCDeriv K g x
    (ydf.1 • zdg.1, fun dx' => ydf.2 (inner dx' zdg.1) + ydf.1 • zdg.2 dx') :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp; sorry_proof


example
  {Y : Type _} [SemiHilbert K Y]
  (f : X → K) (g : X → Y) (x : X)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  (hf' : HasSemiAdjoint K f)
  -- : HasSemiAdjoint K fun x_1 => SciLean.cderiv K f x x_1 • g x
  : HasSemiAdjoint K fun dx : X => f dx • g x
  := by fprop

@[ftrans]
theorem HSMul.hSMul.arg_a0a1.revCDeriv_rule
  {Y : Type _} [SemiHilbert K Y]
  (f : X → K) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : (revCDeriv K fun x => f x • g x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      let zdg := revCDeriv K g x
      (ydf.1 • zdg.1, fun dx' => conj ydf.1 • zdg.2 dx' + ydf.2 (inner zdg.1 dx')) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- HDiv.hDiv -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem HDiv.hDiv.arg_a0a1.revCDeriv_rule_at
  (f g : X → K) (x : X)
  (hf : HasAdjDiffAt K f x) (hg : HasAdjDiffAt K g x) (hx : g x ≠ 0)
  : (revCDeriv K fun x => f x / g x) x
    =
    let ydf := revCDeriv K f x
    let zdg := revCDeriv K g x
    (ydf.1 / zdg.1,
     fun dx' => (1 / (conj zdg.1)^2) • (conj zdg.1 • ydf.2 dx' - conj ydf.1 • zdg.2 dx')) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


@[ftrans]
theorem HDiv.hDiv.arg_a0a1.revCDeriv_rule
  (f g : X → K)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g) (hx : ∀ x, g x ≠ 0)
  : (revCDeriv K fun x => f x / g x)
    =
    fun x =>
      let ydf := revCDeriv K f x
      let zdg := revCDeriv K g x
      (ydf.1 / zdg.1,
       fun dx' => (1 / (conj zdg.1)^2) • (conj zdg.1 • ydf.2 dx' - conj ydf.1 • zdg.2 dx')) :=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv; simp; ftrans; ftrans; simp


-- HPow.hPow -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
def HPow.hPow.arg_a0.revCDeriv_rule_at
  (f : X → K) (x : X) (n : Nat) (hf : HasAdjDiffAt K f x)
  : revCDeriv K (fun x => f x ^ n) x
    =
    let ydf := revCDeriv K f x
    (ydf.1 ^ n, fun dx' => (n * conj ydf.1 ^ (n-1)) • ydf.2 dx') :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv; simp; funext dx; ftrans; ftrans; simp[smul_smul]; ring_nf

@[ftrans]
def HPow.hPow.arg_a0.revCDeriv_rule
  (f : X → K) (n : Nat) (hf : HasAdjDiff K f)
  : revCDeriv K (fun x => f x ^ n)
    =
    fun x =>
      let ydf := revCDeriv K f x
      (ydf.1 ^ n, fun dx' => (n * (conj ydf.1 ^ (n-1))) • ydf.2 dx') :=
by
  have ⟨_,_⟩ := hf
  funext x
  unfold revCDeriv; simp; funext dx; ftrans; ftrans; simp[smul_smul]; ring_nf



-- EnumType.sum ----------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem SciLean.EnumType.sum.arg_f.revCDeriv_rule {ι : Type _} [EnumType ι]
  (f : X → ι → Y) (hf : ∀ i, HasAdjDiff K (fun x => f x i))
  : revCDeriv K (fun x => ∑ i, f x i)
    =
    fun x =>
      let ydf := revCDeriv K (fun x i => f x i) x
      (∑ i, ydf.1 i,
       fun dy => ydf.2 (fun _ => dy)) :=
by
  have _ := fun i => (hf i).1
  have _ := fun i => (hf i).2
  unfold revCDeriv
  funext x; simp
  ftrans
  sorry_proof


-- d/ite -----------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans]
theorem ite.arg_te.revCDeriv_rule
  (c : Prop) [dec : Decidable c] (t e : X → Y)
  : revCDeriv K (fun x => ite c (t x) (e x))
    =
    fun y =>
      ite c (revCDeriv K t y) (revCDeriv K e y) :=
by
  induction dec
  case isTrue h  => ext y <;> simp[h]
  case isFalse h => ext y <;> simp[h]

@[ftrans]
theorem dite.arg_te.revCDeriv_rule
  (c : Prop) [dec : Decidable c]
  (t : c  → X → Y) (e : ¬c → X → Y)
  : revCDeriv K (fun x => dite c (t · x) (e · x))
    =
    fun y =>
      dite c (fun p => revCDeriv K (t p) y)
             (fun p => revCDeriv K (e p) y) :=
by
  induction dec
  case isTrue h  => ext y <;> simp[h]
  case isFalse h => ext y <;> simp[h]


--------------------------------------------------------------------------------

section InnerProductSpace

variable
  {R : Type _} [RealScalar R]
  -- {K : Type _} [Scalar R K]
  {X : Type _} [SemiInnerProductSpace R X]
  {Y : Type _} [SemiHilbert R Y]

-- Inner -----------------------------------------------------------------------
--------------------------------------------------------------------------------

open ComplexConjugate

@[ftrans]
theorem Inner.inner.arg_a0a1.revCDeriv_rule
  (f : X → Y) (g : X → Y)
  (hf : HasAdjDiff R f) (hg : HasAdjDiff R g)
  : (revCDeriv R fun x => ⟪f x, g x⟫[R])
    =
    fun x =>
      let y₁df := revCDeriv R f x
      let y₂dg := revCDeriv R g x
      let dx₁ := y₁df.2 y₂dg.1
      let dx₂ := y₂dg.2 y₁df.1
      (⟪y₁df.1, y₂dg.1⟫[R],
       fun dr =>
         conj dr • dx₁ + dr • dx₂):=
by
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  unfold revCDeriv
  funext x; simp
  ftrans only
  simp
  ftrans


@[ftrans]
theorem SciLean.Norm2.norm2.arg_a0.revCDeriv_rule
  (f : X → Y)
  (hf : HasAdjDiff R f)
  : (revCDeriv R fun x => ‖f x‖₂²[R])
    =
    fun x =>
      let ydf := revCDeriv R f x
      let ynorm2 := ‖ydf.1‖₂²[R]
      (ynorm2,
       fun dr =>
         ((2:R) * dr) • ydf.2 ydf.1):=
by
  have ⟨_,_⟩ := hf
  funext x; simp[revCDeriv]
  ftrans only
  simp
  ftrans
  simp[smul_smul]


@[ftrans]
theorem SciLean.norm₂.arg_x.revCDeriv_rule
  (f : X → Y)
  (hf : HasAdjDiff R f) (hx : fpropParam (∀ x, f x≠0))
  : (revCDeriv R (fun x => ‖f x‖₂[R]))
    =
    fun x =>
      let ydf := revCDeriv R f x
      let ynorm := ‖ydf.1‖₂[R]
      (ynorm,
       fun dr =>
         (ynorm⁻¹ * dr) • ydf.2 ydf.1) :=
by
  have ⟨_,_⟩ := hf
  unfold revCDeriv
  unfold fpropParam at hx
  ftrans only
  simp
  ftrans
  funext dr; simp[smul_smul]


@[ftrans]
theorem SciLean.norm₂.arg_x.revCDeriv_rule_at
  (f : X → Y) (x : X)
  (hf : HasAdjDiffAt R f x) (hx : f x≠0)
  : (revCDeriv R (fun x => ‖f x‖₂[R]) x)
    =
    let ydf := revCDeriv R f x
    let ynorm := ‖ydf.1‖₂[R]
    (ynorm,
     fun dr =>
       (ynorm⁻¹ * dr) • ydf.2 ydf.1):=
by
  have ⟨_,_⟩ := hf
  simp[revCDeriv]
  ftrans only
  simp
  ftrans
  funext dr; simp[smul_smul]

end InnerProductSpace


-- semiAdjoint -----------------------------------------------------------------
--------------------------------------------------------------------------------

-- this should not apply for `a0 = (fun x => x)`
-- @[ftrans]


@[ftrans]
theorem SciLean.semiAdjoint.arg_y.revCDeriv_rule
  (f : X → Y) (a0 : W → Y) (hf : HasSemiAdjoint K f) (ha0 : HasAdjDiff K a0)
  : revCDeriv K (fun w => semiAdjoint K f (a0 w))
    =
    fun w =>
      let ada := revCDeriv K a0 w
      (semiAdjoint K f ada.1,
       fun dx => ada.2 (f dx)) :=
by
  have ⟨_,_⟩ := ha0
  unfold revCDeriv
  funext x; simp; ftrans; ftrans


-- slightly odd rules that are needed when dealing with expressions like:
--
--  let ydg := <∂ (x':=x), g x'
--  <∂ (x':=x), semiAdjoint K ydg.2 (x' - x)
--
-- here we need to know that `ydg.2` has semi-adjoint
--
-- TODO: `fprop` is not designed to use rules like this! It works mainly by accident
--       fom the support for monadic `fwd/revCDerivValM`. This should have first
--       class support.
@[fprop]
theorem Prod.snd.arg.IsDifferentiable_rule_of_revCDeriv
  (f : X → Y) (x : X) (hf : HasAdjDiff K f)
  : IsDifferentiable K (revCDeriv K f x).2 := by unfold revCDeriv; simp; fprop

@[fprop]
theorem Prod.snd.arg.HasSemiAdjoint_rule_revCDeriv
  (f : X → Y) (x : X) (hf : HasAdjDiff K f)
  : HasSemiAdjoint K (revCDeriv K f x).2 := by unfold revCDeriv; simp; fprop

@[fprop]
theorem Prod.snd.arg.HasAdjDiff_rule_revCDeriv
  (f : X → Y) (x : X)
  : HasAdjDiff K (revCDeriv K f x).2 := by unfold revCDeriv; simp; fprop
