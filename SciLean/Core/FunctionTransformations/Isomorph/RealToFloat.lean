import SciLean.Core.FunctionTransformations.Isomorph
import SciLean.Core.Objects.IsomorphicType.RealToFloat

import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan

open SciLean

section RealToFloat

variable {α α' β β' γ γ' : Type _}
  [IsomorphicType `RealToFloat α α']
  [IsomorphicType `RealToFloat β β']
  [IsomorphicType `RealToFloat γ γ']


@[ftrans]
axiom HAdd.hAdd.arg_a0a1.isomorph_rule_RealToFloat (f g : α → ℝ) 
  : isomorph `RealToFloat (fun x => f x + g x)
    =
    fun x : α' => isomorph `RealToFloat f x + isomorph `RealToFloat g x

@[ftrans]
axiom HSub.hSub.arg_a0a1.isomorph_rule_RealToFloat (f g : α → ℝ) 
  : isomorph `RealToFloat (fun x => f x - g x)
    =
    fun x : α' => isomorph `RealToFloat f x - isomorph `RealToFloat g x


@[ftrans]
axiom HMul.hMul.arg_a0a1.isomorph_rule_RealToFloat (f g : α → ℝ) 
  : isomorph `RealToFloat (fun x => f x * g x)
    =
    fun x : α' => isomorph `RealToFloat f x * isomorph `RealToFloat g x


@[ftrans]
axiom HDiv.hDiv.arg_a0a1.isomorph_rule_RealToFloat (f g : α → ℝ) 
  : isomorph `RealToFloat (fun x => f x / g x)
    =
    fun x : α' => isomorph `RealToFloat f x / isomorph `RealToFloat g x


@[ftrans]
axiom Neg.neg.arg_a0.isomorph_rule_RealToFloat (f : α → ℝ) 
  : isomorph `RealToFloat (fun x => - f x)
    =
    fun x : α' => - isomorph `RealToFloat f x

@[ftrans]
axiom Real.sqrt.arg_x.isomorph_rule_RealToFloat (f : α → ℝ)
  : isomorph `RealToFloat (fun x => (f x).sqrt)
    =
    fun x : α' => (isomorph `RealToFloat f x).sqrt


@[ftrans]
theorem Prod.fst.arg_self.isomorph_rule {α α' β₁ β₂ β₁' β₂' : Sort _} 
  [IsomorphicType `RealToFloat α α']
  [IsomorphicType `RealToFloat β₁ β₁']
  [IsomorphicType `RealToFloat β₂ β₂']
  (f : α → β₁×β₂) 
  : isomorph `RealToFloat (fun x => (f x).1)
    =
    fun x => ((isomorph `RealToFloat f) x).1 :=
by
  funext x
  unfold isomorph
  unfold instIsomorphicTypeRealToFloatProd
  unfold IsomorphicType.equiv
  simp

@[ftrans]
theorem Prod.snd.arg_self.isomorph_rule {α α' β₁ β₂ β₁' β₂' : Sort _} 
  [IsomorphicType `RealToFloat α α']
  [IsomorphicType `RealToFloat β₁ β₁']
  [IsomorphicType `RealToFloat β₂ β₂']
  (f : α → β₁×β₂) 
  : isomorph `RealToFloat (fun x => (f x).2)
    =
    fun x => ((isomorph `RealToFloat f) x).2 :=
by
  funext x
  unfold isomorph
  unfold instIsomorphicTypeRealToFloatProd
  unfold IsomorphicType.equiv
  simp


@[ftrans]
axiom And.arg_ab.isomorph_rule {α α' : Sort _} [IsomorphicType `RealToFloat α α']
  (f : α → Prop) (g : α → Prop)
  : isomorph `RealToFloat (fun x => f x ∧ g x)
    =
    fun x => isomorph `RealToFloat f x ∧ isomorph `RealToFloat g x 


@[ftrans]
axiom LE.le.arg_a0a1.isomorph_rule {α α' : Sort _} [IsomorphicType `RealToFloat α α']
  (f : α → ℝ) (g : α → ℝ)
  : isomorph `RealToFloat (fun x => f x ≤ g x)
    =
    fun x => isomorph `RealToFloat f x ≤ isomorph `RealToFloat g x 


@[ftrans]
axiom Real.exp.arg_x.isomorph_rule {α α' : Sort _} [IsomorphicType `RealToFloat α α']
  (f : α → ℝ)
  : isomorph `RealToFloat (fun x => Real.exp (f x))
    =
    fun x => Float.exp (isomorph `RealToFloat f x)


end RealToFloat

section FloatToReal

variable {α α' β β' γ γ' : Type _}
  [IsomorphicType `FloatToReal α α']
  [IsomorphicType `FloatToReal β β']
  [IsomorphicType `FloatToReal γ γ']

instance : Inv Float := ⟨fun x => 1.0 / x⟩

@[ftrans]
axiom HAdd.hAdd.arg_a0a1.isomorph_rule_FloatToReal (f g : α → Float) 
  : isomorph `FloatToReal (fun x => f x + g x)
    =
    fun x : α' => isomorph `FloatToReal f x + isomorph `FloatToReal g x


@[ftrans]
axiom HSub.hSub.arg_a0a1.isomorph_rule_FloatToReal (f g : α → Float) 
  : isomorph `FloatToReal (fun x => f x - g x)
    =
    fun x : α' => isomorph `FloatToReal f x - isomorph `FloatToReal g x


@[ftrans]
axiom HMul.hMul.arg_a0a1.isomorph_rule_FloatToReal (f g : α → Float) 
  : isomorph `FloatToReal (fun x => f x * g x)
    =
    fun x : α' => isomorph `FloatToReal f x * isomorph `FloatToReal g x


@[ftrans]
axiom HDiv.hDiv.arg_a0a1.isomorph_rule_FloatToReal (f g : α → Float) 
  : isomorph `FloatToReal (fun x => f x / g x)
    =
    fun x : α' => isomorph `FloatToReal f x / isomorph `FloatToReal g x


@[ftrans]
axiom Neg.neg.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => - f x)
    =
    fun x : α' => - isomorph `FloatToReal f x


@[ftrans]
axiom Inv.inv.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => (f x)⁻¹)
    =
    fun x : α' => (isomorph `FloatToReal f x)⁻¹


@[ftrans]
axiom Float.exp.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.exp (f x))
    =
    fun x => Real.exp (isomorph `FloatToReal f x)

@[ftrans]
axiom Float.sin.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.sin (f x))
    =
    fun x => Real.sin (isomorph `FloatToReal f x)

@[ftrans]
axiom Float.cos.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.cos (f x))
    =
    fun x => Real.cos (isomorph `FloatToReal f x)

@[ftrans]
axiom Float.asin.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.asin (f x))
    =
    fun x => Real.arcsin (isomorph `FloatToReal f x)

@[ftrans]
axiom Float.acos.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.acos (f x))
    =
    fun x => Real.arccos (isomorph `FloatToReal f x)

@[ftrans]
axiom _root_.Float.atan.arg_a0.isomorph_rule_FloatToReal (f : α → Float) 
  : isomorph `FloatToReal (fun x => Float.atan (f x))
    =
    fun x => Real.arctan (isomorph `FloatToReal f x)


@[simp]
axiom Zero.zero.isomorph_rule_FloatToReal 
  : floatToReal (0 : Float)
    =
    (0 : ℝ)

@[simp]
axiom One.one.isomorph_rule_FloatToReal 
  : floatToReal (1 : Float)
    =
    (1 : ℝ)
