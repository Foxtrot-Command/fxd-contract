// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import hre from 'hardhat'

async function main() {
  let deployer: SignerWithAddress;

  [deployer] = (hre as any).customSigners.concat(await hre.ethers.getSigners());
  let multisigWallet = (hre as any).multiSigAddress;

  // Deploy FXD contract

  const FoxtrotCommandToken = await hre.ethers.getContractFactory("FoxtrotCommand");
  const foxtrotToken = await FoxtrotCommandToken.deploy(multisigWallet)
  await foxtrotToken.deployTransaction.wait(5);

  try {
    await hre.run("verify:verify", {
      address: foxtrotToken.address,
      contract: "contracts/FoxtrotCommand.sol:FoxtrotCommand",
      constructorArguments: [multisigWallet]
    });
  } catch (err: any) {
    if (err.message.includes("Reason: Already Verified")) {
      console.log("Contract is already verified!");
    }
  }

  // Deploy TimeLockController contract

  let args = require('./arguments.js');

  const TimeLockController = await hre.ethers.getContractFactory("TimelockController");
  const timeLockController = await TimeLockController.deploy(args[0], args[1], args[2]);
  await timeLockController.deployTransaction.wait(5);

  try {
    await hre.run("verify:verify", {
      address: timeLockController.address,
      contract: "contracts/TimelockController.sol:TimelockController",
      constructorArguments: args
    });
  } catch (err: any) {
    if (err.message.includes("Reason: Already Verified")) {
      console.log("Contract is already verified!");
    }
  }

  // Set exempts to TimeLockController
  await foxtrotToken.setFoundationExempt(timeLockController.address, true);
  var tx = await foxtrotToken.setCooldownExempt(timeLockController.address, true);
  await tx.wait()

  // Transfer Ownership to the TimeLockController

  //await foxtrotToken.transferOwnership(timeLockController.address);

  // Renounce timeLock ownership role
  //let admin_role = await timeLockController.TIMELOCK_ADMIN_ROLE();
  //await timeLockController.renounceRole(admin_role, deployer.address);

  console.log("FXD token address:", foxtrotToken.address);
  console.log("Timelock address:", timeLockController.address);
  console.log("MultiSig Address:", multisigWallet);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
