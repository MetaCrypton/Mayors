const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');

describe("Integration", function() {
    this.timeout(20000);

    const NUMBER_IN_LOOTBOXES = 3;
    const PRICE = 100;
    const ALICE_MINT = 100;
    const BOB_MINT = 10;

    let admin, alice, bob, charlie;
    let coder;

    let token;
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
        token = await deploy("Token", admin, "Payment token", "PTN", admin.address);
        nft = await deploy("NFT", admin, "Mayors", "MRS", admin.address);
        lootbox = await deploy("Lootbox", admin, "Lootboxes", "LBS", admin.address, nft.address, NUMBER_IN_LOOTBOXES);
        marketplace = await deploy("Marketplace", admin, admin.address, lootbox.address, token.address, PRICE);

        await lootbox.connect(admin).setMarketplaceAddress(marketplace.address);
        await nft.connect(admin).setLootboxAddress(lootbox.address);
    });

    it("Mint tokens", async function() {
        await token.connect(admin).mint(alice.address, ALICE_MINT);
        await token.connect(admin).mint(bob.address, BOB_MINT);
    });

    it("Set eligibles", async function() {
        await marketplace.connect(admin).addToEligible([alice.address, bob.address]);
    });

    it("Buy lootbox", async function() {
        assert.equal(await token.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token.balanceOf(admin.address), 0);

        await token.connect(alice).approve(marketplace.address, PRICE);
        await marketplace.connect(alice).buyLootbox();

        assert.equal(await token.balanceOf(alice.address), 0);
        assert.equal(await token.balanceOf(admin.address), PRICE);
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(alice).reveal(0);
    });

    it("Validate nft ownership", async function() {
        assert.equal(await nft.ownerOf(0), alice.address);
        assert.equal(await nft.ownerOf(1), alice.address);
        assert.equal(await nft.ownerOf(2), alice.address);
    });
});