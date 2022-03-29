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

const BigNumber = (value) => ethers.BigNumber.from(value);
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
    userAccount2,
    foundationVault,
    liquidityMock,
    addrs;

  before(async () => {

    [masterAccount, userAccount, foundationVault, liquidityMock, userAccount2, ...addrs] = await ethers.getSigners();

    const BusdToken = await ethers.getContractFactory("MockBUSD");
    const FoxtrotCommandToken = await ethers.getContractFactory("FoxtrotCommand");

    foxtrotToken = await FoxtrotCommandToken.deploy();
    busdToken = await BusdToken.deploy();

  });

  describe("#Contract initialization", async () => {

    it("Foxtrot command contract should have max supply", async () => {
      var balance = await foxtrotToken.balanceOf(foxtrotToken.address);
      expect(balance).to.equal(parseEther(215000000));
    });

    describe("#~Foundation Fee", async () => {
      it("Should change the Foundation Address", async () => {
        await foxtrotToken.connect(masterAccount).setFoundationAddress(foundationVault.address);
        expect(await foxtrotToken.foundationAddress()).to.be.equal(foundationVault.address);
      })
    })

    describe("#~Test supply transfer", async () => {

      it("Deployer account should be have 50M supply", async () => {
        let event = await foxtrotToken.connect(masterAccount).secureTransfer(foxtrotToken.address, masterAccount.address, parseEther(5000000), "Test withdraw")

        await expect(event).to.emit(foxtrotToken, 'WithdrawTokensFromMainContract')
          .withArgs(masterAccount.address, masterAccount.address, parseEther(5000000), "Test withdraw");

        var balance = await foxtrotToken.balanceOf(masterAccount.address);
        expect(balance).to.equal(parseEther(5000000));
      })

      it("Should set Liquidity Mock Pair Address", async () => {
        await foxtrotToken.connect(masterAccount).setLiquidityPair(liquidityMock.address, "true");
        expect(await foxtrotToken.isLiquidityPair(liquidityMock.address)).to.be.true;
      })

    })

  });


  describe("#~Transactions", async () => {

    it("Should transfer to another account without fees", async () => {
      let amount = 5;
      await foxtrotToken.connect(masterAccount).transfer(userAccount.address, parseEther(amount));
      let balance = await foxtrotToken.balanceOf(userAccount.address);
      expect(balance).to.be.equal(parseEther(amount));
    });

    /*  it("Should 'Liquidity' be exempt of foundation tax", async () => {
       await foxtrotToken.connect(masterAccount).setFoundationExempt(liquidityMock.address, true);
       expect(await foxtrotToken.isExemptFromFoundation(liquidityMock.address)).to.be.true;
     }); */

    it("Should 'Liquidity' be exempt of antibot transaction time", async () => {
      await foxtrotToken.connect(masterAccount).setCooldownExempt(liquidityMock.address, true);
      expect(await foxtrotToken.isExemptFromCooldown(liquidityMock.address)).to.be.true;
    });

    it("Should transfer to another account with fees", async () => {
      await foxtrotToken.connect(userAccount).transfer(liquidityMock.address, parseEther(3));
      let balance = await foxtrotToken.balanceOf(foundationVault.address);
      expect(balance).to.equal(parseEther(0.03));
    });

    describe("#Liquidity test", async () => {

      it("Should 'ADMIN' be exempt of antibot transaction time", async () => {
        await foxtrotToken.connect(masterAccount).setCooldownExempt(masterAccount.address, true);
        expect(await foxtrotToken.isExemptFromCooldown(masterAccount.address)).to.be.true;
      });

      it("Should 'ADMIN' be exempt of foundation tax", async () => {
        await foxtrotToken.connect(masterAccount).setFoundationExempt(masterAccount.address, true);
        expect(await foxtrotToken.isExemptFromFoundation(masterAccount.address)).to.be.true;
      });

      it("Should transfer to liquidity pool without fees", async () => {
        let amount = 5000;

        let balance_before = await foxtrotToken.balanceOf(liquidityMock.address);
        await foxtrotToken.connect(masterAccount).transfer(liquidityMock.address, parseEther(amount));
        let balance = await foxtrotToken.balanceOf(liquidityMock.address);

        expect(balance).to.be.equal(parseEther(amount + formatEther(balance_before)));
      });

      it("Wallet recipient from liquidity as sender should have taxes", async () => {
        let amount = 5;
        await foxtrotToken.connect(liquidityMock).transfer(userAccount2.address, parseEther(amount));
        let balance = await foxtrotToken.balanceOf(userAccount2.address);

        expect(balance).to.be.equal(parseEther(amount - (amount * 0.01)));
      })

    })


  });

  describe("#~OAuth", async () => {

    it("MasterAccount should be the owner", async () => {
      let owner = await foxtrotToken.isOwner(masterAccount.address);
      expect(owner).to.be.true;
    });

    it("Owner should be authorized by default", async () => {
      let authorized = await foxtrotToken.isAuthorized(masterAccount.address);
      expect(authorized).to.be.true;
    });

    it("User must try to execute the authorized function without suscesses", async () => {
      let authorized_function = foxtrotToken.connect(userAccount).setAntibotStatus();
      await expect(authorized_function).to.be.revertedWith('OAuth: you\'re not authorized');
    });

    it("Grant OAuth access to a userAccount", async () => {
      await foxtrotToken.connect(masterAccount).authorize(userAccount.address);
      let authorized = await foxtrotToken.isAuthorized(userAccount.address);
      expect(authorized).to.be.true;
    });

  })

  describe("#~AntiBot", async () => {

    it("Should be able to change the antibot time transaction", async () => {
      let time = 50;
      await foxtrotToken.connect(masterAccount).setAntibotWaitTime(time);
      let actual_time = await foxtrotToken.connect(masterAccount).cooldownTimerInterval();
      expect(time).to.be.equal(BigNumber(actual_time));
    });

    it("No authorized wallet can't update antibot time transaction", async () => {
      let time = 50;
      let change_time = foxtrotToken.connect(userAccount2).setAntibotWaitTime(time);
      await expect(change_time).to.be.revertedWith('OAuth: you\'re not authorized');
    })

    it("Should not be able to change time more than 120 secs", async () => {
      let time = 121;
      let change_time = foxtrotToken.connect(masterAccount).setAntibotWaitTime(time);
      await expect(change_time).to.be.revertedWith('FXDGuard: limit time exceed');
    });

    describe("#Update Exempts", async () => {

      it("-- FILL USERACCOUNT2 BALANCE", async () => {
        let amount = 120;
        let balance_before = await foxtrotToken.balanceOf(userAccount2.address);
        await foxtrotToken.connect(masterAccount).transfer(userAccount2.address, parseEther(amount));
        let balance = await foxtrotToken.balanceOf(userAccount2.address);
        expect(balance).to.be.equal(parseEther(amount + formatEther(balance_before)));
      });

      it("Should not be able to transact two times at time", async () => {
        await expect(foxtrotToken.connect(userAccount2).transfer(liquidityMock.address, parseEther(3)))
          .to.be.revertedWith('FXDGuard: wait between two tx');

      });
    })

  })

});