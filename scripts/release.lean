import Init.System.IO
import Init.System.Process
import Init.Data.String.Basic

/-!
# Release Automation Script

This script automates the release process for Lean Toolchain, including:
- Version management
- Building and testing
- Documentation generation
- Release artifact creation
- Git tagging and pushing
-/

namespace LeanToolchain.Release

/-- Release configuration -/
structure ReleaseConfig where
  version : String
  dryRun : Bool := false
  skipTests : Bool := false
  skipDocs : Bool := false
  skipExtraction : Bool := false

/-- Release step result -/
inductive ReleaseStep where
  | success (message : String)
  | failure (message : String)
  | skipped (message : String)

/-- Run a command and return the result -/
def runCommand (cmd : String) (args : List String) : IO (ReleaseStep × String) := do
  IO.println s!"Running: {cmd} {String.intercalate " " args}"

  let output ← IO.Process.output {
    cmd := cmd
    args := args
  }

  if output.exitCode = 0 then
    return (ReleaseStep.success s!"Command succeeded: {cmd}", output.stdout)
  else
    return (ReleaseStep.failure s!"Command failed: {cmd} (exit code: {output.exitCode})", output.stderr)

/-- Check if git repository is clean -/
def checkGitStatus : IO ReleaseStep := do
  let (result, output) ← runCommand "git" ["status", "--porcelain"]

  match result with
  | ReleaseStep.success _ =>
    if output.trim.isEmpty then
      return ReleaseStep.success "Git repository is clean"
    else
      return ReleaseStep.failure "Git repository has uncommitted changes"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Update version in files -/
def updateVersion (config : ReleaseConfig) : IO ReleaseStep := do
  IO.println s!"Updating version to {config.version}"

  -- Update lakefile.lean
  let lakefileContent ← IO.FS.readFile "lakefile.lean"
  let updatedLakefile := lakefileContent.replace "version = \"0.1.0\"" s!"version = \"{config.version}\""
  IO.FS.writeFile "lakefile.lean" updatedLakefile

  -- Update lakefile.toml
  let tomlContent ← IO.FS.readFile "lakefile.toml"
  let updatedToml := tomlContent.replace "version = \"0.1.0\"" s!"version = \"{config.version}\""
  IO.FS.writeFile "lakefile.toml" updatedToml

  -- Update README.md
  let readmeContent ← IO.FS.readFile "README.md"
  let updatedReadme := readmeContent.replace "version: 0.1.0" s!"version: {config.version}"
  IO.FS.writeFile "README.md" updatedReadme

  return ReleaseStep.success s!"Updated version to {config.version}"

/-- Run tests -/
def runTests (config : ReleaseConfig) : IO ReleaseStep := do
  if config.skipTests then
    return ReleaseStep.skipped "Tests skipped by configuration"

  IO.println "Running tests..."

  -- Run Lean tests
  let (leanResult, leanOutput) ← runCommand "lake" ["test"]
  if leanResult matches ReleaseStep.failure _ then
    return leanResult

  -- Run crypto tests
  let (cryptoResult, cryptoOutput) ← runCommand "lake" ["exe", "cryptoTests"]
  if cryptoResult matches ReleaseStep.failure _ then
    return cryptoResult

  -- Run math tests
  let (mathResult, mathOutput) ← runCommand "lake" ["exe", "mathTests"]
  if mathResult matches ReleaseStep.failure _ then
    return mathResult

  IO.println "All tests passed"
  return ReleaseStep.success "All tests passed"

/-- Build the project -/
def buildProject (config : ReleaseConfig) : IO ReleaseStep := do
  IO.println "Building project..."

  let (result, output) ← runCommand "lake" ["build"]

  match result with
  | ReleaseStep.success _ =>
    IO.println "Build successful"
    return ReleaseStep.success "Build successful"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Generate documentation -/
def generateDocs (config : ReleaseConfig) : IO ReleaseStep := do
  if config.skipDocs then
    return ReleaseStep.skipped "Documentation generation skipped by configuration"

  IO.println "Generating documentation..."

  -- Build documentation
  let (result, output) ← runCommand "lake" ["exe", "leanToolchain"]

  match result with
  | ReleaseStep.success _ =>
    IO.println "Documentation generated successfully"
    return ReleaseStep.success "Documentation generated successfully"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Run extraction -/
def runExtraction (config : ReleaseConfig) : IO ReleaseStep := do
  if config.skipExtraction then
    return ReleaseStep.skipped "Extraction skipped by configuration"

  IO.println "Running extraction..."

  let (result, output) ← runCommand "lake" ["exe", "extract"]

  match result with
  | ReleaseStep.success _ =>
    IO.println "Extraction completed successfully"
    return ReleaseStep.success "Extraction completed successfully"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Run benchmarks -/
def runBenchmarks (config : ReleaseConfig) : IO ReleaseStep := do
  IO.println "Running benchmarks..."

  let (result, output) ← runCommand "lake" ["exe", "benchmarks"]

  match result with
  | ReleaseStep.success _ =>
    IO.println "Benchmarks completed successfully"
    return ReleaseStep.success "Benchmarks completed successfully"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Create release artifacts -/
