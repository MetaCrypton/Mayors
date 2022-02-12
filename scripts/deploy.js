const hre = require("hardhat");

async function deploy(contractName, deployer, ...args) {
    const Factory = await hre.ethers.getContractFactory(contractName, deployer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

function getIndexedEventArgsRAW(coder, tx, eventSignature, eventNotIndexedParams) {
    const sig = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes(eventSignature));
    const log = getLogByFirstTopic(tx, sig);
    return coder.decode(
        eventNotIndexedParams,
        log.data
    );
}

function getIndexedEventArgs(tx, eventSignature, topic) {
    const sig = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes(eventSignature));
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

async function main() {
    const NUMBER_IN_LOOTBOXES = 500;
    const PRICE = 100;

    const RATES = {
        common: 69,
        rare: 94,
        epic: 99,
        legendary: 100
    };

    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const token = await deploy("Token", deployer, "Payment token", "PTN", deployer.address);
    console.log(token.address);
    const nft = await deploy(
        "NFT",
        deployer,
        "Mayors",
        "MRS",
        deployer.address,
        RATES
    );
    console.log(nft.address);
    const lootbox = await deploy("Lootbox", deployer, "Lootboxes", "LBS", deployer.address, nft.address, NUMBER_IN_LOOTBOXES);
    console.log(lootbox.address);
    const marketplace = await deploy("Marketplace", deployer, deployer.address, lootbox.address, token.address, PRICE);
    console.log(marketplace.address);

    await lootbox.connect(deployer).setMarketplaceAddress(marketplace.address);
    await nft.connect(deployer).setLootboxAddress(lootbox.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
