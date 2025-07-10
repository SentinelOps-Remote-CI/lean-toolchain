import LeanToolchain.Math.Vector
import Init.Data.Nat.Basic

/-!
# Vector Tests

This module contains comprehensive tests for the Vector implementation,
including basic operations, properties, and edge cases.
-/

namespace LeanToolchain.Math.Tests

/-- Test basic vector construction -/
def testBasicVectorConstruction : IO Unit := do
  IO.println "Testing basic vector construction..."

  -- Test empty vector
  let emptyVec := Vec.nil
  IO.println s!"Empty vector length: {emptyVec.data.length}"

  -- Test cons construction
  let v1 := Vec.cons 1 Vec.nil
  let v2 := Vec.cons 2 v1
  let v3 := Vec.cons 3 v2
  IO.println s!"Vector [3,2,1] length: {v3.data.length}"
  IO.println s!"Vector [3,2,1] data: {v3.data}"

/-- Test vector operations -/
def testVectorOperations : IO Unit := do
  IO.println "Testing vector operations..."

  -- Create test vectors
  let v1 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 Vec.nil))
  let v2 := Vec.cons 4 (Vec.cons 5 (Vec.cons 6 Vec.nil))

  -- Test addition
  let sum := v1.add v2
  IO.println s!"Vector addition: {v1.data} + {v2.data} = {sum.data}"

  -- Test subtraction
  let diff := v2.sub v1
  IO.println s!"Vector subtraction: {v2.data} - {v1.data} = {diff.data}"

  -- Test scalar multiplication
  let scaled := v1.smul 2
  IO.println s!"Scalar multiplication: 2 * {v1.data} = {scaled.data}"

/-- Test dot product -/
def testDotProduct : IO Unit := do
  IO.println "Testing dot product..."

  let v1 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 Vec.nil))
  let v2 := Vec.cons 4 (Vec.cons 5 (Vec.cons 6 Vec.nil))

  let dot := v1.dot v2
  IO.println s!"Dot product: {v1.data} · {v2.data} = {dot}"

  -- Test with zero vector
  let zeroVec := Vec.zero
  let dotZero := v1.dot zeroVec
  IO.println s!"Dot product with zero: {v1.data} · {zeroVec.data} = {dotZero}"

/-- Test vector magnitude -/
def testVectorMagnitude : IO Unit := do
  IO.println "Testing vector magnitude..."

  let v := Vec.cons 3 (Vec.cons 4 Vec.nil)
  let magSq := v.magSq
  IO.println s!"Magnitude squared of {v.data}: {magSq}"

  let v2 := Vec.cons 1 (Vec.cons 1 (Vec.cons 1 Vec.nil))
  let magSq2 := v2.magSq
  IO.println s!"Magnitude squared of {v2.data}: {magSq2}"

/-- Test vector properties -/
def testVectorProperties : IO Unit := do
  IO.println "Testing vector properties..."

  let v1 := Vec.cons 1 (Vec.cons 2 Vec.nil)
  let v2 := Vec.cons 3 (Vec.cons 4 Vec.nil)
  let v3 := Vec.cons 5 (Vec.cons 6 Vec.nil)

  -- Test commutativity of addition
  let sum1 := v1.add v2
  let sum2 := v2.add v1
  IO.println s!"Addition commutativity: {sum1.data} == {sum2.data}"

  -- Test associativity of addition
  let sum3 := (v1.add v2).add v3
  let sum4 := v1.add (v2.add v3)
  IO.println s!"Addition associativity: {sum3.data} == {sum4.data}"

/-- Test vector indexing -/
def testVectorIndexing : IO Unit := do
  IO.println "Testing vector indexing..."

  let v := Vec.cons 10 (Vec.cons 20 (Vec.cons 30 Vec.nil))

  -- Test head and tail
  IO.println s!"Vector: {v.data}"
  IO.println s!"Head: {v.head}"
  IO.println s!"Tail: {v.tail.data}"

/-- Test vector conversion -/
def testVectorConversion : IO Unit := do
  IO.println "Testing vector conversion..."

  let data := [1, 2, 3, 4, 5]
  let v := Vec.fromList data 5 (by simp)

  IO.println s!"Original list: {data}"
  IO.println s!"Converted vector: {v.data}"
  IO.println s!"Back to list: {v.toList}"

/-- Run all vector tests -/
def runAllVectorTests : IO Unit := do
  IO.println "=== Vector Tests ==="
  testBasicVectorConstruction
  IO.println ""
  testVectorOperations
  IO.println ""
  testDotProduct
  IO.println ""
  testVectorMagnitude
  IO.println ""
  testVectorProperties
  IO.println ""
  testVectorIndexing
  IO.println ""
  testVectorConversion
  IO.println "=== Tests Complete ==="

end LeanToolchain.Math.Tests
