// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ScoreTracker is Ownable, Initializable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // from tracker
    mapping(address => uint256) score;
    mapping(address => bool) public scoreEditor;
    mapping(address => address) public mainWallet;

    address[] public rootWallet;

    bytes32 public studentsMerkleRoot;

    mapping(address => uint256) public poapCount;
    mapping(uint256 => bool) public claimedPoap;

    event ScoreAdded(address receiver, uint256 score, address editor);
    event ScoreAddedManually(address receiver, uint256 score);
    event NewScoreEditor(address editor);
    event NewStudentAdded(address student);
    event NewWalletAdded(address student, address newWallet);
    event NewWalletAddedManually(address student, address newWallet);
    event PoapClaimed(address student, uint256 poapId);

    constructor() Ownable(msg.sender) {}

    modifier onlyScoreEditor() {
        require(scoreEditor[msg.sender], "Not an editor");
        _;
    }

    function getStudents() external view returns (address[] memory) {
        return rootWallet;
    }
    
    function initialize() public onlyOwner initializer {
        scoreEditor[msg.sender] = true;
        scoreEditor[address(this)] = true;
    }
    
    function addScoreEditor(address editor) external onlyScoreEditor {
        scoreEditor[editor] = true;
        emit NewScoreEditor(editor);
    }

    function addScore(address student) public onlyScoreEditor {
        student = mainWallet[student];
        if(mainWallet[student] != address(0)) {
            score[student] += block.number;
            emit ScoreAdded(student, block.number, msg.sender);
        }
    }

    function addScore(address student, uint256 value) external onlyOwner {
        student = mainWallet[student];
        unchecked {
            score[student] += value;
        }

        emit ScoreAddedManually(student, value);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        studentsMerkleRoot = merkleRoot;
    }

    function registerStudent(bytes32[] calldata proof) external {
        require(mainWallet[msg.sender] == address(0), "Already registered");

        bytes32 leaf = keccak256(abi.encode(msg.sender));

        require(
            MerkleProof.verify(proof, studentsMerkleRoot, leaf),
            "Invalid proof provided"
        );
        
        mainWallet[msg.sender] = msg.sender;
        rootWallet.push(msg.sender);
        emit NewStudentAdded(msg.sender);

        // Set intial score
        this.addScore(msg.sender);
    }

    function addWallet(address student, uint256 expiry, bytes memory signature) external {
        require(student != address(0), "Invalid student");
        require(mainWallet[student] == student, "Not a known student");
        require(mainWallet[msg.sender] == address(0), "Already added");
        require(expiry > block.timestamp, "Signature expired");

        // Check signature
        bytes32 hashedMessage = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, expiry));
        address signer = hashedMessage.toEthSignedMessageHash().recover(signature);
        require(signer == student, "Wrong signer");

        mainWallet[msg.sender] = student;
        emit NewWalletAdded(student, msg.sender);
    }

    function addWallet(address student, address newWallet) external onlyOwner {
        require(student != address(0), "Invalid student");
        require(mainWallet[student] == student, "Not a known student");
        require(mainWallet[newWallet] == address(0), "Already added");

        mainWallet[newWallet] = student;
        emit NewWalletAddedManually(student, newWallet);
    }

    function scoreOf(address student) public view returns (uint256) {
        return score[mainWallet[student]];
    }

    function claimSignatureChallenge() external {
        address student = mainWallet[msg.sender];
        require(student != address(0), "Not a student");
        require(student != msg.sender, "Not a secondary wallet");

        this.addScore(student);
    }

    function poapClaimed(address owner, uint256 poapId) external onlyScoreEditor {
        address student = mainWallet[owner];
        require(student != address(0), "Uknown student");
        require(!claimedPoap[poapId], "Poap already claimed");

        ++poapCount[student];
        claimedPoap[poapId] = true;
        emit PoapClaimed(student, poapId);
    }
}