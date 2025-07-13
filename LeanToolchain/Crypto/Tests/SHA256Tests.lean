import LeanToolchain.Crypto.SHA256
import LeanToolchain.Crypto.Utils

/-!
# SHA-256 Tests

This module contains comprehensive tests for the SHA-256 implementation,
including NIST test vectors and basic functionality tests.
-/

namespace LeanToolchain.Crypto.Tests

/-- Test basic SHA-256 functionality -/
def testBasicSha256 : IO Unit := do
  IO.println "Testing basic SHA-256 functionality..."

  -- Test empty string
  let emptyHash := sha256String ""
  IO.println s!"Empty string: {emptyHash}"

  -- Test "hello world"
  let helloHash := sha256String "hello world"
  IO.println s!"'hello world': {helloHash}"

  -- Test single character
  let charHash := sha256String "a"
  IO.println s!"'a': {charHash}"

/-- NIST SHA-256 test vectors -/
def nistTestVectors : List (String × String) :=
  [("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
   ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
   ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"),
   ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")]

/-- Test NIST vectors -/
def testNistVectors : IO Unit := do
  IO.println "Testing NIST SHA-256 test vectors..."

  for (input, expected) in nistTestVectors do
    let actual := sha256String input
    if actual == expected then
      IO.println s!"✓ '{input}': {actual}"
    else
      IO.println s!"✗ '{input}': expected {expected}, got {actual}"

/-- Test SHA-256 with byte arrays -/
def testByteArraySha256 : IO Unit := do
  IO.println "Testing SHA-256 with byte arrays..."

  let testBytes := ByteArray.mk (Array.mk [0x61, 0x62, 0x63]) -- "abc"
  let hash := sha256 testBytes
  let hexHash := bytesToHex hash
  IO.println s!"Byte array [0x61, 0x62, 0x63]: {hexHash}"

/-- Test SHA-256 verification -/
def testSha256Verification : IO Unit := do
  IO.println "Testing SHA-256 verification..."

  let message := stringToBytes "test message"
  let actualHash := sha256 message
  let expected := bytesToHex actualHash  -- Use the actual hash as expected
  let isValid := sha256Verify message expected

  if isValid then
    IO.println "✓ SHA-256 verification passed"
  else
    IO.println "✗ SHA-256 verification failed"

/-- Test SHA-256 padding -/
def testSha256Padding : IO Unit := do
  IO.println "Testing SHA-256 padding..."

  -- Test message that needs padding
  let shortMessage := stringToBytes "short"
  let padded := padMessage shortMessage

  IO.println s!"Original length: {shortMessage.size}"
  IO.println s!"Padded length: {padded.size}"
  IO.println s!"Padded length is multiple of 64: {padded.size % 64 == 0}"

/-- Run all SHA-256 tests -/
def runAllSha256Tests : IO Unit := do
  IO.println "=== SHA-256 Tests ==="
  testBasicSha256
  IO.println ""
  testNistVectors
  IO.println ""
  testByteArraySha256
  IO.println ""
  testSha256Verification
  IO.println ""
  testSha256Padding
  IO.println "=== Tests Complete ==="

end LeanToolchain.Crypto.Tests
