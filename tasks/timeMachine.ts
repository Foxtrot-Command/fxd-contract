import { task, types } from "hardhat/config";

task("advance", "Advance the hardhat EVM time")
.addParam("days", "Advance days in the Hardhat EVM", 0, types.int, true)
.addParam("hours", "Advance hours in the Hardhat EVM", 0, types.int, true)
.addParam("minutes", "Advance minutes in the Hardhat EVM", 0, types.int, true)
.addParam("seconds", "Advance seconds in the Hardhat EVM", 0, types.int, true)
.setAction(async (taskArgs, hre) => {

    let sumOfAll = (taskArgs.days * 24 * 60 * 60) +
        (taskArgs.hours * 60 * 60) +
        (taskArgs.minutes * 60) +
        taskArgs.seconds;

    await hre.ethers.provider.send('evm_increaseTime', [sumOfAll]);
    await hre.ethers.provider.send('evm_mine', []);
});

export { }