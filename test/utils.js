const { ethers, upgrades, waffle } = require("hardhat");

const config = {
    LOOTBOXES_CAP : 3,
    LOOTBOXES_PER_ADDRESS : 3,
    NUMBER_IN_LOOTBOXES : 3,
    PRICE : 100,
    ALICE_MINT : 100,
    CHARLIE_MINT : 200,
    RESALE_PRICE : 200,
    RESALE_FEE : 2,
    RESALE_INCOME : 198,
    BOB_MINT : 10,

    LOOTBOX_ID_0 : 0,
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
    },
    ZEROADDRESS: "0x0000000000000000000000000000000000000000"
}

const coder = ethers.utils.defaultAbiCoder;

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

function getAllIndexedEventsArgsRAW(tx, eventSignature, eventNotIndexedParams) {
    const sig = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventSignature));
    const log = getLogByTopic(tx, sig);
    return log.map(function(event){
        return coder.decode(
                eventNotIndexedParams,
                event.data
        );
    });
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

function getLogByTopic(tx, firstTopic) {
    const logs = tx.events;
    return logs.filter(event=>event.topics[0] === firstTopic);
}

module.exports = { deploy, getIndexedEventArgsRAW, getAllIndexedEventsArgsRAW, config, coder }