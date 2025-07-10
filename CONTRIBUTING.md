# Contributing

Thank you for your interest in contributing to lean-toolchain!

## Getting Started

- Fork the repository and clone your fork.
- Install Lean 4 and Rust (see README for setup instructions).
- Run `lake build` and `lake test` to ensure a clean build.

## Coding Standards

- Follow the `.editorconfig` for whitespace and indentation.
- For Lean: Use descriptive names, add docstrings, and prefer constructive proofs.
- For Rust: No `unsafe` outside FFI modules; document all public APIs.
- Write clear, minimal, and total code. Avoid `sorry` unless absolutely necessary.

## Commit Messages

- Use [Conventional Commits](https://www.conventionalcommits.org/).

## Pull Requests

- Ensure all tests pass (`lake test`).
- Add/Update documentation as needed.
- Link related issues in your PR description.

## Code of Conduct

- Be respectful and inclusive.

See the full documentation for more details.
