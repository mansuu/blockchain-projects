// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**** chainlink VRF imports */
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//Custom errors
error Lottery__NotEnoughEtherSupplied();

contract LotteryContract is VRFConsumerBaseV2 {
    /*  State variables */
    uint256 private immutable i_entryFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_chainlinkVrfCoordinator;

    /* Events */
    event EnterLottery(address indexed player);

    constructor(address vrfCoordinatorV2, uint256 _entryFee) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entryFee = _entryFee;
        i_chainlinkVrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    }

    //Enter Lottery
    function enterLottery() public payable {
        uint256 enteredAmount = msg.value;
        if (enteredAmount < i_entryFee) {
            revert Lottery__NotEnoughEtherSupplied();
        }

        s_players.push(payable(msg.sender));
        /* Emit the event when a new player is added */
        emit EnterLottery(msg.sender);
    }

    function requestRandomWinner() external {}

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {}

    //returns entry fee
    function getLotteryEntryfee() public view returns (uint256) {
        return i_entryFee;
    }

    //return player at a given index

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }
}
