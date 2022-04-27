const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { keccak256 } = require('@ethersproject/solidity');

describe.only("Voting", function() {
    this.timeout(20000);

    let admin, alice, bob, charlie;
    let token1, token2, voteToken, voucherToken;
    let nft, lootbox, marketplace;
    let mayorId, mayorId2, mayorId3, voting;

    const votingDuration = 86400;
    const governanceDuration = 86400 * 6; // 6 days
    const BASE_URI = "https://baseuri.io";
    const NUMBER_IN_LOOTBOXES = 20;
    const ALICE_MINT = 100;
    const ALICE_VOTE_MINT = BigInt(1000000 * ethers.utils.parseEther("0.001"));
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
        University: 0,
        Hospital: 1,
        Bank: 2,
        Factory: 3,
        Stadium: 4,
        Monument: 5
    }

    async function deploy(contractName, signer, ...args) {
        const Factory = await ethers.getContractFactory(contractName, signer)
        const instance = await Factory.deploy(...args)
        return instance.deployed()
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

        [admin, alice, bob, charlie] = await ethers.getSigners();

        token1 = await deploy("Token", admin, "Payment token 1", "PTN1", admin.address);
        token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);
        voteToken = await deploy("Token", admin, "Votes token", "VOTE", admin.address);
        voucherToken = await deploy("Token", admin, "BVoucher token", "BVOUCHER", admin.address);

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
        await marketplace.connect(admin).addToWhiteList(SEASON_ID_2, [alice.address]);
        await token1.connect(alice).approve(marketplace.address, season1.lootboxPrice);
        await marketplace.connect(alice).buyLootboxMP(SEASON_ID_1, 1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);
        await lootbox.connect(alice).reveal(0);
        mayorId = 0;
        mayorId2 = 1;
        mayorId3 = 2;
        voting = await deploy("Voting", admin, nft.address, voteToken.address, voucherToken.address, admin.address);

        await voteToken.connect(alice).approve(voting.address, ALICE_VOTE_MINT);
        await voucherToken.connect(alice).approve(voting.address, ALICE_VOUCHER_MINT);
    });

    it("Does not add the empty list of cities", async function() {
        await expect(voting.connect(admin).addCities(0, [])).to.be.revertedWith("EmptyArray");
    });

    it("Adds new cities and starts voting", async function() {
        let region1Cities = [
            {"id": 0, "name": "Test 0", "population": 1000000, "votePrice": ethers.utils.parseEther("0.001")},
            {"id": 2, "name": "Test 2", "population": 1500000, "votePrice": ethers.utils.parseEther("0.003")},
            {"id": 3, "name": "Test 3", "population": 30000, "votePrice": ethers.utils.parseEther("0.004")},
        ];
        let region2Cities = [
            {"id": 1, "name": "Test 1", "population": 100000, "votePrice": ethers.utils.parseEther("0.002")},
        ];

        await expect(voting.connect(admin).addCities(0, region1Cities)).to.emit(voting, "CitiesAdded").withArgs(0, [0, 2]);
        await expect(voting.connect(admin).addCities(1, region2Cities)).to.emit(voting, "CitiesAdded").withArgs(1, [1]);
        
    });

    it("Does not start voting before voting time ends", async function() {
        await expect(voting.connect(admin).startVoting(0)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Starts voting", async function() {
        await ethers.provider.send('evm_increaseTime', [votingDuration]);
        await expect(voting.connect(admin).startVoting(0)).to.emit(voting, "VotingStarted");
    });

    it("Does not calculate votes price for the mayor nore than maximum city bank", async function() {
        let votesAmount = 10000000;
        await expect(voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.revertedWith("VotesBankExceeded");
    });

    it("Calculating votes price for the mayor without discounts", async function() {
        let votesAmount = 100;
        let expectedPrice = BigInt(votesAmount * ethers.utils.parseEther("0.001"));
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);
    });

    it("Does not set up the amount of votes per citizens to zero", async function() {
        await expect(voting.connect(admin).changeVotesPerCitizen(0)).to.be.revertedWith("IncorrectValue");
    });

    it("Sets up the amount of votes per citizens", async function() {
        let votesAmount = 1000000;
        let expectedPrice = BigInt(votesAmount * ethers.utils.parseEther("0.001"));
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);

        let currentAmount = ethers.utils.parseEther("1");
        let newAmount = BigInt(currentAmount / 2);
        expect(await voting.connect(admin).changeVotesPerCitizen(newAmount)).to.emit(voting, "VotesPerCitizenUpdated").withArgs(currentAmount, newAmount);
        await expect(voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.revertedWith("VotesBankExceeded");
    });

    it("Does not allow to nominate candidate by the non NFT owner", async function() {
        let votesAmount = 100;
        await expect(voting.connect(admin).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("WrongMayor");
    });
    
    it("Does not allow to nominate candidate without enough tokens", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("InsufficientBalance");
    });

    it("Allows to nominate candidate", async function() {
        await voteToken.connect(admin).mint(alice.address, ALICE_VOTE_MINT);
        let votesAmount = 20000;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId, 0, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId2, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId2, 0, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId3, 2, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId3, 2, votesAmount);
        await expect(voting.connect(alice).nominate(mayorId2, 2, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId2, 2, votesAmount);
    });

    it("Does not add a building with non-mayor NFT", async function() {
        await expect(voting.connect(alice).addBuilding(0, mayorId, BUILDINGS.Hospital)).to.be.revertedWith("WrongMayor");
    });

    it("Does not choose winners during election", async function() {
        await expect(voting.connect(alice).chooseWinner(0)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Chooses winners", async function() {
        await ethers.provider.send('evm_increaseTime', [votingDuration]);
        await expect(voting.connect(alice).chooseWinner(0)).to.emit(voting, "Winners");
    });

    it("Does not calculate votes price for the mayor after election", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Does not add a building by the non NFT owner", async function() {
        await expect(voting.connect(admin).addBuilding(0, mayorId, BUILDINGS.Hospital)).to.be.revertedWith("WrongMayor");
    });

    it("Does not add a building without enough tokens", async function() {
        await expect(voting.connect(alice).addBuilding(0, mayorId, BUILDINGS.Hospital)).to.be.revertedWith("InsufficientBalance");
    });

    it("Adds a building by user", async function() {
        let cityMayor0 = (await voting.cityToMayor(0))["mayorId"];
        let cityMayor2 = (await voting.cityToMayor(2))["mayorId"];
        await voucherToken.connect(admin).mint(alice.address, ALICE_VOUCHER_MINT);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.University)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.University, 0, alice.address);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.Hospital)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Hospital, 0, alice.address);
        await expect(voting.connect(alice).addBuilding(2, cityMayor2, BUILDINGS.Hospital)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Hospital, 2, alice.address);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.Bank)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Bank, 0, alice.address);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.Factory)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Factory, 0, alice.address);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.Stadium)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Stadium, 0, alice.address);
        await expect(voting.connect(alice).addBuilding(0, cityMayor0, BUILDINGS.Monument)).to.emit(voting, "BuildingAdded").withArgs(BUILDINGS.Monument, 0, alice.address);
    });

    it("Does not add the already built building", async function() {
        await expect(voting.connect(alice).addBuilding(0, mayorId, BUILDINGS.Hospital)).to.be.revertedWith("BuildingDuplicate");
    });

    it("Closes cities", async function() {
        await expect(voting.connect(admin).updateCities([2, 3], false)).to.emit(voting, "CitiesUpdated").withArgs([2, 3], false);
    });

    it("Does not allow to nominate candidate to the non-active city", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 2, votesAmount)).to.be.revertedWith("InactiveObject");
        await expect(voting.connect(alice).nominate(mayorId, 3, votesAmount)).to.be.revertedWith("InactiveObject");
    });

    it("Does not allow to nominate candidate after election", async function() {
        let votesAmount = 100;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Deletes mayors info with voting start", async function() {
        expect((await voting.cityToMayor(0))["elected"]).to.be.equal(true);
        await ethers.provider.send('evm_increaseTime', [votingDuration]);
        await expect(voting.connect(admin).startVoting(0)).to.emit(voting, "VotingStarted");
        expect((await voting.cityToMayor(0))["elected"]).to.be.equal(false);
    });

    it("Calculating votes price for the mayor with discounts", async function() {
        await nft.updateLevel(mayorId);
        let votesAmount = 100;
        
        let rarity = await nft.getRarity(mayorId);
        let genVotesDiscount = await genVoteDiscount(rarity);
        let expectedPrice = BigInt(votesAmount * ethers.utils.parseEther("0.001") * (100 - genVotesDiscount - 7) / 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);

        rarity = await nft.getRarity(mayorId3);
        genVotesDiscount = 0;
        expectedPrice = BigInt(votesAmount * ethers.utils.parseEther("0.003") * (100 - genVotesDiscount - 5) / 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId3, 2, votesAmount)).to.be.equal(expectedPrice);
    });

    it("Does not calculate prize during election", async function() {
        await expect(voting.calculatePrize(0)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Does not change votes price for the incorrect city", async function() {
        let newVotePrice = ethers.utils.parseEther("0.002");
        await expect(voting.connect(admin).changeCityVotePrice(666, newVotePrice)).to.be.revertedWith("IncorrectValue");
    });

    it("Does not change votes price to the zero", async function() {
        let newVotePrice = 0;
        await expect(voting.connect(admin).changeCityVotePrice(0, newVotePrice)).to.be.revertedWith("IncorrectValue");
    });

    it("Changes votes price for the city", async function() {
        let votesAmount = 100;
        let rarity = await nft.getRarity(mayorId);
        let genVotesDiscount = await genVoteDiscount(rarity);
        let newVotePrice = ethers.utils.parseEther("0.002");
        await expect(voting.connect(admin).changeCityVotePrice(0, newVotePrice)).to.emit(voting, "VotePriceUpdated").withArgs(0, ethers.utils.parseEther("0.001"), newVotePrice);
        let expectedPrice = BigInt(votesAmount * newVotePrice * (100 - genVotesDiscount - 7) / 100);
        expect(await voting.connect(alice).calculateVotesPrice(mayorId, 0, votesAmount)).to.be.equal(expectedPrice);
    });

    it("Chooses winners in the region with closed cities", async function() {
        await voteToken.connect(admin).mint(alice.address, ALICE_VOTE_MINT);
        await voteToken.connect(alice).approve(voting.address, ALICE_VOTE_MINT);
        let votesAmount = 200;
        await expect(voting.connect(alice).nominate(mayorId, 0, votesAmount)).to.emit(voting, "CandidateAdded").withArgs(mayorId, 0, votesAmount);
        await ethers.provider.send('evm_increaseTime', [votingDuration]);
        await expect(voting.connect(alice).chooseWinner(0)).to.emit(voting, "Winners").withArgs(0, [mayorId]);
    });

    it("Does not calculate prize during governance period", async function() {
        await expect(voting.calculatePrize(0)).to.be.revertedWith("IncorrectVotingPeriod");
    });

    it("Calculates prize after governance period", async function() {
        let blockTimestamp = (await ethers.provider.getBlock()).timestamp;
        await ethers.provider.send("evm_setNextBlockTimestamp", [blockTimestamp + governanceDuration]);
        await ethers.provider.send("evm_mine");
        let expectedPrize = BigInt(200 * (87 + 7) / 100);
        expect(await voting.calculatePrize(0)).to.be.equal(expectedPrize);
    });

    it("Closes regions", async function() {
        await expect(voting.connect(admin).updateRegions([1], false)).to.emit(voting, "RegionsUpdated").withArgs([1], false);
    });

    it("Does not choose winners of closed regions", async function() {
        
        await expect(voting.connect(alice).chooseWinner(1)).to.be.revertedWith("InactiveObject");
    });

    it("Does not start voting in closed regions", async function() {
        await expect(voting.connect(admin).startVoting(1)).to.be.revertedWith("InactiveObject");
    });

});