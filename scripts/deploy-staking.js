const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");

async function deploy(contractName, signer, ...args) {
    const Factory = await ethers.getContractFactory(contractName, signer)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
}

async function main() {
    const [admin, alice, bob, charlie] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", admin.address);
    console.log("Accounts: ", admin.address, alice.address, bob.address, charlie.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    voteToken = await deploy("Token", admin, "Vote token", "Vote", admin.address);
    console.log("Vote token:", voteToken.address);

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

    await voucherToken.connect(admin).updateConfig(
        [
            staking.address,
        ]
    )
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
