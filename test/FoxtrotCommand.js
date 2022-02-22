const { expect } = require("chai");
const { ethers } = require("hardhat");

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

const parseEther = (value) => ethers.utils.parseEther(String(value));
const formatEther = (value) => Number(ethers.utils.formatEther(String(value)));
const DEAD = () => "0x000000000000000000000000000000000000dEaD";
const ZERO = () => "0x0000000000000000000000000000000000000000";


describe("Foxtrot Command (FXD)", function () {

  const AdvanceTime = async (time) => {
    await ethers.provider.send('evm_increaseTime', [time]);
    await ethers.provider.send('evm_mine');
  }

  let foxtrotToken,
    busdToken,
    masterAccount,
    userAccount,
    companyVault,
    liquidityMock,
    addrs;

  before(async () => {

    [masterAccount, userAccount, companyVault, liquidityMock, ...addrs] = await ethers.getSigners();

    const BusdToken = await ethers.getContractFactory("MockBUSD");
    const FoxtrotCommandToken = await ethers.getContractFactory("FoxtrotCommand");

    foxtrotToken = await FoxtrotCommandToken.deploy(215000000, [
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
      parseEther(32250000),
      parseEther(31605000),
      parseEther(4945000),
      parseEther(19350000),
      parseEther(19350000),
      parseEther(32250000),
      parseEther(43000000),
      parseEther(251100000),
      parseEther(6450000)
    ]);
    busdToken = await BusdToken.deploy();

  });

  describe("#Initialize sale", async () => {

    it("Foxtrot command contract should have max supply", async () => {
      var balance = await foxtrotToken.balanceOf(foxtrotToken.address);
      expect(balance).to.equal(parseEther(215000000));
    });

  });

});
