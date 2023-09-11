// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**** chainlink VRF imports */
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

//Custom errors
error Lottery__NotEnoughEtherSupplied();
error Lottery__TransferFailed();
error Lottery__NotOpen();

contract LotteryContract is VRFConsumerBaseV2, AutomationCompatibleInterface {
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /*  State variables */
    uint256 private immutable i_entryFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_chainlinkVrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    address payable private lotteryWinner;
    LotteryState private s_lotteryState;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /* Events */
    event EnterLottery(address indexed player);
    event requestedLotteryWinner(uint256 indexed requestId);
    event LotteryWinnerPicked(address payable winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 _entryFee,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entryFee = _entryFee;
        i_chainlinkVrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    //Enter Lottery
    function enterLottery() public payable {
        uint256 enteredAmount = msg.value;
        if (enteredAmount < i_entryFee) {
            revert Lottery__NotEnoughEtherSupplied();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }

        s_players.push(payable(msg.sender));
        /* Emit the event when a new player is added */
        emit EnterLottery(msg.sender);
    }

    /**
     *
     * @dev checkData, is an encoded binary data and which contains the lower bound and upper bound on which to perform the computation
     *
     * @return upkeepNeeded
     * @return performData
     * new random number will be requested if
     * lottery is open
     * atleast one player
     * time passsed is bigger than interval
     * contract should have money
     *
     */
    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool isOpen = (s_lotteryState == LotteryState.OPEN);
        bool hasPlayers = s_players.length > 0;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool contractHasMoney = address(this).balance > 0;
        upkeepNeeded = (isOpen && hasPlayers && timePassed && contractHasMoney);
    }

    function performUpkeep(bytes calldata performData) external override {}

    /**
     * this function request the random number to decide the lottery winner
     */
    function requestRandomWinner() external {
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_chainlinkVrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit requestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*_requestId */,
        uint256[] memory _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        lotteryWinner = winner;

        //Reset the lottery
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = lotteryWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit LotteryWinnerPicked(winner);
    }

    //returns entry fee
    function getLotteryEntryfee() public view returns (uint256) {
        return i_entryFee;
    }

    //return player at a given index

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }
}
