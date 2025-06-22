// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/// @title FintSport contract
/// @notice This contract is an ERC1155 token with pausable and burnable functionalities.
/// @dev This contract uses OpenZeppelin's upgradeable contracts.
contract PTK is
    AccessControlEnumerableUpgradeable,
    ERC1155PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Updates the state of the contract when tokens are transferred.
     * @dev Updates the state of the contract when tokens are transferred.
     * @param from The address of the sender.
     * @param to The address of the receiver.
     * @param ids The IDs of the tokens being transferred.
     * @param values The amounts of tokens being transferred.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        ERC1155PausableUpgradeable._update(from, to, ids, values);
    }

    /**
     * @notice ContractUri
     * @dev ContractUri
     */
    string public contractUri;

    /**
     * @notice Minter role
     * @dev Minter role
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    event ContractURIUpdated(string indexed contractUri);

    event Initialized(address admin, address minter, string uri);

    /**
     * @notice Initializes the contract with admin and minter roles and sets the initial URI.
     * @dev This function can only be called once.
     * @param admin The address to be granted the admin role.
     * @param minter The address to be granted the minter role.
     * @param uri The initial URI for the token metadata.
     */
    function initialize(address admin, address minter, string memory uri) public initializer {
        require(admin != address(0), "PTK: admin is 0");
        require(minter != address(0), "PTK: minter is 0");
        super._grantRole(DEFAULT_ADMIN_ROLE, admin);
        super._grantRole(MINTER_ROLE, admin);
        super._grantRole(BURN_ROLE, admin);
        super._grantRole(MINTER_ROLE, minter);
        __ERC1155_init(uri);
        __UUPSUpgradeable_init();
        __ERC1155Pausable_init();
        __ERC1155Burnable_init();
        __ReentrancyGuard_init();
        emit Initialized(admin, minter, uri);
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @dev This function uses the ERC165 standard.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return True if the contract supports the given interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return ERC1155Upgradeable.supportsInterface(interfaceId)
            || AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the contract URI.
     * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
     * @param _contractUri The new contract URI.
     */
    function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = _contractUri;
        emit ContractURIUpdated(contractUri);
    }

    /**
     * @notice Returns the contract URI.
     * @dev This function is used for OpenSea integration.
     * @return The contract URI.
     */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Authorizes an upgrade to a new implementation.
     * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice Pauses all token transfers.
     * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    /**
     * @notice Unpauses all token transfers.
     * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    /**
     * @notice Mints a new token.
     * @dev Only callable by an account with the MINTER_ROLE.
     * @param account The address to receive the minted token.
     * @param id The token ID.
     * @param amount The amount of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
        nonReentrant
    {
        super._mint(account, id, amount, data);
    }

    /**
     * @notice Mints a batch of new tokens.
     * @dev Only callable by an account with the MINTER_ROLE.
     * @param to The address to receive the minted tokens.
     * @param ids An array of token IDs.
     * @param values An array of amounts of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
        nonReentrant
    {
        super._mintBatch(to, ids, values, data);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     * @notice Transfers a token from one address to another.
     * @param from The address of the sender.
     * @param to The address of the receiver.
     * @param id The ID of the token being transferred.
     * @param value The amount of tokens being transferred.
     * @param data Additional data with no specified format.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        nonReentrant
    {
        super.safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * @notice Transfers a batch of tokens from one address to another.
     * @param from The address of the sender.
     * @param to The address of the receiver.
     * @param ids An array of token IDs.
     * @param values An array of amounts of tokens being transferred.
     * @param data Additional data with no specified format.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override nonReentrant {
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @notice Burns a token.
     * @dev Only callable by an account with the BURN_ROLE.
     * @param account The address of the token holder.
     * @param id The token ID.
     * @param value The amount of tokens to burn.
     */
    function burn(address account, uint256 id, uint256 value)
        public
        virtual
        override
        onlyRole(BURN_ROLE)
        nonReentrant
    {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burn(account, id, value);
    }

    /**
     * @notice Burns a batch of tokens.
     * @dev Only callable by an account with the BURN_ROLE.
     * @param account The address of the token holder.
     * @param ids An array of token IDs.
     * @param values An array of amounts of tokens to burn.
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values)
        public
        virtual
        override
        onlyRole(BURN_ROLE)
        nonReentrant
    {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burnBatch(account, ids, values);
    }
}
