##Solidity Decentralized Exchange (DEX)
This repository contains the source code for a set of smart contracts that form a simple Decentralized Exchange (DEX). This project was developed as a final assignment for a Solidity course and includes two ERC-20 tokens (AlphaToken and BetaToken) and the DEX contract that facilitates their exchange.

The contracts are deployed on the Sepolia test network.

Verified Contract URLs on Etherscan:

AlphaToken (ALPHA): [Paste the Etherscan URL for your TokenA contract here]

BetaToken (BETA): [Paste the Etherscan URL for your TokenB contract here]

SimpleDEX: [Paste the Etherscan URL for your SimpleDEX contract here]

How the Exchange is Built
The DEX is designed to be a simple and secure automated market maker (AMM). It allows users to trade two distinct ERC-20 tokens without intermediaries, using a liquidity pool. The pricing is determined algorithmically by the famous constant product formula (x * y = k).

Core Components
Token Contracts (TokenA.sol, TokenB.sol):

These are standard ERC-20 tokens built using OpenZeppelin's secure contracts.

Upon deployment, an initial supply of 1,000,000 tokens is minted to the contract owner.

The owner also has the ability to mint more tokens if necessary.

DEX Contract (SimpleDEX.sol):

This is the heart of the system, orchestrating liquidity and swaps.

Key Functions and Logic
constructor(address _tokenA, address _tokenB)
Purpose: To initialize the exchange.

How it works: When the DEX contract is deployed, it requires the addresses of the two ERC-20 tokens it will trade. These addresses are stored in immutable state variables (tokenA and tokenB), ensuring they can never be changed. This provides a strong security guarantee.

addLiquidity(uint256 _amountA, uint256 _amountB)
Purpose: To allow users (Liquidity Providers or LPs) to deposit tokens into the pool.

How it works:

A user provides a certain amount of both TokenA and TokenB.

The first provider sets the initial exchange rate by the ratio of tokens they deposit.

Subsequent providers must deposit tokens at a ratio that matches the current reserves to avoid altering the price.

In return for their deposit, the provider receives LP Shares, which represent their proportional ownership of the liquidity pool. These shares are calculated using a square root formula for the first provider and proportionally thereafter.

removeLiquidity(uint256 _shares)
Purpose: To allow LPs to withdraw their tokens from the pool.

How it works: An LP "burns" (gives back) a certain number of their LP shares to the contract. In return, the contract sends them their proportional amount of TokenA and TokenB from the reserves.

swapAforB(uint256 _amountIn) & swapBforA(uint256 _amountIn)
Purpose: To allow users to trade one token for the other.

How it works:

These functions use an internal _swap function to handle the logic.

A user sends a specific amount of one token (e.g., _amountIn of Token A).

The contract calculates the amount of the other token to return using the constant product formula. A 0.3% fee is automatically deducted from the input amount, which serves as a reward for the liquidity providers.

The reserves are updated, and the output tokens are sent to the user. This process slightly changes the price for the next trade.

getPrice(address _token)
Purpose: To provide the current instantaneous price of a token.

How it works: This is a view function, meaning it's free to call. It calculates the price based on the current ratio of the reserves (reserveB / reserveA or vice-versa). It returns how many units of the other token you would get for one full unit (1e18) of the specified token.

Security and Design Patterns
Reentrancy Guard: All functions that involve token transfers use OpenZeppelin's ReentrancyGuard to prevent a common and dangerous type of attack.

Constant Product Formula: The x * y = k model ensures that there is always liquidity in the pool, although prices can change significantly with large trades (this is known as "slippage").

LP Tokens as an Incentive: The 0.3% trading fee is distributed among all liquidity providers proportional to their share of the pool, creating an incentive to provide liquidity.
