
import * as dotenv from "dotenv";
dotenv.config()

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "hardhat-contract-sizer";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "hardhat-deploy";
import "./tasks";

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
