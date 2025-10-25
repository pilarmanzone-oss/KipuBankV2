**Language:** [English](./README.md) | [Español](./README_es.md)

# KipuBankv2: Multi-Token Smart Contract

## Overview

`KipuBankV2.sol` is an improved version of the `KipuBank` contract, offering a multi-token deposit and withdrawal system with access control, Chainlink oracle integration, and decimal handling for different ERC-20 assets and Ether.

This version focuses on **security, extensibility, and gas efficiency**, leveraging OpenZeppelin libraries and smart contract best practices.

---

## 1. Improvements in This Version

### Access Control

* Implements the **role-based** pattern using OpenZeppelin’s `AccessControl`.
* The `ADMIN_ROLE` allows:

  * Registering supported tokens.
  * Setting price oracles.
  * Updating the global deposit limit (bank cap).
* The `OPERATOR_ROLE` is reserved for future automated or maintenance operations.

**Reason:**
Access control strengthens operational security by preventing unauthorized users from modifying critical parameters.

---

### Type Declarations and Constant Variables

* Introduces constants such as `USDC_DECIMALS = 6` and `ADMIN_ROLE = 0x00` for clarity and gas efficiency.
* Uses `immutable` for `USDC_ADDRESS`, since it does not change after deployment.

**Reason:**
Improves readability and optimizes execution.

---

### Chainlink Oracle Instance

* Each supported token can be linked to an **external price feed** (Chainlink or mock).
* A **generic interface `IOracle`** is used, defining `latestAnswer()` to ensure compatibility with both Chainlink and mock feeds.
* Implements `try/catch` to handle feeds that may fail or return invalid data.

**Reason:**
Enables calculation of equivalent USD amounts and prevents transaction failures caused by temporary oracle errors.

---

### Nested Mappings

```solidity
mapping(address => mapping(address => uint256)) public balances;
```

* Structure that enables **multi-token accounting** per user.
* Example: `balances[DAI][user]` or `balances[address(0)][user]` for Ether.

**Reason:**
Allows scalability to multiple assets without deploying new contracts.

---

### Decimal and Value Conversion

* Introduces the `_toUsd6()` function that:

  * Converts amounts from tokens with different decimals (e.g., 18, 8, 6).
  * Applies the price from the feed (typically 8 decimals for Chainlink).
  * Returns the value standardized to **USDC decimals (6)** for internal accounting.

**Reason:**
Standardizing accounting in USD simplifies auditing and control of the global limit (`bankCapUsd6`).

---

## 2. Deployment and Interaction Instructions

### Constructor Parameters

```solidity
constructor(address admin, address usdcAddress, uint256 initialCapUsd6)
```

| Parameter        | Description                                                        |
| ---------------- | ------------------------------------------------------------------ |
| `admin`          | Address of the initial administrator (typically your own wallet)   |
| `usdcAddress`    | USDC contract address (real or mock, whether it is mainnet/testnet)|
| `initialCapUsd6` | Total allowed bank limit in USD (6 decimals)                       |

### Example (Sepolia Testnet):

* `admin`: your own MetaMask wallet address
* `usdcAddress`: `0x07865c6e87b9f70255377e024ace6630c1eaa37f` (USDC Sepolia)
* `initialCapUsd6`: `100000000` (equivalent to 100 USD)

---

### Deployment (Remix and MetaMask)

1. Open **Remix IDE** → `Deploy & Run Transactions`.
2. Select:

   * **Environment:** `Injected Provider - MetaMask`
   * **Network:** `Sepolia`
3. Choose `KipuBankV2_es.sol`.
4. Enter constructor parameters.
5. Click **Deploy**.
6. Confirm in MetaMask.

---

### Basic Interaction

| Function                         | Description                               |
| -------------------------------- | ----------------------------------------- |
| `setTokenSupported(token, bool)` | Enables or disables an ERC-20 token       |
| `setPriceFeed(token, feed)`      | Links a price feed to a token             |
| `depositETH()`                   | Deposits Ether (requires `msg.value > 0`) |
| `depositToken(token, amount)`    | Deposits an approved ERC-20 token         |
| `withdrawETH(amount)`            | Withdraws available Ether                 |
| `withdrawToken(token, amount)`   | Withdraws deposited tokens                |
| `balanceOf(token, user)`         | Queries individual balances               |

---

## 3. Design Decisions and Trade-offs

### Security vs. Flexibility

* Explicit **role-based control** was preferred over `onlyOwner` to facilitate future decentralization.
* Each token must be manually registered before use, preventing interactions with malicious contracts.

### Oracle Usage

* Generic compatibility via `IOracle` was implemented instead of direct Chainlink coupling, allowing greater flexibility and easier local testing.

### Efficiency

* Avoids loops over balances.
* Marks variables as `immutable` and `constant` wherever applicable.
* Follows the `checks-effects-interactions` pattern to mitigate reentrancy attacks, as in the previous version.

### Gas and Precision

* All accounting is maintained in USD with 6 decimals for simple comparisons.
* Dynamic decimal conversions used for tokens with different precision.

---

## Conclusion

KipuBankV2 is a modular, secure, and extensible smart contract that can serve as a foundation for multi-token vaults, among other use cases.
The improvements prioritize **security, traceability, and interoperability with external oracles.**

---

© 2025 KipuBank Project — MIT License
