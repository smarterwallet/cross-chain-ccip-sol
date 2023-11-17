// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {console} from "hardhat/console.sol";

/**
 * @title A sample Liquidity Pool
 * @author David Zhang
 * @notice Implement the function of cross-chain tokens on the destination chain
 */
contract LiquidityPool is ReentrancyGuard, Ownable {
    /* Type declarations */
    IERC20 private immutable i_token;

    /* State variables */
    mapping(address => uint256) private balances;

    /* Events */
    event TokenInPut(address indexed sender, uint256 indexed amount);
    event TokenOutPut(address indexed to, uint256 indexed amount);

    /* Errors */
    error LiquidityPool__TransferFailed();
    error LiquidityPool__NeedSendMore();
    error LiquidityPool__InsufficientBalance();

    constructor(address tokenAddress) Ownable(msg.sender) {
        i_token = IERC20(tokenAddress);
    }

    /* External / Public Functions */
    function depositToken(uint256 amount) public {
        if (amount == 0) {
            revert LiquidityPool__NeedSendMore();
        }
        bool success = i_token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert LiquidityPool__TransferFailed();
        }
        balances[msg.sender] += amount;
        emit TokenInPut(msg.sender, amount);
    }

    function withdrawToken(address to, uint256 amount) external onlyOwner nonReentrant {
        if (i_token.balanceOf(address(this)) < amount) {
            revert LiquidityPool__InsufficientBalance();
        }
        i_token.transfer(to, amount);
        emit TokenOutPut(to, amount);
    }

    /* Getter Functions */
    function getPoolBalance() external view returns (uint256) {
        return i_token.balanceOf(address(this));
    }

    function getFunderBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getTokenAddress() public view returns (address) {
        return address(i_token);
    }

    /* fallback & receive */
    receive() external payable {}
    fallback() external payable {}
}
