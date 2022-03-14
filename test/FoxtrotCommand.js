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
    masterAccount,
    userAccount,
    foundationVault,
    liquidityMock,
    addrs;

  before(async () => {

    [masterAccount, userAccount, foundationVault, liquidityMock, ...addrs] = await ethers.getSigners();

    const BusdToken = await ethers.getContractFactory("MockBUSD");
    const FoxtrotCommandToken = await ethers.getContractFactory("FoxtrotCommand");

    foxtrotToken = await FoxtrotCommandToken.deploy(215000000);
    busdToken = await BusdToken.deploy();

  });

  describe("#Contract initialization", async () => {

    it("Foxtrot command contract should have max supply", async () => {
      var balance = await foxtrotToken.balanceOf(foxtrotToken.address);
      expect(balance).to.equal(parseEther(215000000));
    });

    describe("#~Foundation Fee", async() => {
      it("Should change the Foundation Address", async() => {
        await foxtrotToken.connect(masterAccount).setFoundationAddress(foundationVault.address);
        expect(await foxtrotToken.foundationAddress()).to.be.equal(foundationVault.address);
      })
    })

    describe("#~Test supply transfer", async() => {

      it("Deployer account should be have 50M supply", async() => {
          await foxtrotToken.connect(masterAccount).withdraw(foxtrotToken.address, masterAccount.address, parseEther(5000000));
          var balance = await foxtrotToken.balanceOf(masterAccount.address);
          expect(balance).to.equal(parseEther(5000000));
      })

      it("Should set Liquidity Mock Pair Address", async() => {
          await foxtrotToken.connect(masterAccount).updateLiquidityPairs(liquidityMock.address, "true");
          expect(await foxtrotToken.getStatusOfLiquidityPair(liquidityMock.address)).to.be.true;
      })

    })

    /* it("Should allow to transact", async() => {
      await foxtrotToken.connect(masterAccount).approveSecureTransaction();
      let isAvailableToTransact = await foxtrotToken.connect(masterAccount).checkAddressApproved();
      expect(isAvailableToTransact).to.be.true;
    }); */

  });
  

  describe("#~Transactions", async () => {
    
    it("Should transfer to another account without fees", async() => {
      await foxtrotToken.connect(masterAccount).transfer(userAccount.address, parseEther(5));
      //console.log(await foxtrotToken.balanceOf(userAccount.address))
    });

    it("Should transfer to another account with fees", async() => {
      await foxtrotToken.connect(userAccount).transfer(liquidityMock.address, parseEther(3));
      let balance = await foxtrotToken.balanceOf(foundationVault.address);
      expect(balance).to.equal(parseEther(0.03));
    });


  });

  describe("#~OAuth", async() => {

    it("MasterAccount should be the owner", async() => {
      let owner = await foxtrotToken.isOwner(masterAccount.address);
      expect(owner).to.be.true;
    });

    it("Owner should be authorized by default", async() => {
      let authorized = await foxtrotToken.isAuthorized(masterAccount.address);
      expect(authorized).to.be.true;
    });

    it("User must try to execute the authorized function without suscesses", async() => {
      let authorized_function = foxtrotToken.connect(userAccount).setAntibotStatus();
      await expect(authorized_function).to.be.revertedWith('OAuth: you\'re not authorized');
    });

    it("Grant OAuth access to a userAccount", async() => {
      await foxtrotToken.connect(masterAccount).authorize(userAccount.address);
      let authorized = await foxtrotToken.isAuthorized(userAccount.address);
      expect(authorized).to.be.true;
    });

  })

});