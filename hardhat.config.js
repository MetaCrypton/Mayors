require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.4",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  networks: {
    hardhat: {
      blockGasLimit: 75501907
    },
    goerli: {
      url: `https://goerli.infura.io/v3/31c3397beb4146e4acc9f4a072da5d23`,
      accounts: [
        `0x9d3c762f8732713986756a11c52e6cb60eabc7c2e79d52876ca51425456f1616`,
        `0xeee42d472b027d6efbf8b54e6d824b457c623e5b0ca3f3ac9210a9ec4b865e31`,
        `0x490f59212fee8a04a18ab4f93d85d7fa8246164b16fa861ee8578f1099ba2f2f`,
        `0xa4169cbd5cbd698d5cbb3e6460500846ec647ac6f5e6290bb57b3f1cba1dd4ff`,
      ],
      timeout: 100000
    },
    kovan: {
      url: `https://kovan.infura.io/v3/31c3397beb4146e4acc9f4a072da5d23`,
      accounts: [
        `0x9d3c762f8732713986756a11c52e6cb60eabc7c2e79d52876ca51425456f1616`,
        `0xeee42d472b027d6efbf8b54e6d824b457c623e5b0ca3f3ac9210a9ec4b865e31`,
        `0x490f59212fee8a04a18ab4f93d85d7fa8246164b16fa861ee8578f1099ba2f2f`,
        `0xa4169cbd5cbd698d5cbb3e6460500846ec647ac6f5e6290bb57b3f1cba1dd4ff`,
      ],
      gasPrice: 5000000000,
      timeout: 100000
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/31c3397beb4146e4acc9f4a072da5d23`,
      accounts: [`${PRIVATE_KEY}`],
      timeout: 100000
    },
    bsc_testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      accounts: [`${PRIVATE_KEY}`],
      timeout: 100000
    },
  },
  mocha: {
    timeout: 20000
  }
};
