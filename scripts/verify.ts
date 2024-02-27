const hre = require("hardhat");
import { contracts } from "../typechain-types";

async function main() {
  await hre.run("verify:verify", {
    address: "0x6ecbBa2133ecEeAa2b15deCD481f51d9a2E29EA3",
    constructorArguments: [],
    contract: "contracts/Networking.sol:Networking",
  });

  // await hre.run("verify:verify", {
  //   address: "0x04C957a785EDF5e179a28Cf657D15E478160d6aD",
  //   constructorArguments: [],
  //   contract: "contracts/USDC.sol:Usdc",
  // });

  // await hre.run("verify:verify", {
  //   address: "0xd9de4C445c740497B4B7932f47B5495F9BF83235",
  //   constructorArguments: [],
  //   contract: "contracts/upgradeability/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy",
  // });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
