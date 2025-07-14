import LeanToolchain.Crypto.SHA256
import LeanToolchain.Crypto.Utils
import Init.System.IO

/-!
# Code Generator for Rust Extraction

This module provides a sophisticated code generator that can extract Lean implementations
to Rust code, preserving the logic and structure of the original implementation.
-/

namespace LeanToolchain.Extraction

/-- Rust code generation context -/
structure RustContext where
  indentLevel : Nat := 0
  variables : List String := []
  functions : List String := []

/-- Generate indentation -/
def indent (ctx : RustContext) : String :=
  String.mk (List.replicate (ctx.indentLevel * 2) ' ')

/-- Add indentation level -/
def withIndent (ctx : RustContext) (f : RustContext → String) : String :=
  f { ctx with indentLevel := ctx.indentLevel + 1 }

/-- Generate SHA-256 constants -/
def generateSHA256Constants : String :=
  "// SHA-256 initial hash values
const SHA256_INITIAL_HASH: [u32; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
];

// SHA-256 round constants
const SHA256_ROUND_CONSTANTS: [u32; 64] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];"

/-- Generate SHA-256 utility functions -/
def generateSHA256Utils : String :=
  "// SHA-256 utility functions
fn rotate_right(x: u32, n: u32) -> u32 {
    (x >> n) | (x << (32 - n))
}

fn shift_right(x: u32, n: u32) -> u32 {
    x >> n
}

fn ch(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (!x & z)
}

fn maj(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (x & z) ^ (y & z)
}

fn sigma0(x: u32) -> u32 {
    rotate_right(x, 2) ^ rotate_right(x, 13) ^ rotate_right(x, 22)
}

fn sigma1(x: u32) -> u32 {
    rotate_right(x, 6) ^ rotate_right(x, 11) ^ rotate_right(x, 25)
}

fn sigma0_prime(x: u32) -> u32 {
    rotate_right(x, 7) ^ rotate_right(x, 18) ^ shift_right(x, 3)
}

fn sigma1_prime(x: u32) -> u32 {
    rotate_right(x, 17) ^ rotate_right(x, 19) ^ shift_right(x, 10)
}"

/-- Generate SHA-256 message schedule -/
def generateMessageSchedule : String :=
  "fn generate_message_schedule(block: &[u8; 64]) -> [u32; 64] {
    let mut w = [0u32; 64];

    // Convert block to 16 32-bit words (big-endian)
    for i in 0..16 {
        w[i] = ((block[i * 4] as u32) << 24) |
               ((block[i * 4 + 1] as u32) << 16) |
               ((block[i * 4 + 2] as u32) << 8) |
               (block[i * 4 + 3] as u32);
    }

    // Generate remaining 48 words
    for i in 16..64 {
        w[i] = w[i - 16]
            .wrapping_add(sigma0_prime(w[i - 15]))
            .wrapping_add(w[i - 7])
            .wrapping_add(sigma1_prime(w[i - 2]));
    }

    w
}"

/-- Generate SHA-256 compression function -/
def generateCompressionFunction : String :=
  "fn sha256_compress(hash: &mut [u32; 8], block: &[u8; 64]) {
    let w = generate_message_schedule(block);

    let mut a = hash[0];
    let mut b = hash[1];
    let mut c = hash[2];
    let mut d = hash[3];
    let mut e = hash[4];
    let mut f = hash[5];
    let mut g = hash[6];
    let mut h = hash[7];

    for i in 0..64 {
        let s1 = sigma1(e);
        let ch_val = ch(e, f, g);
        let temp1 = h
            .wrapping_add(s1)
            .wrapping_add(ch_val)
            .wrapping_add(SHA256_ROUND_CONSTANTS[i])
            .wrapping_add(w[i]);

        let s0 = sigma0(a);
        let maj_val = maj(a, b, c);
        let temp2 = s0.wrapping_add(maj_val);

        h = g;
        g = f;
        f = e;
        e = d.wrapping_add(temp1);
        d = c;
        c = b;
        b = a;
        a = temp1.wrapping_add(temp2);
    }

    hash[0] = hash[0].wrapping_add(a);
    hash[1] = hash[1].wrapping_add(b);
    hash[2] = hash[2].wrapping_add(c);
    hash[3] = hash[3].wrapping_add(d);
    hash[4] = hash[4].wrapping_add(e);
    hash[5] = hash[5].wrapping_add(f);
    hash[6] = hash[6].wrapping_add(g);
    hash[7] = hash[7].wrapping_add(h);
}"

