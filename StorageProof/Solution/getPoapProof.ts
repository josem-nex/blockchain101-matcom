import * as ethers from 'ethers';
import fs from 'fs';

async function getProofs() {

    // Creates a new JSON-RPC provider to interact with the Ethereum network.
    const provider = new ethers.JsonRpcProvider('https://rpc.gnosischain.com/'); 
    // Defines wallet address.
    let address = '0xdC10FEDf9B41C1496f4217521250756C8FBbBc0C';
    // Defines the POAP contract address.
    const addrPOAP = '0x22C1f6050E56d2876009903609a2cC3fEf83B415';
    // Defines the ERC721 contract ABI interface.
    const erc721ABI = [
        "function balanceOf(address _owner) external view returns (uint256)",
        "function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)"
    ];
    // Creates a new contract instance with the POAP contract address and ABI.
    let poapCABITransf = new ethers.Contract(addrPOAP, erc721ABI, provider);
    // Creates a new ABI coder.
    let abiCoder = new ethers.AbiCoder();
    // Writes the address to a text file.
    fs.appendFileSync('output.txt','output, address: '+ address + '\n');
    // If the balanceOf and tokenOfOwnerByIndex functions exist in the contract...
    if (poapCABITransf.balanceOf && poapCABITransf.tokenOfOwnerByIndex) {
    // Gets the wallet balance.
    const balance = await poapCABITransf.balanceOf(address);
        // For each token in the balance...
        for (let index = 0; index < balance; index++) {
            console.log("New token.");
            // Gets the token at the specified index.
            const element = await poapCABITransf.tokenOfOwnerByIndex(address, index);
            fs.appendFileSync('output.txt', "----------------------NEW TOKEN -------------------------------\n");
            fs.appendFileSync('output.txt', element + ':\n');
            // Calculates the owner and event slots.
            const slotOwn = ethers.keccak256(abiCoder.encode(['uint256', 'uint256'], [element, 102]));
            const slotEvent = ethers.keccak256(abiCoder.encode(['uint256', 'uint256'], [element, 317]));
            // Gets the owner proof.
            let resultowner = await provider.send('eth_getProof', [addrPOAP,[slotOwn],31476953]);
            fs.appendFileSync('output.txt', "OWNER---------------------------\n");
            fs.appendFileSync('output.txt', (resultowner.storageProof[0].proof) + "\n");
            // Gets the event proof.
            let resultevent = await provider.send('eth_getProof', [addrPOAP,[slotEvent],31476953]);
            fs.appendFileSync('output.txt', "EVENT---------------------------\n");
            fs.appendFileSync('output.txt', (resultevent.storageProof[0].proof) + "\n");
        }
    }

}
getProofs();

