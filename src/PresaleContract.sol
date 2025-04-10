// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IKayenRouter Interface
 * @notice Interfaz para interactuar con el router de Kayen para operaciones de swap
 */
interface IKayenRouter {

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
   
    function getAmountsOut(uint amountIn, address[] calldata path) 
        external view returns (uint[] memory amounts);
        
    function getAmountsIn(uint amountOut, address[] calldata path) 
        external view returns (uint[] memory amounts);        
}


contract PresaleContract is Ownable(msg.sender), Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ==================== Eventos ====================
    event TokensPurchased(address indexed buyer, uint256 chzAmount, uint256 usdcAmount, uint256 tokensReceived);
    event PresaleExtended(uint256 oldEndTime, uint256 newEndTime);
    event TreasuryWalletChanged(address indexed oldWallet, address indexed newWallet);
    event UnsoldTokensRecovered(uint256 amount);
    event ERC20TokensRecovered(address indexed tokenContract, uint256 amount);
    event PresalePaused(address indexed owner);
    event PresaleUnpaused(address indexed owner);

    // ==================== Constantes ====================
    uint256 public constant MIN_USDC_AMOUNT = 10_000; // esta en 6 decimales

    // ==================== Contratos y direcciones ====================
    IERC20 public immutable saleToken;
    IERC20 public immutable usdcContract;
    IERC20 public immutable usdtContract;
    IERC20 public immutable wCHZ;
    address public treasuryWallet;
    IKayenRouter public kayenRouter;

    // ==================== Variables de configuración de la preventa ====================
    uint256 public tokenPriceInUsdc; // en 6 decimales
    uint256 public saleEndTime;
    uint256 public totalTokensForSale;
    uint256 public stableCoinHardCap; // en 6 decimales

    // ==================== Variables de estado de la preventa ====================
    uint256 public totalTokensSold;
    uint256 public totalStableCoinRaised; // en 6 decimales

    // ==================== Estructuras de datos ====================
    
    struct UserInfo {
        uint256 tokenBalance;
        uint256 usdcFromChzSwap;
        uint256 chzPaid;
        uint256 stableCoinDirectContribution;
    }
    
    mapping(address => UserInfo) public userInfo;

    /**
     * @notice Constructor del contrato de preventa
     * @dev Inicializa el contrato con los parámetros necesarios para la preventa
     * @param _saleToken Dirección del token que se venderá
     * @param _tokenPriceInUsdc Precio del token en USDC (con 6 decimales)
     * @param _wCHZ Dirección del token wCHZ
     * @param _saleEndTime Tiempo de finalización de la preventa
     * @param _totalTokensForSale Total de tokens disponibles para la venta
     * @param _usdcContract Dirección del contrato USDC
     * @param _usdtContract Dirección del contrato USDT
     * @param _treasuryWallet Dirección de la billetera del tesoro
     * @param _kayenRouter Dirección del router de Kayen
     * @param _stableCoinHardCap Límite máximo de stablecoins a recaudar
     */
    constructor(
        address _saleToken,
        uint256 _tokenPriceInUsdc,
        address _wCHZ,
        uint256 _saleEndTime,
        uint256 _totalTokensForSale,
        address _usdcContract,
        address _usdtContract,
        address _treasuryWallet,
        address _kayenRouter,
        uint256 _stableCoinHardCap
    ) {
        require(_saleToken != address(0), "Token address cannot be zero");
        require(_wCHZ != address(0), "wCHZ address cannot be zero");
        require(_usdcContract != address(0), "USDC address cannot be zero");
        require(_usdtContract != address(0), "USDT address cannot be zero");
        require(_treasuryWallet != address(0), "Treasury wallet cannot be zero");
        require(_kayenRouter != address(0), "Router address cannot be zero");
        require(_tokenPriceInUsdc > 0, "Token price must be greater than zero");
        require(_saleEndTime > block.timestamp, "Sale time must be in the future");
        require(_totalTokensForSale > 0, "Token amount must be greater than zero");
        require(_stableCoinHardCap > 0, "Stablecoin hard cap must be greater than zero");

        saleToken = IERC20(_saleToken);
        usdcContract = IERC20(_usdcContract);
        usdtContract = IERC20(_usdtContract);
        wCHZ = IERC20(_wCHZ);
        tokenPriceInUsdc = _tokenPriceInUsdc;
        saleEndTime = _saleEndTime;
        totalTokensForSale = _totalTokensForSale;
        treasuryWallet = _treasuryWallet;
        kayenRouter = IKayenRouter(_kayenRouter);
        stableCoinHardCap = _stableCoinHardCap;
    }

    // ==================== Funciones administrativas ====================
    /**
     * @notice Pausa el contrato de preventa
     * @dev Solo puede ser llamado por el propietario
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit PresalePaused(msg.sender);
    }

    /**
     * @notice Reanuda el contrato de preventa después de una pausa
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit PresaleUnpaused(msg.sender);
    }

    /**
     * @notice Actualiza la dirección de la billetera del tesoro
     */
    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "Invalid address");
        address oldWallet = treasuryWallet;
        treasuryWallet = _newTreasuryWallet;
        
        emit TreasuryWalletChanged(oldWallet, _newTreasuryWallet);
    }

    /**
     * @notice Extiende el tiempo de la preventa
     * @param _newSaleEndTime Nuevo tiempo de finalización de la preventa
     */
    function extendedSaleTime(uint256 _newSaleEndTime) external onlyOwner {
        require(_newSaleEndTime > block.timestamp, "New end time must be later than current end time");
        uint256 oldEndTime = saleEndTime;
        saleEndTime = _newSaleEndTime;
        
        emit PresaleExtended(oldEndTime, _newSaleEndTime);
    }

    // ==================== Funciones de compra de tokens ====================
    /**
     * @notice Calcula la cantidad de tokens a recibir por una cantidad de CHZ
     * @dev Utiliza el router de Kayen para obtener la tasa de conversión
     * @param chzAmount Cantidad de CHZ a convertir
     * @return usdcAmount Cantidad equivalente en USDC
     * @return tokensToReceive Cantidad de tokens que recibirá el usuario
     */
    function calculateTokensForChz(uint256 chzAmount) public view returns(uint256 usdcAmount, uint256 tokensToReceive) {
        address[] memory path = new address[](2);
        path[0] = address(wCHZ);
        path[1] = address(usdcContract);
        
        uint256[] memory amounts = kayenRouter.getAmountsOut(chzAmount, path);
        usdcAmount = amounts[1];
        
        tokensToReceive = (usdcAmount * 1e18) / tokenPriceInUsdc;
        return (usdcAmount, tokensToReceive);
    }

    /**
     * @notice Permite a los usuarios comprar tokens con CHZ
     */
    function purchaseTokens() public payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Must send CHZ to purchase tokens");
        require(!isPresaleEnded(), "Presale has ended");
        
        (uint256 usdcAmount, uint256 tokensToReceive) = calculateTokensForChz(msg.value);
        require(tokensToReceive > 0, "Amount too small, would result in zero tokens");
        require(usdcAmount >= MIN_USDC_AMOUNT, "USDC amount too low, minimum is 0.01 USDC");
        require(totalTokensSold + tokensToReceive <= totalTokensForSale, "Exceeds available tokens");
        
        userInfo[msg.sender].tokenBalance += tokensToReceive;
        userInfo[msg.sender].usdcFromChzSwap += usdcAmount;
        userInfo[msg.sender].chzPaid += msg.value;
        
        totalTokensSold += tokensToReceive;
        
        uint256 minUsdcAmount = (usdcAmount * 98) / 100;

        address[] memory path = new address[](2);
        path[0] = address(wCHZ);
        path[1] = address(usdcContract);

        uint256[] memory swapResult = kayenRouter.swapExactETHForTokens{value: msg.value}(
            minUsdcAmount,
            path,
            treasuryWallet,
            block.timestamp + 4 minutes
        );
        totalStableCoinRaised += swapResult[1];

        saleToken.safeTransfer(msg.sender, tokensToReceive);
        
        emit TokensPurchased(msg.sender, msg.value, usdcAmount, tokensToReceive);
    }

    /**
     * @notice Permite a los usuarios comprar tokens con Stablecoins
     * @param amount Cantidad de tokens a comprar
     * @param isUsdc Indica si es USDC o USDT
     */
    function purchaseTokensWithStablecoin(uint256 amount, bool isUsdc) external nonReentrant whenNotPaused {
        require(!isPresaleEnded(), "Presale has ended");
        require(amount > 0, "amount must be more than 0");
        require(totalTokensSold + amount <= totalTokensForSale, "Exceeds available tokens");

        uint256 amountToPay = (amount * tokenPriceInUsdc) / 1e18;
        require(amountToPay > 0, "Amount too small");
        require(amountToPay >= MIN_USDC_AMOUNT, "Stablecoin amount too low, minimum is 0.01 USDC");

        IERC20 stableCoin = isUsdc ? usdcContract : usdtContract;
        stableCoin.safeTransferFrom(msg.sender, treasuryWallet, amountToPay);

        userInfo[msg.sender].stableCoinDirectContribution += amountToPay;

        totalStableCoinRaised += amountToPay;
        totalTokensSold += amount;

        saleToken.safeTransfer(msg.sender, amount);
        userInfo[msg.sender].tokenBalance += amount;
        
        emit TokensPurchased(msg.sender, 0, amountToPay, amount);
    }

    // ==================== Funciones de consulta ====================
   
    function getUserInfo(address user) external view returns (uint256, uint256, uint256, uint256) {
        return (
            userInfo[user].tokenBalance,
            userInfo[user].usdcFromChzSwap,
            userInfo[user].chzPaid,
            userInfo[user].stableCoinDirectContribution
        );
    }

    /**
     * @notice Obtiene las estadisticas actuales de la preventa
     */
    function getPresaleStats() external view returns (uint256 endTime, uint256 totalTokens, uint256 soldTokens, uint256 remainingTokens, uint256 tokenPrice) {
        return (
            saleEndTime,
            totalTokensForSale,
            totalTokensSold,
            totalTokensForSale - totalTokensSold,
            tokenPriceInUsdc
        );
    }

    /**
     * @notice Verifica si la preventa ha terminado
     */
    function isPresaleEnded() public view returns (bool) {
        return block.timestamp > saleEndTime || totalTokensSold >= totalTokensForSale || totalStableCoinRaised >= stableCoinHardCap;
    }

    // ==================== Funciones de recuperación y emergencia ====================
    /**
     * @notice Permite al propietario recuperar tokens no vendidos después de la preventa
     * @dev Solo puede ser llamado después de que la preventa haya terminado
     */
    function recoverUnsoldTokens() external onlyOwner {
        require(isPresaleEnded(), "Presale has not ended");
        uint256 unsoldTokens = totalTokensForSale - totalTokensSold;
        require(unsoldTokens > 0, "No tokens to recover");
        
        saleToken.safeTransfer(owner(), unsoldTokens);
        
        totalTokensForSale = 0;
        
        emit UnsoldTokensRecovered(unsoldTokens);
    }

    /**
     * @notice Permite al propietario recuperar tokens ERC20 enviados al contrato
     */
    function recoverERC20(address tokenContract, uint256 amount) external onlyOwner {
        if (tokenContract == address(saleToken)) {
            require(isPresaleEnded(), "Presale has not ended");
        }
        IERC20(tokenContract).safeTransfer(owner(), amount);
        
        emit ERC20TokensRecovered(tokenContract, amount);
    }

    /**
     * @notice Permite al propietario retirar tokens del contrato en caso de emergencia
     * @dev Solo puede ser llamado cuando el contrato está pausado
     * @param tokenAddress Dirección del token a retirar
     * @param amount Cantidad de tokens a retirar
     */
    function emergencyWithdrawTokens(address tokenAddress, uint256 amount) external onlyOwner whenPaused {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(amount > 0, "Amount must be greater than zero");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient token balance");
        
        token.safeTransfer(owner(), amount);
        
        emit ERC20TokensRecovered(tokenAddress, amount);
    }

    // ==================== Funciones de rechazo de transferencias directas ====================
    
    receive() external payable {
        revert("Direct transfer not allowed");
    }

   
    fallback() external payable {
        revert("Direct transfer not allowed");
    }
}

