// Prepare data for tests:
// 1) npx hardhat node
// 2) npx hardhat run scripts/lootbox-distribution/test-data.js --network localhost

// Launch distribution:
// 1) change PRIVATE_KEY in .env
// 2) change LOOTBOX_ADDRESS
// 3) fill the list of distribution
// 4) npx hardhat run scripts/lootbox-distribution/main.js --network localhost

const { ethers } = require("hardhat");

const LOOTBOX_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

// recipient's address => list of tokeIds
const distribution = {
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC": ["1"],
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906": ["0", "2"],
};

let contract;

async function distribute(owner, distribution) {
    console.log("Owner balance:", await contract.balanceOf(owner.address));

    for(let recipientAddress in distribution) {
        let tokenIds = distribution[recipientAddress];
        for (let i = 0; i < tokenIds.length; i++) {
            let tokenId = tokenIds[i];

            console.log("Transfer to: ", recipientAddress, " tokenId:", tokenId);
            let tx = await contract.transferFrom(owner.address, recipientAddress, tokenId);
            tx.wait();
        }
    }

    console.log("Owner balance:", await contract.balanceOf(owner.address));
}

async function main() {
    const [owner] = await ethers.getSigners();
    console.log('OWNER', owner.address);

    contract = await ethers.getContractAt('Lootbox', LOOTBOX_ADDRESS, owner);

    await distribute(owner, distribution);
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });