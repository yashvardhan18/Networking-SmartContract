import { expect } from "chai";
import { ethers} from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers";
import { Networking, Networking__factory, Usdc, Usdc__factory } from "../typechain-types";
import { expandTo18Decimals,expandTo6Decimals } from "./utilities/utilities";
import { usdcSol } from "../typechain-types/contracts";

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
    await myNetworking.connect(owner).initialize(mockUsdc.address,["Iron","Silver"],[1,2],[150,200]);
  
  });

  

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      await mockUsdc.connect(owner).approve(myNetworking.address,expandTo6Decimals(1000));
      await myNetworking.connect(owner).deposit("Iron",1,zeroAddress,expandTo6Decimals(1000));

      console.log(await myNetworking.seeDeposit(owner.address,1));

    });

  });

  });
