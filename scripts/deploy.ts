import { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";

function sleep(ms: any) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
let owner = "0xC46d483FA31Cd67f93B7158569ACCA8678B1AAf5";
async function main() {
  // We get the contract to deploy
  const networking = await ethers.getContractFactory("Networking");
  const NTW = await networking.deploy();
  await sleep(4000);
  console.log("Campaigning contract address", NTW.address);

  // const usdc = await ethers.getContractFactory("Usdc");
  // const USDC = await usdc.deploy();
  // await sleep(4000);
  // console.log("usdc contract address", USDC.address);

  // const Proxy = await ethers.getContractFactory("OwnedUpgradeabilityProxy");
  // const PROXY1 = await Proxy.deploy();
  // await sleep(4000);
  // console.log("proxy contract address", PROXY1.address);

  // console.log("after");
  // await sleep(6000);
  // console.log("before");

  // await PROXY1.upgradeTo(NTW.address);
  // console.log("______________________");

  // // await sleep(5000);
  // let Proxy1 = await networking.attach(NTW.address);
  // console.log(Proxy1.address, "Networking proxy");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
