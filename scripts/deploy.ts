import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import hre from 'hardhat'

async function main() {
  let deployer: SignerWithAddress;

  [deployer] = (hre as any).customSigners.concat(await hre.ethers.getSigners());

  const FoxtrotCommandToken = await hre.ethers.getContractFactory("FoxtrotCommand");
  const foxtrotToken = await FoxtrotCommandToken.deploy()
  await foxtrotToken.deployed();
  console.log("Token deployed to:", foxtrotToken.address);

  await hre.run("verify:verify", {
    address: foxtrotToken.address,
    contract: "contracts/FoxtrotCommand.sol:FoxtrotCommand",
    constructorArguments: []
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
