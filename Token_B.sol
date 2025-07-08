// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol";

/**
 * @title BetaToken
 * @dev This is the second ERC-20 token for the SimpleDEX.
 * It is structured identically to AlphaToken.
 */
contract BetaToken is ERC20, Ownable {
    /**
     * @dev Constructor that sets the token name and symbol.
     * It also mints the initial total supply to the contract deployer.
     */
    constructor(address initialOwner) ERC20("BetaToken", "BETA") Ownable(initialOwner) {
        // Mint 1,000,000 tokens to the deployer's address.
        // Since the token has 18 decimals, we need to add 18 zeros.
        _mint(msg.sender, 1_000_000 * (10**decimals()));
    }

    /**
     * @dev Creates `amount` new tokens and assigns them to `to`.
     * This function can only be called by the owner of the contract.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}