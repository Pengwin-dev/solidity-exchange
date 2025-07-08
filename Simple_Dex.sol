// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimpleDEX
 * @dev A simple decentralized exchange to swap between two ERC-20 tokens.
 * This version is updated to match specific function signatures.
 */
contract SimpleDEX is ReentrancyGuard {
    // --- State Variables ---

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    mapping(address => uint256) public lpShares;
    uint256 public totalLPShares;

    // --- Events ---

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event TokensSwapped(address indexed user, address indexed tokenFrom, address indexed tokenTo, uint256 amountIn, uint256 amountOut);

    // --- Errors ---

    error InvalidTokens();
    error ZeroAmount();
    error InsufficientLiquidity();
    error InvalidLiquidityAmount();
    error InsufficientOutputAmount();

    // --- Constructor ---

    constructor(address _tokenA, address _tokenB) {
        if (_tokenA == _tokenB || _tokenA == address(0) || _tokenB == address(0)) {
            revert InvalidTokens();
        }
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // --- Liquidity Functions ---

    /**
     * @notice Adds liquidity to the DEX pool.
     */
    function addLiquidity(uint256 _amountA, uint256 _amountB) external nonReentrant returns (uint256 shares) {
        if (_amountA == 0 || _amountB == 0) revert ZeroAmount();

        if (totalLPShares > 0) {
            uint256 requiredB = (_amountA * reserveB) / reserveA;
            if (_amountB < requiredB) revert InvalidLiquidityAmount();
        }

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        if (totalLPShares == 0) {
            shares = _sqrt(_amountA * _amountB);
        } else {
            shares = (_amountA * totalLPShares) / reserveA;
        }
        if (shares == 0) revert InsufficientLiquidity();

        lpShares[msg.sender] += shares;
        totalLPShares += shares;
        reserveA += _amountA;
        reserveB += _amountB;

        emit LiquidityAdded(msg.sender, _amountA, _amountB, shares);
    }

    /**
     * @notice Removes liquidity from the pool by burning LP shares.
     * @param _shares The amount of LP shares to burn.
     */
    function removeLiquidity(uint256 _shares) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        if (_shares == 0 || _shares > lpShares[msg.sender]) revert InvalidLiquidityAmount();

        amountA = (_shares * reserveA) / totalLPShares;
        amountB = (_shares * reserveB) / totalLPShares;
        if (amountA == 0 || amountB == 0) revert InsufficientLiquidity();

        lpShares[msg.sender] -= _shares;
        totalLPShares -= _shares;
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, _shares);
    }

    // --- Swap Functions ---

    /**
     * @notice Swaps an exact amount of Token A for Token B.
     */
    function swapAforB(uint256 _amountIn) external nonReentrant returns (uint256 amountOut) {
        return _swap(_amountIn, address(tokenA), address(tokenB));
    }

    /**
     * @notice Swaps an exact amount of Token B for Token A.
     */
    function swapBforA(uint256 _amountIn) external nonReentrant returns (uint256 amountOut) {
        return _swap(_amountIn, address(tokenB), address(tokenA));
    }

    // --- View Functions ---

    /**
     * @notice Calculates the current price of one token in terms of the other.
     * @dev Returns how many units of the other token you would get for 1 unit of `_token`.
     * Note: This is the instantaneous price and doesn't account for slippage.
     * @param _token The address of the token to get the price of.
     */
    function getPrice(address _token) public view returns (uint256) {
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        
        if (_token == address(tokenA)) {
            // Price of A in terms of B
            return (reserveB * 1e18) / reserveA;
        } else if (_token == address(tokenB)) {
            // Price of B in terms of A
            return (reserveA * 1e18) / reserveB;
        } else {
            revert InvalidTokens();
        }
    }

    // --- Internal Functions ---

    /**
     * @dev Internal function to handle the core swap logic.
     */
    function _swap(uint256 _amountIn, address _tokenFrom, address _tokenTo) internal returns (uint256 amountOut) {
        if (_amountIn == 0) revert ZeroAmount();
        if (totalLPShares == 0) revert InsufficientLiquidity();

        uint256 reserveIn;
        uint256 reserveOut;

        if (_tokenFrom == address(tokenA)) {
            reserveIn = reserveA;
            reserveOut = reserveB;
        } else {
            reserveIn = reserveB;
            reserveOut = reserveA;
        }

        IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountIn);

        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
        if (amountOut == 0) revert InsufficientOutputAmount();

        if (_tokenFrom == address(tokenA)) {
            reserveA += _amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += _amountIn;
            reserveA -= amountOut;
        }

        IERC20(_tokenTo).transfer(msg.sender, amountOut);

        emit TokensSwapped(msg.sender, _tokenFrom, _tokenTo, _amountIn, amountOut);
    }
    
    /**
     * @dev Internal function to calculate the square root of a number.
     */
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
