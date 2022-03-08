// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

interface ForwardProxyLike {
    /**
     * @notice Returns the address which calls to this contract must be forwarded to.
     * @return to The address of the target contract.
     */
    function __to() external view returns (address payable to);

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
    function _(address to) external returns (address payable);

    /**
     * @dev This function does not return to its internall call site, it will return directly to the external caller.
     */
    fallback() external payable;

    /**
     * @dev This function handles plain ether transfers to this contract.
     */
    receive() external payable;
}
