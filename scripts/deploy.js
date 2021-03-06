const { ethers } = require("hardhat");

const MAYORS_NAME = "Mayors"
const MAYORS_SYMBOL = "MRS"
const MAYORS_BASE_URI = "https://mayors.mypinata.cloud/ipfs";

const LOOTBOXES_NAME = "Limousine"
const LOOTBOXES_SYMBOL = "LIMO"
const LOOTBOXES_BASE_URI = "http://www.lootbox.json"

const VOTE_TOKEN_NAME = "Votes token"
const VOTE_TOKEN_SYMBOL = "Vote$"

const VOUCHER_TOKEN_NAME = "Voucher token"
const VOUCHER_TOKEN_SYMBOL = "BVoucher"

const VOTES_PER_CITIZEN = 100;


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

async function deployVoucherToken(admin, stakingAddress) {
    return await deploy(
        "Voucher",
        admin,
        VOUCHER_TOKEN_NAME,
        VOUCHER_TOKEN_SYMBOL,
        [
            stakingAddress,
        ],
        admin.address
    );
}

async function deployStaking(admin, voteTokenAddress, voucherTokenAddress) {
    return await deploy(
        "Staking",
        admin,
        [
            voteTokenAddress,
            voucherTokenAddress,
        ],
        admin.address
    );
}

async function deployThriftbox(admin, voteTokenAddress) {
    return await deploy(
        "Thriftbox",
        admin,
        [
            voteTokenAddress,
        ],
        admin.address,
    );
}

async function deployVoting(admin, nftAddress, voteTokenAddress, voucherTokenAddress, votesPerCitizen) {
    return await deploy(
        "Voting",
        admin,
        nftAddress,
        voteTokenAddress,
        voucherTokenAddress,
        votesPerCitizen,
        admin.address,
    );
}


async function main() {
    // Kovan
    // let token1Address = "0x1E66e23920C4D0fd2B8102804D7E5b2Cc5Bfb10A";
    // let token2Address = "0xF79660f21C004C31683f248b91C357cfe5833ACE";
    // let rarityCalculatorAddress = "0x716Af5C2FE11d8C23eD2f2a8F2f89082a8254281";

    // BSC Testnet
    // token1 - BUSD, token2 - Vote$
    let token1Address = "0x831EaB9ea77c339FFfE770140Bba8b7633C9Ca66";
    let rarityCalculatorAddress = "0xe47d896Cde01be4864eFdB0F91cF9ABB839978aE";

    // BSC mainnet
    // token1 - BUSD, token2 - Vote$
    // let token1Address = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
    // let rarityCalculatorAddress = "0x21d359be2283274ebc87216bf2a02f37a16a4d9d";

    let nftAddress;
    let lootboxAddress;
    let marketplaceAddress;
    let voteTokenAddress;
    let voucherTokenAddress;
    let stakingAddress;
    let votingAddress;

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

    let voucherToken = await deployVoucherToken(admin, ethers.constants.AddressZero);
    voucherTokenAddress = voucherToken.address;
    console.log("Voucher token:", voucherTokenAddress);

    let staking = await deployStaking(admin, voteTokenAddress, voucherTokenAddress);
    stakingAddress = staking.address;
    console.log("Staking:", stakingAddress);

    let voting = await deployVoting(admin, nftAddress, voteTokenAddress, voucherTokenAddress, VOTES_PER_CITIZEN);
    votingAddress = voting.address;
    console.log("Voting:", votingAddress);

    let thriftbox = await deployThriftbox(admin, voteTokenAddress);
    thriftboxAddress = thriftbox.address;
    console.log("Thriftbox:", thriftboxAddress);

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
    await voucherToken.connect(admin).updateConfig(
        [
            stakingAddress,
        ]
    )
    await voteToken.connect(admin).updateConfig(
        [
            votingAddress,
        ]
    )
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });