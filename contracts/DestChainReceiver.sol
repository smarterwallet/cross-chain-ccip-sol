// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./LiquidityPool.sol";

contract DestChainReceiver is CCIPReceiver {
    /* Type declarations */
    LiquidityPool private liquidityPool;

    /* Events */
    event CallData(bytes indexed data);

    /* External / Public Functions */
    constructor(address router, address liquidityPoolAddress) CCIPReceiver(router) {
        liquidityPool = LiquidityPool(payable(liquidityPoolAddress));
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        (bool success,) = address(liquidityPool).call(any2EvmMessage.data);
        require(success, "Transaction Failed");
    }
}
