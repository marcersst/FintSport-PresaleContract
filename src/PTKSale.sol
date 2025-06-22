// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IKayenRouter.sol";
import "./interfaces/IPTK.sol";

contract PTKSale is Ownable(msg.sender), Pausable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;


    // ==================== Eventos ====================
    event TokensPurchased(address indexed buyer, uint256 id, uint256 amount, address paymentToken, uint256 paymentAmount);
    event PriceUpdated(uint256 newPriceUsdc);
    event SaleStatusChanged(bool active);
    event TreasuryWalletChanged(address indexed oldWallet, address indexed newWallet);
    event UnsoldTokensRecovered(uint256 id, uint256 amount);
    
    // Eventos de emergencia
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);
    event EmergencyCHZWithdrawn(address indexed to, uint256 amount);
    event EmergencyTokenWithdrawn(address indexed token, address indexed to, uint256 amount);
    event EmergencyPTKWithdrawn(uint256 indexed id, address indexed to, uint256 amount);
    event EmergencyRouterUpdated(address indexed oldRouter, address indexed newRouter);

    // ==================== Constantes ====================
    uint256 public constant MIN_USDC_AMOUNT = 2_000_000; // 2 USDC (6 decimales)6 decimales

    // ==================== Contratos y direcciones ====================
    IPTK public immutable ptkContract;
    IERC20 public immutable usdcContract;
    IERC20 public immutable usdtContract;
    IERC20 public immutable wchzContract;
    IERC20 public immutable ftkContract;
    IKayenRouter public kayenRouter;
    address public treasuryWallet;

    // ==================== Variables de configuración ====================
    uint256 public tokenPriceInStableCoin; // precio en USDC 6 decimales
    uint256 public tokenPriceInFtk; // precio en FTK (18 decimales)
    mapping(uint256 => uint256) public totalTokensSold; // id => total tokens vendidos

    uint256 public totalStableCoinRaised; // total de stablecoins recaudados
    
    // ==================== Estructura de Usuarios ====================
    struct UserInfo {
        uint256 ftkPaid;
        uint256 chzPaid;
        uint256 stableCoinDirectContribution;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => uint256)) public userTokenBalance;

    // ==================== Constructor ====================
    constructor(
        address _ptkContract,
        address _usdcContract,
        address _usdtContract,
        address _wchzContract,
        address _ftkContract,
        address _kayenRouter,
        address _treasuryWallet,
        uint256 _priceInStableCoin, // en 6 decimales
        uint256 _priceInFtk // en 18 decimales
    ) {
        require(_ptkContract != address(0), "Invalid PTK contract");
        require(_usdcContract != address(0), "Invalid USDC contract");
        require(_usdtContract != address(0), "Invalid USDT contract");
        require(_wchzContract != address(0), "Invalid WCHZ contract");
        require(_ftkContract != address(0), "Invalid FTK contract");
        require(_kayenRouter != address(0), "Invalid router contract");
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        require(_priceInStableCoin > 0, "Price must be greater than 0");
        require(_priceInFtk > 0, "Price must be greater than 0");

        
        ptkContract = IPTK(_ptkContract);
        usdcContract = IERC20(_usdcContract);
        usdtContract = IERC20(_usdtContract);
        wchzContract = IERC20(_wchzContract);
        ftkContract = IERC20(_ftkContract);
        kayenRouter = IKayenRouter(_kayenRouter);
        treasuryWallet = _treasuryWallet;
        tokenPriceInStableCoin = _priceInStableCoin;
        tokenPriceInFtk = _priceInFtk;
    }

    // ==================== Funciones administrativas ====================
    function setTokenPrice(uint256 priceUsdc) external onlyOwner {
        require(priceUsdc > 0, "Price must be greater than 0");
        tokenPriceInStableCoin = priceUsdc;
        emit PriceUpdated(priceUsdc);
    }



    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "Invalid address");
        address oldWallet = treasuryWallet;
        treasuryWallet = _newTreasuryWallet;
        emit TreasuryWalletChanged(oldWallet, _newTreasuryWallet);
    }

     function setTokenPriceInFtk(uint256 priceFtk) external onlyOwner {
        require(priceFtk > 0, "Price must be greater than 0");
        tokenPriceInFtk = priceFtk;
        emit PriceUpdated(priceFtk);
    }


    // ==================== Funciones de compra ====================

    function buyWithStableCoin(uint256 amount, uint256 id, bool isUsdt) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        uint256 stableCoinAmount = amount * tokenPriceInStableCoin;
        require(stableCoinAmount >= MIN_USDC_AMOUNT, "Minimum stablecoin amount not met");
        require(ptkContract.balanceOf(address(this), id) >= amount, "Not enough tokens in contract");
        
        IERC20 stableCoinContract = isUsdt ? usdtContract : usdcContract;

        stableCoinContract.safeTransferFrom(msg.sender, treasuryWallet, stableCoinAmount);

        ptkContract.safeTransferFrom(address(this), msg.sender, id, amount, "");
        
        totalTokensSold[id] += amount;
        userTokenBalance[msg.sender][id] += amount;
        userInfo[msg.sender].stableCoinDirectContribution += stableCoinAmount;
        totalStableCoinRaised += stableCoinAmount;
        emit TokensPurchased(msg.sender, id, amount, address(stableCoinContract), stableCoinAmount);
    }

    function buyWithChz(uint256 amount, uint256 id) external payable nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(ptkContract.balanceOf(address(this), id) >= amount, "Not enough tokens in contract");


        uint256 amountToPayChz = calculateCHZToPay(amount);
        
        require (amountToPayChz == msg.value, "CHZ amount not equal to msg.value");

        uint256 usdcAmount = amount * tokenPriceInStableCoin;
        require(usdcAmount >= MIN_USDC_AMOUNT, "USDC amount too low, minimum is 0.01 USDC");
        
        uint256 minUsdcAmount = (usdcAmount * 98) / 100; // 2% slippage tolerance
        
        address[] memory path = new address[](2);
        path[0] = address(wchzContract);
        path[1] = address(usdcContract);
        
        uint256[] memory swapResult = kayenRouter.swapExactETHForTokens{value: msg.value}(
            minUsdcAmount,
            path,
            treasuryWallet,
            block.timestamp + 4 minutes
        );
        
        ptkContract.safeTransferFrom(address(this), msg.sender, id, amount, "");
        
        totalTokensSold[id] += amount;
        userTokenBalance[msg.sender][id] += amount;
        userInfo[msg.sender].chzPaid += msg.value;
        totalStableCoinRaised += swapResult[1];
        
        emit TokensPurchased(msg.sender, id, amount, address(0), msg.value);
    }

    function buyWithFtk(uint256 amount, uint256 id) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(ptkContract.balanceOf(address(this), id) >= amount, "Not enough tokens in contract");
        
        uint256 ftkAmount = amount * tokenPriceInFtk;
        
        ftkContract.safeTransferFrom(msg.sender, treasuryWallet, ftkAmount);
        
        ptkContract.safeTransferFrom(address(this), msg.sender, id, amount, "");
        
        totalTokensSold[id] += amount;
        userTokenBalance[msg.sender][id] += amount;
        userInfo[msg.sender].ftkPaid += ftkAmount; 
        
        emit TokensPurchased(msg.sender, id, amount, address(ftkContract), ftkAmount);
    }




    // ==================== Cálculo de precios ====================

    function calculateCHZToPay(uint256 amount) public view returns (uint256 amountToPayCHZ) {
        require(amount > 0, "Amount must be greater than 0");
        uint256 amountToPayStableCoin = amount * tokenPriceInStableCoin;
        address[] memory path = new address[](2);
        path[0] = address(wchzContract);
        path[1] = address(usdcContract);
        uint256[] memory amounts = kayenRouter.getAmountsIn(amountToPayStableCoin, path);
        amountToPayCHZ = amounts[0];
    }

    // ==================== Funciones de consulta ====================
    function getUserTokenBalance(address user, uint256 id) external view returns (uint256 tokenBalance, UserInfo memory info) {
        return (userTokenBalance[user][id], userInfo[user]);
    }
    
    function getUserInfo(address user) external view returns (UserInfo memory) {
        return userInfo[user];
    }



    // ==================== Recuperación de tokens no vendidos ====================
    
    function withdrawPTK(uint256 id, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        uint256 balance = ptkContract.balanceOf(address(this), id);
        require(balance >= amount, "Insufficient PTK balance");
        
        ptkContract.safeTransferFrom(address(this), owner(), id, amount, "");
        emit UnsoldTokensRecovered(id, amount);
    }
   
    function withdrawAllPTK(uint256 id) external onlyOwner {
        uint256 balance = ptkContract.balanceOf(address(this), id);
        require(balance > 0, "No PTK tokens to withdraw");
        
        ptkContract.safeTransferFrom(address(this), owner(), id, balance, "");
        emit UnsoldTokensRecovered(id, balance);
    }

    // ==================== Funciones de Emergencia ====================
    
     function emergencyPause() external onlyOwner {
         _pause();
         emit EmergencyPaused(msg.sender);
     }
     
     function emergencyUnpause() external onlyOwner {
         _unpause();
         emit EmergencyUnpaused(msg.sender);
     }
     
   
     function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner {
         require(token != address(0), "Invalid token address");
         IERC20 tokenContract = IERC20(token);
         uint256 balance = tokenContract.balanceOf(address(this));
         require(balance > 0, "No tokens to withdraw");
         
         uint256 withdrawAmount = amount == 0 ? balance : amount;
         require(withdrawAmount <= balance, "Insufficient token balance");
         
         tokenContract.safeTransfer(owner(), withdrawAmount);
         emit EmergencyTokenWithdrawn(token, owner(), withdrawAmount);
     }
     
     

     
   
     function emergencyUpdateRouter(address newRouter) external onlyOwner {
         require(newRouter != address(0), "Invalid router address");
         address oldRouter = address(kayenRouter);
         kayenRouter = IKayenRouter(newRouter);
         emit EmergencyRouterUpdated(oldRouter, newRouter);
     }

    // ==================== Fallbacks ====================
       receive() external payable {
        revert("Direct transfer not allowed");
    }

    fallback() external payable {
        revert("Direct transfer not allowed");
    }
}