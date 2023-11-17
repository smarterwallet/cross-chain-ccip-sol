const { ethers } = require("hardhat");

const networkConfig = {
  default: {
    name: "hardhat",
  },
  31337: {
    name: "localhost",
  },
  11155111: {
    name: "sepolia",
    linkToken: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
    routerAddress: "0xd0daae2231e9cb96b94c8512223533293c3693bf",
  },
  143113: {
    name: "mainnet",
    routerAddress: "0xd0daae2231e9cb96b94c8512223533293c3693bf",
    linkToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
    crossChainToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
  },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
  networkConfig,
  developmentChains,
};
