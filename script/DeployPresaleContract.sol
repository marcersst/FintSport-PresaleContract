// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/Script.sol";
import "../src/PresaleContract.sol";

contract DeployPresaleContract is Script {
    function run() external returns (PresaleContract) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        PresaleContract presaleContract = new PresaleContract(
            vm.envAddress("SALE_TOKEN_ADDRESS"), 
            vm.envUint("TOKEN_PRICE_IN_USDC"), 
            vm.envAddress("WCHZ_ADDRESS"), 
            block.timestamp + vm.envUint("SALE_DURATION_DAYS") * 1 days, 
            vm.envUint("TOTAL_TOKENS_FOR_SALE"),
            vm.envAddress("USDC_ADDRESS"), 
            vm.envAddress("USDT_ADDRESS"), 
            vm.envAddress("TREASURY_WALLET"), 
            vm.envAddress("KAYEN_ROUTER_ADDRESS"), 
            vm.envUint("STABLECOIN_HARDCAP") 
        );
        
        console.log("Contrato de Preventa desplegado en:", address(presaleContract));
        
        vm.stopBroadcast();
        return presaleContract;
    }
}