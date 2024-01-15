import { expect } from "chai";
import { ethers} from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers";
import { Networking, Networking__factory, Usdc, Usdc__factory } from "../typechain-types";
import { expandTo18Decimals,expandTo6Decimals } from "./utilities/utilities";
import { usdcSol } from "../typechain-types/contracts";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Lock", function () {
  
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
    await myNetworking.connect(owner).initialize(mockUsdc.address,[1,2,3,4,5,6],[1,2,3,4,5,6],[1200,700,500,300,200,100,1300,800,550,350,250,150,1400,900,600,400,300,200,1500,1000,650,450,350,250,1800,1100,700,500,400,300,2000,1200,750,550,450,350],150);
  
  });

  

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      await mockUsdc.connect(owner).mint(signers[1].address,expandTo6Decimals(3000));
      await mockUsdc.connect(owner).mint(signers[2].address,expandTo6Decimals(3000));
      await mockUsdc.connect(owner).mint(signers[3].address,expandTo6Decimals(3000));
      await mockUsdc.connect(owner).mint(signers[4].address,expandTo6Decimals(3000));
      await mockUsdc.connect(owner).mint(signers[5].address,expandTo6Decimals(3000));
      await mockUsdc.connect(owner).mint(signers[6].address,expandTo6Decimals(3000));
      
      
      await mockUsdc.connect(owner).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[1]).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[2]).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[3]).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[4]).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[5]).approve(myNetworking.address,expandTo6Decimals(3000));
      await mockUsdc.connect(signers[6]).approve(myNetworking.address,expandTo6Decimals(3000));



      
      await myNetworking.connect(owner).deposit(1,zeroAddress,expandTo6Decimals(2000));
      await myNetworking.connect(signers[1]).deposit(3,owner.address,expandTo6Decimals(1000));
      await myNetworking.connect(signers[2]).deposit(2,signers[1].address,expandTo6Decimals(1000));
      await myNetworking.connect(signers[3]).deposit(6,signers[2].address,expandTo6Decimals(1000));
      await myNetworking.connect(signers[4]).deposit(1,signers[3].address,expandTo6Decimals(1000));
      await myNetworking.connect(signers[5]).deposit(3,signers[4].address,expandTo6Decimals(1000));
      await myNetworking.connect(signers[6]).deposit(5,signers[5].address,expandTo6Decimals(1000));


      // console.log(await myNetworking.seeDeposit(signers[1].address,1));
      // console.log(await myNetworking.Details(owner.address));

      await network.provider.send("evm_increaseTime", [12960000000000])
      await network.provider.send("evm_mine");

      await myNetworking.connect(signers[6]).withdrawReward(expandTo6Decimals(200));
      // console.log("Referral Income",await myNetworking.referralIncome(owner.address));
      // console.log("Referral Income",await myNetworking.Details(signers[6].address));



    });

  });
  });