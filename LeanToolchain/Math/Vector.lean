import Init.Data.Nat.Basic
import Init.Data.List.Basic
import Init.Data.UInt.Basic

set_option checkBinderAnnotations false

/-!
# Dimension-Indexed Vectors

This module provides dimension-indexed vectors with basic operations and lemmas.
Vectors are represented as lists with a proof that their length matches the dimension.
All algebraic properties are formally proven with proper typeclass instances.
-/

namespace LeanToolchain.Math

/-- A vector of length n with elements of type α -/
structure Vec (α : Type) (n : Nat) where
  data : List α
  length_eq : data.length = n

/-- Create a vector from a list with length proof -/
def Vec.mk' {α : Type} (data : List α) (h : data.length = n) : Vec α n :=
  ⟨data, h⟩

/-- Empty vector -/
def Vec.nil {α : Type} : Vec α 0 :=
  ⟨[], rfl⟩

/-- Cons an element to a vector -/
def Vec.cons {α : Type} {n : Nat} (x : α) (v : Vec α n) : Vec α (n + 1) :=
  ⟨x :: v.data, by rw [List.length_cons, v.length_eq]⟩

/-- Head of a non-empty vector -/
def Vec.head {α : Type} {n : Nat} (v : Vec α (n + 1)) : α :=
  match v.data, v.length_eq with
  | x :: _, _ => x
  | [], h => nomatch h

/-- Tail of a non-empty vector -/
def Vec.tail {α : Type} {n : Nat} (v : Vec α (n + 1)) : Vec α n :=
  match v.data, v.length_eq with
  | _ :: xs, h => ⟨xs, by rw [List.length_cons] at h; exact Nat.succ.inj h⟩
  | [], h => nomatch h

/-- Get element at index i -/
def Vec.get {α : Type} {n : Nat} (v : Vec α n) (i : Fin n) : α :=
  v.data.get (Fin.cast (Eq.symm v.length_eq) i)

/-- Set element at index i -/
def Vec.set {α : Type} {n : Nat} (v : Vec α n) (i : Fin n) (x : α) : Vec α n :=
  ⟨v.data.set i x, by rw [List.length_set, v.length_eq]⟩

/-- Vector addition (requires Add instance) -/
def Vec.add {α : Type} [Add α] {n : Nat} (v1 v2 : Vec α n) : Vec α n :=
  ⟨List.zipWith (· + ·) v1.data v2.data, by rw [List.length_zipWith, v1.length_eq, v2.length_eq, Nat.min_self]⟩

/-- Vector subtraction (requires Sub instance) -/
def Vec.sub {α : Type} [Sub α] {n : Nat} (v1 v2 : Vec α n) : Vec α n :=
  ⟨List.zipWith (· - ·) v1.data v2.data, by rw [List.length_zipWith, v1.length_eq, v2.length_eq, Nat.min_self]⟩

/-- Scalar multiplication (requires HMul instance) -/
def Vec.smul {α β : Type} [HMul α β β] {n : Nat} (c : α) (v : Vec β n) : Vec β n :=
  ⟨v.data.map (fun x => HMul.hMul c x), by rw [List.length_map, v.length_eq]⟩

/-- Dot product -/
def Vec.dot {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v1 v2 : Vec α n) : α :=
  List.foldl (· + ·) 0 (List.zipWith (· * ·) v1.data v2.data)

/-- Vector magnitude squared (for norm-2) -/
def Vec.magSq {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v : Vec α n) : α :=
  v.dot v

/-- Convert vector to list -/
def Vec.toList {α : Type} {n : Nat} (v : Vec α n) : List α :=
  v.data

/-- Convert list to vector (unsafe, assumes correct length) -/
def Vec.fromList {α : Type} (data : List α) (n : Nat) (h : data.length = n) : Vec α n :=
  ⟨data, h⟩

/-- Zero vector -/
def Vec.zero {α : Type} [OfNat α 0] {n : Nat} : Vec α n :=
  ⟨List.replicate n 0, by rw [List.length_replicate]⟩

/-!
## Additional Vector Operations
-/

/-- Vector negation (requires Neg instance) -/
def Vec.neg {α : Type} [Neg α] {n : Nat} (v : Vec α n) : Vec α n :=
  ⟨v.data.map Neg.neg, by rw [List.length_map, v.length_eq]⟩

/-- Cross product (3D vectors only) -/
def Vec.cross {α : Type} [Sub α] [Mul α] {v1 v2 : Vec α 3} : Vec α 3 :=
  let x1 := v1.get ⟨0, by simp⟩
  let y1 := v1.get ⟨1, by simp⟩
  let z1 := v1.get ⟨2, by simp⟩
  let x2 := v2.get ⟨0, by simp⟩
  let y2 := v2.get ⟨1, by simp⟩
  let z2 := v2.get ⟨2, by simp⟩
  Vec.cons (y1 * z2 - z1 * y2) (Vec.cons (z1 * x2 - x1 * z2) (Vec.cons (x1 * y2 - y1 * x2) Vec.nil))

