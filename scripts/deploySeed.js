// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  let masterAccount;

  [masterAccount] = await ethers.getSigners();

  const seedSale = (await hre.ethers.getContractFactory("FoxtrotSeedSale")).attach("0xeb720adc2778e32be2260275cfdd7c97081869ae")

  await seedSale.deployed();
  
  console.log("Contract address: %s", seedSale.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
