const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");

async function deploy(contractName, signer, ...args) {
    const Factory = await ethers.getContractFactory(contractName, signer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

async function main() {
    const [admin, alice, bob, charlie, voting] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);
    console.log("Accounts: ", admin.address, alice.address, bob.address, charlie.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    voteToken = await deploy(
        "Vote",
        admin,
        "Votes token",
        "Vote$",
        admin.address,
    );
    console.log("Vote$ token:", voteToken.address);

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
    console.log("BVoucher token:", voucherToken.address);

    staking = await deploy(
        "Staking",
        admin,
        [
            voteToken.address,
            voucherToken.address,
        ],
        admin.address
    );
    console.log("Staking:", staking.address);

    // TODO: deploy Voting contract
    console.log("Voting(mocked):", voting.address);

    await voucherToken.connect(admin).updateConfig(
        [
            staking.address,
        ]
    )
    // TODO: use an address of voting contract after it will be written
    await voteToken.connect(admin).updateConfig(
        [
            voting.address,
        ]
    )
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
