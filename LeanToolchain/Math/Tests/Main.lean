import LeanToolchain.Math.Tests.VectorTests
import LeanToolchain.Math.Tests.MatrixTests
import LeanToolchain.Math.Tests.NormTests

/-!
# Math Tests Main Runner

This module runs all mathematical tests including vectors, matrices, and norms.
-/

def main : IO Unit := do
  IO.println "Running Lean Toolchain Math Tests"
  IO.println "================================="
  IO.println ""

  -- Run vector tests
  LeanToolchain.Math.Tests.runAllVectorTests
  IO.println ""

  -- Run matrix tests
  LeanToolchain.Math.Tests.runAllMatrixTests
  IO.println ""

  -- Run norm tests
  LeanToolchain.Math.Tests.runAllNormTests
  IO.println ""

  IO.println "All math tests completed!"
