// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract Sender is OwnerIsCreator {
    enum payFeesIn {
        Native,
        LINK
    }

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    event MessageSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address feeToken,
        uint256 fees
    );

    IRouterClient router;

    LinkTokenInterface linkToken;

    constructor(address _router, address _link) {
        router = IRouterClient(_router);
        linkToken = LinkTokenInterface(_link);
    }

    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        payFeesIn feeToken,
        address to,
        uint256 amount
    ) external returns (bytes32 messageId) {
        bytes memory functionCall = abi.encodeWithSignature("withdrawToken(address, uint256)", to, amount);

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: functionCall, // ABI-encoded btyes
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                ),
            // Set the feeToken  address, indicating LINK will be used for fees
            feeToken: feeToken == payFeesIn.LINK ? address(linkToken) : address(0)
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        if (feeToken == payFeesIn.LINK) {
            if (fees > linkToken.balanceOf(address(this))) {
                revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);
            }

            // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
            linkToken.approve(address(router), fees);

            // Send the message through the router and store the returned message ID
            messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);
        } else {
            if (fees > address(this).balance) {
                revert("balance is not enough");
            }

            messageId = router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);
        }

        // Emit an event with message details
        emit MessageSent(messageId, destinationChainSelector, receiver, address(linkToken), fees);

        // Return the message ID
        return messageId;
    }

    receive() external payable {}
}
