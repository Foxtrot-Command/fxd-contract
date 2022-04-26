import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deploy: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
    const [deployer] =  (hre as any).customSigners.concat(await hre.ethers.getSigners());
    let multisigWallet = (hre as any).multiSigAddress;

    await hre.run("verify:verify", {
        address: '0x46Bf7De19E3BDDAa61BfbA571b62c5Bb0f0B33E2',
        contract: "FoxtrotCommand",
        constructorArguments: [multisigWallet]
    });

};

deploy.tags = ['Verify Contract']
export default deploy;