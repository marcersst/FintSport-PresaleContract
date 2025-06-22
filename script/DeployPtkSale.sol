// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/Script.sol";
import "../src/PTKSale.sol";
import "../src/interfaces/IPTK.sol";

contract DeployPTKSale is Script {
    function run() external returns (PTKSale) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        uint256 tokenPriceUsdc = 2_000_000 ;
        uint256 tokenPriceFtk = 200000000000000000000; 
        
        PTKSale ptkSale = new PTKSale(
            vm.envAddress("PTK_ADDRESS"),
            vm.envAddress("USDC_ADDRESS"),
            vm.envAddress("USDT_ADDRESS"),
            vm.envAddress("WCHZ_ADDRESS"),
            vm.envAddress("FTK_ADDRESS"),
            vm.envAddress("KAYEN_ROUTER_ADDRESS"),
            vm.envAddress("TREASURY_WALLET"),
            tokenPriceUsdc,
            tokenPriceFtk
        );
        
        
        
        console.log("INFO DEL CONTRATO DESPLEGADO");
        console.log("Direccion del contrato PTKSale:", address(ptkSale));
        console.log("Propietario actual:", ptkSale.owner());
        
        console.log("CONFIGURACION DE PTKALE");
        console.log("Precio del token en USDC:", ptkSale.tokenPriceInStableCoin());
        console.log("Precio del token en FTK:", ptkSale.tokenPriceInFtk());
        console.log("Minimo USDC para compra:", ptkSale.MIN_USDC_AMOUNT());
        
        console.log("DIRECCIONES DE TOKENS Y CONTRATOS");
        console.log("PTK Contract:", address(ptkSale.ptkContract()));
        console.log("USDC:", address(ptkSale.usdcContract()));
        console.log("USDT:", address(ptkSale.usdtContract()));
        console.log("WCHZ:", address(ptkSale.wchzContract()));
        console.log("FTK:", address(ptkSale.ftkContract()));
        console.log("Billetera del tesoro:", ptkSale.treasuryWallet());
        console.log("Router de Kayen:", address(ptkSale.kayenRouter()));
        console.log("Direccion del contrato:", address(ptkSale));
        vm.stopBroadcast();
        return ptkSale;
    }
}
