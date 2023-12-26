// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./RLPReader.sol";
import "./ScoreTracker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

interface LinkTokenUtils {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function transferAndCall(address to, uint256 amount, bytes memory data) external;
    function approve(address spender, uint256 amount) external;
}

contract StorageProofVerifier is Ownable, FunctionsClient {
    using RLPReader for RLPReader.RLPItem;
    using FunctionsRequest for FunctionsRequest.Request;

    address immutable scoreTracker;
    address immutable linkToken = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    uint64 immutable subscriptionId = uint64(1800);
    bytes32 immutable donId = bytes32(0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000);

    bytes32 public storageHash; 
    mapping(uint256 => bool) public usedIds;
    mapping(bytes => bool) public validEvents;
    address public gelatoKeeper;
    bytes32 public lastRequestId;
    string public getStorageHashCode;
    mapping(address => bool) public hashUpdater;


    event HashUpdated(bytes32 storageHash, uint256 gnosisBlock);
    event StorageHashUpdateRequested();
    event EventAdded(bytes eventId);

    constructor(address tracker, address router) Ownable(msg.sender) FunctionsClient(router) {
        scoreTracker = tracker;
    }

    function setGelato(address gelato) external onlyOwner {
        gelatoKeeper = gelato;
    }

    function setCode(string memory code) external onlyOwner {
        getStorageHashCode = code;
    }

    function setValidEvent(bytes memory eventId) external onlyOwner {
        validEvents[eventId] = true;
        emit EventAdded(eventId);
    }

    function setStorageHash(bytes32 hash, uint256 gnosisBlock) external onlyOwner {
        _setStorageHash(hash, gnosisBlock);
    }

    function _setStorageHash(bytes32 hash, uint256 gnosisBlock) internal {
        storageHash = hash;
        emit HashUpdated(hash, gnosisBlock);
    }

    function requestStorageHashUpdate() external {
        address student = ScoreTracker(scoreTracker).mainWallet(msg.sender);

        // check that the requestor is allowed
        require((msg.sender == owner()) || (student != address(0)), "Not a student request");

        // emit event for Gelato to detect the request
        emit StorageHashUpdateRequested();

        // do request with chainlink for redundancy
        LinkTokenUtils(linkToken).transferFrom(msg.sender, address(this), 1 ether);
        LinkTokenUtils(linkToken).transferAndCall(address(i_router), 1 ether, abi.encode(subscriptionId));

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(getStorageHashCode);
        
        lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            uint32(300000),
            donId
        );

        if(!hashUpdater[student]) {
            hashUpdater[student] = true;
            ScoreTracker(scoreTracker).addScore(student);
        }
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        require(lastRequestId == requestId, "Unexpected RequestID");
        require(err.length == 0, "Unexpected Failure: ");
        
        (bytes32 hash, uint256 blockNumber) = abi.decode(response, (bytes32, uint256));
        _setStorageHash(hash, blockNumber);
    }

    function submitStorageHash(bytes32 hash, uint256 gnosisBlock) external {
        require(msg.sender == gelatoKeeper, "Not expected gelato");
        _setStorageHash(hash, gnosisBlock);
    }

    function verifyKey(bytes32 expected, bytes memory value) internal pure {
        require(value.length == 32, "Bad branch key length");
        for(uint i = 0; i < 32; ++i)
            require(value[i] == expected[i], "Bad branch");
    }

    function verify(uint256 slot, bytes[] calldata proof) public view returns (bytes memory value) {
        bytes32 path = keccak256(abi.encode(slot));

        require(proof.length > 0, "Empty proof");
        require(keccak256(proof[0]) == storageHash, "Mismatching storage hash");

        uint i = 0; // path ptr
        uint p = 0; // proof ptr
        RLPReader.RLPItem[] memory current;
        for(; i < 64; ++p) {
            uint8 curByte = uint8(path[i / 2]);
            uint8 nibbleI = i & 1 == 0? curByte / 16 : curByte % 16;

            current = RLPReader.toRlpItem(proof[p]).toList();

            if(current.length == 17) {
                // branch
                verifyKey(keccak256(proof[p + 1]), current[nibbleI].toBytes());
                ++i;
            }
            else {
                require(current.length == 2, "Bad proof");

                bytes memory nodeType = current[0].toBytes();
                uint8 nibbleJ = uint8(nodeType[0]) / 16;


                if(nibbleJ <= 1) {
                    // extension
                    require(current[1].rlpBytesKeccak256() == keccak256(proof[p + 1]), "Bad extension key");
                }
                else {
                    // leaf
                    require(nibbleJ <= 3, "Bad nibble");

                    (current[1].memPtr, current[1].len) = current[1].payloadLocation();
                    (current[1].memPtr, current[1].len) = current[1].payloadLocation();

                    value = current[1].toRlpBytes();
                }

                uint j = 1;

                if(nibbleJ & 1 == 0) ++j;

                for(; j / 2 < nodeType.length;) {
                    curByte = uint8(path[i / 2]);
                    nibbleI = i & 1 == 0? curByte / 16 : curByte % 16;

                    uint8 curByteJ = uint8(nodeType[j / 2]);
                    nibbleJ = j & 1 == 0? curByteJ / 16 : curByteJ % 16;

                    require(nibbleI == nibbleJ, "Bad encodedPath");

                    // updates
                    ++j; ++i;
                }
            }
        }
    }

    function verifyPoapOwnership(uint256 id, bytes[] calldata ownerProof, bytes[] calldata eventProof) external {        
        uint256 slot = uint256(keccak256(abi.encode(id, uint256(102))));
        address owner = address(uint160(bytes20(verify(slot, ownerProof))));
        require(owner == msg.sender, "Wrong owner");

        slot = uint256(keccak256(abi.encode(id, uint256(317))));
        require(validEvents[verify(slot, eventProof)], "Wrong event");

        ScoreTracker(scoreTracker).poapClaimed(owner, id);
    }

    function verifyPoapOwnership(address addr, uint256 id, bytes[] calldata ownerProof, bytes[] calldata eventProof) external {        
        require(ScoreTracker(scoreTracker).mainWallet(addr) == msg.sender, "Not an associated wallet");

        uint256 slot = uint256(keccak256(abi.encode(id, uint256(102))));
        address poapOwner = address(uint160(bytes20(verify(slot, ownerProof))));
        require(poapOwner == addr, "Wrong owner");

        slot = uint256(keccak256(abi.encode(id, uint256(317))));
        require(validEvents[verify(slot, eventProof)], "Wrong event");

        ScoreTracker(scoreTracker).poapClaimed(poapOwner, id);
    }
}