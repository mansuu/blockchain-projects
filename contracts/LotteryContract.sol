// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Custom errors
error Lottery__NotEnoughEtherSupplied();

contract LotteryContract {
    uint256 private immutable i_entryFee;

    constructor(uint256 _entryFee) {
        i_entryFee = _entryFee;
    }

    //Enter Lottery
    function enterLottery() returns () {
        uint256 enteredAmount = msg.value;
        if (enteredAmount < i_entryFee) {
            revert Lottery__NotEnoughEtherSupplied();
        }
    }
}
