// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MagicMoneyMaker {    
    function makeMoney() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}