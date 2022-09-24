require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {

    hardhat: {
      forking: {
        url: "https://goerli.optimism.io"
      },
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000
    },
    mumbai: {
      url: "https://goerli.optimism.io" || "",
      accounts:
       ["PVT_KEY"],
      allowUnlimitedContractSize: true,
    },
  },
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: "API_KEY"
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS,
    currency: "USD",
    token: "MATIC",
    gasPriceApi: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice"
  },
};
