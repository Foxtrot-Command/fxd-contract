const hre = require("hardhat");

async function main() {
    [masterAccount] = await hre.ethers.getSigners();
    // We get the contract to deploy

    const seedSale = await (await hre.ethers.getContractFactory("FoxtrotSeedSale")).attach("0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e")

    await seedSale.connect(masterAccount).changeClaimStatus();

    console.log("Claim Status activado");
    
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });