import SciLean.Core.Vec
import SciLean.Core.IsSmooth
-- import SciLean.Core.IsSmoothDep
-- import SciLean.Core.DifferentialDep
import Lean

namespace SciLean

/-- Diffeological space 

wiki: https://en.wikipedia.org/wiki/Diffeology
-/
class Diff (X : Type) where
  plots : ∀ n, Set ((Fin n → ℝ) → X)
  plot_const : ∀ n (x : X), (λ _ : Fin n → ℝ => x) ∈ plots n
  -- plot_local - locallity aximp
  plot_comp  : ∀ (f : (Fin n → ℝ) → (Fin m → ℝ)) (p : (Fin m → ℝ) → X), 
    IsSmooth f → p ∈ plots m → p ∘ f ∈ plots n

class IsSmoothDep {X Y} [Diff X] [Diff Y] (f : X → Y) where
  maps_plot_to_plot : ∀ (n) (p : (Fin n → ℝ) → X),
    p ∈ Diff.plots n → f ∘ p ∈ Diff.plots n

instance : Diff ℝ := sorry

instance {X : Type} {Y : X → Type} [Diff ((x : X) × Y x)] (x : X) : Diff (Y x) := sorry

-- Can we make instance like this? Looks dangerous
-- instance {X : Type} {Y : X → Type} [Diff ((x : X) × Y x)] : Diff X := sorry


/--
This probably defines Ehresmann connection on `(x : X) × Y x`

wiki: https://en.wikipedia.org/wiki/Ehresmann_connection#Parallel_transport_via_horizontal_lifts
-/
class DiffBundle {X : Type} (Y : X → Type) [Diff X] extends Diff ((x : X) × Y x) where
  -- probably some coherency of the smoothe structure on X and on (x : X) × Y x
  connection : (γ : ℝ → X) → (t s : ℝ) → Y (γ t) → Y (γ s)
  connection_id : ∀ γ x, IsSmoothDep γ → connection γ t t x = x
  connection_comp : ∀ γ t t' t'' x, IsSmoothDep γ → connection γ t' t'' (connection γ t t' x) = connection γ t t'' x
  connection_locality : ∀ γ (f : ℝ → ℝ) s s' t t' (x : Y (γ (f s))), 
    IsSmoothDep γ → (hf : IsSmooth f) → 
    (h : f s = t) → (h' : t' = f s')  → 
    connection (λ t => γ (f t)) s s' x = h' ▸ connection γ t t' (h ▸ x)
  connection_is_smooth : ∀ (γ : ℝ → (x : X) × Y x) s, IsSmoothDep γ → IsSmoothDep λ (t : ℝ) => connection (λ u => (γ u).1) t s (γ t).2


export DiffBundle (connection)

instance {X Y : Type} [Diff X] [Diff Y] : DiffBundle (λ _ : X => Y) := sorry

class TangentSpace (X : Type) (TX : outParam $ X → Type) [Diff X] [∀ x, Vec (TX x)] extends DiffBundle TX where
  connection_linear : ∀ γ t s, IsSmoothDep γ → IsLin (connection γ t s)

instance {X : Type} [Vec X] : Diff X := sorry
instance {X : Type} [Vec X] : TangentSpace X (λ _ : X => X) := sorry

def diff [Diff X] [∀ x, Vec (TX x)] [TangentSpace X TX] 
         [Diff Y] [∀ y, Vec (TY y)] [TangentSpace Y TY] 
         (f : X → Y) (x : X) (dx : TX x) : TY (f x) := sorry

variable 
  {X : Type} {TX : X → Type} [Diff X] [∀ x, Vec (TX x)] [TangentSpace X TX] 
  (x : X) (dx : TX x)


-- Diff of pi type
instance {X : Type} {Y : X → Type} [∀ x, Diff (Y x)] 
         : Diff ((x : X) → Y x) := sorry

-- Diff Bundle of pi type
instance {X : Type} {Y : X → Type} {TY : (x : X) → Y x → Type} 
         [∀ x, Diff (Y x)] [∀ x, DiffBundle (TY x)] 
         : DiffBundle (λ f : (x : X) → Y x => (x : X) → TY x (f x)) := sorry

-- Tangent space of pi type
instance {X : Type} {Y : X → Type} {TY : (x : X) → Y x → Type} 
         [∀ x, Diff (Y x)] [∀ x y, Vec (TY x y)] [∀ x, TangentSpace (Y x) (TY x)] 
         : TangentSpace ((x : X) → Y x) (λ f => (x : X) → TY x (f x)) := sorry


class IsSmoothDiff {X : Type} {Y : X → Type} [Diff X] [DiffBundle Y] (f : (x : X) → Y x) where
  is_smooth : ∀ (γ : ℝ → X), IsSmoothDep γ → IsSmoothDep (λ t => connection γ t 0 (f (γ t)))

-- Diff of comp pi type
instance {X : Type} [Diff X]
         {Y : Type} [Diff Y]
         {Z : Y → Type} [DiffBundle Z]
         (f : X → Y) [IsSmoothDiff f]
         : DiffBundle (λ (x : X) => Z (f x)) := sorry


noncomputable
def D 
  {X : Type} {TX : outParam $ X → Type} [Diff X] [∀ x, Vec (TX x)] [TangentSpace X TX] 
  {Y : X → Type} {TY : outParam $ (x : X) → Y x → Type} [DiffBundle Y] [∀ x y, Vec (TY x y)] [∀ x, TangentSpace (Y x) (TY x)]
  (f : (x : X) → Y x) (x : X) (dx : TX x) : TY x (f x) := 
  have γ : ℝ → X := sorry
  have h  : γ 0 = x := sorry
  have h'  : diff γ 0 1 = h ▸ dx := sorry
  have h'' : ∀ t (y : Y (γ t)), connection γ t t y = y := sorry
  let dy := h ▸ h'' _ (f (γ 0)) ▸ diff (λ t : ℝ => connection γ t 0 (f (γ t))) 0 1
  dy

variable 
  {X : Type} {TX : X → Type} [Diff X] [∀ x, Hilbert (TX x)] [TangentSpace X TX] 
  {Y : X → Type} {TY : (x : X) → Y x → Type} [DiffBundle Y] [∀ x y, Hilbert (TY x y)] [∀ x, TangentSpace (Y x) (TY x)]
  (x : X) (dx : TX x)

instance (f : (x : X) → Y x) [IsSmoothDiff f] : DiffBundle λ x => TX x → TY x (f x) := sorry

-- noncomputable
-- def kineticEnergy (x : ℝ → X) (y : (t : ℝ) → Y (x t)) [IsSmoothDiff x] [IsSmoothDiff y] (t : ℝ) : ℝ := 
--   1/2 * ‖D y t 1‖²

variable (x : ℝ → X) [IsSmoothDiff x]

#check λ t => diff x t 1  -- velocity
#check λ t => D (λ t' => diff x t' 1) t 1 -- acceleration

noncomputable
def velocity (x : ℝ → X) [IsSmoothDiff x] (t : ℝ) : TX (x t) := diff x t 1

noncomputable
def acceleration (x : ℝ → X) [IsSmoothDiff x] (t : ℝ) : TX (x t) := D (velocity x) t 1