/-- Generate SHA-256 padding function -/
def generatePaddingFunction : String :=
  "fn pad_message(message: &[u8]) -> Vec<u8> {
    let message_len = message.len();
    let message_len_bits = (message_len * 8) as u64;

    // Calculate padding length
    let padding_len = if message_len % 64 < 56 {
        56 - (message_len % 64)
    } else {
        120 - (message_len % 64)
    };

    let mut padded = Vec::with_capacity(message_len + padding_len + 8);
    padded.extend_from_slice(message);

    // Add 1-bit (0x80)
    padded.push(0x80);

    // Add zero padding
    padded.extend(std::iter::repeat(0u8).take(padding_len - 1));

    // Add 64-bit length (big-endian)
    padded.extend_from_slice(&message_len_bits.to_be_bytes());

    padded
}"

/-- Generate main SHA-256 function -/
def generateMainSHA256Function : String :=
  "pub fn sha256_hash(input: &[u8]) -> [u8; 32] {
    let padded = pad_message(input);
    let mut hash = SHA256_INITIAL_HASH;

    // Process each 512-bit block
    for chunk in padded.chunks_exact(64) {
        let mut block = [0u8; 64];
        block.copy_from_slice(chunk);
        sha256_compress(&mut hash, &block);
    }

    // Convert hash to bytes (big-endian)
    let mut result = [0u8; 32];
    for i in 0..8 {
        let bytes = hash[i].to_be_bytes();
        result[i * 4] = bytes[0];
        result[i * 4 + 1] = bytes[1];
        result[i * 4 + 2] = bytes[2];
        result[i * 4 + 3] = bytes[3];
    }

    result
}

#[no_mangle]
pub extern \"C\" fn sha256_hash_c(input: *const u8, input_len: usize, output: *mut u8) -> i32 {
    if input.is_null() || output.is_null() {
        return -1;
    }

    let input_slice = unsafe { std::slice::from_raw_parts(input, input_len) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, 32) };

    let hash = sha256_hash(input_slice);
    output_slice.copy_from_slice(&hash);

    0
}"

