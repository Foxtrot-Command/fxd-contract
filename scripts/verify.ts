import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deploy: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
    const [deployer, multisignAccount] =  (hre as any).customSigners.concat(await hre.ethers.getSigners());

    await hre.run("verify:verify", {
        address: '0xa7b738a6b78f52a6ef839f28f82426634c874a19',
        contract: "FoxtrotCommand",
        constructorArguments: [multisignAccount.address]
    });

};

deploy.tags = ['Verify Contract']
export default deploy;