const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function() {
    this.timeout(20000);

    let admin, alice, bob, charlie;
    let token1, token2, voteToken, voucherToken;
    let nft, lootbox, marketplace;
    let mayorId, mayorId2, mayorId3, voting;

    const votingDuration = 86400;
    const governanceDuration = 86400 * 6; // 6 days
    const VOTES_PER_CITIZEN = 100;
    const BASE_URI = "https://baseuri.io";
    const NUMBER_IN_LOOTBOXES = 20;
    const ALICE_MINT = 100;
    const ALICE_VOTE_MINT = BigInt(1000 * 10 ** 4);
    const ALICE_VOUCHER_MINT = 230000;
    const LOOTBOXES_BATCH = 1497;
    const SEASON_ID_1 = 0;
    const SEASON_ID_2 = 1;
    const RARITIES = {
        common: 0,
        rare: 1,
        epic: 2,
        legendary: 3
    };
    const GEN1_VOTES_DISCOUNT = {
        common: 1,
        rare: 2,
        epic: 4,
        legendary: 6
    };

    const BUILDINGS = {
        Empty: 0,
        University: 1,
        Hospital: 2,
        Bank: 3,
        Factory: 4,
        Stadium: 5,
        Monument: 6
    }

    async function deploy(contractName, signer, ...args) {
        const Factory = await ethers.getContractFactory(contractName, signer);
        const instance = await Factory.deploy(...args);
        return instance.deployed();
    }

    async function genVoteDiscount(rarity) {
        if (rarity == RARITIES.common) {
            return GEN1_VOTES_DISCOUNT.common;
        } else if (rarity == RARITIES.rare) {
            return GEN1_VOTES_DISCOUNT.rare;
        } else if (rarity == RARITIES.epic) {
            return GEN1_VOTES_DISCOUNT.epic;
        } else if (rarity == RARITIES.legendary) {
            return GEN1_VOTES_DISCOUNT.legendary;
        }
    }

    before(async function() {
        let season1 = {
            startTimestamp: 0,
            endTimestamp: 0,
            lootboxesNumber: 1,
            lootboxPrice: 100,
            lootboxesPerAddress: 3,
            lootboxesUnlockTimestamp: 0,
            nftNumberInLootbox: NUMBER_IN_LOOTBOXES,
            nftStartIndex: 0,
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
            nftNumberInLootbox: NUMBER_IN_LOOTBOXES,
            nftStartIndex: NUMBER_IN_LOOTBOXES * season1.lootboxesNumber,
            merkleRoot: "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80",
            isPublic: true,
            uri: "season2"
        };

        [admin, alice, bob, charlie] = await ethers.getSigners();

        token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
        token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);
        voteToken = await deploy("Vote", admin, "Votes token", "VOTE", admin.address);
        voucherToken = await deploy(
            "Voucher",
            admin,
            "BVoucher token",
            "BVOUCHER",
            [ethers.constants.AddressZero],
            admin.address
        );

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
            admin.address
        );
        await lootbox.connect(admin).updateConfig(
            [
                marketplace.address,
                nft.address
            ],
            "http://www.lootbox.json",
        );
        await nft.connect(admin).updateConfig(
            [
                lootbox.address,
                admin.address,
                rarityCalculator.address
            ]
        );
        await marketplace.connect(admin).addNewSeasons(
            [
                season1,
                season2
            ]
        );

        await token1.connect(admin).mint(alice.address, ALICE_MINT);
        await marketplace.connect(admin).addToWhiteList(SEASON_ID_2, [alice.address]);
        await token1.connect(alice).approve(marketplace.address, season1.lootboxPrice);
        await marketplace.connect(alice).buyLootboxMP(SEASON_ID_1, 1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);
        await lootbox.connect(alice).reveal(0);
        mayorId = 0;
        mayorId2 = 1;
        mayorId3 = 2;
        voting = await deploy("Voting", admin, nft.address, voteToken.address, voucherToken.address, VOTES_PER_CITIZEN, admin.address);

        await voteToken.connect(admin).updateConfig(
            [
                voting.address,
            ]
        )
        await voteToken.connect(alice).approve(voting.address, ALICE_VOTE_MINT);
        await voucherToken.connect(alice).approve(voting.address, ALICE_VOUCHER_MINT);
    });

    it("Does not add the empty list of cities", async function() {
        await expect(voting.connect(admin).addCities(0, [])).to.be.revertedWith("EmptyArray");
    });

    // season 1

    it("Adds new cities and starts voting", async function() {
        let region1Cities = [
            {"name": "Test 0", "population": 1000000, "votePrice": 100},
            {"name": "Test 1", "population": 100000, "votePrice": 200},
            {"name": "Test 2", "population": 1500000, "votePrice": 300},
        ];
        let region2Cities = [
            {"name": "Test 3", "population": 30000, "votePrice": 400},
        ];

        let region1Cities2 = [
            {"name": "Test 4", "population": 40000, "votePrice": 500},
            {"name": "Test 5", "population": 50000, "votePrice": 600},
        ];

        await expect(voting.connect(admin).addCities(0, region1Cities)).to.emit(voting, "CitiesAdded").withArgs(0, [0, 1, 2]);
        await expect(voting.connect(admin).addCities(1, region2Cities)).to.emit(voting, "CitiesAdded").withArgs(1, [3]);
        await expect(voting.connect(admin).addCities(0, region1Cities2)).to.emit(voting, "CitiesAdded").withArgs(0, [4, 5]);

    });

    it("Calculating votes price for the mayor without discounts", async function() {
        let votesAmount = 100;
        let expectedPrice = BigInt(votesAmount * 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);
    });

    it("Does not set up the amount of votes per citizens to zero", async function() {
        await expect(voting.connect(admin).changeVotesPerCitizen(0)).to.be.revertedWith("IncorrectValue");
    });

    it("Sets up the amount of votes per citizens", async function() {
        let votesAmount = 10000;
        let expectedPrice = BigInt(votesAmount * 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);

        let newAmount = BigInt(VOTES_PER_CITIZEN / 2);
        expect(await voting.connect(admin).changeVotesPerCitizen(newAmount)).to.emit(voting, "VotesPerCitizenUpdated").withArgs(VOTES_PER_CITIZEN, newAmount);
    });

    it("Does not allow to nominate candidate by the non NFT owner", async function() {
        let votesAmount = 100;
        await expect(voting.connect(admin).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("WrongMayor");
    });

    it("Does not allow to nominate candidate without enough tokens", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Does not close cities during voting", async function() {
        await expect(voting.connect(admin).updateCities([2, 3, 1], false)).to.be.revertedWith("IncorrectPeriod");
    });

    it("Allows to nominate candidate", async function() {
        await voteToken.connect(admin).transfer(alice.address, ALICE_VOTE_MINT);
        let votesAmount = 200;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId, 0, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId2, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId2, 0, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId3, 2, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId3, 2, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId2, 2, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId2, 2, votesAmount);
    });

    it("Does not add a building in the incorrect city", async function() {
        await expect(voting.connect(alice).addBuilding(999, BUILDINGS.Hospital)).to.be.revertedWith("UnknownCity");
    });

    it("Does not add a building before governing period", async function() {
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Hospital)).to.be.revertedWith("IncorrectPeriod");
    });

    it("Does not add a building by the non NFT owner", async function() {
        let blockTimestamp = (await ethers.provider.getBlock()).timestamp;
        await ethers.provider.send("evm_setNextBlockTimestamp", [blockTimestamp + votingDuration]);
        await ethers.provider.send("evm_mine");
        await expect(voting.connect(admin).addBuilding(0, BUILDINGS.Hospital)).to.be.revertedWith("NotWinner");
    });

    it("Does not add a building without enough tokens", async function() {
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Hospital)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Adds a building by user", async function() {
        let cityMayor0 = await voting.getWinner(0, 1);
        let cityMayor2 = await voting.getWinner(2, 1);
        await voucherToken.connect(admin).mint(alice.address, ALICE_VOUCHER_MINT);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.University)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.University);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Hospital)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.Hospital);
        await expect(voting.connect(alice).addBuilding(2, BUILDINGS.Hospital)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 2, 1, BUILDINGS.Hospital);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Bank)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.Bank);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Factory)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.Factory);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Stadium)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.Stadium);
        await expect(voting.connect(alice).addBuilding(2, BUILDINGS.Stadium)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 2, 1, BUILDINGS.Stadium);
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Monument)).to.emit(voting, "BuildingAdded").withArgs(alice.address, 0, 1, BUILDINGS.Monument);
    });

    it("Does not add the already built building", async function() {
        await expect(voting.connect(alice).addBuilding(0, BUILDINGS.Hospital)).to.be.revertedWith("BuildingDuplicate");
    });

    it("Closes cities", async function() {
        await expect(voting.connect(admin).updateCities([2, 3], false))
            .to.emit(voting, "CityUpdated").withArgs(2, false)
            .to.emit(voting, "CityUpdated").withArgs(3, false);
    });

    it("Does not allow to nominate candidate to the non-active city", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 2, votesAmount)).to.be.revertedWith("InactiveObject");
        await expect(voting.connect(alice).nominate(mayorId, 3, votesAmount)).to.be.revertedWith("InactiveObject");
    });

    it("Does not allow to nominate candidate after election", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("IncorrectPeriod");
    });

    it("Does not allow to claim prize for the incorrect city", async function() {
        await expect(voting.connect(alice).claimPrizes([[999, [1], []]])).to.be.revertedWith("UnknownCity");
    });

    it("Does not allow to claim prize in the non-reward period", async function() {
        await expect(voting.connect(alice).claimPrizes([[0, [1], []]])).to.be.revertedWith("IncorrectPeriod");
    });

    it("Does not get unclaimed seasons in the non-reward period", async function() {
        let cityId = 0;
        let startSeason = 1;
        let endSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        let currentSeason = endSeason;
        expect(endSeason).to.be.equal(1);

        let unclaimedSeasons = await voting.connect(alice).getUnclaimedSeasons(alice.address, cityId, startSeason, endSeason, currentSeason);
        expect(unclaimedSeasons.length).to.be.equal(1);
        expect(unclaimedSeasons[0]).to.be.equal(false);

        // future season
        unclaimedSeasons = await voting.connect(alice).getUnclaimedSeasons(alice.address, cityId, startSeason, endSeason, currentSeason+1);
        expect(unclaimedSeasons.length).to.be.equal(1);
        expect(unclaimedSeasons[0]).to.be.equal(true);
    });

    it("Get election prizes", async function() {
        let cityId = 0;
        let unclaimedSeasons = [1];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(
            alice.address, cityId, unclaimedSeasons, [], currentSeason)).to.be.equal(348);
    });

    it("Does not get prizes from non-exists seasons", async function() {
        let cityId = 0;
        let unclaimedSeasons = [1, 2, 3];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(
            alice.address, cityId, unclaimedSeasons, [], currentSeason)).to.be.equal(348);
    });

    it("Does not get unclaimed buildings in the non-reward period", async function() {
        let cityId = 0;
        let buildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium, BUILDINGS.Monument];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(currentSeason).to.be.equal(1);

        let unclaimedBuildings = await voting.connect(alice).getUnclaimedBuildings(alice.address, cityId, buildings, currentSeason);
        expect(unclaimedBuildings.length).to.be.equal(4);
        expect(unclaimedBuildings[0]).to.be.equal(false);
        expect(unclaimedBuildings[1]).to.be.equal(false);
        expect(unclaimedBuildings[2]).to.be.equal(false);
        expect(unclaimedBuildings[3]).to.be.equal(false);

        // future season
        unclaimedBuildings = await voting.connect(alice).getUnclaimedBuildings(alice.address, cityId, buildings, currentSeason+1);
        expect(unclaimedBuildings.length).to.be.equal(4);
        expect(unclaimedBuildings[0]).to.be.equal(true);
        expect(unclaimedBuildings[1]).to.be.equal(true);
        expect(unclaimedBuildings[2]).to.be.equal(true);
        expect(unclaimedBuildings[3]).to.be.equal(false);
    });

    it("Get buliding prizes", async function() {
        let cityId = 0;
        let unclaimedBuildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium, BUILDINGS.Monument];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(
            alice.address, cityId, [], unclaimedBuildings, currentSeason)).to.be.equal(0);
    });

    it("Get buliding prizes for the future seasons", async function() {
        let cityId = 0;
        let unclaimedBuildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium, BUILDINGS.Monument];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(
            alice.address, cityId, [], unclaimedBuildings, currentSeason + 1)).to.be.equal(56);
    });

    it("Get monument prizes for the future seasons", async function() {
        let cityId = 0;
        let unclaimedBuildings = [BUILDINGS.Monument];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason)).to.be.equal(0);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 1)).to.be.equal(0);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 2)).to.be.equal(0);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 3)).to.be.equal(0);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 4)).to.be.equal(4);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 500)).to.be.equal(4);
    });

    it("Does not get prizes from non-claimable buildings", async function() {
        let cityId = 0;
        let unclaimedBuildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium, BUILDINGS.Monument, BUILDINGS.Hospital];
        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason)).to.be.equal(0);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, [], unclaimedBuildings, currentSeason + 1)).to.be.equal(56);
    });

    it("Calculates prize after governance period", async function() {
        let cityId = 0;
        let blockTimestamp = (await ethers.provider.getBlock()).timestamp;
        await ethers.provider.send("evm_setNextBlockTimestamp", [blockTimestamp + governanceDuration]);
        await ethers.provider.send('evm_increaseTime', [1]); // transit from governance to voting period
        await ethers.provider.send("evm_mine");

        let currentSeason = Number(await voting.connect(alice).getCurrentSeason(cityId));
        expect(currentSeason).to.be.equal(2);

        let unclaimedSeasons = [1];
        let unclaimedBuildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium];
        let expectedPrize = BigInt(400 * (87 + 7 + 5 + 2) / 100);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId, unclaimedSeasons, unclaimedBuildings, currentSeason)).to.be.equal(expectedPrize);
    });

    it("Claiming prize after governance period", async function() {
        let cityId0 = 0;
        let cityId2 = 2;
        let currentSeason = 2;
        let unclaimedSeasons0 = [1];
        let unclaimedBuildings0 = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium];
        let unclaimedSeasons2 = [1];
        let unclaimedBuildings2 = [BUILDINGS.Stadium];

        let expectedPrize0 = Number(await voting.connect(alice).calculatePrizes(alice.address, cityId0, unclaimedSeasons0, unclaimedBuildings0, currentSeason));
        let expectedPrize2 = Number(await voting.connect(alice).calculatePrizes(alice.address, cityId2, unclaimedSeasons2, unclaimedBuildings2, currentSeason));
        let totalexpected = expectedPrize0 + expectedPrize2;
        let aliceBalance = Number(await voteToken.balanceOf(alice.address));
        let votingBalance = Number(await voteToken.balanceOf(voting.address));
        await expect(voting.connect(alice).claimPrizes([
            [0, unclaimedSeasons0, unclaimedBuildings0],
            [2, unclaimedSeasons2, unclaimedBuildings2],
        ]))
            .to.emit(voting, "PrizeClaimed").withArgs(alice.address, totalexpected, 400 * 0.03 * 2)
            .to.emit(voteToken, "Transfer").withArgs(voting.address, alice.address, expectedPrize0 + expectedPrize2)
        expect(await voteToken.balanceOf(alice.address)).to.be.equal(aliceBalance + totalexpected);
        expect(await voteToken.balanceOf(voting.address)).to.be.equal(votingBalance - totalexpected - 400 * 0.03 * 2);
    });

    it("Does not claim prize second time", async function() {
        let cityId = 0;
        let unclaimedSeasons = [1];
        let unclaimedBuildings = [BUILDINGS.Bank, BUILDINGS.Factory, BUILDINGS.Stadium];
        await expect(voting.connect(alice).claimPrizes([[cityId, unclaimedSeasons, unclaimedBuildings]])).to.be.revertedWith("AlreadyClaimed");
    });

    // season 2
    it("Calculating votes price for the mayor with discounts", async function() {
        await nft.updateLevel(mayorId);
        let votesAmount = 100;

        let rarity = await nft.getRarity(mayorId);
        let genVotesDiscount = await genVoteDiscount(rarity);
        let expectedPrice = BigInt(votesAmount * 100 * (100 - genVotesDiscount - 7) / 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);

        rarity = await nft.getRarity(mayorId3);
        genVotesDiscount = 0;
        expectedPrice = BigInt(votesAmount * 300 * (100 - genVotesDiscount - 5) / 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId3, 2, votesAmount)).to.be.equal(expectedPrice);
    });

    it("Does not change votes price during election", async function() {
        let newVotePrice = 200;
        await expect(voting.connect(admin).changeCityVotePrice(0, newVotePrice)).to.be.revertedWith("IncorrectPeriod");
    });

    it("Chooses winners in the region with closed cities", async function() {
        await voteToken.connect(admin).transfer(alice.address, ALICE_VOTE_MINT);
        await voteToken.connect(alice).approve(voting.address, ALICE_VOTE_MINT);
        let votesAmount = 200;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId, 0, votesAmount);
        await ethers.provider.send('evm_increaseTime', [votingDuration]);
    });

    it("Does not change votes price for the incorrect city", async function() {
        let newVotePrice = 200;
        await expect(voting.connect(admin).changeCityVotePrice(666, newVotePrice)).to.be.revertedWith("UnknownCity");
    });

    it("Does not change votes price to the zero", async function() {
        let newVotePrice = 0;
        await expect(voting.connect(admin).changeCityVotePrice(0, newVotePrice)).to.be.revertedWith("IncorrectValue");
    });

    it("Changes votes price for the city", async function() {
        let newVotePrice = 200;
        await expect(voting.connect(admin).changeCityVotePrice(0, newVotePrice)).to.emit(voting, "VotePriceUpdated").withArgs(0, 100, newVotePrice);
    });

    it("Does not add a building with non-mayor NFT", async function() {
        let winner = await voting.getWinner(0, 1);
        expect(await nft.ownerOf(winner)).to.be.equal(alice.address);
        await expect(voting.connect(admin).addBuilding(0, BUILDINGS.Hospital)).to.be.revertedWith("NotWinner");
    });

    // season 3

    it("Calculates prize for the mayor with the factory and with no buildings", async function() {
        let cityId4 = 4;
        let cityId5 = 5;
        let currentSeason = 3;
        let votesAmount = 200;
        let blockTimestamp = (await ethers.provider.getBlock()).timestamp;
        await ethers.provider.send("evm_setNextBlockTimestamp", [blockTimestamp + governanceDuration]);
        await ethers.provider.send("evm_mine");

        await expect(voting.connect(alice).nominate(mayorId, cityId4, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId, cityId4, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId2, cityId5, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId2, cityId5, votesAmount);
        await ethers.provider.send('evm_increaseTime', [votingDuration]);

        await expect(voting.connect(alice).addBuilding(cityId4, BUILDINGS.Factory)).to.emit(voting, "BuildingAdded").withArgs(alice.address, cityId4, currentSeason, BUILDINGS.Factory);

        blockTimestamp = (await ethers.provider.getBlock()).timestamp;
        await ethers.provider.send("evm_setNextBlockTimestamp", [blockTimestamp + governanceDuration]);
        await ethers.provider.send("evm_mine");
        currentSeason = 4;

        let expectedPrize4 = BigInt(votesAmount * (87 + 5) / 100);
        let expectedPrize5 = BigInt(votesAmount * 87 / 100);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId4, [3], [BUILDINGS.Factory], currentSeason)).to.be.equal(expectedPrize4);
        expect(await voting.connect(alice).calculatePrizes(alice.address, cityId5, [3], [], currentSeason)).to.be.equal(expectedPrize5);
    });

    it("Transfer tokens to recipient", async function() {
        let voteBalance = await voteToken.balanceOf(voting.address);
        let voucherBalance = await voucherToken.balanceOf(voting.address);
        await expect(voting.connect(admin).transferTokens(bob.address))
            .to.emit(voteToken, "Transfer").withArgs(voting.address, bob.address, voteBalance)
            .to.emit(voucherToken, "Transfer").withArgs(voting.address, bob.address, voucherBalance);
        expect(await await voteToken.balanceOf(bob.address)).to.be.equal(voteBalance);
        expect(await await voucherToken.balanceOf(bob.address)).to.be.equal(voucherBalance);
    });
});