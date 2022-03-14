const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');

describe("Integration", function() {
    this.timeout(20000);

    const SEASON_1_URI = "https://mayors_1.io"
    const SEASON_2_URI = "https://mayors_2.io"

    const LOOTBOXES_CAP = 3;
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
    const MAYOR_ID_1 = 1;
    const MAYOR_ID_2 = 2;

    const GEN0 = 0;
    const GEN1 = 1;
    const GEN2 = 2;

    const MERKLE_ROOT = "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80";

    const RATES = {
        common: 69,
        rare: 94,
        epic: 99,
        legendary: 100
    };
    const RARITIES = {
        common: 0,
        rare: 1,
        epic: 2,
        legendary: 3
    };
    const ASSET_TYPES = {
        Ether: 0,
        ERC20: 1,
        ERC721: 2,
    }

    let admin, alice, bob, charlie;
    let coder;

    let token1;
    let token2;
    let nft;
    let lootbox;
    let marketplace;

    async function deploy(contractName, signer, ...args) {
        const Factory = await ethers.getContractFactory(contractName, signer)
        const instance = await Factory.deploy(...args)
        return instance.deployed()
    }

    async function deployWithLib(contractName, signer, libs, ...args) {
        const Factory = await ethers.getContractFactory(contractName, {libraries: libs,}, signer);
        const instance = await Factory.deploy(...args)
        return instance.deployed()
    }

    function getIndexedEventArgsRAW(tx, eventSignature, eventNotIndexedParams) {
        const sig = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventSignature));
        const log = getLogByFirstTopic(tx, sig);
        return coder.decode(
            eventNotIndexedParams,
            log.data
        );
    }

    function getIndexedEventArgs(tx, eventSignature, topic) {
        const sig = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventSignature));
        const log = getLogByFirstTopic(tx, sig);
        return log.args[topic];
    }

    function getLogByFirstTopic(tx, firstTopic) {
        const logs = tx.events;

        for(let i = 0; i < logs.length; i++) {
            if(logs[i].topics[0] === firstTopic){
                return logs[i];
            }
        }
        return null;
    }

    it("Wallets and coder setup", async function() {
        coder = ethers.utils.defaultAbiCoder;
        [admin, alice, bob, charlie] = await ethers.getSigners();
    });

    it("Setup system", async function() {
        token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
        token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);

        const rarityCalculator = await deploy("RarityCalculator", admin);
        nft = await deploy(
            "NFT",
            admin,
            "Mayors",
            "MRS",
            SEASON_1_URI,
            admin.address
        );
        lootbox = await deploy(
            "Lootbox",
            admin,
            "Lootboxes",
            "LBS",
            "",
            admin.address
        );
        marketplace = await deploy(
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
            admin.address
        );

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
    });

    it("Mint tokens", async function() {
        await token1.connect(admin).mint(alice.address, ALICE_MINT);
        await token1.connect(admin).mint(bob.address, BOB_MINT);
        await token2.connect(admin).mint(charlie.address, CHARLIE_MINT);
    });

    it("Set eligibles", async function() {
        await marketplace.connect(admin).addToEligible([alice.address, bob.address]);
    });

    it("Buy lootbox merkle proof", async function() {
        assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, PRICE);
        await marketplace.connect(alice).buyLootboxMP(1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), PRICE);
    });

    it("Sell lootbox", async function() {
        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), CHARLIE_MINT);
        assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), alice.address);

        await lootbox.connect(alice).approve(marketplace.address, LOOTBOX_ID_0);
        await marketplace.connect(alice).setItemPrice({addr: lootbox.address, tokenId: LOOTBOX_ID_0}, RESALE_PRICE);
        await token2.connect(charlie).approve(marketplace.address, RESALE_PRICE);
        await marketplace.connect(charlie).buyItem({addr: lootbox.address, tokenId: LOOTBOX_ID_0});

        assert.equal(await token2.balanceOf(alice.address), RESALE_INCOME);
        assert.equal(await token2.balanceOf(admin.address), RESALE_FEE);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), charlie.address);
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(charlie).reveal(0, ["Mayor0", "Mayor1", "Mayor2"]);
    });

    it("Validate nft ownership", async function() {
        for (let i = 1; i < NUMBER_IN_LOOTBOXES + 1; i++) {
            assert.equal(await nft.ownerOf(i), charlie.address);
        }
    });

    it("Get rarities & hashrates", async function() {
        for (let i = 1; i < NUMBER_IN_LOOTBOXES + 1; i++) {
            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let votePrice = await nft.getVotePrice(i);

            if (rarity == RARITIES.common) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 200);
                assert.isAtLeast(hashrate, 100);
            } else if (rarity == RARITIES.rare) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 550);
                assert.isAtLeast(hashrate, 270);
            } else if (rarity == RARITIES.epic) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 2750);
                assert.isAtLeast(hashrate, 1250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 14000);
                assert.isAtLeast(hashrate, 6500);
            }
        }
    });

    it("Sell mayor", async function() {
        await token2.connect(admin).transfer(alice.address, RESALE_FEE);

        assert.equal(await token2.balanceOf(alice.address), RESALE_PRICE);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await nft.ownerOf(MAYOR_ID_1), charlie.address);

        await nft.connect(charlie).approve(marketplace.address, MAYOR_ID_1);
        await marketplace.connect(charlie).setItemPrice({addr: nft.address, tokenId: MAYOR_ID_1}, RESALE_PRICE);
        await token2.connect(alice).approve(marketplace.address, RESALE_PRICE);
        await marketplace.connect(alice).buyItem({addr: nft.address, tokenId: MAYOR_ID_1});

        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), RESALE_INCOME);
        assert.equal(await token2.balanceOf(admin.address), RESALE_FEE);
        assert.equal(await nft.ownerOf(MAYOR_ID_1), alice.address);
    });

    it("Update levels to GEN1. Get new hashrates", async function() {
        for (let i = 1; i < NUMBER_IN_LOOTBOXES + 1; i++) {
            await nft.updateLevel(i);

            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let votePrice = await nft.getVotePrice(i);
            let hat = await nft.getHat(i);

            assert.equal(hat, i);

            assert.equal(await nft.tokenURI(i), SEASON_1_URI+"/"+rarity+"/"+1+"/"+i+"/"+0);

            if (rarity == RARITIES.common) {
                assert.equal(votePrice, 990000000000000);
                assert.isAtMost(hashrate, 800);
                assert.isAtLeast(hashrate, 400);
            } else if (rarity == RARITIES.rare) {
                assert.equal(votePrice, 980000000000000);
                assert.isAtMost(hashrate, 1650);
                assert.isAtLeast(hashrate, 810);
            } else if (rarity == RARITIES.epic) {
                assert.equal(votePrice, 960000000000000);
                assert.isAtMost(hashrate, 6875);
                assert.isAtLeast(hashrate, 3125);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(votePrice, 940000000000000);
                assert.isAtMost(hashrate, 28000);
                assert.isAtLeast(hashrate, 13000);
            }
        }
    });

    it("Update levels to GEN2. Get new hashrates", async function() {
        for (let i = 1; i < NUMBER_IN_LOOTBOXES + 1; i++) {
            await nft.updateLevel(i);

            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let votePrice = await nft.getVotePrice(i);
            let hat = await nft.getHat(i);
            let inHand = await nft.getInHand(i);

            assert.equal(hat, i);
            assert.equal(inHand, i);

            assert.equal(await nft.tokenURI(i), SEASON_1_URI+"/"+rarity+"/"+2+"/"+i+"/"+i);

            if (rarity == RARITIES.common) {
                assert.equal(votePrice, 980000000000000);
                assert.isAtMost(hashrate, 2400);
                assert.isAtLeast(hashrate, 1200);
            } else if (rarity == RARITIES.rare) {
                assert.equal(votePrice, 960000000000000);
                assert.isAtMost(hashrate, 4125);
                assert.isAtLeast(hashrate, 2025);
            } else if (rarity == RARITIES.epic) {
                assert.equal(votePrice, 940000000000000);
                assert.isAtMost(hashrate, 13750);
                assert.isAtLeast(hashrate, 6250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(votePrice, 920000000000000);
                assert.isAtMost(hashrate, 42000);
                assert.isAtLeast(hashrate, 19500);
            }
        }
    });

    it("Update season", async function() {
        await nft.connect(admin).updateSeason(SEASON_2_URI);
    });

    it("Buy lootbox whitelist", async function() {
        await token1.connect(admin).transfer(alice.address, ALICE_MINT);

        assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, PRICE);

        await marketplace.connect(alice).buyLootbox();

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), PRICE);
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(alice).reveal(1, ["Mayor3", "Mayor4", "Mayor5"]);
    });

    it("Validate nft ownership", async function() {
        for (let i = 4; i < NUMBER_IN_LOOTBOXES + 4; i++) {
            assert.equal(await nft.ownerOf(i), alice.address);
        }
    });

    it("Get rarities & hashrates", async function() {
        for (let i = 4; i < NUMBER_IN_LOOTBOXES + 4; i++) {
            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let votePrice = await nft.getVotePrice(i);

            assert.equal(await nft.tokenURI(i), SEASON_2_URI+"/"+rarity+"/"+0+"/"+0+"/"+0);

            if (rarity == RARITIES.common) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 200);
                assert.isAtLeast(hashrate, 100);
            } else if (rarity == RARITIES.rare) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 550);
                assert.isAtLeast(hashrate, 270);
            } else if (rarity == RARITIES.epic) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 2750);
                assert.isAtLeast(hashrate, 1250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 14000);
                assert.isAtLeast(hashrate, 6500);
            }
        }
    });
});
