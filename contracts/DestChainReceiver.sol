// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./LiquidityPool.sol";

contract DestChainReceiver is CCIPReceiver {
    LiquidityPool private immutable i_liquidityPool;

    event MessageReceived( // The unique ID of the message.
        // The chain selector of the source chain.
        // The address of the sender from the source chain.
        // The text that was received.
    bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);

    bytes32 private lastReceivedMessageId;
    string private lastReceivedText;

    constructor(address router, address liquidityPoolAddress) CCIPReceiver(router) {
        i_liquidityPool = LiquidityPool(liquidityPoolAddress);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        (bool success,) = address(i_liquidityPool).call(any2EvmMessage.data);
        require(success);
    }

    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, string memory text) {
        return (lastReceivedMessageId, lastReceivedText);
    }
}