def createArtifacts (config : ReleaseConfig) : IO ReleaseStep := do
  IO.println "Creating release artifacts..."

  -- Create release directory
  let releaseDir := s!"release-{config.version}"
  IO.FS.createDirAll releaseDir

  -- Copy built artifacts
  let (copyResult, copyOutput) ← runCommand "cp" ["-r", ".lake/build", releaseDir]
  if copyResult matches ReleaseStep.failure _ then
    return copyResult

  -- Copy documentation
  let (docResult, docOutput) ← runCommand "cp" ["-r", "docs", releaseDir]
  if docResult matches ReleaseStep.failure _ then
    return docResult

  -- Copy Rust extraction
  if ¬config.skipExtraction then
    let (rustResult, rustOutput) ← runCommand "cp" ["-r", "rust", releaseDir]
    if rustResult matches ReleaseStep.failure _ then
      return rustResult

  -- Create release notes
  let releaseNotes := s!"# Lean Toolchain {config.version}\n\n## Changes\n\n- Add your changes here\n\n## Installation\n\n```bash\nlake build\n```\n\n## Usage\n\nSee the documentation in the `docs/` directory.\n"
  IO.FS.writeFile (releaseDir ++ "/RELEASE_NOTES.md") releaseNotes

  IO.println s!"Release artifacts created in {releaseDir}"
  return ReleaseStep.success s!"Release artifacts created in {releaseDir}"

/-- Commit changes -/
def commitChanges (config : ReleaseConfig) : IO ReleaseStep := do
  if config.dryRun then
    return ReleaseStep.skipped "Dry run: skipping commit"

  IO.println "Committing changes..."

  -- Add all changes
  let (addResult, addOutput) ← runCommand "git" ["add", "."]
  if addResult matches ReleaseStep.failure _ then
    return addResult

  -- Commit
  let (commitResult, commitOutput) ← runCommand "git" ["commit", "-m", s!"Release version {config.version}"]
  if commitResult matches ReleaseStep.failure _ then
    return commitResult

  return ReleaseStep.success "Changes committed"

/-- Create and push tag -/
def createTag (config : ReleaseConfig) : IO ReleaseStep := do
  if config.dryRun then
    return ReleaseStep.skipped "Dry run: skipping tag creation"

  IO.println s!"Creating tag v{config.version}..."

  -- Create tag
  let (tagResult, tagOutput) ← runCommand "git" ["tag", s!"v{config.version}"]
  if tagResult matches ReleaseStep.failure _ then
    return tagResult

  -- Push tag
  let (pushResult, pushOutput) ← runCommand "git" ["push", "origin", s!"v{config.version}"]
  if pushResult matches ReleaseStep.failure _ then
    return pushResult

  return ReleaseStep.success s!"Tag v{config.version} created and pushed"

/-- Push changes -/
def pushChanges (config : ReleaseConfig) : IO ReleaseStep := do
  if config.dryRun then
    return ReleaseStep.skipped "Dry run: skipping push"

  IO.println "Pushing changes..."

  let (result, output) ← runCommand "git" ["push", "origin", "main"]

  match result with
  | ReleaseStep.success _ =>
    return ReleaseStep.success "Changes pushed successfully"
  | ReleaseStep.failure msg => return ReleaseStep.failure msg
  | ReleaseStep.skipped msg => return ReleaseStep.skipped msg

/-- Main release process -/
def runRelease (config : ReleaseConfig) : IO Unit := do
  IO.println "Starting Lean Toolchain release process"
  IO.println "======================================="
  IO.println s!"Version: {config.version}"
  IO.println s!"Dry run: {config.dryRun}"
  IO.println s!"Skip tests: {config.skipTests}"
  IO.println s!"Skip docs: {config.skipDocs}"
  IO.println s!"Skip extraction: {config.skipExtraction}"
  IO.println ""

  let steps := [
    ("Check git status", checkGitStatus),
    ("Update version", fun _ => updateVersion config),
    ("Run tests", fun _ => runTests config),
    ("Build project", fun _ => buildProject config),
    ("Generate docs", fun _ => generateDocs config),
    ("Run extraction", fun _ => runExtraction config),
    ("Run benchmarks", fun _ => runBenchmarks config),
    ("Create artifacts", fun _ => createArtifacts config),
    ("Commit changes", fun _ => commitChanges config),
    ("Create tag", fun _ => createTag config),
    ("Push changes", fun _ => pushChanges config)
  ]

  for (stepName, stepFn) in steps do
    IO.println s!"Step: {stepName}"
    let result ← stepFn ()

    match result with
    | ReleaseStep.success msg =>
      IO.println s!"✓ {stepName}: {msg}"
    | ReleaseStep.failure msg =>
      IO.println s!"✗ {stepName}: {msg}"
      IO.println "Release failed. Stopping."
      return
    | ReleaseStep.skipped msg =>
      IO.println s!"- {stepName}: {msg}"

    IO.println ""

  IO.println "Release completed successfully!"
  IO.println s!"Version {config.version} has been released."

/-- Parse command line arguments -/
def parseArgs (args : List String) : Option ReleaseConfig :=
  match args with
  | [] => none
  | version :: rest =>
    let config := ReleaseConfig.mk version
    let config := if rest.contains "--dry-run" then { config with dryRun := true } else config
    let config := if rest.contains "--skip-tests" then { config with skipTests := true } else config
    let config := if rest.contains "--skip-docs" then { config with skipDocs := true } else config
    let config := if rest.contains "--skip-extraction" then { config with skipExtraction := true } else config
    some config

/-- Print usage information -/
def printUsage : IO Unit := do
  IO.println "Usage: lake exe release <version> [options]"
  IO.println ""
  IO.println "Options:"
  IO.println "  --dry-run           Don't actually commit or push changes"
  IO.println "  --skip-tests        Skip running tests"
  IO.println "  --skip-docs         Skip generating documentation"
  IO.println "  --skip-extraction   Skip running extraction"
  IO.println ""
  IO.println "Examples:"
  IO.println "  lake exe release 1.0.0"
  IO.println "  lake exe release 1.0.0 --dry-run"
  IO.println "  lake exe release 1.0.0 --skip-tests --skip-docs"

/-- Main entry point -/
def main (args : List String) : IO Unit := do
  match parseArgs args with
  | none => printUsage
  | some config => runRelease config
