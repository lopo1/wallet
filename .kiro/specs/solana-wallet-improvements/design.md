# Design Document

## Overview

This design addresses two critical improvements to the Solana wallet service: dynamic derivation path resolution and accurate gas fee calculation. The solution involves creating an address-to-index mapping system and implementing proper Solana fee calculation logic that accounts for base fees, priority fees, and compute unit pricing.

## Architecture

### Current Architecture Issues

1. **Hardcoded Derivation Path**: The current implementation uses `"m/44'/501'/0'"` which only works for the first address (index 0)
2. **Inaccurate Fee Calculation**: The current fee estimation doesn't properly account for Solana's compute unit model and priority fees
3. **Missing Address-Index Mapping**: No mechanism to determine which derivation index corresponds to a given address

### Proposed Architecture Changes

The solution involves three main components:

1. **AddressIndexResolver**: A service to maintain and resolve address-to-index mappings
2. **SolanaFeeCalculator**: An enhanced fee calculation system that properly handles Solana's fee structure
3. **Enhanced SolanaWalletService**: Updated to use dynamic derivation paths and accurate fee calculations

## Components and Interfaces

### 1. AddressIndexResolver

```dart
class AddressIndexResolver {
  // Cache for address-to-index mappings
  final Map<String, int> _addressToIndexCache = {};
  
  // Resolve index for a given address within a wallet
  Future<int> resolveAddressIndex(String mnemonic, String address);
  
  // Build mapping for all addresses in wallet up to maxIndex
  Future<Map<String, int>> buildAddressMapping(String mnemonic, int maxIndex);
  
  // Cache management
  void cacheAddressIndex(String address, int index);
  int? getCachedIndex(String address);
  void clearCache();
}
```

### 2. SolanaFeeCalculator

```dart
class SolanaFeeCalculator {
  // Calculate base fee for transaction
  Future<int> calculateBaseFee(List<TransactionInstruction> instructions);
  
  // Calculate priority fee based on network conditions and priority level
  Future<int> calculatePriorityFee(SolanaTransactionPriority priority);
  
  // Get current compute unit prices from network
  Future<int> getCurrentComputeUnitPrice();
  
  // Estimate total fee including base + priority
  Future<SolanaTransactionFee> estimateTransactionFee(
    List<TransactionInstruction> instructions,
    SolanaTransactionPriority priority
  );
}
```

### 3. Enhanced SolanaWalletService

The existing `SolanaWalletService` will be enhanced with:

- Integration with `AddressIndexResolver` for dynamic path resolution
- Integration with `SolanaFeeCalculator` for accurate fee estimation
- Improved error handling for address mismatches
- Better transaction fee transparency

## Data Models

### Enhanced SolanaTransactionFee

The existing `SolanaTransactionFee` model will be enhanced to include:

```dart
class SolanaTransactionFee {
  final int baseFee;              // Base transaction fee (5000 lamports typically)
  final int priorityFee;          // Priority fee based on compute units
  final int totalFee;             // baseFee + priorityFee
  final int computeUnits;         // Estimated compute units for transaction
  final int computeUnitPrice;     // Price per compute unit (micro-lamports)
  final double priorityMultiplier; // Multiplier based on priority level
  final DateTime calculatedAt;    // When fee was calculated
  final bool isEstimate;          // Whether this is an estimate or actual
}
```

### AddressIndexMapping

New model to store address-to-index relationships:

```dart
class AddressIndexMapping {
  final String address;
  final int index;
  final String derivationPath;
  final DateTime createdAt;
  
  // Convert to/from storage format
  Map<String, dynamic> toJson();
  factory AddressIndexMapping.fromJson(Map<String, dynamic> json);
}
```

## Error Handling

### Address Resolution Errors

1. **AddressNotFoundError**: When an address doesn't belong to the current wallet
2. **DerivationPathError**: When derivation path generation fails
3. **IndexResolutionError**: When address-to-index mapping fails

### Fee Calculation Errors

1. **NetworkConnectionError**: When unable to fetch current fee rates
2. **FeeEstimationError**: When fee calculation fails
3. **ComputeUnitError**: When compute unit estimation fails

### Error Recovery Strategies

1. **Address Resolution**: Fall back to scanning known address range (0-100)
2. **Fee Calculation**: Use cached fee rates or reasonable defaults
3. **Network Issues**: Implement retry logic with exponential backoff

## Testing Strategy

### Unit Tests

1. **AddressIndexResolver Tests**:
   - Test address-to-index resolution for various scenarios
   - Test cache functionality
   - Test error handling for invalid addresses

2. **SolanaFeeCalculator Tests**:
   - Test base fee calculation
   - Test priority fee calculation with different priority levels
   - Test fee estimation accuracy
   - Test error handling for network failures

3. **Enhanced SolanaWalletService Tests**:
   - Test dynamic derivation path resolution
   - Test transaction creation with correct fees
   - Test address validation and error handling

### Integration Tests

1. **End-to-End Transaction Flow**:
   - Create transaction with dynamic address resolution
   - Verify correct derivation path is used
   - Verify accurate fee calculation
   - Test transaction signing and submission

2. **Fee Accuracy Tests**:
   - Compare calculated fees with actual network fees
   - Test fee calculation under different network conditions
   - Verify priority fee adjustments work correctly

### Performance Tests

1. **Address Resolution Performance**:
   - Test resolution time for large address sets
   - Test cache performance
   - Memory usage optimization

2. **Fee Calculation Performance**:
   - Test fee calculation response time
   - Test under high network load conditions

## Implementation Approach

### Phase 1: Address Index Resolution

1. Implement `AddressIndexResolver` class
2. Add address-to-index mapping to wallet storage
3. Update `SolanaWalletService` to use dynamic derivation paths
4. Add comprehensive error handling

### Phase 2: Fee Calculator Enhancement

1. Implement `SolanaFeeCalculator` class
2. Add network fee rate fetching
3. Implement priority fee calculation logic
4. Update fee estimation in `SolanaWalletService`

### Phase 3: Integration and Testing

1. Integrate both components into `SolanaWalletService`
2. Update transaction creation flow
3. Add comprehensive test coverage
4. Performance optimization

## Security Considerations

1. **Private Key Handling**: Ensure derived private keys are properly secured and not cached
2. **Address Validation**: Validate that resolved addresses actually belong to the wallet
3. **Fee Manipulation**: Prevent fee calculation manipulation through input validation
4. **Network Security**: Secure communication with Solana RPC endpoints

## Performance Optimizations

1. **Address Caching**: Cache address-to-index mappings to avoid repeated derivations
2. **Fee Caching**: Cache fee rates for short periods to reduce network calls
3. **Batch Operations**: Process multiple address resolutions in batches when possible
4. **Lazy Loading**: Only resolve addresses when needed for transactions