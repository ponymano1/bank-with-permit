// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Bank.sol";
import "../src/TigerToken.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 部署 TigerToken
        TigerToken tigerToken = new TigerToken(
            "Tiger Token",
            "TIGER",
            18,
            1000000 * 10 ** 18 // 1,000,000 tokens
        );

        console.log("TigerToken deployed at:", address(tigerToken));

        // 部署 Bank
        Bank bank = new Bank();

        console.log("Bank deployed at:", address(bank));

        // 将 TigerToken 添加到 Bank 支持的 token 列表中
        bank.addSupportedToken(address(tigerToken));

        console.log("TigerToken added to Bank supported tokens");

        vm.stopBroadcast();

        console.log("Deployment completed successfully!");
        console.log("TigerToken:", address(tigerToken));
        console.log("Bank:", address(bank));
    }
}
