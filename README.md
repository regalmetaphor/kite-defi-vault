# Kite Authorization Vault

This repository contains a small on-chain authorization layer for a Kite DeFi agent. An owner signs an EIP-712 budget permit; an agent can consume that budget until its deadline, while revocation remains explicit.

The contract does not custody ERC-20 tokens or perform settlement. Payment adapters can integrate the authorization primitive without granting the vault broad transfer permissions.

```bash
npm install
npm test
```

The compile step checks the Solidity source with `solc` and writes an ABI/bytecode artifact to `build/`.
