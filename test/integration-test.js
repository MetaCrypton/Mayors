const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');
const { deploy, getIndexedEventArgsRAW, getAllIndexedEventsArgsRAW, config, coder } = require("./utils");

describe("Integration", function() {
    this.timeout(20000);

    let admin, alice, bob, charlie;

    let token1;
    let token2;
    let nft;
    let lootbox;
    let marketplace;
    let inventory;
    let ids;


    it("Wallets and coder setup", async function() {
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
            "",
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
    });

    it("Mint tokens", async function() {
        await token1.connect(admin).mint(alice.address, config.ALICE_MINT);
        await token1.connect(admin).mint(bob.address, config.BOB_MINT);
        await token2.connect(admin).mint(charlie.address, config.CHARLIE_MINT);
    });

    it("Set eligibles", async function() {
        await marketplace.connect(admin).addToEligible([alice.address, bob.address]);
    });

    it("Buy lootbox", async function() {
        assert.equal(await token1.balanceOf(alice.address), config.ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, config.PRICE);
        await marketplace.connect(alice).buyLootboxMP(1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), config.PRICE);
    });

    it("Sell lootbox", async function() {
        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), config.CHARLIE_MINT);
        assert.equal(await lootbox.ownerOf(config.LOOTBOX_ID_0), alice.address);

        await lootbox.connect(alice).approve(marketplace.address, config.LOOTBOX_ID_0);
        await marketplace.connect(alice).setForSale({addr: lootbox.address, tokenId: config.LOOTBOX_ID_0}, config.RESALE_PRICE);
        await token2.connect(charlie).approve(marketplace.address, config.RESALE_PRICE);
        await marketplace.connect(charlie).buyItem({addr: lootbox.address, tokenId: config.LOOTBOX_ID_0});

        assert.equal(await token2.balanceOf(alice.address), config.RESALE_INCOME);
        assert.equal(await token2.balanceOf(admin.address), config.RESALE_FEE);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await lootbox.ownerOf(config.LOOTBOX_ID_0), charlie.address);
    });

    it("Reveal lootbox", async function() {
        let tx = await lootbox.connect(charlie).reveal(0, ["Mayor0", "Mayor1", "Mayor2"]);
        const result = await tx.wait();
        const eventArgs = getAllIndexedEventsArgsRAW(
            result,
            "NameSet(uint256,string)",
            ["uint256", "string"],
        );
        ids = eventArgs.map(function(event){
            return event[0].toNumber();
        });
    });

    it("Validate nft ownership", async function() {
        ids.forEach(async function(i){
            assert.equal(await nft.ownerOf(i), charlie.address);
        });
    });

    it("Get rarities & hashrates", async function() {
        let id=0;

        for (let i = 0; i < config.NUMBER_IN_LOOTBOXES; i++) {
            id = ids[i];
            let rarity = await nft.getRarity(id);
            let hashrate = await nft.getHashrate(id);
            let votePrice = await nft.getVotePrice(id);

            if (rarity == config.RARITIES.common) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 200);
                assert.isAtLeast(hashrate, 100);
            } else if (rarity == config.RARITIES.rare) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 550);
                assert.isAtLeast(hashrate, 270);
            } else if (rarity == config.RARITIES.epic) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 2750);
                assert.isAtLeast(hashrate, 1250);
            } else if (rarity == config.RARITIES.legendary) {
                assert.equal(votePrice, 1000000000000000);
                assert.isAtMost(hashrate, 14000);
                assert.isAtLeast(hashrate, 6500);
            }
        }
    });

    it("Sell mayor", async function() {
        const MAYOR_ID_0 = ids[0];
        await token2.connect(admin).transfer(alice.address, config.RESALE_FEE);

        assert.equal(await token2.balanceOf(alice.address), config.RESALE_PRICE);
        assert.equal(await token2.balanceOf(charlie.address), 0);
        assert.equal(await nft.ownerOf(MAYOR_ID_0), charlie.address);

        await nft.connect(charlie).approve(marketplace.address, MAYOR_ID_0);
        await marketplace.connect(charlie).setForSale({addr: nft.address, tokenId: MAYOR_ID_0}, config.RESALE_PRICE);
        await token2.connect(alice).approve(marketplace.address, config.RESALE_PRICE);
        await marketplace.connect(alice).buyItem({addr: nft.address, tokenId: MAYOR_ID_0});

        assert.equal(await token2.balanceOf(alice.address), 0);
        assert.equal(await token2.balanceOf(charlie.address), config.RESALE_INCOME);
        assert.equal(await token2.balanceOf(admin.address), config.RESALE_FEE);
        assert.equal(await nft.ownerOf(MAYOR_ID_0), alice.address);
    });

    it("Update levels to GEN1. Get new hashrates", async function() {
        let id=0;

        for (let i = 0; i < config.NUMBER_IN_LOOTBOXES; i++) {
            id = ids[i];
            await nft.updateLevel(id, config.GEN1);

            let rarity = await nft.getRarity(id);
            let hashrate = await nft.getHashrate(id);
            let votePrice = await nft.getVotePrice(id);

            if (rarity == config.RARITIES.common) {
                assert.equal(votePrice, 990000000000000);
                assert.isAtMost(hashrate, 800);
                assert.isAtLeast(hashrate, 400);
            } else if (rarity == config.RARITIES.rare) {
                assert.equal(votePrice, 980000000000000);
                assert.isAtMost(hashrate, 1650);
                assert.isAtLeast(hashrate, 810);
            } else if (rarity == config.RARITIES.epic) {
                assert.equal(votePrice, 960000000000000);
                assert.isAtMost(hashrate, 6875);
                assert.isAtLeast(hashrate, 3125);
            } else if (rarity == config.RARITIES.legendary) {
                assert.equal(votePrice, 940000000000000);
                assert.isAtMost(hashrate, 28000);
                assert.isAtLeast(hashrate, 13000);
            }
        }
    });

    it("Update levels to GEN2. Get new hashrates", async function() {
        let id=0;

        for (let i = 0; i < config.NUMBER_IN_LOOTBOXES; i++) {
            id = ids[i];
            await nft.updateLevel(id, config.GEN2);

            let rarity = await nft.getRarity(id);
            let hashrate = await nft.getHashrate(id);
            let votePrice = await nft.getVotePrice(id);

            if (rarity == config.RARITIES.common) {
                assert.equal(votePrice, 980000000000000);
                assert.isAtMost(hashrate, 2400);
                assert.isAtLeast(hashrate, 1200);
            } else if (rarity == config.RARITIES.rare) {
                assert.equal(votePrice, 960000000000000);
                assert.isAtMost(hashrate, 4125);
                assert.isAtLeast(hashrate, 2025);
            } else if (rarity == config.RARITIES.epic) {
                assert.equal(votePrice, 940000000000000);
                assert.isAtMost(hashrate, 13750);
                assert.isAtLeast(hashrate, 6250);
            } else if (rarity == config.RARITIES.legendary) {
                assert.equal(votePrice, 920000000000000);
                assert.isAtMost(hashrate, 42000);
                assert.isAtLeast(hashrate, 19500);
            }
        }
    });

    // it("Deposit and withdraw ether in inventory", async function() {
    //     let balance;

    //     await inventory.connect(admin).depositEther({value: ethers.utils.parseEther("1.0")})
    //     balance = await inventory.connect(admin).getEtherBalance();
    //     assert.equal(ethers.utils.formatEther(balance), "1.0");

    //     await inventory.connect(admin).withdrawEther(admin.address, ethers.utils.parseEther("0.7"));
    //     balance = await inventory.connect(admin).getEtherBalance();
    //     assert.equal(ethers.utils.formatEther(balance), "0.3");
    // });

    // it("Deposit and withdraw ERC20 in inventory", async function() {
    //     let balance;

    //     const token = await deploy("Token", admin, "Random ERC20 token", "TKN", admin.address);
    //     await token.connect(admin).mint(alice.address, ALICE_MINT);
    //     await token.connect(admin).mint(bob.address, BOB_MINT);

    //     await token.connect(alice).approve(inventory.address, 10);
    //     await token.connect(admin).approve(bob.address, 7);

    //     await inventory.connect(admin).depositERC20(alice.address, token.address, 10);
    //     balance = await inventory.connect(admin).getERC20Balance(token.address);
    //     assert.equal(balance, 10);

    //     await inventory.connect(admin).withdrawERC20(bob.address, token.address, 7);
    //     balance = await inventory.connect(admin).getERC20Balance(token.address);
    //     assert.equal(balance, 3);

    //     assert.equal(await token.balanceOf(alice.address), ALICE_MINT - 10);
    //     assert.equal(await token.balanceOf(bob.address), BOB_MINT + 7);

    //     const assets = await inventory.connect(admin).getERC20s(0, 2);
    //     assert.equal(assets.length, 1);
    //     assert.equal(assets[0].tokenAddress, token.address);
    //     assert.equal(assets[0].amount, 3);
    // });

    // it("Deposit and withdraw ERC721 in inventory", async function() {
    //     const test = await deploy("TestERC721", admin, "Random ERC721 token", "TKN");

    //     const tx = await test.connect(alice).mint("URI");
    //     const result = await tx.wait();
    //     const tokenId = getIndexedEventArgs(
    //         result,
    //         "Transfer(address,address,uint256)",
    //         2,
    //     );

    //     await test.connect(alice).approve(inventory.address, tokenId);
    //     await inventory.connect(admin).depositERC721(alice.address, test.address, tokenId);
    //     assert.equal(await inventory.connect(admin).isERC721Owner(test.address, tokenId), true);

    //     await inventory.connect(admin).withdrawERC721(bob.address, test.address, tokenId);
    //     assert.equal(await inventory.connect(admin).isERC721Owner(test.address, tokenId), false);

    //     assert.equal(await test.balanceOf(alice.address), 0);
    //     assert.equal(await test.balanceOf(bob.address), 1);
    //     assert.equal(await test.balanceOf(inventory.address), 0);
    // });
});
