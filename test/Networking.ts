import { expect } from "chai";
import { ethers, network } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers";
import {
  Networking,
  Networking__factory,
  Usdc,
  Usdc__factory,
} from "../typechain-types";
import { expandTo18Decimals, expandTo6Decimals } from "./utilities/utilities";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Networking", function () {
  let myNetworking: Networking; //Primary marketplace contract
  let mockUsdc: Usdc; //ERC20 fanverse token
  let owner: SignerWithAddress;
  let signers: SignerWithAddress[];
  let provider: any;
  let zeroAddress = "0x0000000000000000000000000000000000000000";

  beforeEach("Primary and secondary marketplace deploy", async () => {
    signers = await ethers.getSigners();
    owner = signers[0];
    myNetworking = await new Networking__factory(owner).deploy();
    mockUsdc = await new Usdc__factory(owner).deploy();
    await myNetworking
      .connect(owner)
      .initialize(
        mockUsdc.address,
        [1, 2, 3, 4, 5, 6],
        [1, 2, 3, 4, 5, 6],
        [
          1200,
          700,
          500,
          300,
          200,
          100,
          1300,
          800,
          550,
          350,
          250,
          150,
          1400,
          900,
          600,
          400,
          300,
          200,
          1500,
          1000,
          650,
          450,
          350,
          250,
          1800,
          1100,
          700,
          500,
          400,
          300,
          2000,
          1200,
          750,
          550,
          450,
          350,
        ],
        [
          expandTo6Decimals(50),
          expandTo6Decimals(100),
          expandTo6Decimals(250),
          expandTo6Decimals(500),
          expandTo6Decimals(750),
          expandTo6Decimals(850),
          expandTo6Decimals(1000),
        ],
        [6000, 2000, 1200, 800, 0, 0],
        150
      );
    await myNetworking
      .connect(owner)
      .setMinWithdrawalLimit(expandTo6Decimals(50));
    await myNetworking
      .connect(owner)
      .setMaxDepositAmount(expandTo6Decimals(5000000));
    await myNetworking
      .connect(owner)
      .setMinDepositAmount(expandTo6Decimals(100));
  });

  describe("Testing", function () {
    it("Test case for depositing amount and distributing referral incomes and calculating rewards", async function () {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(owner)
        .mint(signers[2].address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(owner)
        .mint(signers[3].address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(owner)
        .mint(signers[4].address, expandTo6Decimals(30000000));
      await mockUsdc
        .connect(owner)
        .mint(signers[5].address, expandTo6Decimals(300000000000));
      await mockUsdc
        .connect(owner)
        .mint(signers[6].address, expandTo6Decimals(3000000000000));

      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[2])
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[3])
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[4])
        .approve(myNetworking.address, expandTo6Decimals(3000000000000));
      await mockUsdc
        .connect(signers[5])
        .approve(myNetworking.address, expandTo6Decimals(3000000000000));
      await mockUsdc
        .connect(signers[6])
        .approve(myNetworking.address, expandTo6Decimals(3000000000000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(200));
      await myNetworking
        .connect(signers[1])
        .deposit(3, owner.address, expandTo6Decimals(1000));
      await myNetworking
        .connect(signers[2])
        .deposit(2, signers[1].address, expandTo6Decimals(1000));
      await myNetworking
        .connect(signers[3])
        .deposit(6, signers[2].address, expandTo6Decimals(1000));
      await myNetworking
        .connect(signers[4])
        .deposit(1, signers[3].address, expandTo6Decimals(10000));
      await myNetworking
        .connect(signers[5])
        .deposit(3, signers[4].address, expandTo6Decimals(30000));
      await myNetworking
        .connect(signers[6])
        .deposit(6, signers[5].address, expandTo6Decimals(5000000));
      await network.provider.send("evm_increaseTime", [12232000]);
      await network.provider.send("evm_mine");

      await myNetworking.connect(signers[5]).withdrawReward();
      expect(
        await myNetworking.connect(signers[1]).seeInvestment(signers[1].address)
      ).to.be.eq(expandTo6Decimals(1000));
      await myNetworking._calculateRewards(signers[1].address);
      expect(
        await myNetworking.connect(signers[1]).Totalreward(signers[1].address)
      ).to.be.eq(2141024000);

      // expect(await myNetworking.Totalreward(signers[1].address)).to.be.eq()
      // console.log("Referral Income for owner",await myNetworking.referralIncome(owner.address));
    });

    it("Test case to check the recurrence of robo fee ", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(4000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(8000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(16000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(32000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(64000));
    });

    it("Test case for the robo time expiration", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await network.provider.send("evm_increaseTime", [15780000]);
      await network.provider.send("evm_mine");

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));
    });

    // it("withdrawing robo reward", async () => {
    //   await mockUsdc
    //     .connect(owner)
    //     .mint(signers[1].address, expandTo6Decimals(3000000));
    //   await mockUsdc
    //     .connect(owner)
    //     .approve(myNetworking.address, expandTo6Decimals(3000000));
    //   await mockUsdc
    //     .connect(signers[1])
    //     .approve(myNetworking.address, expandTo6Decimals(3000000));

    //   await myNetworking
    //     .connect(owner)
    //     .deposit(1, zeroAddress, expandTo6Decimals(2000));

    //   await myNetworking
    //     .connect(signers[1])
    //     .deposit(1, owner.address, expandTo6Decimals(2000));

    //   await myNetworking
    //     .connect(signers[1])
    //     .deposit(1, owner.address, expandTo6Decimals(2000));

    //   await network.provider.send("evm_increaseTime", [15780000]);
    //   await network.provider.send("evm_mine");

    //   await myNetworking
    //     .connect(signers[1])
    //     .deposit(1, owner.address, expandTo6Decimals(2000));

    //   await myNetworking.connect(owner).withdrawRoboIncome();
    //   expect(
    //     await myNetworking.connect(owner).RoboIncome(owner.address)
    //   ).to.be.eq(42500000n);
    // });

    it("Withdrawing company robo reward and service charge amount", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await network.provider.send("evm_increaseTime", [15780000]);
      await network.provider.send("evm_mine");

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));
      await myNetworking
        .connect(owner)
        .withdrawServiceChargeAmountAndCompanyRoboReward();
      // console.log(await myNetworking.connect(owner).CompanyRoboAndServiceChargeIncome());
      let result = await myNetworking
        .connect(owner)
        .CompanyRoboAndServiceChargeIncome();

      expect(result[0]).to.be.eq(397500000n);
      expect(result[1]).to.be.eq(4804800150n);
    });

    it("Setting package threshhold", async () => {
      expect(await myNetworking.packageThreshold(3, 2)).to.be.eq(900);
      await myNetworking.connect(owner).setPackage(3, 2, 800);
      expect(await myNetworking.packageThreshold(3, 2)).to.be.eq(800);
    });

    it("Setting ROI percentage", async () => {
      expect(await myNetworking.ROIpercent()).to.be.eq(150);
      await myNetworking.connect(owner).setROIPercentage(200);
      expect(await myNetworking.ROIpercent()).to.be.eq(200);
    });

    it("Setting New minimum withdrawal limit", async () => {
      expect(await myNetworking.minWithdrawalAmount()).to.be.eq(
        expandTo6Decimals(50)
      );
      await myNetworking
        .connect(owner)
        .setMinWithdrawalLimit(expandTo6Decimals(100));
      expect(await myNetworking.minWithdrawalAmount()).to.be.eq(
        expandTo6Decimals(100)
      );
    });

    it("Updating rank for an user", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(1, owner.address, expandTo6Decimals(2000));

      await myNetworking.connect(owner).setRefferersRank(signers[1].address, 3);
    });

    it("Withdrawing investment", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000));

      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));
      await myNetworking
        .connect(signers[1])
        .deposit(3, owner.address, expandTo6Decimals(1000));

      await network.provider.send("evm_increaseTime", [12232000]);
      await network.provider.send("evm_mine");

      expect(
        await myNetworking.connect(signers[1]).seeInvestment(signers[1].address)
      ).to.be.eq(expandTo6Decimals(1000));
      await myNetworking.connect(signers[1]).withdrawInvestment();
      expect(
        await myNetworking.connect(signers[1]).seeInvestment(signers[1].address)
      ).to.be.eq(expandTo6Decimals(0));
    });
    it("Withdrawing investment before reward getting", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000));

      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));

      await myNetworking
        .connect(signers[1])
        .deposit(3, owner.address, expandTo6Decimals(1000));

      expect(
        await myNetworking.connect(signers[1]).seeInvestment(signers[1].address)
      ).to.be.eq(expandTo6Decimals(1000));

      await myNetworking.connect(signers[1]).withdrawInvestment();
      expect(await mockUsdc.balanceOf(signers[1].address)).to.be.eq(
        expandTo6Decimals(2600)
      );
    });
  });

  describe("Negative Testcases", async () => {
    it("Revert case for invalid referrer", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000));

      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));
      await expect(
        myNetworking
          .connect(signers[1])
          .deposit(3, signers[1].address, expandTo6Decimals(1000))
      ).to.be.revertedWithCustomError(myNetworking, "InvalidReferrer");
      await expect(
        myNetworking
          .connect(signers[1])
          .deposit(3, signers[3].address, expandTo6Decimals(1000))
      ).to.be.revertedWithCustomError(myNetworking, "InvalidReferrer");
    });

    it("Revert cases for invalid deposit amount", async () => {
      await mockUsdc
        .connect(owner)
        .mint(signers[1].address, expandTo6Decimals(3000));

      await mockUsdc
        .connect(owner)
        .approve(myNetworking.address, expandTo6Decimals(3000));
      await mockUsdc
        .connect(signers[1])
        .approve(myNetworking.address, expandTo6Decimals(3000));

      await myNetworking
        .connect(owner)
        .deposit(1, zeroAddress, expandTo6Decimals(2000));
      await expect(
        myNetworking
          .connect(signers[1])
          .deposit(3, owner.address, expandTo6Decimals(10))
      ).to.be.revertedWithCustomError(myNetworking, "InvalidDepositAmount");
      await expect(
        myNetworking
          .connect(signers[1])
          .deposit(3, owner.address, expandTo6Decimals(100000000000000))
      ).to.be.revertedWithCustomError(myNetworking, "InvalidDepositAmount");
    });

    it("Revert case for invalid rank percentage", async () => {
      await expect(
        myNetworking.connect(owner).setPackage(3, 0, 400)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidLevel");
      await expect(
        myNetworking.connect(owner).setPackage(3, 7, 400)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidLevel");
      await expect(
        myNetworking.connect(owner).setPackage(3, 2, 4000000)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidIncomePercentage");
      await expect(
        myNetworking.connect(owner).setPackage(3, 2, 40)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidIncomePercentage");
      await expect(
        myNetworking.connect(owner).setPackage(0, 2, 400)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidRank");
      await expect(
        myNetworking.connect(owner).setPackage(7, 2, 400)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidRank");
    });

    it("Revert case for zero amount of ROI percentage", async () => {
      await expect(
        myNetworking.connect(owner).setROIPercentage(0)
      ).to.be.revertedWithCustomError(myNetworking, "ZeroAmount");
    });

    it("Revert case for Zero address and invalid rank in upgrading users' rank", async () => {
      await expect(
        myNetworking.connect(owner).setRefferersRank(signers[1].address, 0)
      ).to.be.revertedWithCustomError(myNetworking, "InvalidRank");
      await expect(
        myNetworking
          .connect(owner)
          .setRefferersRank("0x0000000000000000000000000000000000000000", 5)
      ).to.be.revertedWithCustomError(myNetworking, "ZeroAddress");
    });
    it("Revert case for calling only owner functions with external account", async () => {
      await expect(
        myNetworking
          .connect(signers[1])
          .withdrawServiceChargeAmountAndCompanyRoboReward()
      ).to.be.revertedWithCustomError(
        myNetworking,
        "OwnableUnauthorizedAccount"
      );
      await expect(
        myNetworking.connect(signers[1]).setRefferersRank(signers[1].address, 5)
      ).to.be.revertedWithCustomError(
        myNetworking,
        "OwnableUnauthorizedAccount"
      );

      await expect(
        myNetworking.connect(signers[1]).setROIPercentage(200)
      ).to.be.revertedWithCustomError(
        myNetworking,
        "OwnableUnauthorizedAccount"
      );

      await expect(
        myNetworking.connect(signers[1]).setPackage(3, 2, 800)
      ).to.be.revertedWithCustomError(
        myNetworking,
        "OwnableUnauthorizedAccount"
      );

      await expect(
        myNetworking
          .connect(signers[1])
          .setMinWithdrawalLimit(expandTo6Decimals(100))
      ).to.be.revertedWithCustomError(
        myNetworking,
        "OwnableUnauthorizedAccount"
      );
    });
  });
});
