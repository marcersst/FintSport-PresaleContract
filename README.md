
## Descripción

Este es  un proyecto de contratos  para la plataforma FintSport, incluye un contrato de preventa que permite a los usuarios comprar tokens utilizando stablecoins (USDC/USDT) o CHZ nativo. El proyecto está construido utilizando Foundry, un toolkit modular para el desarrollo de aplicaciones Ethereum.

## Características Principales

- **Contrato de Preventa**: Permite a los usuarios comprar tokens con USDC, USDT o CHZ nativo.
- **Integración con Kayen Router**: Para realizar swaps de CHZ a stablecoins.
- **Mecanismos de Seguridad**: Incluye protección contra reentrancia y capacidad de pausar el contrato.
- **Gestión de Tesorería**: Fondos recaudados se envían a una wallet de tesorería configurable.
- **Recuperación de Tokens**: Funcionalidad para recuperar tokens no vendidos al finalizar la preventa.

## Funcionamiento del Contrato

El contrato `PresaleContract` implementa un mecanismo de preventa de tokens con las siguientes características:

### Métodos de Compra

1. **Compra con Stablecoins (USDC/USDT)**:
   - Los usuarios pueden comprar tokens directamente con USDC o USDT.
   - La función `purchaseTokensWithStablecoin` permite especificar la cantidad de tokens a comprar y el tipo de stablecoin a utilizar.
   - Los fondos se transfieren directamente a la wallet de tesorería.

2. **Compra con CHZ Nativo**:
   - Los usuarios pueden comprar tokens con CHZ utilizando la función `purchaseTokens`.
   - El CHZ se convierte automáticamente a USDC mediante el router de Kayen.
   - El USDC resultante se envía a la wallet de tesorería.

### Funciones Principales

- **calculateTokensForChz**: Calcula la cantidad de tokens que recibirá un usuario al pagar con CHZ.
- **purchaseTokens**: Permite comprar tokens con CHZ nativo.
- **purchaseTokensWithStablecoin**: Permite comprar tokens con USDC o USDT.
- **getUserInfo**: Obtiene información sobre las compras de un usuario.
- **getPresaleStats**: Obtiene estadísticas actuales de la preventa.
- **isPresaleEnded**: Verifica si la preventa ha finalizado.

### Funciones Administrativas

- **pauseContract/unpauseContract**: Permite pausar/reanudar el contrato en caso de emergencia.
- **setTreasuryWallet**: Actualiza la dirección de la wallet de tesorería.
- **extendedSaleTime**: Extiende el tiempo de la preventa.
- **recoverUnsoldTokens**: Recupera tokens no vendidos después de finalizar la preventa.
- **recoverERC20**: Recupera tokens ERC20 enviados al contrato.
- **emergencyWithdrawTokens**: Permite retirar tokens en caso de emergencia (solo cuando está pausado).

### Mecanismos de Seguridad

- **ReentrancyGuard**: Protección contra ataques de reentrancia.
- **Pausable**: Capacidad de pausar el contrato en caso de emergencia.
- **Ownable**: Control de acceso para funciones administrativas.

## Resumen de los Tests

El archivo `PresaleContractTest.t.sol` contiene pruebas exhaustivas que verifican todas las funcionalidades del contrato:

### Tests de Compra de Tokens

- **testBuyTokens**: Verifica la compra de tokens con USDC, asegurando que los balances se actualicen correctamente.
- **testBuyTokensWithCHZ**: Prueba la compra de tokens con CHZ nativo, verificando la conversión a USDC y la transferencia de tokens.
- **testCompararComprasConMismoValor**: Compara la compra de tokens con CHZ y con USDC por el mismo valor, asegurando que los resultados sean similares.

### Tests de Funcionalidades de Emergencia y Finalización

- **testPauseContract**: Verifica que el contrato pueda ser pausado y reanudado correctamente.
- **testEmergencyWithdrawTokens**: Prueba la funcionalidad de retiro de emergencia de tokens.
- **testHardCapReached**: Verifica que la preventa finalice cuando se alcanza el límite máximo de recaudación.
- **testPresaleEndTime**: Comprueba que la preventa finalice cuando se alcanza el tiempo límite.
- **testRecoverUnsoldTokens**: Verifica la recuperación de tokens no vendidos después de finalizar la preventa.
- **testRecoverERC20**: Prueba la recuperación de tokens ERC20 enviados al contrato.




