// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  let masterAccount;

  [masterAccount] = await ethers.getSigners();

  const FoxtrotCommandToken = await hre.ethers.getContractFactory("FoxtrotCommand");
  const foxtrotToken = await FoxtrotCommandToken.deploy(215000000, [
    "Seed",
    "Private",
    "Public",
    "Ecosystem",
    "Partners",
    "Team",
    "Staking",
    "Play",
    "Marketing"
  ], [
    ethers.utils.parseEther(String(32250000)),
    ethers.utils.parseEther(String(31605000)),
    ethers.utils.parseEther(String(4945000)),
    ethers.utils.parseEther(String(19350000)),
    ethers.utils.parseEther(String(19350000)),
    ethers.utils.parseEther(String(32250000)),
    ethers.utils.parseEther(String(43000000)),
    ethers.utils.parseEther(String(25800000)),
    ethers.utils.parseEther(String(6450000))
  ])
  
  //const BusdToken = await hre.ethers.getContractFactory("MockBUSD");
  //const busdToken = await BusdToken.deploy();
  
  //const SeedSale = await hre.ethers.getContractFactory("FoxtrotSeedSale");
  //const seedSale = await SeedSale.deploy(masterAccount.address, busdToken.address);

  await foxtrotToken.deployed();
  //await busdToken.deployed();
  //await seedSale.deployed();

  //await seedSale.connect(masterAccount).addAddressToWhitelist(masterAccount.address, ethers.utils.parseEther('120000'));
  //await foxtrotToken.connect(masterAccount).transfer(seedSale.address, ethers.utils.parseEther('32250000'));

  //await foxtrotToken.connect(masterAccount).setAddressOfAllowedContract('Seed', seedSale.address);
  //await foxtrotToken.connect(masterAccount).safeTransferBusinessTokens('Seed');
  //await seedSale.setContractToken(foxtrotToken.address);

  console.log("Token deployed to:", foxtrotToken.address);

  /* console.log(`
NEXT_PUBLIC_SEED_CONTRACT=${seedSale.address}
NEXT_PUBLIC_BUSD_CONTRACT=${busdToken.address}
NEXT_PUBLIC_FXD_CONTRACT=${foxtrotToken.address}
  `) */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
