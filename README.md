# ElectionChain

A secure blockchain-based voting solution for federal elections and congressional races built on the Stacks blockchain using Clarity smart contracts.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technical Specifications](#technical-specifications)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Contract Functions Documentation](#contract-functions-documentation)
- [Deployment Guide](#deployment-guide)
- [Security Notes](#security-notes)
- [Testing](#testing)
- [License](#license)

## Overview

ElectionChain is a decentralized voting platform that leverages blockchain technology to ensure transparent, secure, and tamper-proof elections. The smart contract provides comprehensive election management capabilities including voter registration, candidate management, ballot casting, and transparent vote tallying for federal, congressional, and local elections.

## Features

### Core Functionality
- **Multi-Election Support**: Create and manage multiple concurrent elections with different types (federal, congressional, local)
- **Voter Registration System**: Secure voter registration with unique voter IDs and blockchain-based verification
- **Candidate Management**: Add and manage candidates with party affiliations and descriptions
- **Secure Voting**: One-person-one-vote enforcement with cryptographic guarantees
- **Real-time Vote Tallying**: Transparent and immutable vote counting
- **Time-bound Elections**: Configurable voting periods with block-based start and end times
- **Administrator Controls**: Role-based access control for election management

### Security Features
- **Double-voting Prevention**: Cryptographic enforcement preventing voters from casting multiple ballots
- **Voter Privacy**: Votes are recorded on-chain while maintaining voter anonymity through the use of principals
- **Immutable Audit Trail**: All voting actions are permanently recorded on the blockchain
- **Permission-based Administration**: Only authorized administrators can create elections and add candidates

## Technical Specifications

### Blockchain Platform
- **Network**: Stacks Blockchain
- **Language**: Clarity 2.0
- **Contract Version**: 1.0.0
- **Epoch**: 2.5

### Data Structures

#### Elections Map
Stores comprehensive election information:
- `name`: Election name (max 100 characters)
- `description`: Detailed election description (max 500 characters)
- `start-block`: Block height when voting begins
- `end-block`: Block height when voting ends
- `election-type`: Type of election (federal/congressional/local)
- `is-active`: Boolean flag for election status
- `total-votes`: Running count of votes cast

#### Candidates Map
Stores candidate information per election:
- `name`: Candidate name (max 100 characters)
- `party`: Political party affiliation (max 50 characters)
- `description`: Candidate description (max 300 characters)
- `vote-count`: Running tally of votes received

#### Voter Registry
Maintains registered voter information:
- `is-registered`: Registration status
- `registration-block`: Block height when registered
- `voter-id`: External voter ID for verification

## Installation

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet/installation) - Clarity smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ElectionChain_contract
```

2. Install dependencies:
```bash
npm install
```

3. Initialize Clarinet (if not already initialized):
```bash
clarinet integrate
```

## Usage Examples

### Initialize the Contract
```clarity
(contract-call? .ElectionChain initialize)
```

### Add an Administrator
```clarity
(contract-call? .ElectionChain add-admin 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Create an Election
```clarity
(contract-call? .ElectionChain create-election
  "2024 Presidential Election"
  "Federal election for the President of the United States"
  u100  ;; start-block
  u10000  ;; end-block
  "federal"
)
```

### Add a Candidate
```clarity
(contract-call? .ElectionChain add-candidate
  u1  ;; election-id
  "John Doe"
  "Democratic Party"
  "Experienced public servant with 20 years in government"
)
```

### Register as a Voter
```clarity
(contract-call? .ElectionChain register-voter "VOT-123456789")
```

### Cast a Vote
```clarity
(contract-call? .ElectionChain cast-vote
  u1  ;; election-id
  u1  ;; candidate-id
)
```

### Check Election Results
```clarity
(contract-call? .ElectionChain get-election-results u1)
```

## Contract Functions Documentation

### Administrative Functions

#### `initialize()`
Initializes the contract and sets the deployer as the first administrator.
- **Returns**: `(response bool uint)`
- **Authorization**: Public, callable once

#### `add-admin(admin: principal)`
Adds a new election administrator.
- **Parameters**:
  - `admin`: Principal address of the new administrator
- **Returns**: `(response bool uint)`
- **Authorization**: Contract owner only

#### `remove-admin(admin: principal)`
Removes an election administrator.
- **Parameters**:
  - `admin`: Principal address to remove
- **Returns**: `(response bool uint)`
- **Authorization**: Contract owner only

### Election Management Functions

#### `create-election(name, description, start-block, end-block, election-type)`
Creates a new election with specified parameters.
- **Parameters**:
  - `name`: Election name (string-ascii 100)
  - `description`: Election description (string-ascii 500)
  - `start-block`: Starting block height (uint)
  - `end-block`: Ending block height (uint)
  - `election-type`: Type of election (string-ascii 50)
- **Returns**: `(response uint uint)` - Returns election ID on success
- **Authorization**: Election administrators only

#### `add-candidate(election-id, name, party, description)`
Adds a candidate to an existing election.
- **Parameters**:
  - `election-id`: ID of the election (uint)
  - `name`: Candidate name (string-ascii 100)
  - `party`: Party affiliation (string-ascii 50)
  - `description`: Candidate description (string-ascii 300)
- **Returns**: `(response uint uint)` - Returns candidate ID on success
- **Authorization**: Election administrators only

#### `end-election(election-id)`
Manually ends an election before its scheduled end block.
- **Parameters**:
  - `election-id`: ID of the election to end (uint)
- **Returns**: `(response bool uint)`
- **Authorization**: Election administrators only

### Voter Functions

#### `register-voter(voter-id)`
Registers a voter with an external verification ID.
- **Parameters**:
  - `voter-id`: External voter ID (string-ascii 50)
- **Returns**: `(response bool uint)`
- **Authorization**: Any principal can register

#### `cast-vote(election-id, candidate-id)`
Casts a vote for a specific candidate in an election.
- **Parameters**:
  - `election-id`: ID of the election (uint)
  - `candidate-id`: ID of the candidate (uint)
- **Returns**: `(response bool uint)`
- **Authorization**: Registered voters only

### Read-Only Functions

#### `get-election(election-id)`
Returns detailed information about an election.

#### `get-candidate(election-id, candidate-id)`
Returns information about a specific candidate.

#### `get-voter-info(voter)`
Returns registration information for a voter.

#### `has-voter-voted(voter, election-id)`
Checks if a voter has cast a ballot in a specific election.

#### `get-election-results(election-id)`
Returns current election results and statistics.

#### `is-voting-open(election-id)`
Checks if voting is currently open for an election.

#### `is-admin(user)`
Checks if a principal is an election administrator.

#### `get-candidate-count(election-id)`
Returns the total number of candidates in an election.

## Deployment Guide

### Local Development

1. Start a local Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
(deploy-contract 'ElectionChain)
```

3. Initialize the contract:
```clarity
(contract-call? .ElectionChain initialize)
```

### Testnet Deployment

1. Configure your Testnet settings in `settings/Testnet.toml`

2. Generate a testnet deployment plan:
```bash
clarinet deployment generate --testnet
```

3. Apply the deployment:
```bash
clarinet deployment apply --testnet
```

### Mainnet Deployment

1. Configure your Mainnet settings in `settings/Mainnet.toml`

2. Generate a mainnet deployment plan:
```bash
clarinet deployment generate --mainnet
```

3. Review the deployment plan carefully

4. Apply the deployment:
```bash
clarinet deployment apply --mainnet
```

## Security Notes

### Best Practices
1. **Administrator Management**: Carefully manage administrator privileges and regularly audit the admin list
2. **Voter Verification**: Implement off-chain voter verification processes before registration
3. **Time Boundaries**: Set appropriate block-based time boundaries for elections considering block time variability
4. **Candidate Verification**: Verify candidate eligibility off-chain before adding to elections

### Security Features
- **Immutable Voting Records**: Once cast, votes cannot be altered or deleted
- **Single Vote Enforcement**: Contract prevents double-voting through cryptographic checks
- **Time-bound Voting**: Elections automatically close at the specified end block
- **Role-based Access Control**: Clear separation between admin and voter functions

### Potential Risks and Mitigations
1. **Block Time Variability**: Elections use block heights rather than timestamps; plan accordingly
2. **Gas Costs**: Large elections may require significant transaction fees
3. **Privacy Considerations**: While votes are anonymous, transaction metadata is public
4. **Administrator Trust**: System requires trusted administrators for election creation

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## License

This project is licensed under the ISC License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure all tests pass and follow the existing code style when submitting pull requests.

## Support

For issues, questions, or suggestions, please open an issue in the repository or contact the development team.