const { ethers } = require("hardhat");

const MAYORS_NAME = "Mayors"
const MAYORS_SYMBOL = "MRS"
const MAYORS_BASE_URI = "https://mayors.mypinata.cloud/ipfs";

const LOOTBOXES_NAME = "Limousine"
const LOOTBOXES_SYMBOL = "LIMO"
const LOOTBOXES_BASE_URI = "http://www.lootbox.json"

const VOTE_TOKEN_NAME = "Votes token"
const VOTE_TOKEN_SYMBOL = "Vote$"


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

async function deployMarketplace(admin, nftAddress, lootboxAddress, token1Address, voteAddress) {
    return await deploy(
        "Marketplace",
        admin,
        [
            lootboxAddress,
            nftAddress,
            token1Address,
            voteAddress,
            admin.address,
        ],
        admin.address
    );
}

async function deployVoteToken(admin) {
    return await deploy(
        "Vote",
        admin,
        VOTE_TOKEN_NAME,
        VOTE_TOKEN_SYMBOL,
        admin.address,
    );
}

const ADMIN_MINT = 300;

const SEASON_1_URI = "season_uri_1";

const MERKLE_ROOT = "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80";

const LOOTBOXES_NUMBER = 30000;
const LOOTBOXES_PER_ADDRESS = 3;
const NUMBER_IN_LOOTBOXES = 3;
const LOOTBOX_PRICE = 100;
const LOOTBOXES_UNLOCK_TIMESTAMP = 0;
const SEASON_IS_PUBLIC = true;

async function testData(marketplace, lootboxAddress, nftAddress, voteTokenAddress) {
    const [admin] = await ethers.getSigners();

    let token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
    console.log("Token 1:", token1.address);

    await marketplace.connect(admin).updateConfig(
        [
            lootboxAddress,
            nftAddress,
            token1.address,
            voteTokenAddress,
            admin.address,
        ],
    )

    let seasonId = 0;
    let startTimestamp = 0;
    let endTimestamp = 1751570550;
    let nftStartIndex = 0;
    const season1 = [
        startTimestamp,
        endTimestamp,
        LOOTBOXES_NUMBER,
        LOOTBOX_PRICE,
        LOOTBOXES_PER_ADDRESS,
        LOOTBOXES_UNLOCK_TIMESTAMP,
        NUMBER_IN_LOOTBOXES,
        nftStartIndex,
        MERKLE_ROOT,
        SEASON_IS_PUBLIC,
        SEASON_1_URI,
    ]
    await marketplace.connect(admin).addNewSeasons([season1]);
    console.log("New season:");
    console.log("--- season0.startTimestamp: ", startTimestamp);
    console.log("--- season0.endTimestamp: ", endTimestamp);
    console.log("--- season0.lootboxesNumber: ", LOOTBOXES_NUMBER);
    console.log("--- season0.lootboxPrice: ", LOOTBOX_PRICE);
    console.log("--- season0.lootboxesPerAddress: ", LOOTBOXES_PER_ADDRESS);
    console.log("--- season0.lootboxesUnlockTimestamp: ", LOOTBOXES_UNLOCK_TIMESTAMP);
    console.log("--- season0.nftNumberInLootbox: ", NUMBER_IN_LOOTBOXES);
    console.log("--- season0.nftStartIndex: ", nftStartIndex);
    console.log("--- season0.merkleRoot: ", MERKLE_ROOT);
    console.log("--- season0.isPublic: ", SEASON_IS_PUBLIC);
    console.log("--- season0.uri: ", SEASON_1_URI);

    await token1.connect(admin).mint(admin.address, ADMIN_MINT);
    await marketplace.connect(admin).addToWhiteList(seasonId, [admin.address]);

    // admin buys a lootbox
    await token1.connect(admin).approve(marketplace.address, LOOTBOX_PRICE);
    await marketplace.connect(admin).buyLootbox(seasonId);

    await token1.connect(admin).approve(marketplace.address, LOOTBOX_PRICE);
    await marketplace.connect(admin).buyLootbox(seasonId);

    await token1.connect(admin).approve(marketplace.address, LOOTBOX_PRICE);
    await marketplace.connect(admin).buyLootbox(seasonId);
}

async function main() {
    // token1 - BUSD, token2 - Vote$
    let token1Address = "0x831EaB9ea77c339FFfE770140Bba8b7633C9Ca66";
    let rarityCalculatorAddress = "0xe47d896Cde01be4864eFdB0F91cF9ABB839978aE";

    let nftAddress;
    let lootboxAddress;
    let marketplaceAddress;
    let voteTokenAddress;

    const [admin] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    let voteToken = await deployVoteToken(admin);
    voteTokenAddress = voteToken.address;

    console.log("Token 1(BUSD):", token1Address);
    console.log("Token 2(Vote$):", voteTokenAddress);
    console.log("Rarity calculator:", rarityCalculatorAddress);

    let nft = await deployNFT(admin);
    nftAddress = nft.address;
    console.log("NFT:", nftAddress);

    let lootbox = await deployLootbox(admin);
    lootboxAddress = lootbox.address;
    console.log("Lootbox:", lootboxAddress);

    let marketplace = await deployMarketplace(admin, nftAddress, lootboxAddress, token1Address, voteTokenAddress);
    marketplaceAddress = marketplace.address;
    console.log("Marketplace:", marketplaceAddress);

    await lootbox.connect(admin).updateConfig(
        [
            marketplaceAddress,
            nftAddress,
        ],
        LOOTBOXES_BASE_URI,
    )
    await nft.connect(admin).updateConfig(
        [
            lootboxAddress,
            rarityCalculatorAddress,
        ]
    )

    // test data
    await testData(marketplace, lootboxAddress, nftAddress, voteTokenAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });