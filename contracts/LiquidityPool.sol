// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/* Errors */
error LiquidityPool__TransferFailed();

/**
 * @title A sample Liquidity Pool
 * @author David Zhang
 * @notice Implement the function of cross-chain tokens on the destination chain
 */
contract LiquidityPool {
    /* State variables */
    IERC20 private immutable i_token;
    mapping(address => uint256) private balances;

    /* Events */
    event TokenInPut(address indexed sender, uint256 indexed amount);

    /* Public / External Functions */
    constructor(address tokenAddress) {
        i_token = IERC20(tokenAddress);
    }

    function depositToken(uint256 amount) public {
        uint256 balanceBefore = i_token.balanceOf(address(this));
        bool success = i_token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert LiquidityPool__TransferFailed();
        }
        balances[msg.sender] += amount;
        require(i_token.balanceOf(address(this)) == balanceBefore + amount, "Transfer failed");
        emit TokenInPut(msg.sender, amount);
    }

    function withdrawToken(address to, uint256 amount) external {
        i_token.transfer(to, amount);
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
}