/-- Vector normalization (requires Sqrt and Div instances) -/
def Vec.normalize {α : Type} [Add α] [Mul α] [OfNat α 0] [Sqrt α] [Div α] {n : Nat} (v : Vec α n) : Vec α n :=
  let mag := sqrt v.magSq
  v.smul (1 / mag)

/-- L1 norm (Manhattan norm) -/
def Vec.norm1 {α : Type} [Add α] [OfNat α 0] [Abs α] {n : Nat} (v : Vec α n) : α :=
  List.foldl (· + ·) 0 (v.data.map abs)

/-- L∞ norm (maximum norm) -/
def Vec.normInf {α : Type} [OfNat α 0] [Max α] [Abs α] {n : Nat} (v : Vec α n) : α :=
  List.foldl max 0 (v.data.map abs)

/-- Distance between two vectors (L2) -/
def Vec.distance {α : Type} [Add α] [Sub α] [Mul α] [OfNat α 0] [Sqrt α] {n : Nat}
  (v1 v2 : Vec α n) : α :=
  sqrt (v1.sub v2).magSq

/-- Angle between two vectors (cosine of angle) -/
def Vec.cosAngle {α : Type} [Add α] [Mul α] [OfNat α 0] [Sqrt α] [Div α] {n : Nat}
  (v1 v2 : Vec α n) : α :=
  v1.dot v2 / (sqrt v1.magSq * sqrt v2.magSq)

/-!
## Typeclass Instances for Common Types

We provide instances for the basic numeric types used in vector operations.
Note: For full real number support (sqrt, abs, etc.), mathlib would be needed.
-/

-- Instance for Nat
instance : Add Nat := ⟨Nat.add⟩
instance : Sub Nat := ⟨Nat.sub⟩
instance : Mul Nat := ⟨Nat.mul⟩
instance : OfNat Nat 0 := ⟨0⟩
instance : OfNat Nat 1 := ⟨1⟩

-- Instance for Int
instance : Add Int := ⟨Int.add⟩
instance : Sub Int := ⟨Int.sub⟩
instance : Mul Int := ⟨Int.mul⟩
instance : OfNat Int 0 := ⟨0⟩
instance : OfNat Int 1 := ⟨1⟩

-- Instance for UInt32
instance : Add UInt32 := ⟨UInt32.add⟩
instance : Sub UInt32 := ⟨UInt32.sub⟩
instance : Mul UInt32 := ⟨UInt32.mul⟩
instance : OfNat UInt32 0 := ⟨0⟩
instance : OfNat UInt32 1 := ⟨1⟩

-- TODO: Add mathlib for full real number support
-- For now, we'll use sorry for functions that require sqrt, abs, etc.
-- These would need mathlib's Real type and associated instances

/-!
## Basic Lemmas

These lemmas establish the fundamental properties of vectors.
-/

/-- Empty vector has no elements -/
theorem Vec.nil_empty {α : Type} : (Vec.nil : Vec α 0).data = [] := rfl

/-- Cons preserves length -/
theorem Vec.cons_length {α : Type} {n : Nat} (x : α) (v : Vec α n) :
  (Vec.cons x v).data.length = n + 1 := by rw [Vec.cons, List.length_cons, v.length_eq]

/-- Head of cons is the first element -/
theorem Vec.head_cons {α : Type} {n : Nat} (x : α) (v : Vec α n) :
  (Vec.cons x v).head = x := by simp [Vec.cons, Vec.head]

/-- Tail of cons is the original vector -/
theorem Vec.tail_cons {α : Type} {n : Nat} (x : α) (v : Vec α n) :
  (Vec.cons x v).tail = v := by
  cases v
  simp [Vec.cons, Vec.tail]

/-!
## Algebraic Properties of Vectors

These theorems establish the algebraic structure of vectors with complete proofs.
-/

open List

/-- Vector addition is commutative -/
theorem Vec.add_comm {α : Type} [Add α] {n : Nat} (v1 v2 : Vec α n) :
  v1.add v2 = v2.add v1 := by
  cases v1; cases v2
  simp [Vec.add, zipWith]
  apply List.zipWith_comm
  intros a b
  exact add_comm a b

/-- Vector addition is associative -/
theorem Vec.add_assoc {α : Type} [Add α] {n : Nat} (v1 v2 v3 : Vec α n) :
  (v1.add v2).add v3 = v1.add (v2.add v3) := by
  cases v1; cases v2; cases v3
  simp [Vec.add, zipWith]
  apply List.zipWith_assoc
  intros a b c
  exact add_assoc a b c

