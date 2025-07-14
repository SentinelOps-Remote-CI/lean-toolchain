import LeanToolchain.Crypto.SHA256
import LeanToolchain.Crypto.HMAC
import LeanToolchain.Math.Vector
import LeanToolchain.Math.Matrix
import Init.System.IO
import Init.System.Time

/-!
# Lean Toolchain Benchmarks

This module provides performance benchmarks for the Lean implementations.
It measures execution time and provides performance comparisons.
-/

namespace LeanToolchain.Benchmarks

/-- Benchmark configuration -/
structure BenchmarkConfig where
  iterations : Nat := 1000
  warmupIterations : Nat := 100
  reportDetailed : Bool := true

/-- Time measurement result -/
structure BenchmarkResult where
  operation : String
  iterations : Nat
  totalTime : Float
  averageTime : Float
  throughput : Float -- operations per second

/-- Measure execution time of a function -/
def measureTime {α : Type} (f : Unit → α) (iterations : Nat) : IO Float := do
  let startTime ← IO.monoMsNow
  for _ in List.range iterations do
    let _ := f ()
  let endTime ← IO.monoMsNow
  return (endTime - startTime).toFloat

/-- Run benchmark for a function -/
def runBenchmark (name : String) (f : Unit → Unit) (config : BenchmarkConfig) : IO BenchmarkResult := do
  IO.println s!"Running benchmark: {name}"

  -- Warmup
  for _ in List.range config.warmupIterations do
    f ()

  -- Actual measurement
  let totalTime ← measureTime (fun _ => f ()) config.iterations
  let averageTime := totalTime / config.iterations.toFloat
  let throughput := 1000.0 / averageTime -- ops per second

  let result := BenchmarkResult.mk name config.iterations totalTime averageTime throughput

  if config.reportDetailed then
    IO.println s!"  Total time: {totalTime:.2f}ms"
    IO.println s!"  Average time: {averageTime:.4f}ms"
    IO.println s!"  Throughput: {throughput:.0f} ops/sec"

  return result

/-- Benchmark SHA-256 operations -/
def benchmarkSHA256 (config : BenchmarkConfig) : IO (List BenchmarkResult) := do
  IO.println "=== SHA-256 Benchmarks ==="

  let results : List BenchmarkResult := []

  -- Empty string
  let emptyResult ← runBenchmark "SHA-256 (empty)"
    (fun _ => let _ := sha256String "") config
  let results := results ++ [emptyResult]

  -- Short string
  let shortResult ← runBenchmark "SHA-256 (short)"
    (fun _ => let _ := sha256String "abc") config
  let results := results ++ [shortResult]

  -- Medium string
  let mediumResult ← runBenchmark "SHA-256 (medium)"
    (fun _ => let _ := sha256String "The quick brown fox jumps over the lazy dog") config
  let results := results ++ [mediumResult]

  -- Long string
  let longString := String.mk (List.replicate 1000 'a')
  let longResult ← runBenchmark "SHA-256 (long)"
    (fun _ => let _ := sha256String longString) config
  let results := results ++ [longResult]

  return results

/-- Benchmark HMAC operations -/
def benchmarkHMAC (config : BenchmarkConfig) : IO (List BenchmarkResult) := do
  IO.println "=== HMAC-SHA256 Benchmarks ==="

  let results : List BenchmarkResult := []

  -- Short key and message
  let shortResult ← runBenchmark "HMAC-SHA256 (short)"
    (fun _ => let _ := hmacSha256String "key" "message") config
  let results := results ++ [shortResult]

  -- Medium key and message
  let mediumResult ← runBenchmark "HMAC-SHA256 (medium)"
    (fun _ => let _ := hmacSha256String "secret_key" "The quick brown fox jumps over the lazy dog") config
  let results := results ++ [mediumResult]

  -- Long key and message
  let longKey := String.mk (List.replicate 100 'k')
  let longMessage := String.mk (List.replicate 1000 'm')
  let longResult ← runBenchmark "HMAC-SHA256 (long)"
    (fun _ => let _ := hmacSha256String longKey longMessage) config
  let results := results ++ [longResult]

  return results