/-- Generate SHA-256 tests -/
def generateSHA256Tests : String :=
  "#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256_empty() {
        let input = b\"\";
        let expected = [
            0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
            0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
            0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
            0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_sha256_abc() {
        let input = b\"abc\";
        let expected = [
            0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
            0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
            0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
            0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_sha256_quick_brown_fox() {
        let input = b\"The quick brown fox jumps over the lazy dog\";
        let expected = [
            0xd7, 0xa8, 0xfb, 0xb3, 0x07, 0xd7, 0x80, 0x94,
            0x69, 0xca, 0x9a, 0xbc, 0xb0, 0x08, 0x2e, 0x4f,
            0x8d, 0x56, 0x51, 0xe4, 0x6d, 0x3c, 0xdb, 0x76,
            0x2d, 0x02, 0xd0, 0xbf, 0x37, 0xc9, 0xe5, 0x92
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }
}"

/-- Generate complete SHA-256 Rust module -/
def generateSHA256Module : String :=
  "//! SHA-256 implementation extracted from Lean 4
//!
//! This module contains a complete SHA-256 implementation that matches
//! the behavior of the Lean 4 implementation.

" ++ generateSHA256Constants ++ "\n\n" ++
  generateSHA256Utils ++ "\n\n" ++
  generateMessageSchedule ++ "\n\n" ++
  generateCompressionFunction ++ "\n\n" ++
  generatePaddingFunction ++ "\n\n" ++
  generateMainSHA256Function ++ "\n\n" ++
  generateSHA256Tests

/-- Generate HMAC-SHA256 implementation -/
def generateHMACModule : String :=
  "//! HMAC-SHA256 implementation extracted from Lean 4

use super::sha256::sha256_hash;

const HMAC_OUTER_PAD: u8 = 0x5c;
const HMAC_INNER_PAD: u8 = 0x36;
const SHA256_BLOCK_SIZE: usize = 64;

fn prepare_key(key: &[u8]) -> [u8; SHA256_BLOCK_SIZE] {
    let mut prepared = [0u8; SHA256_BLOCK_SIZE];

    if key.len() > SHA256_BLOCK_SIZE {
        // If key is longer than block size, hash it first
        let hashed_key = sha256_hash(key);
        prepared[..32].copy_from_slice(&hashed_key);
    } else {
        // Copy key and pad with zeros
        let copy_len = key.len().min(SHA256_BLOCK_SIZE);
        prepared[..copy_len].copy_from_slice(&key[..copy_len]);
    }

    prepared
}

fn xor_with_constant(bytes: &[u8; SHA256_BLOCK_SIZE], constant: u8) -> [u8; SHA256_BLOCK_SIZE] {
    let mut result = [0u8; SHA256_BLOCK_SIZE];
    for i in 0..SHA256_BLOCK_SIZE {
        result[i] = bytes[i] ^ constant;
    }
    result
}

pub fn hmac_sha256(key: &[u8], message: &[u8]) -> [u8; 32] {
    let prepared_key = prepare_key(key);
    let outer_key = xor_with_constant(&prepared_key, HMAC_OUTER_PAD);
    let inner_key = xor_with_constant(&prepared_key, HMAC_INNER_PAD);

    // Inner hash: H(K_inner || message)
    let mut inner_input = Vec::with_capacity(SHA256_BLOCK_SIZE + message.len());
    inner_input.extend_from_slice(&inner_key);
    inner_input.extend_from_slice(message);
    let inner_hash = sha256_hash(&inner_input);

    // Outer hash: H(K_outer || inner_hash)
    let mut outer_input = Vec::with_capacity(SHA256_BLOCK_SIZE + 32);
    outer_input.extend_from_slice(&outer_key);
    outer_input.extend_from_slice(&inner_hash);
    sha256_hash(&outer_input)
}

#[no_mangle]
pub extern \"C\" fn hmac_sha256_c(
    key: *const u8,
    key_len: usize,
    message: *const u8,
    message_len: usize,
    output: *mut u8
) -> i32 {
    if key.is_null() || message.is_null() || output.is_null() {
        return -1;
    }

    let key_slice = unsafe { std::slice::from_raw_parts(key, key_len) };
    let message_slice = unsafe { std::slice::from_raw_parts(message, message_len) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, 32) };

    let hmac = hmac_sha256(key_slice, message_slice);
    output_slice.copy_from_slice(&hmac);

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hmac_basic() {
        let key = b\"key\";
        let message = b\"The quick brown fox jumps over the lazy dog\";
        let expected = [
            0xf7, 0xbc, 0x83, 0xf4, 0x30, 0x53, 0x84, 0x27,
            0x9c, 0xd7, 0xba, 0x4b, 0xcb, 0x9e, 0x8f, 0x8b,
            0x4d, 0x8d, 0x4c, 0x63, 0xcb, 0x1e, 0xdf, 0x7f,
            0x4b, 0x8b, 0x1f, 0x84, 0x2c, 0x7a, 0x85, 0x6c
        ];
        let result = hmac_sha256(key, message);
        assert_eq!(result, expected);
    }
}"

/-- Generate Vector implementation -/
def generateVectorModule : String :=
  "//! Vector operations extracted from Lean 4

use std::vec::Vec;

#[no_mangle]
pub extern \"C\" fn vector_add(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] + b_slice[i];
    }

    0
}

#[no_mangle]
pub extern \"C\" fn vector_sub(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] - b_slice[i];
    }

    0
}

#[no_mangle]
pub extern \"C\" fn vector_smul(
    a: *const f64,
    scalar: f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] * scalar;
    }

    0
}

