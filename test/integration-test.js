const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');

describe("Integration", function() {
    this.timeout(20000);

    const NUMBER_IN_LOOTBOXES = 3;
    const PRICE = 100;
    const ALICE_MINT = 100;
    const CHARLIE_MINT = 200;
    const BOB_MINT = 10;

    const LOOTBOX_ID_0 = 0;
    const MAYOR_ID_0 = 0;

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
        nft = await deploy(
            "Mayor",
            admin,
            "Mayors",
            "MRS",
            admin.address
        );
        lootbox = await deploy("Lootbox", admin, "Lootboxes", "LBS", admin.address, nft.address, NUMBER_IN_LOOTBOXES);
        marketplace = await deploy("Marketplace", admin, admin.address, lootbox.address, nft.address, token1.address, token2.address, PRICE);

        await lootbox.connect(admin).setMarketplaceAddress(marketplace.address);
        await nft.connect(admin).setLootboxAddress(lootbox.address);
    });

    it("Mint tokens", async function() {
        await token1.connect(admin).mint(alice.address, ALICE_MINT);
        await token1.connect(admin).mint(bob.address, BOB_MINT);
        await token2.connect(admin).mint(charlie.address, CHARLIE_MINT);
    });

    it("Set eligibles", async function() {
        await marketplace.connect(admin).addToEligible([alice.address, bob.address]);
    });

    it("Buy lootbox", async function() {
        assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, PRICE);
        await marketplace.connect(alice).buyLootbox();

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), PRICE);
    });

    it("Sell lootbox", async function() {
        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), CHARLIE_MINT);
        assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), alice.address);

        await lootbox.connect(alice).approve(marketplace.address, LOOTBOX_ID_0);
        await marketplace.connect(alice).setForSale({addr: lootbox.address, tokenId: LOOTBOX_ID_0}, CHARLIE_MINT);
        await token2.connect(charlie).approve(marketplace.address, CHARLIE_MINT);
        await marketplace.connect(charlie).buyItem({addr: lootbox.address, tokenId: LOOTBOX_ID_0});

        assert.equal(await token2.balanceOf(alice.address), CHARLIE_MINT);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await lootbox.ownerOf(LOOTBOX_ID_0), charlie.address);
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(charlie).reveal(0, ["Mayor0", "Mayor1", "Mayor2"]);
    });

    it("Validate nft ownership", async function() {
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            assert.equal(await nft.ownerOf(i), charlie.address);
        }
    });

    it("Get rarities", async function() {
        let commons = 0;
        let rares = 0;
        let epics = 0;
        let legendaries = 0;
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            let rarity = await nft.getRarity(i);
            if (rarity == RARITIES.common) {
                commons++;
            } else if (rarity == RARITIES.rare) {
                rares++;
            } else if (rarity == RARITIES.epic) {
                epics++;
            } else if (rarity == RARITIES.legendary) {
                legendaries++;
            }
        }
        console.log("Commons number: ", commons);
        console.log("Rares number: ", rares);
        console.log("Epics number: ", epics);
        console.log("Legendaries number: ", legendaries);
    });

    it("Sell mayor", async function() {
        assert.equal(await token2.balanceOf(alice.address), CHARLIE_MINT);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await nft.ownerOf(MAYOR_ID_0), charlie.address);

        await nft.connect(charlie).approve(marketplace.address, MAYOR_ID_0);
        await marketplace.connect(charlie).setForSale({addr: nft.address, tokenId: MAYOR_ID_0}, CHARLIE_MINT);
        await token2.connect(alice).approve(marketplace.address, CHARLIE_MINT);
        await marketplace.connect(alice).buyItem({addr: nft.address, tokenId: MAYOR_ID_0});

        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), CHARLIE_MINT);
        assert.equal(await nft.ownerOf(MAYOR_ID_0), alice.address);
    });
});