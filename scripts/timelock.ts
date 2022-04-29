import hre from 'hardhat'

async function main() {

    let args = require('./arguments.js');

    const TimeLockController = await hre.ethers.getContractFactory("TimelockController");
    const timeLockController = await TimeLockController.deploy(args[0], args[1], args[2]);
    await timeLockController.deployed();
    console.log("Timelock address:", timeLockController.address);

    await hre.run("verify:verify", {
        address: timeLockController.address,
        contract: "contracts/TimelockController.sol:TimelockController",
        constructorArguments: args
    });

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
