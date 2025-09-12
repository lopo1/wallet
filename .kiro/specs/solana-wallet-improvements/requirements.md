# Requirements Document

## Introduction

This feature addresses two critical issues in the Solana wallet service: dynamic derivation path resolution and accurate gas fee calculation. Currently, the system uses a hardcoded derivation path which prevents proper address-to-index mapping, and the gas fee calculation logic has inaccuracies that affect transaction cost estimation and priority fee handling.

## Requirements

### Requirement 1

**User Story:** As a wallet user, I want the system to automatically determine the correct derivation path index for any given address, so that I can properly sign transactions from any address in my wallet.

#### Acceptance Criteria

1. WHEN a transaction is initiated with a specific address THEN the system SHALL determine the correct derivation path index for that address
2. WHEN multiple addresses exist in a wallet THEN the system SHALL maintain a mapping between addresses and their corresponding derivation indices
3. WHEN an address is not found in the current wallet THEN the system SHALL throw a descriptive error indicating the address mismatch
4. IF an address belongs to the wallet THEN the system SHALL use the correct index to derive the private key for signing

### Requirement 2

**User Story:** As a wallet user, I want accurate gas fee calculations for Solana transactions, so that I can make informed decisions about transaction costs and priority levels.

#### Acceptance Criteria

1. WHEN estimating transaction fees THEN the system SHALL calculate the base fee accurately using current network conditions
2. WHEN a priority level is selected THEN the system SHALL calculate the priority fee based on current network congestion and the selected priority multiplier
3. WHEN creating a transaction THEN the system SHALL include both base fee and priority fee in the total fee calculation
4. WHEN network conditions change THEN the system SHALL update fee calculations to reflect current rates
5. IF priority fee calculation fails THEN the system SHALL fall back to a reasonable default priority fee
6. WHEN displaying fees to users THEN the system SHALL show base fee, priority fee, and total fee separately for transparency

### Requirement 3

**User Story:** As a developer, I want the address-to-index mapping to be efficiently maintained and accessible, so that the wallet service can quickly resolve derivation paths without performance issues.

#### Acceptance Criteria

1. WHEN a new address is generated THEN the system SHALL store the address-to-index mapping
2. WHEN looking up an address index THEN the system SHALL retrieve it in O(1) time complexity
3. WHEN the wallet is loaded THEN the system SHALL reconstruct the address-to-index mapping from stored data
4. IF the mapping becomes corrupted THEN the system SHALL be able to regenerate it by re-deriving addresses up to the known maximum index