/-- Benchmark Vector operations -/
def benchmarkVector (config : BenchmarkConfig) : IO (List BenchmarkResult) := do
  IO.println "=== Vector Benchmarks ==="

  let results : List BenchmarkResult := []

  -- Create test vectors
  let v1 : Vec Nat 100 := Vec.fromList (List.range 100) 100 (by simp)
  let v2 : Vec Nat 100 := Vec.fromList (List.range 100 200) 100 (by simp)

  -- Vector addition
  let addResult ← runBenchmark "Vector Addition (100 elements)"
    (fun _ => let _ := v1.add v2) config
  let results := results ++ [addResult]

  -- Vector dot product
  let dotResult ← runBenchmark "Vector Dot Product (100 elements)"
    (fun _ => let _ := v1.dot v2) config
  let results := results ++ [dotResult]

  -- Vector scalar multiplication
  let smulResult ← runBenchmark "Vector Scalar Multiplication (100 elements)"
    (fun _ => let _ := v1.smul 2) config
  let results := results ++ [smulResult]

  return results

/-- Benchmark Matrix operations -/
def benchmarkMatrix (config : BenchmarkConfig) : IO (List BenchmarkResult) := do
  IO.println "=== Matrix Benchmarks ==="

  let results : List BenchmarkResult := []

  -- Create test matrices (simplified for now)
  let mat1 : Matrix Nat 10 10 := Matrix.zero
  let mat2 : Matrix Nat 10 10 := Matrix.zero

  -- Matrix addition
  let addResult ← runBenchmark "Matrix Addition (10x10)"
    (fun _ => let _ := mat1.add mat2) config
  let results := results ++ [addResult]

  -- Matrix scalar multiplication
  let smulResult ← runBenchmark "Matrix Scalar Multiplication (10x10)"
    (fun _ => let _ := mat1.smul 2) config
  let results := results ++ [smulResult]

  -- Matrix transpose
  let transposeResult ← runBenchmark "Matrix Transpose (10x10)"
    (fun _ => let _ := mat1.transpose) config
  let results := results ++ [transposeResult]

  return results

/-- Generate benchmark report -/
def generateReport (results : List BenchmarkResult) : String :=
  let header := "Benchmark Report\n" ++ "================\n\n"

  let tableHeader := "Operation | Iterations | Total Time (ms) | Avg Time (ms) | Throughput (ops/sec)\n"
  let separator := "----------|------------|-----------------|---------------|----------------------\n"

  let rows := results.map (fun r =>
    s!"{r.operation} | {r.iterations} | {r.totalTime:.2f} | {r.averageTime:.4f} | {r.throughput:.0f}")

  let table := String.intercalate "\n" (tableHeader :: separator :: rows)

  header ++ table

/-- Run all benchmarks -/
def runAllBenchmarks (config : BenchmarkConfig) : IO Unit := do
  IO.println "Starting Lean Toolchain Benchmarks"
  IO.println "=================================="
  IO.println ""

  let allResults : List BenchmarkResult := []

  -- Run all benchmark suites
  let sha256Results ← benchmarkSHA256 config
  let hmacResults ← benchmarkHMAC config
  let vectorResults ← benchmarkVector config
  let matrixResults ← benchmarkMatrix config

  let allResults := allResults ++ sha256Results ++ hmacResults ++ vectorResults ++ matrixResults

  IO.println ""
  IO.println "=== Summary Report ==="
  IO.println (generateReport allResults)

  -- Find fastest and slowest operations
  let sortedResults := allResults.qsort (fun a b => a.averageTime < b.averageTime)

  match sortedResults with
  | [] => IO.println "No benchmark results"
  | fastest :: _ =>
    IO.println s!"\nFastest operation: {fastest.operation} ({fastest.averageTime:.4f}ms avg)"
  | _ =>
    let slowest := sortedResults.getLast!
    IO.println s!"\nSlowest operation: {slowest.operation} ({slowest.averageTime:.4f}ms avg)"

/-- Main entry point -/
def main : IO Unit := do
  let config := BenchmarkConfig.mk
  runAllBenchmarks config
