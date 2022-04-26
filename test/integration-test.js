const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');

describe("Integration", function() {
    this.timeout(20000);

    const BASE_URI = "https://baseuri.io";

    const NUMBER_IN_LOOTBOXES = 3;

    const SEASON_ID_1 = 0;
    const SEASON_ID_2 = 1;
    const LOOTBOXES_BATCH = 1497;

    const ALICE_MINT = 100;
    const CHARLIE_MINT = 200;
    const RESALE_PRICE = CHARLIE_MINT;
    const RESALE_FEE = RESALE_PRICE / 100;
    const RESALE_INCOME = RESALE_PRICE - RESALE_FEE;
    const BOB_MINT = 10;

    const LOOTBOX_ID_0 = 0;
    const MAYOR_ID_0 = 0;
    const MAYOR_ID_1 = 1;

    const GEN0 = 0;
    const GEN1 = 1;
    const GEN2 = 2;

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

    let season1 = {
        startTimestamp: 0,
        endTimestamp: 0,
        lootboxesNumber: 1,
        lootboxPrice: 100,
        lootboxesPerAddress: 3,
        lootboxesUnlockTimestamp: 0,
        merkleRoot: "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80",
        isPublic: true,
        uri: "season1"
    };

    let season2 = {
        startTimestamp: 0,
        endTimestamp: 0,
        lootboxesNumber: LOOTBOXES_BATCH + 1,
        lootboxPrice: 100,
        lootboxesPerAddress: LOOTBOXES_BATCH,
        lootboxesUnlockTimestamp: 0,
        merkleRoot: "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80",
        isPublic: true,
        uri: "season2"
    };

    let admin, alice, bob, charlie;
    let coder;

    let token1;
    let token2;
    let nft;
    let lootbox;
    let marketplace;
    let voteToken;
    let voucherToken;
    let staking;

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
            BASE_URI,
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
            ],
            [
                season1,
                season2
            ],
            admin.address
        );
        // TODO: change Token to Vote
        voteToken = await deploy("Token", admin, "Vote token", "Vote", admin.address);
        voucherToken = await deploy(
            "Voucher",
            admin,
            "Voucher token",
            "BVoucher",
            [
                ethers.constants.AddressZero
            ],
            admin.address
        );
        staking = await deploy(
            "Staking",
            admin,
            [
                voteToken.address,
                voucherToken.address,
            ],
            admin.address
        );
        await voucherToken.connect(admin).updateConfig(
            [
                staking.address,
            ]
        )

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

    it("Set eligibles for season 2", async function() {
        await marketplace.connect(admin).addToWhiteList(SEASON_ID_2, [alice.address, bob.address]);
    });

    it("Buy lootbox merkle proof from season 1", async function() {
        assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, season1.lootboxPrice);
        await marketplace.connect(alice).buyLootboxMP(SEASON_ID_1, 1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), season1.lootboxPrice);
    });

    it("Sell lootbox", async function() {
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
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(charlie).reveal(0);
    });

    it("Validate nft ownership", async function() {
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            assert.equal(await nft.ownerOf(i), charlie.address);
        }
    });

    it("Get rarities & hashrates", async function() {
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let voteDiscount = await nft.getVoteDiscount(i);

            if (rarity == RARITIES.common) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 200);
                assert.isAtLeast(hashrate, 100);
            } else if (rarity == RARITIES.rare) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 550);
                assert.isAtLeast(hashrate, 270);
            } else if (rarity == RARITIES.epic) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 2750);
                assert.isAtLeast(hashrate, 1250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 14000);
                assert.isAtLeast(hashrate, 6500);
            }
        }
    });

    it("Sell mayor", async function() {
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
    });

    it("Update levels to GEN1. Get new hashrates", async function() {
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            await nft.updateLevel(i);

            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let voteDiscount = await nft.getVoteDiscount(i);

            assert.equal(await nft.tokenURI(i), BASE_URI+"/"+season1.uri+"/"+i+"/"+i+"_"+1+".json");

            if (rarity == RARITIES.common) {
                assert.equal(voteDiscount, 1);
                assert.isAtMost(hashrate, 800);
                assert.isAtLeast(hashrate, 400);
            } else if (rarity == RARITIES.rare) {
                assert.equal(voteDiscount, 2);
                assert.isAtMost(hashrate, 1650);
                assert.isAtLeast(hashrate, 810);
            } else if (rarity == RARITIES.epic) {
                assert.equal(voteDiscount, 4);
                assert.isAtMost(hashrate, 6875);
                assert.isAtLeast(hashrate, 3125);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(voteDiscount, 6);
                assert.isAtMost(hashrate, 28000);
                assert.isAtLeast(hashrate, 13000);
            }
        }
    });

    it("Update levels to GEN2. Get new hashrates", async function() {
        for (let i = 0; i < NUMBER_IN_LOOTBOXES; i++) {
            await nft.updateLevel(i);

            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let voteDiscount = await nft.getVoteDiscount(i);

            assert.equal(await nft.tokenURI(i), BASE_URI+"/"+season1.uri+"/"+i+"/"+i+"_"+2+".json");

            if (rarity == RARITIES.common) {
                assert.equal(voteDiscount, 2);
                assert.isAtMost(hashrate, 2400);
                assert.isAtLeast(hashrate, 1200);
            } else if (rarity == RARITIES.rare) {
                assert.equal(voteDiscount, 4);
                assert.isAtMost(hashrate, 4125);
                assert.isAtLeast(hashrate, 2025);
            } else if (rarity == RARITIES.epic) {
                assert.equal(voteDiscount, 6);
                assert.isAtMost(hashrate, 13750);
                assert.isAtLeast(hashrate, 6250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(voteDiscount, 8);
                assert.isAtMost(hashrate, 42000);
                assert.isAtLeast(hashrate, 19500);
            }
        }
    });

    it("Buy lootbox whitelist", async function() {
        await token1.connect(admin).transfer(alice.address, ALICE_MINT);

        assert.equal(await token1.balanceOf(alice.address), ALICE_MINT);
        assert.equal(await token1.balanceOf(admin.address), 0);

        await token1.connect(alice).approve(marketplace.address, season2.lootboxPrice);

        await marketplace.connect(alice).buyLootbox(SEASON_ID_2);

        assert.equal(await token1.balanceOf(alice.address), 0);
        assert.equal(await token1.balanceOf(admin.address), season2.lootboxPrice);
    });

    it("Reveal lootbox", async function() {
        await lootbox.connect(alice).reveal(1);
    });

    it("Validate nft ownership", async function() {
        for (let i = 3; i < NUMBER_IN_LOOTBOXES + 3; i++) {
            assert.equal(await nft.ownerOf(i), alice.address);
        }
    });

    it("Get rarities & hashrates", async function() {
        for (let i = 3; i < NUMBER_IN_LOOTBOXES + 3; i++) {
            let rarity = await nft.getRarity(i);
            let hashrate = await nft.getHashrate(i);
            let voteDiscount = await nft.getVoteDiscount(i);

            assert.equal(await nft.tokenURI(i), BASE_URI+"/"+season2.uri+"/"+i+"/"+i+"_"+0+".json");

            if (rarity == RARITIES.common) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 200);
                assert.isAtLeast(hashrate, 100);
            } else if (rarity == RARITIES.rare) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 550);
                assert.isAtLeast(hashrate, 270);
            } else if (rarity == RARITIES.epic) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 2750);
                assert.isAtLeast(hashrate, 1250);
            } else if (rarity == RARITIES.legendary) {
                assert.equal(voteDiscount, 0);
                assert.isAtMost(hashrate, 14000);
                assert.isAtLeast(hashrate, 6500);
            }
        }
    });

    it("Send lootboxes in batch", async function() {
        assert.equal(await lootbox.balanceOf(alice.address), 0);
        let tx = await marketplace.connect(admin).sendLootboxes(SEASON_ID_2, LOOTBOXES_BATCH, alice.address, {gasLimit: 75501907});

        assert.equal(await lootbox.balanceOf(alice.address), LOOTBOXES_BATCH);
    });

    it("Mint and burn vouchers", async function() {
        await voucherToken.connect(admin).mint(alice.address, 500);
        await expect(voucherToken.connect(alice).mint(alice.address, 500)).to.be.revertedWith('NoPermission()');
        assert.equal(await voucherToken.balanceOf(alice.address), 500);
    });

    it("Stake votes", async function() {
        const twoHours = 2 * 60 * 60;
        const twoDays = 48 * 60 * 60 + 45 * 60;

        // mint votes
        await voteToken.connect(admin).mint(alice.address, 1000);
        await voteToken.connect(admin).mint(bob.address, 2000);
        await voteToken.connect(alice).approve(staking.address, 1000);
        await voteToken.connect(bob).approve(staking.address, 2000);

        // try to stake wrong amounts of votes
        await expect(staking.connect(alice).stakeVotes(15)).to.be.revertedWith('WrongMultiplicity()');
        await expect(staking.connect(alice).stakeVotes(200)).to.be.revertedWith('NotEnoughVotesForStake()');

        // stake votes
        await staking.connect(alice).stakeVotes(500);
        await staking.connect(bob).stakeVotes(700);
        assert.equal(await voteToken.balanceOf(alice.address), 500);
        assert.equal(await voteToken.balanceOf(bob.address), 1300);
        assert.equal(await voteToken.balanceOf(staking.address), 1200);

        // increase time and stake again
        const blockNum = await ethers.provider.getBlockNumber();
        const block = await ethers.provider.getBlock(blockNum);
        const timestamp = block.timestamp;

        await ethers.provider.send('evm_increaseTime', [twoHours]);
        await ethers.provider.send('evm_mine');
        await expect(staking.connect(alice).stakeVotes(100)).to.be.revertedWith('TooOftenStaking()');

        await ethers.provider.send('evm_increaseTime', [twoDays]);
        await ethers.provider.send('evm_mine');
        await staking.connect(alice).stakeVotes(100);

        // check balances
        assert.equal(await voteToken.balanceOf(alice.address), 400);
        assert.equal(await voteToken.balanceOf(bob.address), 1300);
        assert.equal(await voteToken.balanceOf(staking.address), 1300);
        assert.equal(await staking.connect(alice).getVotesAmount(0, 2), 600);
        assert.equal(await staking.connect(bob).getVotesAmount(0, 1), 700);

        // check accumulated vouchers
        // (500 staked votes / 500) * (50 hours / 24 hours)
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 208);
        // (700 staked votes / 500) * (50 hours / 24 hours)
        assert.equal(await staking.connect(bob).getVouchersAmount(0, 1), 291);

        // increase time again and check accumulated vouchers
        await ethers.provider.send('evm_increaseTime', [twoHours + twoDays]);
        await ethers.provider.send('evm_mine');

        // (500 staked votes / 500) * (101 hours / 24 hours) +
        // (100 staked votes / 500) * (50 hours / 24 hours)
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 461);
        // (700 staked votes / 500) * (101 hours / 24 hours)
        assert.equal(await staking.connect(bob).getVouchersAmount(0, 1), 589);
    });

    it("Withdraw vouchers", async function() {
        // check balances
        assert.equal(await voteToken.balanceOf(alice.address), 400);
        assert.equal(await voucherToken.balanceOf(alice.address), 500);
        assert.equal(await staking.connect(alice).getVotesAmount(0, 2), 600);
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 461);
        assert.equal(await staking.connect(bob).getVouchersAmount(0, 1), 589);

        // wrong staker address
        const zeroAddress = ethers.constants.AddressZero;
        await expect(staking.connect(admin).withdrawVouchers(zeroAddress, 0, 1)).to.be.revertedWith('WrongEndIndex()');

        // withdraw twice
        await staking.connect(admin).withdrawVouchers(alice.address, 0, 2);
        await staking.connect(admin).withdrawVouchers(alice.address, 0, 2);

        // check balances after withdraw
        assert.equal(await voteToken.balanceOf(alice.address), 400);
        assert.equal(await voucherToken.balanceOf(alice.address), 961);
        assert.equal(await staking.connect(alice).getVotesAmount(0, 2), 600);
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 0);

        // increase time
        const fiftyHours = 50 * 60 * 60 + 45 * 60;
        await ethers.provider.send('evm_increaseTime', [fiftyHours]);
        await ethers.provider.send('evm_mine');

        // check accumulated vouchers
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 249);

        // bob without any changes
        assert.equal(await voteToken.balanceOf(bob.address), 1300);
        assert.equal(await voucherToken.balanceOf(bob.address), 0);
        assert.equal(await staking.connect(bob).getVotesAmount(0, 1), 700);
        // (700 staked votes / 500) * (152 hours / 24 hours)
        assert.equal(await staking.connect(bob).getVouchersAmount(0, 1), 886);
    });

    it("Unstake votes", async function() {
        // before unstake
        assert.equal(await voteToken.balanceOf(alice.address), 400);
        assert.equal(await voucherToken.balanceOf(alice.address), 961);
        assert.equal(await staking.connect(alice).getVotesAmount(0, 2), 600);
        assert.equal(await staking.connect(alice).getVouchersAmount(0, 2), 249);

        // unstake
        assert.equal(await staking.getStakersNumber(), 2);
        assert.equal(await staking.getStakesNumber(alice.address), 2);
        await staking.connect(alice).unstakeVotes(0, 1);
        assert.equal(await staking.getStakersNumber(), 2);
        assert.equal(await staking.getStakesNumber(alice.address), 1);
        await staking.connect(alice).unstakeVotes(0, 1);
        assert.equal(await staking.getStakersNumber(), 1);
        assert.equal(await staking.getStakesNumber(alice.address), 0);

        // after unstake
        assert.equal(await voteToken.balanceOf(alice.address), 1000);
        assert.equal(await voucherToken.balanceOf(alice.address), 1210);
        await expect(staking.connect(alice).getVotesAmount(0, 2)).to.be.revertedWith('WrongEndIndex()');
        await expect(staking.connect(alice).getVouchersAmount(0, 2)).to.be.revertedWith('WrongEndIndex()');

        // bob was not hit
        assert.equal(await voteToken.balanceOf(bob.address), 1300);
        assert.equal(await voucherToken.balanceOf(bob.address), 0);
        assert.equal(await staking.connect(bob).getVotesAmount(0, 1), 700);
        assert.equal(await staking.connect(bob).getVouchersAmount(0, 1), 886);
    });
});
