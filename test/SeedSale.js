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


describe("Seed Sale", function () {

  const AdvanceTime = async (time) => {
    await ethers.provider.send('evm_increaseTime', [time]);
    await ethers.provider.send('evm_mine');
  }

  let BusdToken,
    FoxtrotCommandToken,
    SeedSale,
    foxtrotToken,
    busdToken,
    seedSale,
    masterAccount,
    userAccount,
    companyVault,
    addrs;

  const tokenomicsPercentTokens = ethers.utils.parseEther('32250000');
  const investorAddresses = [
    "0xB0d9c5c28a37ee221288B4E14B5917dC6dDB9Cb6",
    "0x13F2A61AF3638ebfb97712Acdd4c9392737326bA",
    "0xfdF5967FE2DfbB91706f75B7DEF63990ACDBd2d7",
    "0xA5dBa213413f068A88Df27dcf7bd268b952b48fE",
    "0x1741D2ab85FC633174Af4a19017ae3a51a4c204F",
    "0x0fB213a1Af101b1429e6aD3020ad92Fb0D25Eb1E",
    "0x56823CB370E1749970aA8FEa6464E96CEBCb0FBb"
];

  before(async () => {

    [masterAccount, userAccount, companyVault, ...addrs] = await ethers.getSigners();

    BusdToken = await ethers.getContractFactory("MockBUSD");
    FoxtrotCommandToken = await ethers.getContractFactory("FoxtrotCommand");
    SeedSale = await ethers.getContractFactory("FoxtrotSeedSale");


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
      ethers.utils.parseEther(String(32250000)),
      ethers.utils.parseEther(String(31605000)),
      ethers.utils.parseEther(String(4945000)),
      ethers.utils.parseEther(String(19350000)),
      ethers.utils.parseEther(String(19350000)),
      ethers.utils.parseEther(String(32250000)),
      ethers.utils.parseEther(String(43000000)),
      ethers.utils.parseEther(String(251100000)),
      ethers.utils.parseEther(String(6450000))
    ]);
    busdToken = await BusdToken.deploy();
    seedSale = await SeedSale.deploy(companyVault.address, busdToken.address);

  });

  describe("#Initialize sale", async () => {

    it("Should transfer Foxtrot Tokens to Seed Sale balance", async () => {
      await foxtrotToken.connect(masterAccount).setAddressOfAllowedContract('Seed', seedSale.address);
      await foxtrotToken.connect(masterAccount).safeTransferBusinessTokens('Seed');
      await seedSale.setContractToken(foxtrotToken.address);
    });

    it("Should check Foxtrot Tokens balance in Seed Sale contract", async () => {
      var balance = await seedSale.balance(foxtrotToken.address);
      expect(balance).to.equal(tokenomicsPercentTokens);
    });

    describe("#BUSD deployment", async () => {
      it("master wallet should have all of the BUSD tokens", async () => {
        var balance = await busdToken.balanceOf(masterAccount.address);
        expect(balance).to.equal(ethers.utils.parseEther(String(500000000)));
      });
    });

  });

  describe("#Manual Investment", async () => {

    it("Normal account can't use manual Invest", async () => {
      let amount = ethers.utils.parseEther(String(5000));
      let manualInvestment = seedSale.connect(userAccount).manualInvest(investorAddresses[0], amount);
      await expect(manualInvestment).to.be.revertedWith('Ownable: caller is not the owner');      
    });

    it("Should manual invest a investment from old investor of the old contract", async () => {
      let amount = ethers.utils.parseEther(String(5000));
      let manualInvest = seedSale.connect(masterAccount).manualInvest(investorAddresses[0], amount);
      await expect(manualInvest).to.emit(seedSale, 'Invest')
      .withArgs(investorAddresses[0], amount, ethers.utils.parseEther('400000'));

      let accounting = await seedSale.investorAccounting(investorAddresses[0]);
      expect(accounting.total).to.equal(ethers.utils.parseEther(String(400000)), 'Amount incorrect');
      expect(accounting.claimed).to.equal(0, 'Amount incorrect');
      expect(accounting.locked).to.equal(ethers.utils.parseEther(String(400000)), 'Amount incorrect');
      expect(accounting.busd).to.equal(ethers.utils.parseEther(String(5000)), 'Amount incorrect');
    })
  });

  describe("#Invest", async () => {

    it("Should send money from Master to User wallet to invest", async () => {
      let amount = ethers.utils.parseEther(String(15000));
      await busdToken.connect(masterAccount).transfer(userAccount.address, amount);
      let newBalance = await busdToken.balanceOf(userAccount.address);
      expect(newBalance).to.equal(amount);
    });

    it("UserAccount should be on the whitelist", async () => {
      await seedSale.connect(masterAccount).addAddressToWhitelist(userAccount.address, ethers.utils.parseEther(String(11000)));
      expect(await seedSale.whitelist(userAccount.address), "Wallet not in whitelist").to.true;
    });

    it("UserAccount should have maximum invest amount of 5000", async () => {
      let whitelistAmount = await seedSale.amount(userAccount.address);
      expect(whitelistAmount).to.equal(ethers.utils.parseEther(String(11000)), "Wallet not in whitelist");
    });

    it("Should approve allowance", async () => {
      let amount = ethers.utils.parseEther(String(10000000));
      await busdToken.connect(userAccount).approve(seedSale.address, amount);

      let allowance = await busdToken.allowance(userAccount.address, seedSale.address);
      expect(allowance).to.equal(amount, 'Allowance amount incorrect');
    });

    it("Should check userAccount BUSD balance", async () => {
      let expectedBalance = ethers.utils.parseEther(String(15000));
      let actualBalance = await busdToken.balanceOf(userAccount.address);
      expect(actualBalance).to.equal(expectedBalance, "Balance incorrect!");
    });

    it("It should NOT be possible to invest more than whitelisted BUSD", async () => {
      let amount = ethers.utils.parseEther(String(11001));
      await expect(seedSale
        .connect(userAccount)
        .invest(amount)).to.be
        .revertedWith('FXD: Seed purchase limit');
    });

    it("Should invest 5000 BUSD from userAccount", async () => {
      let amount = ethers.utils.parseEther(String(5000));
      await expect(seedSale.connect(userAccount).invest(amount))
      .to.emit(seedSale, 'Invest')
      .withArgs(userAccount.address, amount, ethers.utils.parseEther('400000'));
    });

    it("It should can not invest left BUSD", async () => {
      let amount = ethers.utils.parseEther(String(6500));
      await expect(seedSale.connect(userAccount).invest(amount)).to.be.revertedWith('FXD: Seed purchase limit');
    });

    it("It should can invest left BUSD in whitelist balance", async () => {
      let amount = ethers.utils.parseEther(String(6000));
      await expect(seedSale.connect(userAccount).invest(amount))
      .to.emit(seedSale, 'Invest')
      .withArgs(userAccount.address, amount, ethers.utils.parseEther('480000'));
    });

    it("Company vault should have 5000 BUSD in the wallet", async () => {
      let expectedBalance = ethers.utils.parseEther(String(11000));
      var balance = await busdToken.balanceOf(companyVault.address);
      expect(balance).to.equal(expectedBalance, "Balance incorrect!");
    });

  });

  describe("#Claim", async () => {
    it("Should check the total amount of accounting investor", async () => {
      let accounting = await seedSale.investorAccounting(userAccount.address);
      expect(accounting.total).to.equal(ethers.utils.parseEther(String(880000)), 'Amount incorrect');
      expect(accounting.claimed).to.equal(0, 'Amount incorrect');
      expect(accounting.locked).to.equal(ethers.utils.parseEther(String(880000)), 'Amount incorrect');
      expect(accounting.busd).to.equal(ethers.utils.parseEther(String(11000)), 'Amount incorrect');
    });

    it("Should enable Claim status", async () => {
      const changeClaimStatusTx = await seedSale.connect(masterAccount).changeClaimStatus();
      await changeClaimStatusTx.wait();
      //expect(changeClaimStatusTx, "Change claim is not available").to.true;
    });

    it("It should not be possible to change Claim status again", async () => {
      await expect(seedSale.connect(masterAccount).changeClaimStatus()).to.be.revertedWith('FXD: Claim already enabled');
    });

    it("Should be able to claim 5% of available tokens", async () => {
      await seedSale.connect(userAccount).claim();
      var balance = await foxtrotToken.balanceOf(userAccount.address);
      //console.log("Balance: (Time:", (await web3.eth.getBlock('latest')).timestamp, ") ", web3.utils.fromWei(balance, 'ether'));
      expect(Number(ethers.utils.formatEther(String(balance)))).to.equal(44000, 'Balance of 5% tokens incorrect');
    });

    it('It should NOT be possible to claim until 90 days of cliff time', async () => {
      await expect(seedSale.connect(userAccount).claim()).to.be.revertedWith('FXD: Can\'t claim, 90 days cliff');
    });

  });

  describe('#Purge non selled tokens', async () => {

    it("Should purge non selled tokens", async () => {
      //AdvanceTime(Days(366));
      await seedSale.setSaleEnd();

      await seedSale.connect(masterAccount).purgeNonSelledTokens();
      let balance = await seedSale.balance(foxtrotToken.address);
      expect(Number(ethers.utils.formatEther(String(balance)))).to.equal(1236000, 'Purge balance seedSale incorrect');

      balance = await foxtrotToken.balanceOf(foxtrotToken.address);
      expect(Number(ethers.utils.formatEther(String(balance)))).to.equal(213720000, 'Purge balance foxtrotToken incorrect');

      //test = await foxtrotToken.availableRemainderTokens();
    });

  })

  describe('#Time advanced', async () => {

    describe('#Day one', async () => {
      it("Should be able to claim at day one after cliff time", async () => {

        AdvanceTime(Days(91));

        await seedSale.connect(userAccount).claim();

        let balance = await foxtrotToken.balanceOf(userAccount.address);
        expect(Number(ethers.utils.formatEther(balance))).to.be.at.least(20633);
      });

      it("Should get +1 token after 3 minutes", async () => {
        AdvanceTime(Seconds(180));
        await seedSale.connect(userAccount).claim();

        let balance = await foxtrotToken.balanceOf(userAccount.address);
        expect(Number(ethers.utils.formatEther(balance))).to.be.at.least(20634);
      });

    })

    describe('#Day Two', async () => {
      it("Should be able to claim at day two after cliff time", async () => {
        AdvanceTime(Days(1));
        await seedSale.connect(userAccount).claim();

        let balance = await foxtrotToken.balanceOf(userAccount.address);
        expect(Number(ethers.utils.formatEther(balance))).to.be.at.least(21268);
      });

    })

    describe('#Day 600', async () => {

      it("Should be able to get all of their tokens after 600 days", async () => {
        AdvanceTime(Days(600));

        await seedSale.connect(userAccount).claim();

        let balance = await foxtrotToken.balanceOf(userAccount.address);
        balance = Number(ethers.utils.formatEther(balance));

        expect(balance).to.be.equal(Number(880000), "Balance is above than registered number");
      });
    })
  })

});
