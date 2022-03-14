const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { deploy, getIndexedEventArgsRAW, getAllIndexedEventsArgsRAW, config, coder } = require("./utils");

describe("NFT contract", function() {
    this.timeout(20000);
    
    let admin, alice, bob, charlie;

    let nft, lootbox, marketplace;
    let rarityCalculator;
    let ids;
    let aliceTotalBalance = 0;

    before(async function(){
        [admin, alice, bob, charlie] = await ethers.getSigners();

        token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
        token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);
        lootbox = await deploy(
            "Lootbox",
            admin,
            "Lootboxes",
            "LBS",
            "",
            admin.address
        );
        rarityCalculator = await deploy("RarityCalculator", admin);

    });

    it("Is deployed with empty metadata", async function(){
        nft = await deploy("NFT", admin, "", "", "", admin.address);
        assert.equal(await nft.name(), "");
        assert.equal(await nft.symbol(), "");
    });

    it("Is deployed with not deployer owner", async function(){
        nft = await deploy("NFT", admin, "Mayors", "MRS", "", charlie.address);
        assert.equal(await nft.name(), "Mayors");
        assert.equal(await nft.symbol(), "MRS");
    });

    it("Is deployed with not empty metadata", async function(){
        nft = await deploy("NFT", admin, "Mayors", "MRS", "", admin.address);
        assert.equal(await nft.name(), "Mayors");
        assert.equal(await nft.symbol(), "MRS");
    });

    it("Mints a batch with one NFT", async function(){
        marketplace = await deploy(
            "Marketplace",
            admin,
            [
                lootbox.address,
                nft.address,
                token1.address,
                token2.address,
                admin.address,
                config.PRICE,
                config.LOOTBOXES_CAP,
                config.LOOTBOXES_PER_ADDRESS,
                config.MERKLE_ROOT
            ],
            admin.address
        );

        await lootbox.connect(admin).updateConfig(
            [
                config.NUMBER_IN_LOOTBOXES,
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

        let tx = await nft.connect(admin).batchMint(alice.address, ["Mayor 1"]);
        let receipt = await tx.wait();

        assert.equal(receipt.events.length, 2);
        for (const event of receipt.events) {
            expect(event.event).to.be.oneOf(["Transfer", "NameSet"]);
        }
        aliceTotalBalance += 1;
        assert.equal(await nft.balanceOf(alice.address), 1);
    });

    it("Mints a batch with several NFTs", async function(){
        let aliceBalance = await nft.balanceOf(alice.address);
        let names = ["Mayor 2", "Mayor 3", "Mayor 4", "Mayor 5"];
        let tx = await nft.connect(admin).batchMint(alice.address, names);
        let receipt = await tx.wait();

        const eventArgs = getAllIndexedEventsArgsRAW(
            receipt,
            "NameSet(uint256,string)",
            ["uint256", "string"],
        );
        ids = eventArgs.map(function(event){
            return event[0].toNumber();
        });

        assert.equal(receipt.events.length, names.length * 2);
        for (const event of receipt.events) {
            expect(event.event).to.be.oneOf(["Transfer", "NameSet"]);
        }
        aliceTotalBalance += names.length;
        assert.equal(await nft.balanceOf(alice.address), aliceBalance.toNumber() + names.length);
    });

    it("Doesn't mint a batch by a non-owner", async function(){
        await expect(nft.connect(charlie).batchMint(charlie.address, ["Mayor 6"])).to.be.revertedWith("NoPermission()");
    });
    

    it("Doesn't mint a batch to zero address", async function(){
        await expect(nft.connect(admin).batchMint(config.ZEROADDRESS, ["Mayor 6"])).to.be.revertedWith("ERC721: mint to the zero address");
    });

    it("Doesn't mint a batch of more that 255 NFTs", async function(){
        let aliceBalance = await nft.balanceOf(alice.address);
        let names = [...Array(256).keys()].map(name=>name.toString());
        await expect(nft.connect(admin).batchMint(alice.address, names)).to.be.revertedWith("Overflow()");
        assert.equal(await nft.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Doesn't mint a batch with empty names", async function(){
        let aliceBalance = await nft.balanceOf(alice.address);
        let names = ["", "", ""];
        await expect(nft.connect(admin).batchMint(alice.address, names)).to.be.revertedWith("EmptyName()");
        assert.equal(await nft.balanceOf(alice.address), aliceBalance.toNumber());
    });

    it("Returns name of NFT", async function(){
        let names = ["Mayor 2", "Mayor 3", "Mayor 4", "Mayor 5"];
        for (let i=0; i< ids.length; i++) {
            assert.equal(await nft.getName(ids[i]), names[i]);
        }
    });

    it("Doesn't return name of a non-existent NFT", async function(){
        await expect(nft.getName(1000)).to.be.revertedWith("UnexistingToken()");
    });

    it("Returns level of NFT", async function(){
        for (const id of ids) {
            assert.equal(await nft.getLevel(id), config.GEN0);
        }
    });

    it("Doesn't return level of a non-existent NFT", async function(){
        await expect(nft.getLevel(1000)).to.be.revertedWith("UnexistingToken()");
    });

    it("Returns rarity of NFT", async function(){
        let rarities = Object.keys(config.RARITIES).map(key => config.RARITIES[key]);
        for (const id of ids) {
            expect(await nft.getRarity(id)).to.be.oneOf(rarities);
        }
    });

    it("Doesn't return rarity of a non-existent NFT", async function(){
        await expect(nft.getRarity(1000)).to.be.revertedWith("UnexistingToken()");
    });

    it("Returns hashrate of NFT", async function(){
        // TODO: add check depends on level (levels multipliers should be added)
        let rarity;
        for (const id of ids) {
            rarity = await nft.getRarity(id);
            if (rarity == config.RARITIES.common) {
                expect(await nft.getHashrate(id)).to.be.within(100, 200);
            } else if (rarity == config.RARITIES.rare) {
                expect(await nft.getHashrate(id)).to.be.within(270, 550);
            } else if (rarity == config.RARITIES.epic) {
                expect(await nft.getHashrate(id)).to.be.within(1250, 2750);
            } else if (rarity == config.RARITIES.legendary) {
                expect(await nft.getHashrate(id)).to.be.within(6500, 14000);
            }
        }
    });

    it("Returns vote price of NFT", async function(){
        // TODO: add check depends on level (levels multipliers should be added)
        for (const id of ids) {
            assert.equal(await nft.getVotePrice(id), 0.001 * (10 ** 18));
        }
    });

    it("Doesn't return hashrate of a non-existent NFT", async function(){
        await expect(nft.getHashrate(1000)).to.be.revertedWith("UnexistingToken()");
    });

    it("Doesn't update level of NFT by a non-eligible address", async function(){
        for (const id of ids) {
            await expect(nft.connect(charlie).updateLevel(id, config.GEN1)).to.be.revertedWith("NotEligible()");
            assert.equal(await nft.getLevel(id), config.GEN0);
        }
    });

    it("Doesn't update level of NFT with the same value", async function(){
        for (const id of ids) {
            await expect(nft.updateLevel(id, config.GEN0)).to.be.revertedWith("SameValue()");
            assert.equal(await nft.getLevel(id), config.GEN0);
        }
    });

    it("Doesn't update level of a non-existent NFT", async function(){
        await expect(nft.updateLevel(1000, config.GEN1)).to.be.revertedWith("UnexistingToken()");
    });

    it("Updates level of NFT", async function(){
        for (const id of ids) {
            await expect(nft.updateLevel(id, config.GEN2)).to.emit(nft, "LevelUpdated").withArgs(id, config.GEN2);
            assert.equal(await nft.getLevel(id), config.GEN2);
        }
    });

    it("Updates level of NFT with less value", async function(){
        for (const id of ids) {
            await expect(nft.updateLevel(id, config.GEN1)).to.emit(nft, "LevelUpdated").withArgs(id, config.GEN1);
            assert.equal(await nft.getLevel(id), config.GEN1);
        }
    });
});