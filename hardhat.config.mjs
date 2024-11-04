import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import "@nomicfoundation/hardhat-foundry";

/** @type import('hardhat/config').HardhatUserConfig */
export default {
  solidity: {
    version: "0.8.26",
    settings: {
      viaIR: true
    }
  }
  
};
