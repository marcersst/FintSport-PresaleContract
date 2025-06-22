// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPTK Interface
 * @dev Interface for the PTK ERC1155 token contract.
 * Includes standard ERC1155 functions and common PTK-specific functions.
 */
interface IPTK {
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

   
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    
}
