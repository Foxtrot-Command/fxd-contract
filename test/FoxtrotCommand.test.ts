import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect, use } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { solidity } from 'ethereum-waffle';

use(solidity);

const BigNumber = (value: number) => ethers.BigNumber.from(value);
const parseEther = (value: number) => ethers.utils.parseEther(String(value));
const formatEther = (value: number) => Number(ethers.utils.formatEther(String(value)));

const AdvanceTime = async (time: number) => {
  await ethers.provider.send('evm_increaseTime', [time]);
  await ethers.provider.send('evm_mine', []);
}

describe("Foxtrot Command (FXD)", function () {

  let foxtrotToken: Contract,
    busdToken: Contract,
    timeLockController: Contract,
    userAccount: SignerWithAddress,
    userAccount2: SignerWithAddress,
    multisigWallet: SignerWithAddress,
    foundationVault: SignerWithAddress,
    liquidityMock: SignerWithAddress,
    addrs;

  let defaultByte32 = '0x0000000000000000000000000000000000000000000000000000000000000000';

  before(async () => {

    [multisigWallet, userAccount, foundationVault, liquidityMock, userAccount2, ...addrs] = await ethers.getSigners();

    const BusdToken = await ethers.getContractFactory("MockBUSD");
    const FoxtrotCommandToken = await ethers.getContractFactory("FoxtrotCommand");
    const TimeLockController = await ethers.getContractFactory("TimelockController");

    foxtrotToken = await FoxtrotCommandToken.deploy(multisigWallet.address);
    timeLockController = await TimeLockController.deploy(172800, [multisigWallet.address], [multisigWallet.address]);
    busdToken = await BusdToken.deploy();

  });

  describe("#Contract initialization", async () => {

    it("Foxtrot command multisig Wallet should have max supply", async () => {
      var balance = await foxtrotToken.balanceOf(foxtrotToken.address);
      expect(balance).to.equal(parseEther(215000000));
    });

    it("Transfer ownership to TimeLock contract", async () => {
      await foxtrotToken.transferOwnership(timeLockController.address);
    })

    describe("#~ TimeLock", async () => {

      it("Should be able to schedule a transaction", async () => {
        let ABI = [
          "function secureTransfer(address token, address receiver, uint256 amount, string memory reason)"
        ];
        let iface = new ethers.utils.Interface(ABI);
        let encode_data = iface.encodeFunctionData(
          "secureTransfer",
          [foxtrotToken.address, multisigWallet.address, parseEther(100000), "Fill multisign wallet with FXD Tokens"]
        );

        let content = await timeLockController.connect(multisigWallet).schedule(
          foxtrotToken.address,
          0,
          encode_data,
          defaultByte32,
          defaultByte32,
          172800
        );

        await AdvanceTime(172801);

        await timeLockController.connect(multisigWallet).execute(
          foxtrotToken.address,
          0,
          encode_data,
          defaultByte32,
          defaultByte32
        );

        expect(content).to.emit(timeLockController, 'CallScheduled');
        var balance = await foxtrotToken.balanceOf(multisigWallet.address);
        expect(balance).to.equal(parseEther(100000));
      })

      it("Restore ownership to multisig for test purpouses", async () => {
        let ABI = [
          "function transferOwnership(address newOwner)"
        ];
        let iface = new ethers.utils.Interface(ABI);
        let encode_data = iface.encodeFunctionData(
          "transferOwnership",
          [multisigWallet.address]
        );

        await timeLockController.connect(multisigWallet).schedule(
          foxtrotToken.address,
          0,
          encode_data,
          defaultByte32,
          defaultByte32,
          172800
        );

        await AdvanceTime(172801);

        await timeLockController.connect(multisigWallet).execute(
          foxtrotToken.address,
          0,
          encode_data,
          defaultByte32,
          defaultByte32
        );
      })
    })

    describe("#~Foundation", async () => {

      it("Should change the Foundation Address", async () => {
        await foxtrotToken.connect(multisigWallet).setFoundationAddress(foundationVault.address);
        expect(await foxtrotToken.foundationAddress()).to.be.equal(foundationVault.address);
      })

      it("Should not be able to apply more than 2% tax", async () => {
        await expect(
          foxtrotToken.connect(multisigWallet).setFoundationFee(201))
          .to.be.revertedWith('FXD: tax amount exceed limit');
      });

      it("Unauthorized account cannot modify the foundation fee", async () => {
        await expect(
          foxtrotToken.connect(userAccount).setFoundationFee(201)
        ).to.be.reverted;
      });

      it("Should be able to change the fee from 1% to 1.5%", async () => {
        await foxtrotToken.connect(multisigWallet).setFoundationFee(150);
        expect(await foxtrotToken.foundationTax()).to.be.equal(150);
      });

      describe("#Revert fee", async () => {
        it("Revert fee to the default value", async () => {
          await foxtrotToken.connect(multisigWallet).setFoundationFee(100);
          expect(await foxtrotToken.foundationTax()).to.be.equal(100);
        });
      })

    })

    describe("#~Test supply transfer", async () => {

      it("Should set Liquidity Mock Pair Address", async () => {
        await foxtrotToken.connect(multisigWallet).setLiquidityPair(liquidityMock.address, "true");
        expect(await foxtrotToken.isLiquidityPair(liquidityMock.address)).to.be.true;
      })

    })

  });

  describe("#~Transactions", async () => {

    it("Should transfer to another account without fees", async () => {
      let amount = 5;
      await foxtrotToken.connect(multisigWallet).transfer(userAccount.address, parseEther(amount));
      let balance = await foxtrotToken.balanceOf(userAccount.address);
      expect(balance).to.be.equal(parseEther(amount));
    });

    it("Should 'Liquidity' be exempt of foundation tax", async () => {
      await foxtrotToken.connect(multisigWallet).setFoundationExempt(liquidityMock.address, true);
      expect(await foxtrotToken.isExemptFromFoundation(liquidityMock.address)).to.be.true;
    });

    it("Should 'Liquidity' be exempt of antibot transaction time", async () => {
      await foxtrotToken.connect(multisigWallet).setCooldownExempt(liquidityMock.address, true);
      expect(await foxtrotToken.isExemptFromCooldown(liquidityMock.address)).to.be.true;
    });

    it("Should transfer to another account with fees", async () => {
      await foxtrotToken.connect(userAccount).transfer(liquidityMock.address, parseEther(3));
      let balance = await foxtrotToken.balanceOf(foundationVault.address);
      expect(balance).to.equal(parseEther(0.03));
    });

    describe("#Liquidity test", async () => {

      it("Should 'ADMIN' be exempt of antibot transaction time", async () => {
        await foxtrotToken.connect(multisigWallet).setCooldownExempt(multisigWallet.address, true);
        expect(await foxtrotToken.isExemptFromCooldown(multisigWallet.address)).to.be.true;
      });

      it("Should 'ADMIN' be exempt of foundation tax", async () => {
        await foxtrotToken.connect(multisigWallet).setFoundationExempt(multisigWallet.address, true);
        expect(await foxtrotToken.isExemptFromFoundation(multisigWallet.address)).to.be.true;
      });

      it("Should transfer to liquidity pool without fees", async () => {
        let amount = 5000;

        let balance_before = await foxtrotToken.balanceOf(liquidityMock.address);
        await foxtrotToken.connect(multisigWallet).transfer(liquidityMock.address, parseEther(amount));
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

    it("Multisig address should be the owner", async () => {
      let owner = await foxtrotToken.owner();
      expect(owner).to.be.equal(multisigWallet.address);
    });

    it("User must try to execute the authorized function without suscesses", async () => {
      let authorized_function = foxtrotToken.connect(userAccount).setAntibotStatus();
      await expect(authorized_function).to.be.reverted;
    });

  })

  describe("#~AntiBot", async () => {

    it("Should be able to change the antibot time transaction", async () => {
      let time = 50;
      await foxtrotToken.connect(multisigWallet).setAntibotWaitTime(time);
      let actual_time = await foxtrotToken.connect(multisigWallet).cooldownTimerInterval();
      expect(time).to.be.equal(BigNumber(actual_time));
    });

    it("No authorized wallet can't update antibot time transaction", async () => {
      let time = 50;
      let change_time = foxtrotToken.connect(userAccount2).setAntibotWaitTime(time);
      await expect(change_time).to.be.reverted;
    })

    it("Should not be able to change time more than 120 secs", async () => {
      let time = 121;
      let change_time = foxtrotToken.connect(multisigWallet).setAntibotWaitTime(time);
      await expect(change_time).to.be.revertedWith('FXDGuard: limit time exceed');
    });

    describe("#Update Exempts", async () => {

      it("-- FILL USERACCOUNT2 BALANCE", async () => {
        let amount = 120;
        let balance_before = await foxtrotToken.balanceOf(userAccount2.address);
        await foxtrotToken.connect(multisigWallet).transfer(userAccount2.address, parseEther(amount));
        let balance = await foxtrotToken.balanceOf(userAccount2.address);
        expect(balance).to.be.equal(parseEther(amount + formatEther(balance_before)));
      });

      it("Should not be able to transact two times at time", async () => {
        await expect(foxtrotToken.connect(userAccount2).transfer(liquidityMock.address, parseEther(3)))
          .to.be.revertedWith('FXDGuard: wait between two tx');
      });

      it("Should be able to transact with advanced time", async () => {
        await AdvanceTime(60);
        await foxtrotToken.connect(userAccount2).transfer(liquidityMock.address, parseEther(3));
      });
    })
  })

});