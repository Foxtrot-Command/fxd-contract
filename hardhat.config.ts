
import * as dotenv from "dotenv";
dotenv.config()

import { extendEnvironment, HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "hardhat-contract-sizer";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "hardhat-deploy";
import "./tasks";

const private_keys: string[] = [
  process.env.PRIVATE_KEY_DEPLOYER as string
];

extendEnvironment((hre: any) => {
  const formatedCustomKeys = private_keys.map((private_key: string) => {
    return new hre.ethers.Wallet(private_key, hre.ethers.provider)
  })
  hre.multiSigAddress = '0x52b14E50D0490958B8ce34E14d27ceAA05391CCD';
  hre.customSigners = formatedCustomKeys;

});

interface FullHardhatUserConfig extends HardhatUserConfig {
  etherscan: {
    apiKey: any;
  }
}

const config: FullHardhatUserConfig = {
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
      initialBaseFeePerGas: 0,
      gasPrice: 5000000000
      /* forking: {
        url: "https://bsc-dataseed.binance.org"
      } */
    },
    bsc: {
      accounts: process.env.BSC_DEPLOYER_KEY !== undefined ? [process.env.BSC_DEPLOYER_KEY] : [],
      url: `https://bsc-dataseed1.binance.org`,
    },
    bscTestnet : {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [private_keys[0]]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [private_keys[0]],
      chainId: 4,
      gasPrice: 5000000000,
      gasMultiplier: 2
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true" ? true : false,
    token: "BNB",
    gasPriceApi: "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice",
    currency: "USD",
  },
  etherscan: {
    apiKey: /* {
      mainnet: process.env.ETHERSCAN_API_KEY,
      rinkeby: process.env.ETHERSCAN_API_KEY, */
      process.env.BSCSCAN_API_KEY

  },
};

export default config;