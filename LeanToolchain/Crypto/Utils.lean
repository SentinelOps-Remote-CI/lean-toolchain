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

-- TODO: Implement hexToBytes when string indexing is available

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
    | [] => acc
    | [b1] => (b1.toUInt32 <<< 24) :: acc
    | [b1, b2] => ((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16)) :: acc
    | [b1, b2, b3] => ((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16) ||| (b3.toUInt32 <<< 8)) :: acc
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

/-- Convert list to array -/
def listToArray (xs : List UInt8) : Array UInt8 :=
  let rec aux (acc : Array UInt8) (ys : List UInt8) : Array UInt8 :=
    match ys with
    | [] => acc
    | y :: rest => aux (acc.push y) rest
  aux Array.empty xs

/-- Pad a message to a multiple of 512 bits (64 bytes) -/
def padMessage (message : ByteArray) : ByteArray :=
  let messageLength := message.size
  let messageLengthBits := messageLength * 8
  let paddingLength := if messageLength % 64 < 56 then 56 - (messageLength % 64) else 120 - (messageLength % 64)

  let padding := ByteArray.mk (replicate paddingLength 0x80)
  let lengthBytes := ByteArray.mk (listToArray (wordsToBytes [messageLengthBits.toUInt32]))

  message ++ padding ++ lengthBytes

end LeanToolchain.Crypto
