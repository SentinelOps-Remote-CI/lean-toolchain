# Cryptographic API Reference

## Overview

The cryptographic module provides formally verified implementations of cryptographic primitives including SHA-256 and HMAC-SHA256. All implementations are proven correct and can be extracted to high-performance Rust code.

## SHA-256 Hash Function

### `sha256 : ByteArray → ByteArray`

Computes the SHA-256 hash of a byte array.

**Parameters:**

- `message : ByteArray` - The input message to hash

**Returns:**

- `ByteArray` - The 32-byte SHA-256 hash

**Example:**

```lean
let message := stringToBytes "hello world"
let hash := sha256 message
-- hash is a 32-byte array containing the SHA-256 hash
```

### `sha256String : String → String`

Computes the SHA-256 hash of a string and returns it as a hexadecimal string.

**Parameters:**

- `s : String` - The input string to hash

**Returns:**

- `String` - The hexadecimal representation of the SHA-256 hash

**Example:**

```lean
let hash := sha256String "hello world"
-- hash is "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
```

### `sha256Verify : ByteArray → String → Bool`

Verifies that a message produces the expected SHA-256 hash.

**Parameters:**

- `message : ByteArray` - The message to verify
- `expected : String` - The expected hexadecimal hash

**Returns:**

- `Bool` - `true` if the message produces the expected hash, `false` otherwise

**Example:**

```lean
let message := stringToBytes "hello world"
let expected := "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
let isValid := sha256Verify message expected
-- isValid is true
```

## HMAC-SHA256

### `hmacSha256 : ByteArray → ByteArray → ByteArray`

Computes the HMAC-SHA256 of a message using a key.

**Parameters:**

- `key : ByteArray` - The secret key
- `message : ByteArray` - The message to authenticate

**Returns:**

- `ByteArray` - The 32-byte HMAC-SHA256 signature

**Example:**

```lean
let key := stringToBytes "secret"
let message := stringToBytes "hello world"
let hmac := hmacSha256 key message
-- hmac is a 32-byte array containing the HMAC-SHA256 signature
```

### `hmacSha256String : String → String → String`

Computes the HMAC-SHA256 of a string message using a string key and returns it as a hexadecimal string.

**Parameters:**

- `key : String` - The secret key
- `message : String` - The message to authenticate

**Returns:**

- `String` - The hexadecimal representation of the HMAC-SHA256 signature

**Example:**

```lean
let hmac := hmacSha256String "secret" "hello world"
-- hmac is a 64-character hexadecimal string
```

### `hmacSha256Verify : ByteArray → ByteArray → String → Bool`

Verifies an HMAC-SHA256 signature.

**Parameters:**

- `key : ByteArray` - The secret key
- `message : ByteArray` - The message that was signed
- `signature : String` - The expected hexadecimal signature

**Returns:**

- `Bool` - `true` if the signature is valid, `false` otherwise

**Example:**

```lean
let key := stringToBytes "secret"
let message := stringToBytes "hello world"
let signature := "expected_hmac_signature_here"
let isValid := hmacSha256Verify key message signature
-- isValid is true if the signature matches
```

### `hmacSha256Hex : String → String → Option String`

Computes HMAC-SHA256 with hex-encoded inputs (useful for RFC test vectors).

**Parameters:**

- `keyHex : String` - The secret key in hexadecimal format
- `messageHex : String` - The message in hexadecimal format

**Returns:**

- `Option String` - `some signature` if successful, `none` if hex parsing fails

**Example:**

```lean
let keyHex := "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"
let messageHex := "4869205468657265"
let signature := hmacSha256Hex keyHex messageHex
-- signature is some "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
```

## Cryptographic Utilities

### `stringToBytes : String → ByteArray`

Converts a string to a byte array using UTF-8 encoding.

**Parameters:**

- `s : String` - The string to convert

**Returns:**

- `ByteArray` - The UTF-8 encoded byte array

### `bytesToHex : ByteArray → String`

Converts a byte array to a hexadecimal string.

**Parameters:**

- `bytes : ByteArray` - The byte array to convert

**Returns:**

- `String` - The hexadecimal representation

### `hexToBytes : String → Option ByteArray`

Converts a hexadecimal string to a byte array.

**Parameters:**

- `hex : String` - The hexadecimal string to convert

**Returns:**

- `Option ByteArray` - `some bytes` if successful, `none` if hex parsing fails

### `padMessage : ByteArray → ByteArray`

Pads a message according to SHA-256 padding rules.

**Parameters:**

- `message : ByteArray` - The message to pad

**Returns:**

- `ByteArray` - The padded message (length is a multiple of 64 bytes)

## Constants

### SHA-256 Constants

- `sha256InitialHash : Array UInt32` - Initial hash values for SHA-256
- `sha256RoundConstants : Array UInt32` - Round constants for SHA-256

### HMAC Constants

- `hmacOuterPad : UInt8` - Outer padding constant (0x5c)
- `hmacInnerPad : UInt8` - Inner padding constant (0x36)
- `sha256BlockSize : Nat` - SHA-256 block size (64 bytes)
- `sha256OutputSize : Nat` - SHA-256 output size (32 bytes)

## Error Handling

All cryptographic functions are designed to be safe and handle edge cases gracefully:

- **Null pointers**: Functions that take pointers check for null and return error codes
- **Invalid hex**: `hexToBytes` returns `none` for invalid hex strings
- **Empty inputs**: All functions handle empty strings and byte arrays correctly
- **Large inputs**: Functions handle inputs of any size (though very large inputs may be slow)

## Performance Characteristics

- **SHA-256**: O(n) time complexity where n is the message length
- **HMAC-SHA256**: O(n) time complexity where n is the message length
- **Memory usage**: Constant memory overhead for all operations
- **Thread safety**: All functions are thread-safe and reentrant

## Security Considerations

- **Key management**: Keys should be stored securely and not logged
- **Timing attacks**: The implementation is not designed to be constant-time
- **Random number generation**: This module does not provide random number generation
- **Key derivation**: Use appropriate key derivation functions (PBKDF2, Argon2, etc.) for password-based keys

## Testing

The cryptographic implementations include comprehensive test suites:

- **NIST test vectors**: SHA-256 implementation verified against NIST test vectors
- **RFC test vectors**: HMAC-SHA256 implementation verified against RFC 4231 test vectors
- **Edge cases**: Empty inputs, single bytes, large inputs
- **Property-based tests**: Algebraic properties and invariants

## Extraction to Rust

All cryptographic functions can be extracted to high-performance Rust code:

```bash
lake exe extract
cd rust
cargo build
cargo test
```

The extracted Rust code provides C-compatible interfaces for integration with other languages and systems.