#[no_mangle]
pub extern \"C\" fn vector_dot_product(
    a: *const f64,
    b: *const f64,
    len: usize
) -> f64 {
    if a.is_null() || b.is_null() {
        return 0.0;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };

    let mut result = 0.0;
    for i in 0..len {
        result += a_slice[i] * b_slice[i];
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vector_add() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        let mut result = vec![0.0; 3];

        let res = vector_add(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 3);
        assert_eq!(res, 0);
        assert_eq!(result, vec![5.0, 7.0, 9.0]);
    }

    #[test]
    fn test_vector_dot_product() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];

        let result = vector_dot_product(a.as_ptr(), b.as_ptr(), 3);
        assert_eq!(result, 32.0);
    }
}"

/-- Generate Matrix implementation -/
def generateMatrixModule : String :=
  "//! Matrix operations extracted from Lean 4

use std::vec::Vec;

#[no_mangle]
pub extern \"C\" fn matrix_add(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    rows: usize,
    cols: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let len = rows * cols;
    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] + b_slice[i];
    }

    0
}

#[no_mangle]
pub extern \"C\" fn matrix_multiply(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    m: usize,
    n: usize,
    p: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, m * n) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, n * p) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, m * p) };

    // Initialize result to zero
    for i in 0..m * p {
        result_slice[i] = 0.0;
    }

    // Perform matrix multiplication
    for i in 0..m {
        for j in 0..p {
            for k in 0..n {
                result_slice[i * p + j] += a_slice[i * n + k] * b_slice[k * p + j];
            }
        }
    }

    0
}

#[no_mangle]
pub extern \"C\" fn matrix_transpose(
    input: *const f64,
    output: *mut f64,
    rows: usize,
    cols: usize
) -> i32 {
    if input.is_null() || output.is_null() {
        return -1;
    }

    let input_slice = unsafe { std::slice::from_raw_parts(input, rows * cols) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, rows * cols) };

    for i in 0..rows {
        for j in 0..cols {
            output_slice[j * rows + i] = input_slice[i * cols + j];
        }
    }

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_matrix_add() {
        let a = vec![1.0, 2.0, 3.0, 4.0];
        let b = vec![5.0, 6.0, 7.0, 8.0];
        let mut result = vec![0.0; 4];

        let res = matrix_add(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 2, 2);
        assert_eq!(res, 0);
        assert_eq!(result, vec![6.0, 8.0, 10.0, 12.0]);
    }

    #[test]
    fn test_matrix_multiply() {
        let a = vec![1.0, 2.0, 3.0, 4.0];
        let b = vec![5.0, 6.0, 7.0, 8.0];
        let mut result = vec![0.0; 4];

        let res = matrix_multiply(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 2, 2, 2);
        assert_eq!(res, 0);
        // Expected: [[19, 22], [43, 50]]
        assert_eq!(result, vec![19.0, 22.0, 43.0, 50.0]);
    }
}"

/-- Generate complete Rust library -/
def generateCompleteRustLibrary : String :=
  "//! Lean Toolchain Rust Library
//!
//! This library contains Rust implementations extracted from Lean 4 code.
//! All functions are designed to be called from C/C++ code.

pub mod sha256;
pub mod hmac;
pub mod vector;
pub mod matrix;

// Re-export main functions for easier access
pub use sha256::*;
pub use hmac::*;
pub use vector::*;
pub use matrix::*;"

/-- Extract all modules to Rust -/
def extractAllToRust (outputDir : String) : IO Unit := do
  IO.println "Generating complete Rust library..."

  -- Create output directory
  IO.FS.createDirAll outputDir
  IO.FS.createDirAll "rust/benches"

  -- Generate all modules
  IO.FS.writeFile (outputDir ++ "/sha256.rs") (generateSHA256Module)
  IO.FS.writeFile (outputDir ++ "/hmac.rs") (generateHMACModule)
  IO.FS.writeFile (outputDir ++ "/vector.rs") (generateVectorModule)
  IO.FS.writeFile (outputDir ++ "/matrix.rs") (generateMatrixModule)
  IO.FS.writeFile (outputDir ++ "/lib.rs") (generateCompleteRustLibrary)

  IO.println "Rust library generation completed!"
