// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

import {ForwardProxy} from "./ForwardProxy.sol";

/**
 * @author Henrique Barcelos <henrique@clio.finance>
 * @title AuthForwardProxy
 * @notice This contract is a permissioned version of `ForwardProxy`.
 * @dev The main use case for this contract is to set it as the owner of contracts whose permissioned methods should not
 * be made completely permissionless by using `ForwardProxy`.
 * `AuthForwardProxy` can be thought of as a 1-out-of-N multisig to interact with other smart contracts.
 * Each address allowed into `AuthForwarProxy` is a `ward.` Once an address receives a `ward` status, it can add or
 * remove other wards, but it cannot modify the `owner`. The `owner` has root access to the contract.
 */
contract AuthForwardProxy is ForwardProxy {
    /// @dev Uses an arbitrary storage slot to store the owner.
    bytes32 internal constant OWNER_SLOT = keccak256(abi.encode("dev.henriquebarcelos.authforwardproxy.owner"));

    /// @dev Uses an arbitrary storage slot to store the wards mapping.
    bytes32 internal constant WARDS_SLOT = keccak256(abi.encode("dev.henriquebarcelos.authforwardproxy.wards"));

    modifier owner() {
        require(getOwner() == msg.sender, "AuthForwardProxy/not-owner");
        _;
    }

    modifier auth() {
        require(getOwner() == msg.sender || getWard(msg.sender) == 1, "AuthForwardProxy/not-allowed");
        _;
    }

    /**
     * @dev The `owner` of the contract is set to `msg.sender`
     */
    constructor() public {
        setOwner(msg.sender);
    }

    /**
     * @notice Updates the `to` address and returns the address this contract instance.
     * @dev This function is meant to be used for chaining calls like:
     *
     * ```solidity
     * Target(proxy._(address(target))).targetFunction();
     * ```
     *
     * @param to The contract to which calls to this contract must be forwarded to.
     * @return The address of this contract instance.
     */
    function _(address to) public virtual override auth returns (address payable) {
        return super._(to);
    }

    /**
     * @dev This function does not return to its internall call site, it will return directly to the external caller.
     */
    fallback() external payable virtual override auth {
        super._fallback();
    }

    /**
     * @notice Gets the owner of the contract.
     * @return The owner address.
     */
    function owner_8da5cb5b() external view returns (address) {
        return getOwner();
    }

    /**
     * @notice Transfers the ownership of the contract to `who`.
     * @param who The new owner address.
     */
    function transferOwnership_f2fde38b(address who) external owner {
        return setOwner(who);
    }

    /**
     * @notice Allows `who` to call the target contract.
     * @dev Only the owner or a ward can call this function.
     * @param who The ward address.
     */
    function rely_65fae35e(address who) external auth {
        setWard(who, 1);
    }

    /**
     * @notice Disallows `who` to call the target contract.
     * @dev Only the owner or a ward can call this function.
     * @param who The ward address.
     */
    function deny_9c52a7f1(address who) external auth {
        setWard(who, 0);
    }

    /**
     * @notice Gets the ward status of `who`.
     * @param who The ward address.
     * @return `1` if the `who` is a ward or `0` otherwise.
     */
    function wards_bf353dbb(address who) external view returns (uint256) {
        return getWard(who);
    }

    /**
     * @dev Gets the owner address from storage.
     * @return The owner address.
     */
    function getOwner() internal view returns (address) {
        return address(bytes20(getStorageAt(OWNER_SLOT)));
    }

    /**
     * @dev Changes the onwer of the contract in storage.
     * @param who The new owner address.
     */
    function setOwner(address who) internal {
        setStorageAt(OWNER_SLOT, bytes20(who));
    }

    /**
     * @dev Gets the ward status of `who` from storage.
     * @param who The ward address.
     * @return `1` if the `who` is a ward or `0` otherwise.
     */
    function getWard(address who) internal view returns (uint256) {
        return uint256(getMappingStorageAt(bytes20(who), WARDS_SLOT));
    }

    /**
     * @dev Sets the ward status of `who` in storage.
     * @param who The ward address.
     */
    function setWard(address who, uint256 value) internal {
        setMappingStorageAt(bytes20(who), WARDS_SLOT, bytes32(value));
    }

    /**
     * @dev Gets the value in a specific storage slot.
     * @param s The slot number.
     */
    function getStorageAt(bytes32 s) internal view returns (bytes32 r) {
        assembly {
            r := sload(s)
        }
    }

    /**
     * @dev Updates the value in a specific storage slot.
     * @param s The slot number.
     * @param v The new value.
     */
    function setStorageAt(bytes32 s, bytes32 v) internal {
        assembly {
            sstore(s, v)
        }
    }

    /**
     * @dev Gets the value in a specific storage slot for a mapping.
     * @param i The mapping key.
     * @param s The slot number.
     */
    function getMappingStorageAt(bytes32 i, bytes32 s) internal view returns (bytes32 r) {
        assembly {
            // Store the position `i` in memory scratch space
            mstore(0, i)
            // Store the slot `s` in the scratch space after `i`
            mstore(32, s)
            // Calculate h(i . s) as per solidity storage layout rules
            let hash := keccak256(0, 64)
            // Load the mapping value using the hash
            r := sload(hash)
        }
    }

    /**
     * @dev Updates the value in a specific storage slot for a mapping.
     * @param i The mapping key.
     * @param s The slot number.
     * @param v The new value.
     */
    function setMappingStorageAt(
        bytes32 i,
        bytes32 s,
        bytes32 v
    ) internal {
        assembly {
            // Store the position `i` in memory scratch space
            mstore(0, i)
            // Store the slot `s` in the scratch space after `i`
            mstore(32, s)
            // Calculate h(i . s) as per solidity storage layout rules
            let hash := keccak256(0, 64)
            // Store the mapping value using the hash
            sstore(hash, v)
        }
    }
}
