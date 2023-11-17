// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SourceChainSender is OwnerIsCreator, ReentrancyGuard {
    /* Enums */
    enum payFeesIn {
        Native,
        LINK
    }

    /* Type declarations */
    IRouterClient private immutable i_router;
    LinkTokenInterface private immutable i_linkToken;
    IERC20 private immutable i_crossChainToken;
    mapping(address => uint256) private balances;

    /* Events */
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address feeToken,
        uint256 fees,
        address to,
        uint256 amount
    );
    event TokenInPut(address indexed sender, uint256 indexed amount);
    event OwnerWithdrawn(address indexed owner, uint256 indexed amount);
    event Withdrawn(address indexed owner, uint256 indexed amount);

    /* Errors */
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error SourceChainSender__NeedSendMore();
    error SourceChainSender__TransferFailed();
    error SourceChainSender__NeedFundToken();
    error SourceChainSender__InsufficientBalance();
    error SourceChainSender__Insufficient();
    error SourceChainSender__WithdrawFailed();

    constructor(address _router, address _link, address _crossChainToken) {
        i_router = IRouterClient(_router);
        i_linkToken = LinkTokenInterface(_link);
        i_crossChainToken = IERC20(_crossChainToken);
    }

    /* External / Public Functions */
    function fund(uint256 amount) public {
        if (amount < 0) {
            revert SourceChainSender__NeedSendMore();
        }
        bool success = i_crossChainToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert SourceChainSender__TransferFailed();
        }
        balances[msg.sender] += amount;
        emit TokenInPut(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        if (i_crossChainToken.balanceOf(msg.sender) < 0) {
            revert SourceChainSender__Insufficient();
        }
        balances[msg.sender] -= amount;
        bool success = i_crossChainToken.transfer(msg.sender, amount);
        if (!success) {
            revert SourceChainSender__WithdrawFailed();
        }
        emit Withdrawn(msg.sender, amount);
    }

    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        payFeesIn feeToken,
        address to,
        uint256 amount
    ) external returns (bytes32 messageId) {
        if (balances[msg.sender] < amount) {
            revert SourceChainSender__NeedFundToken();
        }
        bytes memory functionCall = abi.encodeWithSignature("withdrawToken(address,uint256)", to, amount);

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: functionCall,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})),
            feeToken: feeToken == payFeesIn.LINK ? address(i_linkToken) : address(0)
        });

        uint256 fees = i_router.getFee(destinationChainSelector, evm2AnyMessage);

        if (feeToken == payFeesIn.LINK) {
            if (fees > i_linkToken.balanceOf(address(this))) {
                revert NotEnoughBalance(i_linkToken.balanceOf(address(this)), fees);
            }

            i_linkToken.approve(address(i_router), fees);

            messageId = i_router.ccipSend(destinationChainSelector, evm2AnyMessage);
        } else {
            if (fees > address(this).balance) {
                revert("balance is not enough");
            }

            messageId = i_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);
        }

        emit MessageSent(messageId, destinationChainSelector, receiver, address(i_linkToken), fees, to, amount);

        return messageId;
    }

    function onlyOwnerWithdraw(uint256 amount) public onlyOwner nonReentrant {
        if (i_crossChainToken.balanceOf(address(this)) < 0) {
            revert SourceChainSender__InsufficientBalance();
        }
        i_crossChainToken.transfer(owner(), amount);
        emit OwnerWithdrawn(owner(), amount);
    }

    /* Getter Functions */
    function getPoolBalance() external view returns (uint256) {
        return i_crossChainToken.balanceOf(address(this));
    }

    function getFunderBalance(address funder) external view returns (uint256) {
        return balances[funder];
    }

    function getTokenAddress() public view returns (address) {
        return address(i_crossChainToken);
    }

    /* fallback & receive */
    receive() external payable {}
}
