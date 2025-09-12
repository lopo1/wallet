# Implementation Plan

- [ ] 1. Create AddressIndexResolver service for dynamic derivation path resolution
  - Implement core address-to-index mapping functionality
  - Add caching mechanism for performance optimization
  - Include error handling for address resolution failures
  - _Requirements: 1.1, 1.2, 3.1, 3.2_

- [ ] 2. Implement SolanaFeeCalculator for accurate fee calculations
  - Create base fee calculation logic using current Solana network conditions
  - Implement priority fee calculation based on compute units and network congestion
  - Add compute unit estimation for different transaction types
  - Include fallback mechanisms for network failures
  - _Requirements: 2.1, 2.2, 2.3, 2.5_

- [ ] 3. Enhance SolanaTransactionFee model with additional fee details
  - Add computeUnits, computeUnitPrice, calculatedAt, and isEstimate fields
  - Update toJson/fromJson methods to handle new fields
  - Ensure backward compatibility with existing fee structures
  - _Requirements: 2.4, 2.6_

- [ ] 4. Create AddressIndexMapping model for storage
  - Define data structure for address-to-index relationships
  - Implement serialization methods for storage persistence
  - Add validation for derivation path format
  - _Requirements: 3.1, 3.3_

- [ ] 5. Update SolanaWalletService to use dynamic derivation paths
  - Replace hardcoded path with AddressIndexResolver integration
  - Modify sendSolTransfer method to resolve correct derivation index
  - Add address validation to ensure address belongs to wallet
  - Update error messages to be more descriptive
  - _Requirements: 1.1, 1.3, 1.4_

- [ ] 6. Integrate SolanaFeeCalculator into transaction fee estimation
  - Replace current estimateFee method with enhanced fee calculation
  - Update sendSolTransfer to use accurate fee calculations
  - Ensure fee transparency by showing base fee and priority fee separately
  - Add priority fee adjustment based on transaction priority level
  - _Requirements: 2.1, 2.2, 2.3, 2.6_

- [ ] 7. Add address-to-index mapping storage to WalletProvider
  - Extend wallet storage to include address index mappings
  - Update wallet loading to reconstruct address mappings
  - Add methods to update and retrieve address mappings
  - Ensure mapping persistence across app restarts
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 8. Implement error handling and recovery mechanisms
  - Add specific error types for address resolution and fee calculation failures
  - Implement retry logic for network-related fee calculation errors
  - Add fallback address scanning for corrupted mappings
  - Create user-friendly error messages for common failure scenarios
  - _Requirements: 1.3, 2.5, 3.4_

- [ ] 9. Create comprehensive unit tests for AddressIndexResolver
  - Test address-to-index resolution with various wallet configurations
  - Test cache functionality and performance
  - Test error handling for invalid addresses and network failures
  - Verify derivation path generation accuracy
  - _Requirements: 1.1, 1.2, 3.1, 3.2_

- [ ] 10. Create comprehensive unit tests for SolanaFeeCalculator
  - Test base fee calculation accuracy
  - Test priority fee calculation with different priority levels
  - Test compute unit estimation for various transaction types
  - Test error handling and fallback mechanisms
  - _Requirements: 2.1, 2.2, 2.3, 2.5_

- [ ] 11. Create integration tests for enhanced SolanaWalletService
  - Test end-to-end transaction flow with dynamic address resolution
  - Verify correct derivation paths are used for different addresses
  - Test fee calculation accuracy in real network conditions
  - Test error scenarios and recovery mechanisms
  - _Requirements: 1.1, 1.4, 2.1, 2.2, 2.3_

- [ ] 12. Add performance optimization and caching
  - Implement efficient caching strategies for address mappings
  - Add fee rate caching to reduce network calls
  - Optimize address resolution for large wallet configurations
  - Add performance monitoring and logging
  - _Requirements: 3.2, 3.4_