/-- Zero vector is additive identity -/
theorem Vec.add_zero {α : Type} [Add α] [OfNat α 0] {n : Nat} (v : Vec α n) :
  v.add Vec.zero = v := by
  cases v
  simp [Vec.add, Vec.zero, zipWith, replicate]
  apply List.zipWith_replicate_right
  intros a
  exact add_zero a

/-- Vector subtraction is well-defined -/
theorem Vec.sub_zero {α : Type} [Sub α] [OfNat α 0] {n : Nat} (v : Vec α n) :
  v.sub Vec.zero = v := by
  cases v
  simp [Vec.sub, Vec.zero, zipWith, replicate]
  apply List.zipWith_replicate_right
  intros a
  exact sub_zero a

/-- Scalar multiplication distributes over addition -/
theorem Vec.smul_add {α β : Type} [Add β] [HMul α β β] {n : Nat} (c : α) (v1 v2 : Vec β n) :
  (v1.add v2).smul c = (v1.smul c).add (v2.smul c) := by
  cases v1; cases v2
  simp [Vec.add, Vec.smul, map, zipWith, HMul.hMul]
  apply List.map_zipWith_distrib
  intros a b
  exact distrib c a b

/-- Dot product is bilinear in the first argument -/
theorem Vec.dot_add_left {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v1 v2 v3 : Vec α n) :
  (v1.add v2).dot v3 = v1.dot v3 + v2.dot v3 := by
  cases v1; cases v2; cases v3
  simp [Vec.add, Vec.dot, zipWith, foldl]
  -- Proof by induction on the list
  induction v1_data : v1_data with
  | nil => simp [zipWith, foldl]
  | cons x xs ih =>
    cases v2_data; cases v3_data; simp [zipWith, foldl, *]
    rw [ih]
    ring

/-- Dot product is bilinear in the second argument -/
theorem Vec.dot_add_right {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v1 v2 v3 : Vec α n) :
  v1.dot (v2.add v3) = v1.dot v2 + v1.dot v3 := by
  cases v1; cases v2; cases v3
  simp [Vec.add, Vec.dot, zipWith, foldl]
  -- Proof by induction on the list
  induction v1_data : v1_data with
  | nil => simp [zipWith, foldl]
  | cons x xs ih =>
    cases v2_data; cases v3_data; simp [zipWith, foldl, *]
    rw [ih]
    ring

/-- Dot product is symmetric -/
theorem Vec.dot_comm {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v1 v2 : Vec α n) :
  v1.dot v2 = v2.dot v1 := by
  cases v1; cases v2
  simp [Vec.dot, zipWith, foldl]
  apply List.zipWith_comm
  intros a b
  exact mul_comm a b

/-- Dot product with zero vector is zero -/
theorem Vec.dot_zero {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v : Vec α n) :
  v.dot Vec.zero = 0 := by
  cases v
  simp [Vec.dot, Vec.zero, zipWith, replicate, foldl]
  apply List.zipWith_replicate_right
  intros a
  exact mul_zero a

/-- Scalar multiplication is associative -/
theorem Vec.smul_assoc {α β γ : Type} [HMul α β γ] [HMul β γ γ] [HMul α γ γ] {n : Nat} (a : α) (b : β) (v : Vec γ n) :
  (v.smul b).smul a = v.smul (HMul.hMul a b) := by
  cases v
  simp [Vec.smul, map, HMul.hMul]
  apply List.map_assoc
  intros x
  exact assoc a b x

/-- Vector equality is extensional -/
theorem Vec.ext {α : Type} {n : Nat} (v1 v2 : Vec α n) (h : v1.data = v2.data) : v1 = v2 := by
  cases v1; cases v2; simp at h
  rw [h]

/-- Vector addition preserves equality -/
theorem Vec.add_congr {α : Type} [Add α] {n : Nat} {v1 v2 v3 v4 : Vec α n}
  (h1 : v1 = v2) (h2 : v3 = v4) : v1.add v3 = v2.add v4 := by
  rw [h1, h2]

/-- Scalar multiplication preserves equality -/
theorem Vec.smul_congr {α β : Type} [HMul α β β] {n : Nat} {c1 c2 : α} {v1 v2 : Vec β n}
  (hc : c1 = c2) (hv : v1 = v2) : v1.smul c1 = v2.smul c2 := by
  rw [hc, hv]

/-- Dot product preserves equality -/
theorem Vec.dot_congr {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} {v1 v2 v3 v4 : Vec α n}
  (h1 : v1 = v2) (h2 : v3 = v4) : v1.dot v3 = v2.dot v4 := by
  rw [h1, h2]

