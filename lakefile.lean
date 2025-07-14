import Lake
open Lake DSL

-- TODO: Add mathlib back when we need real numbers
-- require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.1.0"

package leanToolchain

@[default_target]
lean_lib LeanToolchain

lean_exe leanToolchain {
  root := `Main
}

lean_exe cryptoTests {
  root := `LeanToolchain.Crypto.Tests.Main
}

lean_exe mathTests {
  root := `LeanToolchain.Math.Tests.Main
}

-- Rust extraction targets
lean_exe extract {
  root := `LeanToolchain.Extraction.Main
}

lean_exe benchmarks {
  root := `LeanToolchain.Benchmarks.Main
}
