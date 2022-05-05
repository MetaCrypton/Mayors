const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");

async function deploy(contractName, signer, ...args) {
    const Factory = await ethers.getContractFactory(contractName, signer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

async function main() {
    const SEASON_1_URI = "https://mayors_1.io";
    const SEASON_2_URI = "https://mayors_2.io";

    const LOOTBOXES_BATCH = 1570;

    const LOOTBOXES_CAP = 30000;
    const LOOTBOXES_PER_ADDRESS = 3;
    const NUMBER_IN_LOOTBOXES = 3;
    const PRICE = 100;
    const ALICE_MINT = 100;
    const CHARLIE_MINT = 200;
    const RESALE_PRICE = CHARLIE_MINT;
    const RESALE_FEE = RESALE_PRICE / 100;
    const RESALE_INCOME = RESALE_PRICE - RESALE_FEE;
    const BOB_MINT = 10;

    const LOOTBOX_ID_0 = 0;
    const MAYOR_ID_0 = 0;

    const MERKLE_ROOT = "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80";
    // Addresses in merkle tree:
    // 0x625CbEf3fF81710766fAC05309a20D1E3F7d50f4
    // 0x1D29fF4568E9343C64ab4DFe81eD1655c6004DF8
    // 0x6F8C28c9A1a8FEf299Cd8dD86aD151891488bC61
    // 0xbAEc9cef35808591005f5C4AF960Cc879d120269

    const RARITIES = {
        common: 0,
        rare: 1,
        epic: 2,
        legendary: 3
    };


    const [admin, alice, bob, charlie] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);

    console.log("Accounts: ", admin.address, alice.address, bob.address, charlie.address);

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

    await token1.connect(admin).mint(alice.address, ALICE_MINT);
    await token1.connect(admin).mint(bob.address, BOB_MINT);
    await token2.connect(admin).mint(charlie.address, CHARLIE_MINT);

    await marketplace.connect(admin).addToWhiteList([alice.address, bob.address]);



    assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
    assert.equal(await token1.balanceOf(admin.address), 0);

    await token1.connect(alice).approve(marketplace.address, PRICE);
    await marketplace.connect(alice).buyLootbox();

    assert.equal(await token1.balanceOf(alice.address), 0);
    assert.equal(await token1.balanceOf(admin.address), PRICE);

    assert.equal(await token2.balanceOf(alice.address), 0);
    assert.equal(await token2.balanceOf(charlie.address), CHARLIE_MINT);
    assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), alice.address);

    await lootbox.connect(alice).approve(marketplace.address, LOOTBOX_ID_0);
    await marketplace.connect(alice).setItemForSale({addr: lootbox.address, tokenId: LOOTBOX_ID_0}, RESALE_PRICE);
    await token2.connect(charlie).approve(marketplace.address, RESALE_PRICE);
    await marketplace.connect(charlie).buyItem({addr: lootbox.address, tokenId: LOOTBOX_ID_0});

    assert.equal(await token2.balanceOf(alice.address), RESALE_INCOME);
    assert.equal(await token2.balanceOf(admin.address), RESALE_FEE);
    assert.equal(await token2.balanceOf(charlie.address), 0);
    assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), charlie.address);

    await lootbox.connect(charlie).reveal(0);

    for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
        assert.equal(await nft.ownerOf(i), charlie.address);
    }

    for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
        let rarity = await nft.getRarity(i);
        let hashrate = await nft.getHashrate(i);
        let voteDiscount = await nft.getVoteDiscount(i);

        if (rarity == RARITIES.common) {
            assert.equal(voteDiscount, 100);
            assert.isAtMost(hashrate, 200);
            assert.isAtLeast(hashrate, 100);
        } else if (rarity == RARITIES.rare) {
            assert.equal(voteDiscount, 100);
            assert.isAtMost(hashrate, 550);
            assert.isAtLeast(hashrate, 270);
        } else if (rarity == RARITIES.epic) {
            assert.equal(voteDiscount, 100);
            assert.isAtMost(hashrate, 2750);
            assert.isAtLeast(hashrate, 1250);
        } else if (rarity == RARITIES.legendary) {
            assert.equal(voteDiscount, 100);
            assert.isAtMost(hashrate, 14000);
            assert.isAtLeast(hashrate, 6500);
        }
    }

    await token2.connect(admin).transfer(alice.address, RESALE_FEE);

    assert.equal(await token2.balanceOf(alice.address), RESALE_PRICE);
    assert.equal(await token2.balanceOf(charlie.address), 0);
    assert.equal(await nft.ownerOf(MAYOR_ID_0), charlie.address);

    await nft.connect(charlie).approve(marketplace.address, MAYOR_ID_0);
    await marketplace.connect(charlie).setItemForSale({addr: nft.address, tokenId: MAYOR_ID_0}, RESALE_PRICE);
    await token2.connect(alice).approve(marketplace.address, RESALE_PRICE);
    await marketplace.connect(alice).buyItem({addr: nft.address, tokenId: MAYOR_ID_0});

    assert.equal(await token2.balanceOf(alice.address), 0);
    assert.equal(await token2.balanceOf(charlie.address), RESALE_INCOME);
    assert.equal(await token2.balanceOf(admin.address), RESALE_FEE);
    assert.equal(await nft.ownerOf(MAYOR_ID_0), alice.address);

    for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
        await nft.updateLevel(i);

        let rarity = await nft.getRarity(i);
        let hashrate = await nft.getHashrate(i);
        let voteDiscount = await nft.getVoteDiscount(i);

        assert.equal(await nft.tokenURI(i), SEASON_1_URI+"/"+rarity+"/"+1);

        if (rarity == RARITIES.common) {
            assert.equal(voteDiscount, 99);
            assert.isAtMost(hashrate, 800);
            assert.isAtLeast(hashrate, 400);
        } else if (rarity == RARITIES.rare) {
            assert.equal(voteDiscount, 98);
            assert.isAtMost(hashrate, 1650);
            assert.isAtLeast(hashrate, 810);
        } else if (rarity == RARITIES.epic) {
            assert.equal(voteDiscount, 96);
            assert.isAtMost(hashrate, 6875);
            assert.isAtLeast(hashrate, 3125);
        } else if (rarity == RARITIES.legendary) {
            assert.equal(voteDiscount, 94);
            assert.isAtMost(hashrate, 28000);
            assert.isAtLeast(hashrate, 13000);
        }
    }

    for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
        await nft.updateLevel(i);

        let rarity = await nft.getRarity(i);
        let hashrate = await nft.getHashrate(i);
        let voteDiscount = await nft.getVoteDiscount(i);

        assert.equal(await nft.tokenURI(i), SEASON_1_URI+"/"+rarity+"/"+2);

        if (rarity == RARITIES.common) {
            assert.equal(voteDiscount, 98);
            assert.isAtMost(hashrate, 2400);
            assert.isAtLeast(hashrate, 1200);
        } else if (rarity == RARITIES.rare) {
            assert.equal(voteDiscount, 96);
            assert.isAtMost(hashrate, 4125);
            assert.isAtLeast(hashrate, 2025);
        } else if (rarity == RARITIES.epic) {
            assert.equal(voteDiscount, 94);
            assert.isAtMost(hashrate, 13750);
            assert.isAtLeast(hashrate, 6250);
        } else if (rarity == RARITIES.legendary) {
            assert.equal(voteDiscount, 92);
            assert.isAtMost(hashrate, 42000);
            assert.isAtLeast(hashrate, 19500);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
