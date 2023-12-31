// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MoneyFactory {
    function mine(bytes32 mineSection) external {}
    }
contract successfulWorker is Ownable{
    bool receiveActive = false;
    using Clones for address;
    bytes32 mineSection = keccak256(abi.encode(msg.sender, block.timestamp));
    MoneyFactory mf;
    address makeMoney = address(0x12B47058Dee1B24C06501df2a128D43Af9Bb9831);
    address moneyFact = address(0xCd92435512f7AD66A210c641416a4D91369c3cBd);

    constructor() Ownable(msg.sender){}
    function activateReceive() public onlyOwner{
        receiveActive = true;
    }
    function desactiveReceive() public onlyOwner{
        receiveActive = false;
    }
    function worker() public onlyOwner{
        bytes32 salt = keccak256(abi.encode(address(this), mineSection));
        address cloneAddress = makeMoney.predictDeterministicAddress(salt, moneyFact);
        payable(cloneAddress).transfer(address(this).balance);

        mf = MoneyFactory(moneyFact);
        mf.mine(mineSection);
    }
    receive() external payable {
        if(receiveActive){
            receiveActive = false;
            mineSection = keccak256(abi.encode(address(this), block.timestamp));
            bytes32 salt = keccak256(abi.encode(address(this), mineSection));
            address cloneAddress = makeMoney.predictDeterministicAddress(salt, moneyFact);
            payable(cloneAddress).transfer(address(this).balance);
            mf.mine(mineSection);
        }
    }
}
