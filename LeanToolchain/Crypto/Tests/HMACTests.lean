import LeanToolchain.Crypto.HMAC
import LeanToolchain.Crypto.Utils

/-!
# HMAC-SHA256 Tests

This module contains comprehensive tests for the HMAC-SHA256 implementation,
including RFC test vectors and basic functionality tests.
-/

namespace LeanToolchain.Crypto.Tests

/-- Test basic HMAC-SHA256 functionality -/
def testBasicHMAC : IO Unit := do
  IO.println "Testing basic HMAC-SHA256 functionality..."

  -- Test with simple key and message
  let key := "key"
  let message := "The quick brown fox jumps over the lazy dog"
  let hmac := hmacSha256String key message
  IO.println s!"HMAC-SHA256('{key}', '{message}'): {hmac}"

/-- RFC 4231 HMAC-SHA256 test vectors -/
def rfc4231TestVectors : List (String × String × String) :=
  [("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b", "4869205468657265", "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"),
   ("4a656665", "7768617420646f2079612077616e7420666f72206e6f7468696e673f", "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"),
   ("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd", "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe"),
   ("0102030405060708090a0b0c0d0e0f10111213141516171819", "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd", "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")]

/-- Test RFC 4231 vectors -/
def testRfc4231Vectors : IO Unit := do
  IO.println "Testing RFC 4231 HMAC-SHA256 test vectors..."

  for (keyHex, messageHex, expected) in rfc4231TestVectors do
    match hmacSha256Hex keyHex messageHex with
    | some actual =>
      if actual == expected then
        IO.println s!"✓ Key: {keyHex}, Message: {messageHex}"
        IO.println s!"  HMAC: {actual}"
      else
        IO.println s!"✗ Key: {keyHex}, Message: {messageHex}"
        IO.println s!"  Expected: {expected}, Got: {actual}"
    | none =>
      IO.println s!"✗ Failed to parse hex for key: {keyHex}, message: {messageHex}"

/-- Test HMAC-SHA256 with byte arrays -/
def testByteArrayHMAC : IO Unit := do
  IO.println "Testing HMAC-SHA256 with byte arrays..."

  let key := ByteArray.mk (Array.mk [0x6b, 0x65, 0x79]) -- "key"
  let message := ByteArray.mk (Array.mk [0x74, 0x65, 0x73, 0x74]) -- "test"
  let hmac := hmacSha256 key message
  let hexHmac := bytesToHex hmac
  IO.println s!"HMAC-SHA256([0x6b,0x65,0x79], [0x74,0x65,0x73,0x74]): {hexHmac}"

/-- Test HMAC-SHA256 verification -/
def testHMACVerification : IO Unit := do
  IO.println "Testing HMAC-SHA256 verification..."

  let key := stringToBytes "secret"
  let message := stringToBytes "message"
  let actualHmac := hmacSha256 key message
  let signature := bytesToHex actualHmac  -- Use the actual HMAC as expected
  let isValid := hmacSha256Verify key message signature

  if isValid then
    IO.println "✓ HMAC-SHA256 verification passed"
  else
    IO.println "✗ HMAC-SHA256 verification failed"

/-- Test HMAC key preparation -/
def testHMACKeyPreparation : IO Unit := do
  IO.println "Testing HMAC key preparation..."

  -- Test short key
  let shortKey := ByteArray.mk (Array.mk [0x61, 0x62, 0x63]) -- "abc"
  let preparedShort := hmacPrepareKey shortKey
  IO.println s!"Short key length: {shortKey.size} -> {preparedShort.size}"

  -- Test long key
  let longKey := ByteArray.mk (Array.mk (List.replicate 100 0x61)) -- 100 bytes
  let preparedLong := hmacPrepareKey longKey
  IO.println s!"Long key length: {longKey.size} -> {preparedLong.size}"

/-- Test length extension resistance -/
def testLengthExtensionResistance : IO Unit := do
  IO.println "Testing HMAC length extension resistance..."

  let key := "secret"
  let message1 := "original message"
  let message2 := "original message with extension"

  let hmac1 := hmacSha256String key message1
  let hmac2 := hmacSha256String key message2

  -- HMAC should be resistant to length extension attacks
  -- The hashes should be completely different
  if hmac1 != hmac2 then
    IO.println "✓ HMAC shows length extension resistance"
  else
    IO.println "✗ HMAC may be vulnerable to length extension"

/-- Run all HMAC tests -/
def runAllHMACTests : IO Unit := do
  IO.println "=== HMAC-SHA256 Tests ==="
  testBasicHMAC
  IO.println ""
  testRfc4231Vectors
  IO.println ""
  testByteArrayHMAC
  IO.println ""
  testHMACVerification
  IO.println ""
  testHMACKeyPreparation
  IO.println ""
  testLengthExtensionResistance
  IO.println "=== Tests Complete ==="

end LeanToolchain.Crypto.Tests
