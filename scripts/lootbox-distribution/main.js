// Prepare data for tests:
// 1) npx hardhat node
// 2) npx hardhat run scripts/lootbox-distribution/test-data.js --network localhost

// Launch distribution:
// 1) change PRIVATE_KEY in .env
// 2) change LOOTBOX_ADDRESS
// 3) fill the list of distribution
// 4) npx hardhat run scripts/lootbox-distribution/main.js --network localhost

const { ethers } = require("hardhat");


// localhost
const LOOTBOX_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
// recipient's address => list of tokeIds
const distribution = {
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC": ["1"],
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906": ["0", "2"],
};

// // BSC mainnet
// const LOOTBOX_ADDRESS = "0x7ee40fc74964dd7b027d5349de6dd23acf807c6f";
// // recipient's address => list of tokeIds
// const distribution = {
//     "0x380d4267dC110fF9AbFC2c14482b9d55BA0A8Dc1": ["732"],
//     "0x3399c93a8C61b0eABc5358a36D3862e650557e3d": ["733"],
//     "0x3D618F273F382b6d52ad2c6233a969Fc4A50aeEA": ["734"],
//     "0x38c86d8d2E1D256C9cc1732C1BF5a259A7ab2320": ["735"],
//     "0xAA84e65d3cfFAB0829F116E757e3EbC1e58a9A85": ["736"],
//     "0x97e93014B8ceE15177DbC58194F520F17037b5C7": ["737"],
//     "0x15C61c67EDCdE0B3Fa85997075F87f15190505Cc": ["738"],
//     "0x4E774A9CC188C10293AD9507e6794f75F709fD1e": ["739"],
//     "0x0C0feC2B3A20EF2389eBbb7923a351DBe7080f35": ["740"],
//     "0x1b824111F07E773FaEF07284F70c2cF755beb608": ["741"],
//     "0x7c29aD60aDA4B7AA75a339d4D9055Bf1FB17Ea1a": ["742"],
//     "0x3be148C1fb7244B169Ad0eB5F1a4c7F3a8B18edC": ["743"],
//     "0xe1648803a27Eb5704A5B296bb033BAAD716c341B": ["744"],
//     "0x3dC8104d4136Bd49cA3662b35b117ea3BC963E69": ["745"],
//     "0xedC3f8A3F8E0847e91E56F0D1a6eEDe3987CD4bf": ["746"],
//     "0x57D0D6bfa1699d2C99d869d51b8FCB9A73e0FBF3": ["747"],
//     "0x1F29cba44478Bd2df384e4b21B39e6fB92F350fa": ["748"],
//     "0x919677cD45E209b276F3CC65f8f96872B2F3b947": ["749"],
//     "0xb99C6c583639dF4504f22a91b2167AE1Ee439d00": ["750"],
//     "0xB75B668967473cC14615322b9d8BcffB591044A1": ["751"],
//     "0x8470629Ffd28fd18E41B636456a9CDD43AaD9e3B": ["752"],
//     "0x28ABd89DB49171D57Ce7c6Cf0851F39a3CD43363": ["753"],
//     "0x0eb37DaD11F8fd2FdE2a621C5c801292AEeEAE43": ["754"],
//     "0xEf440e569c925a277c4f219c194c86C807e11E04": ["755"],
//     "0x3c57d0A38Ed61eF0C23EA0c15F9165634b1bf10B": ["756"],
//     "0xb028C3C9d221BFC2786DEA2A8502b0449a09eFDB": ["757"],
//     "0x1a62a18883664DD21D91522afC1aD937f839C9A8": ["758"],
//     "0x1a4CA26eB1fA50c927388bCcB46B28AEBaF339d8": ["759"],
//     "0x438A091010DBbA318a1d8D7048AD1f2E1D133e41": ["760"],
//     "0xf354084ad463DCb9DE9308FF5A07C35038b2694E": ["761"],
//     "0xFd625e0405b418d539e852b50340A786db8C048d": ["762"],
//     "0x94F284057F807a536220dD5180a095dE226eCa8B": ["763"],
//     "0x5b91b7e41a586bebd4c0ef3cba77ba62d301df82": ["764"],
//     "0xd4b340fa4B1dE93959FD0EC377cc575D44391D96": ["765"],
//     "0xd7F0d1d5A784d9E5131Ce65deC0f28B9C8CBCd96": ["766"],
//     "0x13367A20679B6C4fE75e92326ef84e2F09E58C30": ["767"],
//     "0x7e0B84D32AAd3127baCf55a798d9834d2573cb05": ["768"],
//     "0xB5618867F5750904D5D17dd6E5a24ba53125BAFF": ["769"],
//     "0xAF1d089C1f8bC21cdFA761bD1A6d8c7C1aa75C0F": ["770"],
//     "0x980AaF219b12C7Bef412A0338B8cf0d4993b7E9e": ["771"],
//     "0x07F512660944b865C4a6880c9bD1062bbF350Daf": ["772"],
//     "0x57B80BdEA67ac2f112E74C7f165B8F94f3c6DCec": ["773"],  // to admin
//     "0x4E27bbc814f0b8581af0b6893Fb4450E553F1c27": ["774"],
//     "0x257a72cdf29Ce18178b387e3Eac982D4e9bF85F6": ["775"],
//     "0x299026a011a95083afa9e6dc6474f5147558e663": ["776"],
//     "0x859c3a5649c0cd88db495ae576f8430cdb48b2ee": ["777"],
//     "0x934F11b7D627d4c9a74F304940a0E1b10339B0Eb": ["778"],
//     "0x359fCa19BF122D2E734Cb86bAa9d6cA15f176Db3": ["779"],
//     "0x9f043aDDdAC06eF9934e987CF53f6187AE075F7F": ["780"],
//     "0xE1A5DF56Aa9af5D0BF3EEAb5b0ECbedccf5c4813": ["781"],
//     "0xc453e4f07E766bfF78B04e319beBefc57D64D3Ea": ["782"],
//     "0x46f5ce7081d33c3639c9c76912625eab6bcfbb70": ["783"],
//     "0x34c9fe7e1ba6abcbcf1abbe8308fd809f0869551": ["784"],
//     "0x991cc86e9af3d51251b041508f7e25e81e5e08cb": ["785"],
//     "0x37bb4f8b7aaab88a7cc7065fe7334ddcd62c1fa5": ["786"],
//     "0x4f3b8bfcc66d98e869d2ec8988434cb0881c5019": ["787"],
//     "0x52e5a80fc20b3aedefaae7c54d2c8a1a8ff6ddaf": ["788"],
//     "0xcC27819D2a88Ddc83A0A9f81aF426B5bF06Ee047": ["789"],
//     "0x8485b2a2930f3759e5cbb1c5f89ff488c833d1b5": ["790"],
//     "0xf6caeda93253a6ea822240a2e599c5abdb8ea69b": ["791"],
//     "0xad15fbe93dd6bd1b2d075432f65fbb294733f28e": ["792"],
//     "0x4EFfbda4A2486489c7750e003563D07B3f4cA1c4": ["793"],
//     "0x8280606afce89386f2155f40940d7a035debb5fd": ["794"],
//     "0xee2cf6040e6e891b0964e52276a1db32899bd4f2": ["795"],
// };

let contract;

async function distribute(owner, distribution) {
    console.log("Owner balance:", await contract.balanceOf(owner.address));

    // set nonce counter
    let baseNonce = ethers.provider.getTransactionCount(owner.address);
    let nonceOffset = 0;
    function getNonce() {
        return baseNonce.then((nonce) => (nonce + (nonceOffset++)));
    }

    for(let recipientAddress in distribution) {
        let tokenIds = distribution[recipientAddress];
        for (let i = 0; i < tokenIds.length; i++) {
            let tokenId = tokenIds[i];

            console.log("Transfer to: ", recipientAddress, " tokenId:", tokenId);
            let tx = await contract.transferFrom(owner.address, recipientAddress, tokenId, {nonce: getNonce()});
            tx.wait();
        }
    }

    console.log("Owner balance:", await contract.balanceOf(owner.address));
}

async function main() {
    const [owner] = await ethers.getSigners();
    console.log('OWNER', owner.address);

    contract = await ethers.getContractAt('Lootbox', LOOTBOX_ADDRESS, owner);

    await distribute(owner, distribution);
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });