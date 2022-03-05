const { ethers, upgrades, waffle } = require("hardhat");

const config = {
    LOOTBOXES_CAP: 3,
    LOOTBOXES_PER_ADDRESS: 3,
    NUMBER_IN_LOOTBOXES : 3,
    PRICE : 100,
    ALICE_MINT : 100,
    CHARLIE_MINT : 200,
    RESALE_PRICE : 200,
    RESALE_FEE : 200 / 100,
    RESALE_INCOME : 200 - 200 / 100,
    BOB_MINT : 10,

    LOOTBOX_ID_0 : 0,
    MAYOR_ID_0 : 0,
    MAYOR_ID_1 : 1,

    GEN0 : 0,
    GEN1 : 1,
    GEN2 : 2,

    MERKLE_ROOT : "0xef632875969c3f4f26e5150b180649bf68b4ead8eef4f253dee7559f2e2d7e80",

    RATES : {
        common: 69,
        rare: 94,
        epic: 99,
        legendary: 100
    },
    RARITIES : {
        common: 0,
        rare: 1,
        epic: 2,
        legendary: 3
    }
}

async function deploy(contractName, signer, args) {
    const Factory = await ethers.getContractFactory(contractName, signer);
    const instance = await upgrades.deployProxy(Factory, args);
    return instance.deployed();
}

async function upgrade(proxy, contractName, signer) {
    const Factory = await ethers.getContractFactory(contractName, signer);
    const instance = await upgrades.upgradeProxy(proxy, Factory);
}

module.exports = { deploy, upgrade, config }