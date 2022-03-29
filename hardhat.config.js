require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0
      /* forking: {
        url: "https://bsc-dataseed.binance.org"
      } */
    },
    bsc: {
      accounts: process.env.BSC_KEY !== undefined ? [process.env.BSC_KEY] : [],
      url: `https://bsc-dataseed1.binance.org`,
    },
    bscTestnet : {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: process.env.BSC_TESNET_KEY !== undefined ? [process.env.BSC_TESTNET_KEY] : []
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true" ? true : false,
    token: "BNB",
    gasPriceApi: "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice",
    currency: "USD",
  },
  etherscan: {
    apiKey: 'QK2C68NV8K7G2IEK636A9KJHCJ2NDQK8SF',
  },
};
