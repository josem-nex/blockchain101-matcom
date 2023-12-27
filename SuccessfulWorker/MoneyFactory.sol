// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ScoreTracker.sol";


interface IMoneyMaker {
    function makeMoney() external;
}

contract MoneyFactory {
    using Clones for address;

    event SuccessfulWorkerDetected(address worker);

    address immutable model;
    address immutable vault;
    address immutable tracker;

    mapping(address => bool) public successfulWorkers;

    uint256 workSession;

    constructor(address workModel, address scoreTracker) {
        model = workModel;
        vault = msg.sender;
        tracker = scoreTracker;
    }
    
    function mine(bytes32 mineSection) external {
        workSession += 1;

        address worker = msg.sender;
        IMoneyMaker maker = IMoneyMaker(model.cloneDeterministic(keccak256(abi.encode(worker, mineSection))));

        uint256 currentBalance = address(this).balance;
        require(worker.balance == 0, "Not broke worker");
        maker.makeMoney();
        uint256 workResult = address(this).balance - currentBalance;
        require(workResult >= 0.1 ether, "Not productive worker");

        if(workSession > 1) {
            successfulWorkers[tx.origin] = true;
            emit SuccessfulWorkerDetected(tx.origin);

            ScoreTracker(tracker).addScore(tx.origin);
        }
        
        // Split earnings
        payable(vault).transfer(0.05 ether);
        (bool success, ) = worker.call{value: workResult - 0.05 ether}("");
        require(success, "Worker refused the money");
        
        workSession -= 1;
    }

    receive() external payable {}

    function clean() external {
        payable(vault).transfer(address(this).balance);
    }
}