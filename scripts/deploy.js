const hre = require("hardhat");

async function deploy(contractName, signer, ...args) {
    const Factory = await ethers.getContractFactory(contractName, signer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

async function main() {
    const SEASON_1_URI = "https://mayors_1.io";

    const LOOTBOXES_CAP = 30000;
    const LOOTBOXES_PER_ADDRESS = 3;
    const NUMBER_IN_LOOTBOXES = 3;
    const PRICE = 100;

    const MERKLE_ROOT = "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80";
    // Addresses in merkle tree:
    // 0x625CbEf3fF81710766fAC05309a20D1E3F7d50f4
    // 0x1D29fF4568E9343C64ab4DFe81eD1655c6004DF8
    // 0x6F8C28c9A1a8FEf299Cd8dD86aD151891488bC61
    // 0xbAEc9cef35808591005f5C4AF960Cc879d120269


    const [admin] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);

    console.log("Account balance:", (await admin.getBalance()).toString());

    let token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
    let token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);
    console.log("Token 1:", token1.address);
    console.log("Token 2:", token2.address);

    const rarityCalculator = await deploy("RarityCalculator", admin);
    console.log("Rarity calculator:", rarityCalculator.address);
    let nft = await deploy(
        "NFT",
        admin,
        "Mayors",
        "MRS",
        admin.address
    );
    console.log("NFT:", nft.address);
    let lootbox = await deploy(
        "Lootbox",
        admin,
        "Lootboxes",
        "LBS",
        "",
        admin.address
    );
    console.log("Lootbox:", lootbox.address);
    let marketplace = await deploy(
        "Marketplace",
        admin,
        [
            lootbox.address,
            nft.address,
            token1.address,
            token2.address,
            admin.address,
            PRICE,
            LOOTBOXES_PER_ADDRESS,
            MERKLE_ROOT
        ],
        LOOTBOXES_CAP,
        SEASON_1_URI,
        admin.address
    );
    console.log("Marketplace:", marketplace.address);

    await lootbox.connect(admin).updateConfig(
        [
            NUMBER_IN_LOOTBOXES,
            marketplace.address,
            nft.address
        ]
    );
    await nft.connect(admin).updateConfig(
        [
            lootbox.address,
            admin.address,
            rarityCalculator.address
        ]
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
