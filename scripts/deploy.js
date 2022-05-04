const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");

const MAYORS_NAME = "Mayors"
const MAYORS_SYMBOL = "MRS"
const MAYORS_BASE_URI = "https://mayors.mypinata.cloud/ipfs";


const LOOTBOXES_NAME = "Lootboxes"
const LOOTBOXES_SYMBOL = "LBS"
const LOOTBOXES_BASE_URI = "http://www.lootbox.json"


async function deploy(contractName, signer, ...args) {
    const Factory = await ethers.getContractFactory(contractName, signer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

async function deployNFT(admin) {
    return await deploy(
        "NFT",
        admin,
        MAYORS_NAME,
        MAYORS_SYMBOL,
        MAYORS_BASE_URI,
        admin.address
    );
}

async function deployLootbox(admin) {
    return await deploy(
        "Lootbox",
        admin,
        LOOTBOXES_NAME,
        LOOTBOXES_SYMBOL,
        admin.address
    );
}

async function deployMarketplace(admin, nftAddress, lootboxAddress, token1Address, token2Address) {
    return await deploy(
        "Marketplace",
        admin,
        [
            lootboxAddress,
            nftAddress,
            token1Address,
            token2Address,
            admin.address,
        ],
        admin.address
    );
}

async function main() {
    const [admin] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    const token1Address = "0x1E66e23920C4D0fd2B8102804D7E5b2Cc5Bfb10A"
    const token2Address = "0xF79660f21C004C31683f248b91C357cfe5833ACE"
    console.log("Token 1:", token1Address);
    console.log("Token 2:", token2Address);

    const rarityCalculatorAddress = "0x716Af5C2FE11d8C23eD2f2a8F2f89082a8254281";
    console.log("Rarity calculator:", rarityCalculatorAddress);

    let nft = await deployNFT(admin);
    const nftAddress = nft.address;
    console.log("NFT:", nftAddress);

    let lootbox = await deployLootbox(admin);
    const lootboxAddress = lootbox.address;
    console.log("Lootbox:", lootboxAddress);

    let marketplace = await deployMarketplace(admin, nftAddress, lootboxAddress, token1Address, token2Address);
    const marketplaceAddress = marketplace.address;
    console.log("Marketplace:", marketplaceAddress);

    await lootbox.connect(admin).updateConfig(
        [
            marketplaceAddress,
            nftAddress,
        ],
        LOOTBOXES_BASE_URI,
    );

    await nft.connect(admin).updateConfig(
        [
            lootboxAddress,
            admin.address,
            rarityCalculatorAddress,
        ]
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
