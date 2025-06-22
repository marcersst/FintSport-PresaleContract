# FintSportContract

## Descripción

Este es un proyecto de contratos inteligentes para la plataforma **FintSport**, una innovadora plataforma que combina la pasión por el deporte con la tecnología blockchain. FintSport permite a los fanáticos ser parte del viaje de los atletas ofreciendo nuevas formas de conectarse con sus jugadores y equipos favoritos a través de tokens digitales.

El proyecto incluye contratos de preventa para dos tipos de tokens:
- **PTK (Player Tokens)**: Tokens utilitarios ERC1155 vinculados al rendimiento de jugadores específicos
- **FTK (FintSport Token)**: Token comodín ERC20 que proporciona acceso temprano y derechos exclusivos

El proyecto opera en Chiliz Chain, respaldado por una alianza estratégica con Chiliz y Socios.com.

## Características Principales

### Ecosistema FintSport
- **Player Tokens (PTK)**: Tokens ERC1155 con suministro fijo vinculados al rendimiento de jugadores
- **FintSport Token (FTK)**: Token ERC20 de acceso temprano con descuentos exclusivos para PTK
- **Mecanismo de Quema**: Los PTK se queman al canjear recompensas exclusivas, reduciendo el suministro circulante
- **Recompensas Exclusivas**: Entradas VIP, camisetas, experiencias con jugadores y otros premios atractivos

### Funcionalidades Técnicas
- **Contratos de Preventa**: Permiten comprar tokens con USDC, USDT o CHZ nativo
- **Integración con Kayen Router**: Para realizar swaps de CHZ a stablecoins
- **Mecanismos de Seguridad**: Protección contra reentrancia y capacidad de pausar contratos
- **Gestión de Tesorería**: Fondos recaudados se envían a wallet de tesorería configurable
- **Recuperación de Tokens**: Funcionalidad para recuperar tokens no vendidos

## Contratos del Proyecto

### 1. Contrato PTK (PTK.sol)
Token ERC1155 que representa a jugadores individuales:
- **Suministro Fijo**: Cada PTK tiene un suministro limitado y predefinido
- **Vinculación al Rendimiento**: Los tokens están vinculados a datos personales y rendimiento de jugadores
- **Mecanismo de Quema**: Los PTK se queman al canjear recompensas, creando escasez
- **Roles y Permisos**: Sistema de roles para administradores, minters y quemadores
- **Pausable y Actualizable**: Capacidad de pausar y actualizar el contrato

### 2. Contrato PTKSale (PTKSale.sol)
Contrato de venta para tokens PTK:
- **Múltiples Métodos de Pago**: Acepta USDC, USDT, CHZ y FTK
- **Precios Configurables**: Precios ajustables por el administrador
- **Integración con Router**: Utiliza Kayen Router para conversiones de CHZ
- **Límites de Compra**: Control sobre cantidades mínimas y máximas

### 3. Contrato PresaleContract (PresaleContract.sol)
Contrato de preventa general que implementa un mecanismo de preventa de tokens con las siguientes características:

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

## Contexto de FintSport

FintSport es una plataforma innovadora respaldada por **Chiliz** y **Socios.com**, con acceso a más de 3 millones de usuarios. La plataforma democratiza el acceso al mundo del fútbol, permitiendo a los fanáticos participar activamente en el éxito de sus jugadores y equipos favoritos.

### Características del Ecosistema:
- **Acceso Múltiple**: Los usuarios pueden adquirir tokens usando fiat (transferencias bancarias, tarjetas de crédito) y criptomonedas (CHZ)
- **Experiencias Exclusivas**: Los PTK acumulan puntos canjeables por entradas VIP, camisetas, experiencias con jugadores
- **Transparencia Total**: Contratos auditados con direcciones y hashes de auditoría embebidos
- **Cumplimiento Regulatorio**: Medidas de seguridad estrictas y políticas transparentes

### Tokenomics:
- **PTK**: Tokens utilitarios exclusivos, no representan acciones ni participación en ganancias
- **FTK**: Token de acceso temprano con descuentos exclusivos para PTK
- **Emisión Escalonada**: Incentiva la participación y lealtad del usuario
- **Reducción de Suministro**: Mecanismo de quema al canjear recompensas

## Resumen de los Tests

Los archivos de test contienen pruebas exhaustivas que verifican todas las funcionalidades de los contratos:

### Tests de PresaleContract (PresaleContractTest.t.sol)

#### Tests de Compra de Tokens
- **testBuyTokens**: Verifica la compra de tokens con USDC, asegurando que los balances se actualicen correctamente
- **testBuyTokensWithCHZ**: Prueba la compra de tokens con CHZ nativo, verificando la conversión a USDC y la transferencia de tokens
- **testCompararComprasConMismoValor**: Compara la compra de tokens con CHZ y con USDC por el mismo valor, asegurando que los resultados sean similares

#### Tests de Funcionalidades de Emergencia y Finalización
- **testPauseContract**: Verifica que el contrato pueda ser pausado y reanudado correctamente
- **testEmergencyWithdrawTokens**: Prueba la funcionalidad de retiro de emergencia de tokens
- **testHardCapReached**: Verifica que la preventa finalice cuando se alcanza el límite máximo de recaudación
- **testPresaleEndTime**: Comprueba que la preventa finalice cuando se alcanza el tiempo límite
- **testRecoverUnsoldTokens**: Verifica la recuperación de tokens no vendidos después de finalizar la preventa
- **testRecoverERC20**: Prueba la recuperación de tokens ERC20 enviados al contrato

### Tests de PTKSale (PTKSaleTest.t.sol)

#### Tests de Funcionalidades de Compra
- **Compra con Stablecoins**: Verificación de compras con USDC y USDT
- **Compra con CHZ**: Pruebas de conversión de CHZ a stablecoins mediante Kayen Router
- **Compra con FTK**: Tests de compra utilizando FintSport Token como método de pago
- **Cálculos de Precios**: Verificación de cálculos correctos para diferentes métodos de pago

#### Tests de Administración y Seguridad
- **Gestión de Precios**: Tests de configuración de precios para diferentes tokens
- **Funciones de Pausa**: Verificación de capacidades de pausa y reanudación
- **Recuperación de Tokens**: Tests de retiro de tokens PTK no vendidos
- **Funciones de Emergencia**: Pruebas de funcionalidades de emergencia y recuperación

## Tecnologías Utilizadas

- **Foundry**: Framework de desarrollo para Ethereum
- **Solidity**: Lenguaje de programación para contratos inteligentes
- **OpenZeppelin**: Biblioteca de contratos seguros y auditados
- **Chiliz Chain**: Blockchain especializada en deportes y entretenimiento
- **ERC1155**: Estándar para tokens multi-token (PTK)
- **ERC20**: Estándar para tokens fungibles (FTK)




