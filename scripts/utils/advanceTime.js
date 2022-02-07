const hre = require("hardhat");
const ethers = hre.ethers;

const Minutes = (mins) => {
    return mins * 60
}

const Seconds = (secs) => {
    return secs;
}

const Hours = (hours) => {
    return hours * 60 * 60
}

const Days = (days) => {
    return days * 24 * 60 * 60;
}

async function main() {
    await hre.ethers.provider.send('evm_increaseTime', [Days(91)]);
    await hre.ethers.provider.send('evm_mine');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }
);