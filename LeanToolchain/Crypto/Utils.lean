import Init.Data.ByteArray
import Init.Data.Nat.Bitwise
import Init.Data.List.Basic
import Init.Data.UInt

/-!
# Cryptographic Utilities

This module provides utility functions for cryptographic operations including
byte arrays, bit operations, and conversions.
-/

namespace LeanToolchain.Crypto

/-- Convert a string to a ByteArray -/
def stringToBytes (s : String) : ByteArray :=
  s.toUTF8

/-- Convert a single byte to hex string -/
def byteToHex (b : UInt8) : String :=
  let high := (b >>> 4).toUInt32.toNat
  let low := (b &&& 0xF).toUInt32.toNat
  let highChar := if high < 10 then Char.ofNat (high + 48) else Char.ofNat (high + 87)
  let lowChar := if low < 10 then Char.ofNat (low + 48) else Char.ofNat (low + 87)
  String.mk [highChar, lowChar]

/-- Convert a ByteArray to a hex string -/
def bytesToHex (bytes : ByteArray) : String :=
  let rec aux (acc : String) (i : Nat) : String :=
    if i >= bytes.size then acc
    else aux (acc ++ byteToHex bytes[i]!) (i + 1)
  aux "" 0

/-- Convert a hex character to its numeric value -/
def hexCharToNat (c : Char) : Option Nat :=
  let n := c.toNat
  if n >= 48 && n <= 57 then some (n - 48)  -- '0' to '9'
  else if n >= 97 && n <= 102 then some (n - 97 + 10)  -- 'a' to 'f'
  else if n >= 65 && n <= 70 then some (n - 65 + 10)   -- 'A' to 'F'
  else none

/-- Convert a hex string to a ByteArray -/
def hexToBytes (hex : String) : Option ByteArray :=
  let hex := hex.trim
  let chars := hex.toList
  if chars.length % 2 != 0 then none
  else
    let rec aux (acc : List UInt8) (cs : List Char) : Option (List UInt8) :=
      match cs with
      | [] => some acc.reverse
      | c1 :: c2 :: rest =>
        match hexCharToNat c1, hexCharToNat c2 with
        | some high, some low =>
          let byte := (high.toUInt8 <<< 4) ||| low.toUInt8
          aux (byte :: acc) rest
        | _, _ => none
      | _ => none -- Odd number of chars (should not happen)
    match aux [] chars with
    | some bytes => some (ByteArray.mk (Array.mk bytes))
    | none => none

/-- Right rotate a 32-bit word by n bits -/
def rotateRight32 (x : UInt32) (n : Nat) : UInt32 :=
  let n := n % 32
  (x >>> (n : UInt32)) ||| (x <<< ((32 - n) : UInt32))

/-- Right shift a 32-bit word by n bits -/
def shiftRight32 (x : UInt32) (n : Nat) : UInt32 :=
  x >>> (n : UInt32)

/-- Convert a list of UInt8 to a list of UInt32 (big-endian) -/
def bytesToWords (bytes : List UInt8) : List UInt32 :=
  let rec aux (acc : List UInt32) (bs : List UInt8) : List UInt32 :=
    match bs with
    | [] => acc.reverse
    | [b1] => ((b1.toUInt32 <<< 24) :: acc).reverse
    | [b1, b2] => (((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16)) :: acc).reverse
    | [b1, b2, b3] => (((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16) ||| (b3.toUInt32 <<< 8)) :: acc).reverse
    | b1 :: b2 :: b3 :: b4 :: rest =>
      let word := (b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16) ||| (b3.toUInt32 <<< 8) ||| b4.toUInt32
      aux (word :: acc) rest
  aux [] bytes

/-- Convert a list of UInt32 to a list of UInt8 (big-endian) -/
def wordsToBytes (words : List UInt32) : List UInt8 :=
  let rec aux (acc : List UInt8) (ws : List UInt32) : List UInt8 :=
    match ws with
    | [] => acc
    | word :: rest =>
      let bytes := [(word >>> 24).toUInt8, (word >>> 16).toUInt8, (word >>> 8).toUInt8, word.toUInt8]
      aux (acc ++ bytes) rest
  aux [] words

/-- Create a list of n repeated elements -/
def replicate (n : Nat) (x : UInt8) : Array UInt8 :=
  let rec aux (acc : Array UInt8) (i : Nat) : Array UInt8 :=
    if i >= n then acc else aux (acc.push x) (i + 1)
  aux Array.empty 0

/-- Pad a message to a multiple of 512 bits (64 bytes) -/
def padMessage (message : ByteArray) : ByteArray :=
  let messageLength := message.size
  let messageLengthBits := messageLength * 8

  -- Calculate padding length: we need (messageLength + 1 + paddingLength + 8) % 64 = 0
  -- So paddingLength = (64 - ((messageLength + 1 + 8) % 64)) % 64
  let paddingLength := (64 - ((messageLength + 1 + 8) % 64)) % 64

  -- Add the 1-bit (0x80 byte)
  let messageWithBit := message ++ ByteArray.mk #[0x80]

  -- Add zero padding
  let messageWithPadding := messageWithBit ++ ByteArray.mk (replicate paddingLength 0)

  -- Add 64-bit length (big-endian, but we only use the lower 32 bits for now)
  let lengthBytes := ByteArray.mk (Array.mk (wordsToBytes [0, messageLengthBits.toUInt32]))

  messageWithPadding ++ lengthBytes

/-- Lemma: padMessage always produces a length that is a multiple of 64 -/
theorem padMessage_length_mod_64 (msg : ByteArray) : (padMessage msg).size % 64 = 0 := by
  let messageLength := msg.size
  let base := messageLength + 1 + 8
  let y := (64 - base % 64) % 64
  -- We need to show (base + y) % 64 = 0
  -- Since y = (64 - base % 64) % 64, we have base % 64 + y = 64 (mod 64) = 0
  sorry

/-- XOR two byte arrays of the same length -/
def xorBytes (a b : ByteArray) : Option ByteArray :=
  if a.size != b.size then none
  else
    let result := Array.mk (List.range a.size |>.map (fun i => a[i]! ^^^ b[i]!))
    some (ByteArray.mk result)

/-- Concatenate two byte arrays -/
def concatBytes (a b : ByteArray) : ByteArray :=
  ByteArray.mk (a.data ++ b.data)

/-- Extract a subarray from a byte array -/
def extractBytes (bytes : ByteArray) (start : Nat) (end : Nat) : ByteArray :=
  if start >= bytes.size || end > bytes.size || start >= end then
    ByteArray.empty
  else
    ByteArray.mk (Array.mk (List.range (end - start) |>.map (fun i => bytes[start + i]!)))

/-- Compare two byte arrays for equality -/
def bytesEqual (a b : ByteArray) : Bool :=
  if a.size != b.size then false
  else List.all (List.range a.size) (fun i => a[i]! == b[i]!)

end LeanToolchain.Crypto
