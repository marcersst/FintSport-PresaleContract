// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {PresaleContract} from "../src/PresaleContract.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TokenSale is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract PresaleContractTest is Test {
    
    PresaleContract public presaleContract;
    IERC20 public usdcContract;
    IERC20 public usdtContract;
    IERC20 public wChz;
    TokenSale public tokenSaleContract;
    
    IERC20 public tokenSale;
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public treasury = vm.addr(3);


    function setUp () public {
        //inicializacion de variables
        usdcContract = IERC20(vm.envAddress("USDC_ADDRESS"));
        usdtContract = IERC20(vm.envAddress("USDT_ADDRESS"));
        wChz = IERC20(vm.envAddress("WCHZ_ADDRESS"));

        string memory forkUrl = vm.envString("CHILIZ_RPC_URL");
        vm.createSelectFork(forkUrl);

        tokenSaleContract = new TokenSale("Token Sale", "TSL");

        presaleContract = new PresaleContract(
            address(tokenSaleContract), // _saleToken
            250000, // _tokenPriceInUsdc (0.25 USDC con 6 decimales)
            address(wChz), // _wCHZ
            block.timestamp + 30 days, // _saleEndTime (30 días a partir de ahora)
            10000 * 10**18, // _totalTokensForSale (10000 tokens)
            address(usdcContract), // _usdcContract
            address(usdtContract), // _usdtContract
            treasury, // _treasuryWallet
            address(vm.envAddress("KAYEN_ROUTER_ADDRESS")),
            1000000 * 10**6 // _stableCoinHardCap (1000 USDC con 6 decimales)
        );

        tokenSaleContract.mint(address(presaleContract), 10000 * 10**18);
        console.log("balance del Contrato de Presale:", tokenSaleContract.balanceOf(address(presaleContract)));

        
        deal(address(usdcContract), user1, 10000 * 10**6);
        deal(address(usdtContract), user1, 10000 * 10**6);
        deal(address(usdcContract), user2, 10000 * 10**6);

        //asignar chz a las direcciones simuladas
        vm.deal(user1, 100000 ether);
        vm.deal(user2, 100000 ether);

        //control de balance de las direcciones simuladas
        console.log("[USDC] Balance de user1 (en unidades con 6 decimales):", usdcContract.balanceOf(user1));
        console.log("[USDC] Balance de user2 (en unidades con 6 decimales):", usdcContract.balanceOf(user2));
        console.log("[USDT] Balance de user1 (en unidades con 6 decimales):", usdtContract.balanceOf(user1));

        //balance de CHZ nativo de las direcciones simuladas
        console.log("[CHZ] Balance nativo de user1 (en wei):", address(user1).balance);
        console.log("[CHZ] Balance nativo de user2 (en wei):", address(user2).balance);

        // Direcciones de los contratos desplegados
        console.log("direccion del contrato de Presale:", address(presaleContract));
        console.log("direccion del contrato TokenSale:", address(tokenSaleContract));
        console.log("direccion del contrato USDC:", address(usdcContract));
        console.log("direccion del contrato USDT:", address(usdtContract));
        
    }

    //test de la funcion buyTokens
    function testBuyTokens() public {
        uint256 initialUserUsdcBalance = usdcContract.balanceOf(user1);
        uint256 initialUserTokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 initialPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 initialTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("Balance inicial de USDC del usuario:", initialUserUsdcBalance);
        console.log("Balance inicial de tokens del usuario:", initialUserTokenBalance);
        console.log("Balance inicial de tokens del contrato de preventa:", initialPresaleTokenBalance);
        console.log("Balance inicial de USDC del tesoro:", initialTreasuryUsdcBalance);
       
        vm.startPrank(user1);
        uint256 value = 120110000;   
        uint256 cantidaddetokens = 480440000000000000000;
        usdcContract.approve(address(presaleContract), value);
        presaleContract.purchaseTokensWithStablecoin(cantidaddetokens, true);
        vm.stopPrank(); 

        uint256 finalUserUsdcBalance = usdcContract.balanceOf(user1);
        uint256 finalUserTokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 finalPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("Balance final de USDC del usuario:", finalUserUsdcBalance);
        console.log("Balance final de tokens del usuario:", finalUserTokenBalance);
        console.log("Balance final de tokens del contrato de preventa:", finalPresaleTokenBalance);
        console.log("Balance final de USDC del tesoro:", finalTreasuryUsdcBalance);
        
        assertEq(finalUserUsdcBalance, initialUserUsdcBalance - value, "El balance de USDC del usuario no disminuyo correctamente");
        assertEq(finalUserTokenBalance, initialUserTokenBalance + cantidaddetokens, "El usuario no recibio la cantidad correcta de tokens");
        assertEq(finalPresaleTokenBalance, initialPresaleTokenBalance - cantidaddetokens, "El contrato de preventa no envio la cantidad correcta de tokens");
        assertEq(finalTreasuryUsdcBalance, initialTreasuryUsdcBalance + value, "El tesoro no recibio la cantidad correcta de USDC");
    }

    function testBuyTokensWithCHZ() public {
        uint256 value = 3351760000000000000000;
        uint256 initialUserChzBalance = address(user1).balance;
        uint256 initialUserTokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 initialPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 initialTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        (uint256 usdcAmount, uint256 tokensToReceive) = presaleContract.calculateTokensForChz(value);
        
        console.log("USDC equivalente para CHZ:", usdcAmount);
        console.log("Tokens a recibir:", tokensToReceive);
        console.log("Balance inicial de CHZ del usuario (en wei):", initialUserChzBalance);
        console.log("Balance inicial de tokens del usuario:", initialUserTokenBalance);
        console.log("Balance inicial de tokens del contrato de preventa:", initialPresaleTokenBalance);
        console.log("Balance inicial de USDC del tesoro:", initialTreasuryUsdcBalance);
       
        vm.startPrank(user1);
        presaleContract.purchaseTokens{value: value}();
        vm.stopPrank();

        uint256 finalUserChzBalance = address(user1).balance;
        uint256 finalUserTokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 finalPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("Balance final de CHZ del usuario (en wei):", finalUserChzBalance);
        console.log("Balance final de tokens del usuario:", finalUserTokenBalance);
        console.log("Balance final de tokens del contrato de preventa:", finalPresaleTokenBalance);
        console.log("Balance final de USDC del tesoro:", finalTreasuryUsdcBalance);
        
        assertEq(finalUserChzBalance, initialUserChzBalance - value, "El balance de CHZ del usuario no disminuyo correctamente");
        assertEq(finalUserTokenBalance, initialUserTokenBalance + tokensToReceive, "El usuario no recibio la cantidad correcta de tokens");
        assertEq(finalPresaleTokenBalance, initialPresaleTokenBalance - tokensToReceive, "El contrato de preventa no envio la cantidad correcta de tokens");
        assertEq(finalTreasuryUsdcBalance, initialTreasuryUsdcBalance + usdcAmount, "El tesoro no recibio la cantidad correcta de USDC");
    }

    function testCompararComprasConMismoValor() public {
        uint256 chzAmount = 30000000000000000000000;
        
        (uint256 usdcEquivalente, uint256 tokensEsperadosConChz) = presaleContract.calculateTokensForChz(chzAmount);
        
        console.log("=== COMPARACION DE COMPRAS CON MISMO VALOR ===");
        console.log("Cantidad de CHZ a usar:", chzAmount);
        console.log("Equivalente en USDC:", usdcEquivalente);
        console.log("Tokens esperados con CHZ:", tokensEsperadosConChz);
        
        uint256 initialUser1ChzBalance = address(user1).balance;
        uint256 initialUser1TokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 initialPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 initialTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("Balance inicial de tokens del contrato de preventa:", initialPresaleTokenBalance);
        
        vm.startPrank(user1);
        presaleContract.purchaseTokens{value: chzAmount}();
        vm.stopPrank();
        
        uint256 finalUser1ChzBalance = address(user1).balance;
        uint256 finalUser1TokenBalance = tokenSaleContract.balanceOf(user1);
        uint256 finalPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("Balance final de tokens del contrato de preventa despues de CHZ:", finalPresaleTokenBalance);
        
        console.log("\n=== RESULTADOS COMPRA CON CHZ ===");
        console.log("CHZ gastados:", initialUser1ChzBalance - finalUser1ChzBalance);
        console.log("Tokens recibidos:", finalUser1TokenBalance - initialUser1TokenBalance);
        console.log("USDC recibido por el tesoro:", finalTreasuryUsdcBalance - initialTreasuryUsdcBalance);
        
        uint256 initialUser2UsdcBalance = usdcContract.balanceOf(user2);
        uint256 initialUser2TokenBalance = tokenSaleContract.balanceOf(user2);
        uint256 updatedPresaleTokenBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 updatedTreasuryUsdcBalance = usdcContract.balanceOf(treasury);
        
        console.log("\nBalance de tokens del contrato de preventa antes de USDC:", updatedPresaleTokenBalance);
        
        uint256 tokensEsperadosConUsdc = (usdcEquivalente * 1e18) / presaleContract.tokenPriceInUsdc();
        console.log("\n=== COMPRA CON USDC EQUIVALENTE ===");
        console.log("USDC a usar:", usdcEquivalente);
        console.log("Tokens esperados con USDC:", tokensEsperadosConUsdc);
        
        vm.startPrank(user2);
        usdcContract.approve(address(presaleContract), usdcEquivalente);
        presaleContract.purchaseTokensWithStablecoin(tokensEsperadosConUsdc, true);
        vm.stopPrank();
        
        uint256 finalUser2UsdcBalance = usdcContract.balanceOf(user2);
        uint256 finalUser2TokenBalance = tokenSaleContract.balanceOf(user2);
        uint256 finalPresaleTokenBalanceAfterUsdc = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalTreasuryUsdcBalanceAfterUsdc = usdcContract.balanceOf(treasury);
        
        console.log("Balance final de tokens del contrato de preventa despues de USDC:", finalPresaleTokenBalanceAfterUsdc);
        console.log("\n=== RESULTADOS COMPRA CON USDC ===");
        console.log("USDC gastados:", initialUser2UsdcBalance - finalUser2UsdcBalance);
        console.log("Tokens recibidos:", finalUser2TokenBalance - initialUser2TokenBalance);
        console.log("USDC recibido por el tesoro:", finalTreasuryUsdcBalanceAfterUsdc - updatedTreasuryUsdcBalance);
        
        console.log("\n=== COMPARACION DE RESULTADOS ===");
        console.log("Diferencia en tokens recibidos:", int256((finalUser1TokenBalance - initialUser1TokenBalance) - (finalUser2TokenBalance - initialUser2TokenBalance)));
        console.log("Diferencia en USDC recibido por tesoro:", int256((finalTreasuryUsdcBalance - initialTreasuryUsdcBalance) - (finalTreasuryUsdcBalanceAfterUsdc - updatedTreasuryUsdcBalance)));
        
        assertApproxEqRel(
            finalUser1TokenBalance - initialUser1TokenBalance,
            finalUser2TokenBalance - initialUser2TokenBalance,
            0.01e18,
            "La cantidad de tokens recibidos deberia ser similar en ambos metodo"
        );
        
        assertApproxEqRel(
            finalTreasuryUsdcBalance - initialTreasuryUsdcBalance,
            finalTreasuryUsdcBalanceAfterUsdc - updatedTreasuryUsdcBalance,
            0.01e18,
            "La cantidad de USDC recibida por el tesoro deberia ser similar en ambos metodo"
        );
        
        console.log("\n=== RESUMEN FINAL DE LA PRUEBA ===");
        console.log("Tokens comprados con CHZ:", finalUser1TokenBalance - initialUser1TokenBalance);
        console.log("Tokens comprados con USDC:", finalUser2TokenBalance - initialUser2TokenBalance);
        console.log("CHZ gastados:", initialUser1ChzBalance - finalUser1ChzBalance);
        console.log("USDC gastados:", initialUser2UsdcBalance - finalUser2UsdcBalance);
        console.log("Balance final del contrato de presale:", finalPresaleTokenBalanceAfterUsdc);
        console.log("USDC total en tesoreria:", finalTreasuryUsdcBalanceAfterUsdc);
    }

    // ==================== Tests de funcionalidades de emergencia y finalización ====================

    function testPauseContract() public {
        vm.startPrank(address(this));
        bool isPaused = false;
        try presaleContract.purchaseTokens{value: 1 ether}() {
            isPaused = false;
        } catch {
            isPaused = true;
        }
        vm.stopPrank();
        assertFalse(isPaused, "El contrato no deberia estar pausado inicialmente");

        vm.prank(presaleContract.owner());
        presaleContract.pauseContract();

        vm.startPrank(user1);
        bool failedAfterPause = false;
        try presaleContract.purchaseTokens{value: 1 ether}() {
            failedAfterPause = false;
        } catch {
            failedAfterPause = true;
        }
        vm.stopPrank();
        assertTrue(failedAfterPause, "El contrato deberia estar pausado y rechazar compras");

        vm.prank(presaleContract.owner());
        presaleContract.unpauseContract();

        vm.startPrank(user1);
        bool isUnpaused = false;
        try presaleContract.purchaseTokens{value: 1 ether}() {
            isUnpaused = true;
        } catch {
            isUnpaused = false;
        }
        vm.stopPrank();
        assertTrue(isUnpaused, "El contrato deberia estar despausado y permitir compras");
    }

    function testEmergencyWithdrawTokens() public {
        vm.prank(presaleContract.owner());
        presaleContract.pauseContract();

        uint256 initialContractBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 initialOwnerBalance = tokenSaleContract.balanceOf(presaleContract.owner());

        console.log("Balance inicial de tokens en el contrato:", initialContractBalance);
        console.log("Balance inicial de tokens del owner:", initialOwnerBalance);

        uint256 emergencyAmount = 1000 * 10**18;

        vm.prank(presaleContract.owner());
        presaleContract.emergencyWithdrawTokens(address(tokenSaleContract), emergencyAmount);

        uint256 finalContractBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalOwnerBalance = tokenSaleContract.balanceOf(presaleContract.owner());

        console.log("Balance final de tokens en el contrato:", finalContractBalance);
        console.log("Balance final de tokens del owner:", finalOwnerBalance);

        assertEq(finalContractBalance, initialContractBalance - emergencyAmount, "El balance del contrato deberia disminuir");
        assertEq(finalOwnerBalance, initialOwnerBalance + emergencyAmount, "El balance del owner deberia aumentar");
    }

    function testHardCapReached() public {
        uint256 hardcap = presaleContract.stableCoinHardCap();
        uint256 tokenPrice = presaleContract.tokenPriceInUsdc();
       
        uint256 tokensToReachHardcap = (hardcap * 1e18) / tokenPrice;
        uint256 availableTokens = presaleContract.totalTokensForSale() - presaleContract.totalTokensSold();
        
        if (tokensToReachHardcap > availableTokens) {
            tokensToReachHardcap = availableTokens;
        }

        console.log("Hardcap en USDC:", hardcap);
        console.log("Precio del token en USDC:", tokenPrice);
        console.log("Tokens necesarios para alcanzar hardcap:", tokensToReachHardcap);
        console.log("Tokens disponibles:", availableTokens);

        uint256 usdcNeeded = (tokensToReachHardcap * tokenPrice) / 1e18;
        
        deal(address(usdcContract), user1, usdcNeeded);

        vm.startPrank(user1);
        usdcContract.approve(address(presaleContract), usdcNeeded);
        presaleContract.purchaseTokensWithStablecoin(tokensToReachHardcap, true);
        vm.stopPrank();

        assertTrue(
            presaleContract.totalStableCoinRaised() >= hardcap || 
            presaleContract.totalTokensSold() >= presaleContract.totalTokensForSale(),
            "No se alcanzo el hardcap o no se vendieron todos los tokens"
        );

        vm.startPrank(user2);
        usdcContract.approve(address(presaleContract), 1000 * 10**6);
        uint256 tokensToTryBuy = (1000 * 10**6 * 1e18) / tokenPrice;

        bool purchaseFailed = false;
        try presaleContract.purchaseTokensWithStablecoin(tokensToTryBuy, true) {
            purchaseFailed = false;
        } catch {
            purchaseFailed = true;
        }
        vm.stopPrank();

        assertTrue(purchaseFailed, "La compra deberia fallar cuando se alcanza el hardcap");
        assertTrue(presaleContract.isPresaleEnded(), "La preventa deberia considerarse finalizada al alcanzar el hardcap");
    }

    function testPresaleEndTime() public {
        assertFalse(presaleContract.isPresaleEnded(), "La preventa no deberia estar finalizada inicialmente");

        uint256 endTime = presaleContract.saleEndTime();
        vm.warp(endTime + 1 hours);

        assertTrue(presaleContract.isPresaleEnded(), "La preventa deberia estar finalizada despues del tiempo limite");

        vm.startPrank(user1);
        bool purchaseFailed = false;
        try presaleContract.purchaseTokens{value: 1 ether}() {
            purchaseFailed = false;
        } catch {
            purchaseFailed = true;
        }
        vm.stopPrank();

        assertTrue(purchaseFailed, "La compra deberia fallar cuando la preventa ha finalizado");
    }

    function testRecoverUnsoldTokens() public {
        uint256 endTime = presaleContract.saleEndTime();
        vm.warp(endTime + 1 hours);

        assertTrue(presaleContract.isPresaleEnded(), "La preventa deberia estar finalizada");

        uint256 totalTokensForSale = presaleContract.totalTokensForSale();
        uint256 totalTokensSold = presaleContract.totalTokensSold();
        uint256 unsoldTokens = totalTokensForSale - totalTokensSold;

        console.log("Total tokens para venta:", totalTokensForSale);
        console.log("Total tokens vendidos:", totalTokensSold);
        console.log("Tokens no vendidos:", unsoldTokens);

        uint256 initialContractBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 initialOwnerBalance = tokenSaleContract.balanceOf(presaleContract.owner());

        console.log("Balance inicial de tokens en el contrato:", initialContractBalance);
        console.log("Balance inicial de tokens del owner:", initialOwnerBalance);

        vm.prank(presaleContract.owner());
        presaleContract.recoverUnsoldTokens();

        uint256 finalContractBalance = tokenSaleContract.balanceOf(address(presaleContract));
        uint256 finalOwnerBalance = tokenSaleContract.balanceOf(presaleContract.owner());

        console.log("Balance final de tokens en el contrato:", finalContractBalance);
        console.log("Balance final de tokens del owner:", finalOwnerBalance);

        assertEq(finalContractBalance, initialContractBalance - unsoldTokens, "El balance del contrato deberia disminuir");
        assertEq(finalOwnerBalance, initialOwnerBalance + unsoldTokens, "El balance del owner deberia aumentar");
        assertEq(presaleContract.totalTokensForSale(), 0, "El total de tokens para venta deberia ser 0 despues de recuperar");
    }

    function testRecoverERC20() public {
        TokenSale testToken = new TokenSale("Test Token", "TST");
        testToken.mint(address(this), 1000 * 10**18);
        testToken.transfer(address(presaleContract), 500 * 10**18);

        uint256 initialContractBalance = testToken.balanceOf(address(presaleContract));
        uint256 initialOwnerBalance = testToken.balanceOf(presaleContract.owner());

        console.log("Balance inicial de tokens de prueba en el contrato:", initialContractBalance);
        console.log("Balance inicial de tokens de prueba del owner:", initialOwnerBalance);

        vm.prank(presaleContract.owner());
        presaleContract.recoverERC20(address(testToken), initialContractBalance);

        uint256 finalContractBalance = testToken.balanceOf(address(presaleContract));
        uint256 finalOwnerBalance = testToken.balanceOf(presaleContract.owner());

        console.log("Balance final de tokens de prueba en el contrato:", finalContractBalance);
        console.log("Balance final de tokens de prueba del owner:", finalOwnerBalance);

        assertEq(finalContractBalance, 0, "El balance del contrato deberia ser 0");
        assertEq(finalOwnerBalance, initialOwnerBalance + initialContractBalance, "El balance del owner deberia aumentar");
    }
}