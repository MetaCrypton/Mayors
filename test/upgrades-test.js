const { expect, assert } = require("chai");
const { ethers, upgrades, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');
const { deploy, upgrade, config } = require("./utils");

describe("Upgrades", function() {
    this.timeout(20000);

    let token1;
    let token2;
    let nft;
    let lootbox;
    let marketplace;

    async function deployOld(contractName, signer, ...args) {
        const Factory = await ethers.getContractFactory(contractName, signer)
        const instance = await Factory.deploy(...args)
        return instance.deployed()
    }

    before(async function() {
        [admin, alice, bob, charlie] = await ethers.getSigners();
    });

    it("Upgrade token contract", async function() {
        token1 = await deploy("Token", admin, ["Test token", "TST", admin.address]);
        await upgrade(token1.address, "TestToken", admin);
        let upgradedToken1 = await ethers.getContractAt("ITestToken", token1.address);
        assert.equal(await upgradedToken1.getNumber(), 0);
        let num = 10;
        await upgradedToken1.setNumber(num);
        assert.equal(await upgradedToken1.getNumber(), num);
        await upgrade(token1.address, "TestTokenInc", admin);
        upgradedToken1 = await ethers.getContractAt("ITestTokenInc", token1.address);
        assert.equal(await upgradedToken1.getNumber(), num);
        await upgradedToken1.incNumber();
        assert.equal(await upgradedToken1.getNumber(), num+1);
    });

    it("Upgrade token contract with removed function", async function() {
        token1 = await deploy("TestTokenInc", admin, ["Test token", "TST", admin.address]);
        await token1.incNumber();
        await upgrade(token1.address, "TestToken", admin);
        await expect(token1.incNumber()).to.be.revertedWith("function selector was not recognized and there's no fallback function");
    });

    it("Not upgrades token with the same contract", async function(){
        token1 = await deploy("Token", admin, ["Test token", "TST", admin.address]);
        let implAddress = await upgrades.erc1967.getImplementationAddress(token1.address);
        await upgrade(token1.address, "Token", admin);
        let implAddress2 = await upgrades.erc1967.getImplementationAddress(token1.address);
        assert.equal(implAddress, implAddress2);
    });

    it("Upgrade nft contract", async function() {
        nft = await deploy(
            "NFT",
            admin,
            ["Mayors",
            "MRS",
            admin.address]
        );
        await upgrade(nft.address, "TestNFT", admin);
        let upgradedNft = await ethers.getContractAt("ITestNFT", nft.address);
        assert.equal(await upgradedNft.getNumber(), 0);
        let num = 10;
        await upgradedNft.setNumber(num);
        assert.equal(await upgradedNft.getNumber(), num);
        await upgrade(nft.address, "TestNFTInc", admin);
        upgradedNft = await ethers.getContractAt("ITestNFTInc", nft.address);
        assert.equal(await upgradedNft.getNumber(), num);
        await upgradedNft.incNumber();
        assert.equal(await upgradedNft.getNumber(), num+1);
    });

    it("Upgrade nft contract with removed function", async function() {
        nft = await deploy(
            "TestNFTInc",
            admin,
            ["Mayors",
            "MRS",
            admin.address]
        );
        await nft.incNumber();
        await upgrade(nft.address, "TestNFT", admin);
        await expect(nft.incNumber()).to.be.revertedWith("function selector was not recognized and there's no fallback function");
    });

    it("Not upgrades nft with the same contract", async function(){
        nft = await deploy(
            "NFT",
            admin,
            ["Mayors",
            "MRS",
            admin.address]
        );
        let implAddress = await upgrades.erc1967.getImplementationAddress(nft.address);
        await upgrade(nft.address, "NFT", admin);
        let implAddress2 = await upgrades.erc1967.getImplementationAddress(nft.address);
        assert.equal(implAddress, implAddress2);
    });

    it("Upgrade lootbox contract", async function() {
        lootbox = await deploy(
            "Lootbox",
            admin,
            ["Lootboxes",
            "LBS",
            admin.address]
        );
        await upgrade(lootbox.address, "TestLootbox", admin);
        let upgradedLootbox = await ethers.getContractAt("ITestLootbox", lootbox.address);
        assert.equal(await upgradedLootbox.getNumber(), 0);
        let num = 10;
        await upgradedLootbox.setNumber(num);
        assert.equal(await upgradedLootbox.getNumber(), num);
        await upgrade(lootbox.address, "TestLootboxInc", admin);
        upgradedLootbox = await ethers.getContractAt("ITestLootboxInc", lootbox.address);
        assert.equal(await upgradedLootbox.getNumber(), num);
        await upgradedLootbox.incNumber();
        assert.equal(await upgradedLootbox.getNumber(), num+1);
    });

    it("Upgrade lootbox contract with removed function", async function() {
        lootbox = await deploy(
            "TestLootboxInc",
            admin,
            ["Lootboxes",
            "LBS",
            admin.address]
        );
        await lootbox.incNumber();
        await upgrade(lootbox.address, "TestLootbox", admin);
        await expect(lootbox.incNumber()).to.be.revertedWith("function selector was not recognized and there's no fallback function");
    });

    it("Not upgrades lootbox with the same contract", async function(){
        lootbox = await deploy(
            "Lootbox",
            admin,
            ["Lootboxes",
            "LBS",
            admin.address]
        );
        let implAddress = await upgrades.erc1967.getImplementationAddress(lootbox.address);
        await upgrade(lootbox.address, "Lootbox", admin);
        let implAddress2 = await upgrades.erc1967.getImplementationAddress(lootbox.address);
        assert.equal(implAddress, implAddress2);
    });

    it("Upgrade marketplace contract", async function() {
        token2 = await deploy("Token", admin, ["Test token 2", "TST2", admin.address]);
        marketplace = await deploy(
            "Marketplace",
            admin,
            [[
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
            admin.address]
        );
        await upgrade(marketplace.address, "TestMarketplace", admin);
        let upgradedMarketplace = await ethers.getContractAt("ITestMarketplace", marketplace.address);
        assert.equal(await upgradedMarketplace.getNumber(), 0);
        let num = 10;
        await upgradedMarketplace.setNumber(num);
        assert.equal(await upgradedMarketplace.getNumber(), num);
        await upgrade(marketplace.address, "TestMarketplaceInc", admin);
        upgradedMarketplace = await ethers.getContractAt("ITestMarketplaceInc", marketplace.address);
        assert.equal(await upgradedMarketplace.getNumber(), num);
        await upgradedMarketplace.incNumber();
        assert.equal(await upgradedMarketplace.getNumber(), num+1);
    });

    it("Upgrade marketplace contract with removed function", async function() {
        marketplace = await deploy(
            "TestMarketplaceInc",
            admin,
            [[
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
            admin.address]
        );
        await marketplace.incNumber();
        await upgrade(marketplace.address, "TestMarketplace", admin);
        await expect(marketplace.incNumber()).to.be.revertedWith("function selector was not recognized and there's no fallback function");
    });

    it("Not upgrades lootbox with the same contract", async function(){
        marketplace = await deploy(
            "Marketplace",
            admin,
            [[
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
            admin.address]
        );
        let implAddress = await upgrades.erc1967.getImplementationAddress(marketplace.address);
        await upgrade(marketplace.address, "Marketplace", admin);
        let implAddress2 = await upgrades.erc1967.getImplementationAddress(marketplace.address);
        assert.equal(implAddress, implAddress2);
    });
});