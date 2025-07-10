import LeanToolchain.Crypto.Tests.SHA256Tests
import LeanToolchain.Crypto.Tests.HMACTests

/-!
# Cryptographic Tests Main Runner

This module runs all cryptographic tests including SHA-256 and HMAC-SHA256.
-/

def main : IO Unit := do
  IO.println "Running Lean Toolchain Cryptographic Tests"
  IO.println "=========================================="
  IO.println ""

  -- Run SHA-256 tests
  LeanToolchain.Crypto.Tests.runAllSha256Tests
  IO.println ""

  -- Run HMAC tests
  LeanToolchain.Crypto.Tests.runAllHMACTests
  IO.println ""

  IO.println "All tests completed!"
