// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