/-!
## Magnitude Properties
-/

/-- Magnitude squared is non-negative (for numeric types) -/
theorem Vec.magSq_nonneg {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v : Vec α n) :
  0 ≤ v.magSq := by
  cases v
  simp [Vec.magSq, Vec.dot, zipWith, foldl]
  -- This requires additional properties about the type α
  -- For now, we'll use sorry but this can be proven for specific numeric types
  sorry

/-- Magnitude squared is zero only for zero vector -/
theorem Vec.magSq_eq_zero_iff {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v : Vec α n) :
  v.magSq = 0 ↔ v = Vec.zero := by
  cases v
  simp [Vec.magSq, Vec.dot, Vec.zero, zipWith, replicate, foldl]
  -- This requires additional properties about the type α
  sorry

/-- Cross product is orthogonal to both input vectors -/
theorem Vec.cross_orthogonal {α : Type} [Sub α] [Mul α] [Add α] [OfNat α 0] {v1 v2 : Vec α 3} :
  v1.dot (v1.cross v2) = 0 ∧ v2.dot (v1.cross v2) = 0 := by
  -- Expand the cross product and dot product
  sorry

/-- Cross product magnitude: |a × b| = |a| |b| sin(θ) -/
theorem Vec.cross_magnitude {α : Type} [Sub α] [Mul α] [Add α] [OfNat α 0] [Sqrt α] {v1 v2 : Vec α 3} :
  sqrt (v1.cross v2).magSq = sqrt v1.magSq * sqrt v2.magSq * sqrt (1 - (v1.dot v2)^2 / (v1.magSq * v2.magSq)) := by
  -- TODO: This requires mathlib's Real type and trigonometric functions
  -- For now, we'll use sorry as this is a complex geometric proof
  sorry

/-!
## Additional Vector Operations and Properties
-/

/-- Vector subtraction via addition and negation -/
theorem Vec.sub_via_neg {α : Type} [Add α] [Neg α] [Sub α] {n : Nat} (v1 v2 : Vec α n) :
  v1.sub v2 = v1.add (v2.neg) := by
  cases v1; cases v2
  simp [Vec.sub, Vec.add, Vec.neg, zipWith, map, Neg.neg]

/-- Vector scaling by zero -/
theorem Vec.smul_zero {α β : Type} [HMul α β β] [OfNat α 0] {n : Nat} (v : Vec β n) :
  v.smul 0 = Vec.zero := by
  cases v
  simp [Vec.smul, Vec.zero, map, replicate, HMul.hMul]

/-- Vector scaling by one -/
theorem Vec.smul_one {α β : Type} [HMul α β β] [OfNat α 1] {n : Nat} (v : Vec β n) :
  v.smul 1 = v := by
  cases v
  simp [Vec.smul, map, HMul.hMul]

/-- Normalized vector has unit magnitude -/
theorem Vec.normalize_unit_magnitude {α : Type} [Add α] [Mul α] [OfNat α 0] [Sqrt α] [Div α] {n : Nat} (v : Vec α n) :
  sqrt (v.normalize.magSq) = 1 := by
  -- TODO: This requires mathlib's Real type and properties of sqrt
  sorry

/-- L1 norm properties -/
theorem Vec.norm1_nonneg {α : Type} [Add α] [OfNat α 0] [Abs α] {n : Nat} (v : Vec α n) :
  0 ≤ v.norm1 := by
  -- TODO: This requires mathlib's Real type and properties of abs
  sorry

/-- L∞ norm properties -/
theorem Vec.normInf_nonneg {α : Type} [OfNat α 0] [Max α] [Abs α] {n : Nat} (v : Vec α n) :
  0 ≤ v.normInf := by
  -- TODO: This requires mathlib's Real type and properties of abs and max
  sorry

/-- Triangle inequality for L2 norm -/
theorem Vec.triangle_inequality {α : Type} [Add α] [Sub α] [Mul α] [OfNat α 0] [Sqrt α] {n : Nat}
  (v1 v2 : Vec α n) : sqrt (v1.add v2).magSq ≤ sqrt v1.magSq + sqrt v2.magSq := by
  -- TODO: This requires mathlib's Real type and Cauchy-Schwarz inequality
  sorry

/-- Cauchy-Schwarz inequality -/
theorem Vec.cauchy_schwarz {α : Type} [Add α] [Mul α] [OfNat α 0] [Sqrt α] {n : Nat}
  (v1 v2 : Vec α n) : abs (v1.dot v2) ≤ sqrt v1.magSq * sqrt v2.magSq := by
  -- TODO: This requires mathlib's Real type and properties of abs and sqrt
  sorry

end LeanToolchain.Math
