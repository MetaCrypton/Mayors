
const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { deploy, getIndexedEventArgsRAW, getAllIndexedEventsArgsRAW, config, coder } = require("./utils");

describe("NFT", function() {
    this.timeout(20000);

    let admin, alice, bob, charlie;
    let token1;
    let token2;
    let nft;
    let lootbox;
    let marketplace;
    let inventory;
    let ids;
    let rarityCalculator;

    before(async function(){
        [admin, alice, bob, charlie] = await ethers.getSigners();

        token1 = await deploy("Token", admin, "Payment token 1", "PTN111", admin.address);
        token2 = await deploy("Token", admin, "Payment token 2", "PTN2", admin.address);

        rarityCalculator = await deploy("RarityCalculator", admin);
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
    });

    it("Reveals lootbox with correct proportion of nft's rarity", async function(){
        const NUMBER_IN_LOOTBOXES = 140;

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

        await token1.connect(admin).mint(alice.address, config.ALICE_MINT);

        await marketplace.connect(admin).addToEligible([alice.address]);

        await token1.connect(alice).approve(marketplace.address, config.PRICE);
        await marketplace.connect(alice).buyLootboxMP(1, [
            "0xec7c6f475a6906fcbf6e554651d7b7ee5189b7720b5b5156114f584164683940"
        ]);

        let names = [...Array(NUMBER_IN_LOOTBOXES).keys()].map(name=>name.toString());
        let tx = await lootbox.connect(alice).reveal(0, names);
        const result = await tx.wait();
        const eventArgs = getAllIndexedEventsArgsRAW(
            result,
            "NameSet(uint256,string)",
            ["uint256", "string"],
        );
        ids = eventArgs.map(function(event){
            return event[0].toNumber();
        });

        let commonCount = Math.floor(NUMBER_IN_LOOTBOXES * 0.69);
        let rareCount = Math.floor(NUMBER_IN_LOOTBOXES * 0.25);
        let epicCount = Math.floor(NUMBER_IN_LOOTBOXES * 0.05);
        let legendaryCount = Math.floor(NUMBER_IN_LOOTBOXES * 0.01);


        let commonNFTs = ids.filter(i => i < 138000).length;
        let rareNFTs = ids.filter(i => i >= 138000 && i < 188000).length;
        let epicNFTs = ids.filter(i => i >= 188000 && i < 198000).length;
        let legendaryNFTs = ids.filter(i => i >= 198000).length;

        let accuracy = 0.30;
        let coeffMin, coeffMax;
        [coeffMin, coeffMax] = [1-accuracy, 1+accuracy];

        assert.isAtLeast(commonNFTs, Math.floor(commonCount * coeffMin));
        assert.isAtMost(commonNFTs, Math.floor(commonCount * coeffMax));
        assert.isAtLeast(rareNFTs, Math.floor(rareCount * coeffMin));
        assert.isAtMost(rareNFTs, Math.floor(rareCount * coeffMax));
        assert.isAtLeast(epicNFTs, Math.floor(epicCount * coeffMin));
        assert.isAtMost(epicNFTs, Math.floor(epicCount * coeffMax));
        assert.isAtLeast(legendaryNFTs, Math.floor(legendaryCount * coeffMin));
        assert.isAtMost(legendaryNFTs, Math.floor(legendaryCount * coeffMax));
    });
});