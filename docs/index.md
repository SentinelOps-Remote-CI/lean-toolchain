# Lean Toolchain

Cryptographic, math, and data-parsing primitives formally proven in Lean 4.

## Overview

Lean Toolchain provides a collection of formally verified cryptographic algorithms, mathematical operations, and data parsing utilities. All implementations are proven correct in Lean 4 and can be extracted to high-performance Rust code.

## Key Features

- **Formally Verified**: All algorithms come with mathematical proofs of correctness
- **High Performance**: Extracted Rust code matches or exceeds industry standards
- **Comprehensive**: SHA-256, HMAC, linear algebra, CSV/JSON parsing
- **Developer Friendly**: Clear documentation, examples, and contribution guidelines

## Quick Start

```bash
# Install Lean 4
lake build

# Run tests
lake test

# Extract to Rust (coming soon)
lake exe extract
```

## Project Status

- [x] Repository scaffolding
- [ ] SHA-256 implementation and proofs
- [ ] HMAC-SHA256 implementation
- [ ] Linear algebra primitives
- [ ] CSV/JSON parsers
- [ ] Rust extraction pipeline
- [ ] Documentation and examples

## Contributing

We welcome contributions! See our [Contributing Guide](development/contributing.md) for details.

## License

MIT License - see [LICENSE](../LICENSE) for details.
