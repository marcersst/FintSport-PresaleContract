// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {PTKSale} from "../src/PTKSale.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../src/interfaces/IPTK.sol";
import "../src/interfaces/IKayenRouter.sol";
import {PTK} from "../src/PTK.sol";

contract MockFTK is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

contract PTKSaleTest is Test {
    
    PTKSale public ptkSale;
    PTK public ptkContract;
    IERC20 public usdcContract;
    IERC20 public usdtContract;
    IERC20 public wchzContract;
    MockFTK public ftkContract;
    
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public treasury = vm.addr(3);
    address public owner = vm.addr(4);
    address public minter = vm.addr(5);

    uint256 constant TOKEN_ID = 1;
    uint256 TOKEN_PRICE_USDC;
    uint256 TOKEN_PRICE_FTK;
    uint256 constant TOKENS_FOR_SALE = 10000 * 10**18;

    function setUp() public {

        TOKEN_PRICE_USDC = vm.envUint("TOKEN_PRICE_USDC");
        TOKEN_PRICE_FTK = vm.envUint("TOKEN_PRICE_FTK");
        
        usdcContract = IERC20(vm.envAddress("USDC_ADDRESS"));
        usdtContract = IERC20(vm.envAddress("USDT_ADDRESS"));
        wchzContract = IERC20(vm.envAddress("WCHZ_ADDRESS"));
        
        vm.createSelectFork(vm.envString("CHILIZ_RPC_URL"));
        
        ptkContract = new PTK();
        ptkContract.initialize(owner, minter, "https://example.com/metadata/{id}.json");
        ftkContract = new MockFTK("FTK Token", "FTK");
        
        vm.startPrank(owner);
        
        ptkSale = new PTKSale(
            address(ptkContract),
            address(usdcContract),
            address(usdtContract),
            address(wchzContract),
            address(ftkContract),
            vm.envAddress("KAYEN_ROUTER_ADDRESS"),
            treasury,
            TOKEN_PRICE_USDC,
            TOKEN_PRICE_FTK
        );
        
        vm.stopPrank();
        
        vm.startPrank(minter);
        ptkContract.mint(address(ptkSale), TOKEN_ID, TOKENS_FOR_SALE, "");
        vm.stopPrank();
        deal(address(usdcContract), user1, 10000 * 10**6);
        deal(address(usdtContract), user1, 10000 * 10**6);
        MockFTK(address(ftkContract)).mint(user1, 1000000 * 10**18);
        
        deal(address(usdcContract), user2, 10000 * 10**6);
        deal(address(usdtContract), user2, 10000 * 10**6);
        MockFTK(address(ftkContract)).mint(user2, 1000000 * 10**18);
        
        vm.deal(user1, 100000 ether);
        vm.deal(user2, 100000 ether);
        
        console.log("Balance USDC de user1:", usdcContract.balanceOf(user1));
        console.log("Balance USDC de user2:", usdcContract.balanceOf(user2));
        console.log("Balance USDT de user1:", usdtContract.balanceOf(user1));
        console.log("Balance FTK de user1:", ftkContract.balanceOf(user1));
        console.log("Balance CHZ nativo de user1:", address(user1).balance);
        console.log("Balance CHZ nativo de user2:", address(user2).balance);
        console.log("Direccion del contrato PTKSale:", address(ptkSale));
        console.log("Direccion del contrato PTK:", address(ptkContract));
        console.log("Direccion del contrato USDC:", address(usdcContract));
        console.log("Direccion del contrato USDT:", address(usdtContract));
        console.log("Direccion del contrato WCHZ:", address(wchzContract));
        console.log("Direccion del contrato FTK:", address(ftkContract));
        console.log("Direccion del treasury:", treasury);
        console.log("=== PARAMETROS DE VENTA ===");
        console.log("Precio del token en USDC:", TOKEN_PRICE_USDC);
        console.log("Precio del token en FTK:", TOKEN_PRICE_FTK);
        console.log("Tokens disponibles para venta:", TOKENS_FOR_SALE);
        console.log("Balance PTK del contrato de venta:", ptkContract.balanceOf(address(ptkSale), TOKEN_ID));
    }

    // Test que verifica la compra de tokens PTK usando USDC como metodo de pago
    function testBuyWithUSDC() public {
        uint256 tokenAmount = 100; 
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC; 
        
        uint256 initialUserUSDC = usdcContract.balanceOf(user1);
        uint256 initialUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 initialTreasuryUSDC = usdcContract.balanceOf(treasury);
        
        console.log("=== TEST COMPRA CON USDC ===");
        console.log("Tokens a comprar:", tokenAmount);
        console.log("Costo en USDC:", usdcCost);
        console.log("Balance inicial USDC user1:", initialUserUSDC);
        console.log("Balance inicial PTK user1:", initialUserPTK);
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), usdcCost);
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false); 
        vm.stopPrank();
        
        uint256 finalUserUSDC = usdcContract.balanceOf(user1);
        uint256 finalUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 finalTreasuryUSDC = usdcContract.balanceOf(treasury);
        
        console.log("Balance final USDC user1:", finalUserUSDC);
        console.log("Balance final PTK user1:", finalUserPTK);
        console.log("Balance final USDC treasury:", finalTreasuryUSDC);
        
        assertEq(finalUserUSDC, initialUserUSDC - usdcCost, "USDC no se debito correctamente");
        assertEq(finalUserPTK, initialUserPTK + tokenAmount, "PTK no se acredito correctamente");
        assertEq(finalTreasuryUSDC, initialTreasuryUSDC + usdcCost, "Treasury no recibio USDC");
    }
    
    // Test que verifica la compra de tokens PTK usando USDT como metodo de pago
    function testBuyWithUSDT() public {
        uint256 tokenAmount = 50; 
        uint256 usdtCost = tokenAmount * TOKEN_PRICE_USDC; 
        
        uint256 initialUserUSDT = usdtContract.balanceOf(user1);
        uint256 initialUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 initialTreasuryUSDT = usdtContract.balanceOf(treasury);
        
        console.log("=== TEST COMPRA CON USDT ===");
        console.log("Tokens a comprar:", tokenAmount);
        console.log("Costo en USDT:", usdtCost);
        
        vm.startPrank(user1);
        usdtContract.approve(address(ptkSale), usdtCost);
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, true); 
        vm.stopPrank();
        
        uint256 finalUserUSDT = usdtContract.balanceOf(user1);
        uint256 finalUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 finalTreasuryUSDT = usdtContract.balanceOf(treasury);
        
        assertEq(finalUserUSDT, initialUserUSDT - usdtCost, "USDT no se debito correctamente");
        assertEq(finalUserPTK, initialUserPTK + tokenAmount, "PTK no se acredito correctamente");
        assertEq(finalTreasuryUSDT, initialTreasuryUSDT + usdtCost, "Treasury no recibio USDT");
    }
    
    // Test que verifica la compra de tokens PTK usando FTK como metodo de pago
    function testBuyWithFTK() public {
        uint256 tokenAmount = 200; 
        uint256 ftkCost = tokenAmount * TOKEN_PRICE_FTK;
        
        uint256 initialUserFTK = ftkContract.balanceOf(user1);
        uint256 initialUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 initialTreasuryFTK = ftkContract.balanceOf(treasury);
        
        console.log("=== TEST COMPRA CON FTK ===");
        console.log("Tokens a comprar:", tokenAmount);
        console.log("Costo en FTK:", ftkCost);
        
        vm.startPrank(user1);
        ftkContract.approve(address(ptkSale), ftkCost);
        ptkSale.buyWithFtk(tokenAmount, TOKEN_ID);
        vm.stopPrank();
        
        uint256 finalUserFTK = ftkContract.balanceOf(user1);
        uint256 finalUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 finalTreasuryFTK = ftkContract.balanceOf(treasury);
        
        assertEq(finalUserFTK, initialUserFTK - ftkCost, "FTK no se debito correctamente");
        assertEq(finalUserPTK, initialUserPTK + tokenAmount, "PTK no se acredito correctamente");
        assertEq(finalTreasuryFTK, initialTreasuryFTK + ftkCost, "Treasury no recibio FTK");
    }
    
    // Test que verifica la compra de tokens PTK usando CHZ nativo como metodo de pago
    function testBuyWithCHZ() public {        
        uint256 tokenAmount = 100; 
        
        
        uint256 chzAmount = ptkSale.calculateCHZToPay(tokenAmount);
        
        uint256 initialUserCHZ = address(user1).balance;
        uint256 initialUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 initialTreasuryUSDC = usdcContract.balanceOf(treasury);
        
        console.log("=== TEST COMPRA CON CHZ NATIVO ===");
        console.log("Tokens a comprar:", tokenAmount);
        console.log("CHZ calculado necesario:", chzAmount);
        console.log("Balance inicial CHZ user1:", initialUserCHZ);
        console.log("Balance inicial PTK user1:", initialUserPTK);
        console.log("Balance inicial USDC treasury:", initialTreasuryUSDC);
        
        vm.startPrank(user1);
        ptkSale.buyWithChz{value: chzAmount}(tokenAmount, TOKEN_ID);
        vm.stopPrank();
        
        uint256 finalUserCHZ = address(user1).balance;
        uint256 finalUserPTK = ptkContract.balanceOf(user1, TOKEN_ID);
        uint256 finalTreasuryUSDC = usdcContract.balanceOf(treasury);
        
        console.log("Balance final CHZ user1:", finalUserCHZ);
        console.log("Balance final PTK user1:", finalUserPTK);
        console.log("Balance final USDC treasury:", finalTreasuryUSDC);
        console.log("CHZ realmente usado:", initialUserCHZ - finalUserCHZ);
        
        
        assertEq(finalUserPTK, initialUserPTK + tokenAmount, "PTK no se acredito correctamente");
        
        
        uint256 chzUsed = initialUserCHZ - finalUserCHZ;
        assertGe(chzUsed, chzAmount, "No se uso suficiente CHZ");
        assertLe(chzUsed, chzAmount + 0.1 ether, "Se uso demasiado CHZ (probablemente gas)");
        
        assertGt(finalTreasuryUSDC, initialTreasuryUSDC, "Treasury no recibio USDC del swap CHZ->USDC");
        
        PTKSale.UserInfo memory userInfo = ptkSale.getUserInfo(user1);
        assertGt(userInfo.chzPaid, 0, "CHZ pagado no se registro correctamente");
        assertEq(userInfo.chzPaid, chzAmount, "CHZ pagado registrado no coincide con el calculado");
    }
    
    // Test que verifica la obtencion del balance de tokens PTK de un usuario
    function testGetUserTokenBalance() public {
        uint256 tokenAmount = 100; 
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC; 
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), usdcCost);
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
        vm.stopPrank();
        
        (uint256 tokenBalance, PTKSale.UserInfo memory userInfo) = ptkSale.getUserTokenBalance(user1, TOKEN_ID);
        
        assertEq(tokenBalance, tokenAmount, "Balance de tokens incorrecto");
        assertEq(userInfo.stableCoinDirectContribution, usdcCost, "contribucion de stablecoin incorrecta");
        assertEq(userInfo.ftkPaid, 0, "FTK pagado deberia ser 0");
        assertEq(userInfo.chzPaid, 0, "CHZ pagado deberia ser 0");
    }
    
    // Test que verifica la obtencion de informacion de usuario sin transacciones previas
    function testGetUserInfo() public {
        PTKSale.UserInfo memory userInfo = ptkSale.getUserInfo(user1);
        
        assertEq(userInfo.stableCoinDirectContribution, 0, "contribucion inicial deberia ser 0");
        assertEq(userInfo.ftkPaid, 0, "FTK inicial deberia ser 0");
        assertEq(userInfo.chzPaid, 0, "CHZ inicial deberia ser 0");
    }
    
    // Test que verifica la actualizacion del precio de tokens en stablecoin por el owner
    function testSetTokenPrice() public {
        uint256 newPrice = 500000;
        
        vm.startPrank(owner);
        ptkSale.setTokenPrice(newPrice);
        vm.stopPrank();
        
        assertEq(ptkSale.tokenPriceInStableCoin(), newPrice, "Precio no se actualizo correctamente");
    }
    
    // Test que verifica la actualizacion del precio de tokens en FTK por el owner
    function testSetTokenPriceInFtk() public {
        uint256 newPrice = 500000000000000000;
        
        vm.startPrank(owner);
        ptkSale.setTokenPriceInFtk(newPrice);
        vm.stopPrank();
        
        assertEq(ptkSale.tokenPriceInFtk(), newPrice, "Precio FTK no se actualizo correctamente");
    }
    
    // Test que verifica la funcionalidad de pausa de emergencia del contrato
    function testEmergencyPause() public {
        vm.startPrank(owner);
        ptkSale.emergencyPause();
        vm.stopPrank();
        
        assertTrue(ptkSale.paused(), "El contrato deberia estar pausado");
        
        uint256 tokenAmount = 100;
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), usdcCost);
        
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
        
        vm.stopPrank();
    }
    
    // Test que verifica la funcionalidad de reanudar el contrato despues de una pausa
    function testEmergencyUnpause() public {
        vm.startPrank(owner);
        ptkSale.emergencyPause();
        assertTrue(ptkSale.paused(), "El contrato deberia estar pausado");
        
        ptkSale.emergencyUnpause();
        vm.stopPrank();
        
        assertFalse(ptkSale.paused(), "El contrato no deberia estar pausado");
    }
    
    // Test que verifica el retiro de tokens PTK no vendidos por el owner
    function testWithdrawPTK() public {
        uint256 withdrawAmount = 1000;
        uint256 initialOwnerBalance = ptkContract.balanceOf(owner, TOKEN_ID);
        
        vm.startPrank(owner);
        ptkSale.withdrawPTK(TOKEN_ID, withdrawAmount);
        vm.stopPrank();
        
        uint256 finalOwnerBalance = ptkContract.balanceOf(owner, TOKEN_ID);
        assertEq(finalOwnerBalance, initialOwnerBalance + withdrawAmount, "Owner no recibio los tokens PTK");
    }
    
    // Test que verifica que no se pueden comprar cero tokens
    function testCannotBuyZeroTokens() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be greater than 0");
        ptkSale.buyWithStableCoin(0, TOKEN_ID, false);
        vm.stopPrank();
    }
    
    // Test que verifica que solo el owner puede cambiar el precio de los tokens
    function testOnlyOwnerCanSetPrice() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        ptkSale.setTokenPrice(500000);
        vm.stopPrank();
    }
    
    // Test que verifica que solo el owner puede pausar el contrato
    function testOnlyOwnerCanPause() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        ptkSale.emergencyPause();
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra con saldo USDC insuficiente
    function testRejectPurchaseInsufficientUSDCBalance() public {
        uint256 tokenAmount = 100;
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
        
        address userSinBalance = vm.addr(10);
        deal(address(usdcContract), userSinBalance, usdcCost - 1); 
        
        vm.startPrank(userSinBalance);
        usdcContract.approve(address(ptkSale), usdcCost);
        
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra con saldo USDT insuficiente
    function testRejectPurchaseInsufficientUSDTBalance() public {
        uint256 tokenAmount = 50;
        uint256 usdtCost = tokenAmount * TOKEN_PRICE_USDC;
        
        address userSinBalance = vm.addr(11);
        deal(address(usdtContract), userSinBalance, usdtCost - 1);
        
        vm.startPrank(userSinBalance);
        usdtContract.approve(address(ptkSale), usdtCost);
        
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, true); 
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra con saldo FTK insuficiente
    function testRejectPurchaseInsufficientFTKBalance() public {
        uint256 tokenAmount = 10;
        uint256 ftkCost = tokenAmount * TOKEN_PRICE_FTK;
        
        address userSinBalance = vm.addr(12);
        MockFTK(address(ftkContract)).mint(userSinBalance, ftkCost - 1); 
        
        vm.startPrank(userSinBalance);
        ftkContract.approve(address(ptkSale), ftkCost);
        
        vm.expectRevert();
        ptkSale.buyWithFtk(tokenAmount, TOKEN_ID);
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra con saldo CHZ insuficiente
    function testRejectPurchaseInsufficientCHZBalance() public {
        uint256 tokenAmount = 10;
        uint256 chzNeeded = ptkSale.calculateCHZToPay(tokenAmount);
        
        address userSinBalance = vm.addr(13);
        vm.deal(userSinBalance, chzNeeded - 1 wei); 
        
        vm.startPrank(userSinBalance);
        
        vm.expectRevert();
        ptkSale.buyWithChz{value: chzNeeded - 1 wei}(tokenAmount, TOKEN_ID);
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra cuando no hay suficientes tokens PTK en el contrato
    function testRejectPurchaseInsufficientPTKInContract() public {

        uint256 contractBalance = ptkContract.balanceOf(address(ptkSale), TOKEN_ID);
        uint256 withdrawAmount = contractBalance - 5; 

        vm.startPrank(owner);
        ptkSale.withdrawPTK(TOKEN_ID, withdrawAmount);
        vm.stopPrank();
        
        uint256 tokenAmount = 10; 
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), usdcCost);
        
        vm.expectRevert("Not enough tokens in contract");
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra por debajo del monto minimo de USDC
    function testRejectPurchaseBelowMinimumUSDCAmount() public {
        uint256 minUsdcRequired = ptkSale.MIN_USDC_AMOUNT();
        uint256 tokenAmount = (minUsdcRequired / TOKEN_PRICE_USDC) - 1; 
        
        if (tokenAmount > 0) {
            uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
            
            vm.startPrank(user1);
            usdcContract.approve(address(ptkSale), usdcCost);
            
            vm.expectRevert("Minimum stablecoin amount not met");
            ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
            vm.stopPrank();
        }
    }
    
    // Test que verifica que se rechace la compra con CHZ cuando el valor enviado no coincide
    function testRejectCHZPurchaseIncorrectValue() public {
        uint256 tokenAmount = 10;
        uint256 chzNeeded = ptkSale.calculateCHZToPay(tokenAmount);
        uint256 incorrectValue = chzNeeded + 1 ether; 
        
        vm.startPrank(user1);
        
        vm.expectRevert("CHZ amount not equal to msg.value");
        ptkSale.buyWithChz{value: incorrectValue}(tokenAmount, TOKEN_ID);
        vm.stopPrank();
    }
    
    // Test que verifica que se rechace la compra con allowance insuficiente
    function testRejectPurchaseInsufficientAllowance() public {
        uint256 tokenAmount = 100;
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
        uint256 insufficientAllowance = usdcCost - 1; 
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), insufficientAllowance);
        
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        ptkSale.buyWithStableCoin(tokenAmount, TOKEN_ID, false);
        vm.stopPrank();
    }
    
    // Test que verifica el comportamiento con token ID inexistente
    function testPurchaseWithInvalidTokenId() public {
        uint256 invalidTokenId = 999; 
        uint256 tokenAmount = 10;
        uint256 usdcCost = tokenAmount * TOKEN_PRICE_USDC;
        
        vm.startPrank(user1);
        usdcContract.approve(address(ptkSale), usdcCost);
        
        vm.expectRevert("Not enough tokens in contract");
        ptkSale.buyWithStableCoin(tokenAmount, invalidTokenId, false);
        vm.stopPrank();
    }
}