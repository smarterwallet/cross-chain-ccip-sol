// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./LiquidityPool.sol";

error DestChainReceiver__TransactionFailed();

contract DestChainReceiver is CCIPReceiver {
    event CallData(bytes indexed data);

    LiquidityPool private immutable i_liquidityPool;

    constructor(address router, address liquidityPoolAddress) CCIPReceiver(router) {
        i_liquidityPool = LiquidityPool(liquidityPoolAddress);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        (bool success,) = address(i_liquidityPool).call(any2EvmMessage.data);
        require(success);
        emit CallData(any2EvmMessage.data);
    }
}
