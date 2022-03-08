// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

import {DSTest} from "ds-test/test.sol";

import {ForwardProxy} from "./ForwardProxy.sol";
import {AuthForwardProxy} from "./AuthForwardProxy.sol";

contract Target {
    event A(address who);
    event B(address who);

    function funcA() public returns (address) {
        emit A(msg.sender);
        return msg.sender;
    }

    function funcB() public view returns (address) {
        return msg.sender;
    }

    function funcC(bytes32 params) public pure returns (bytes32) {
        return params;
    }
}

contract PayableTarget {
    event A(address who, uint256 wad);

    function funcA() public payable returns (address, uint256) {
        emit A(msg.sender, msg.value);
        return (msg.sender, msg.value);
    }

    receive() external payable {}
}

contract AuthForwardProxyTest is DSTest {
    AuthForwardProxy proxy;
    ForwardProxy ward;
    ForwardProxy notWard;
    Target target;

    function setUp() public {
        proxy = new AuthForwardProxy();
        ward = new ForwardProxy();
        notWard = new ForwardProxy();
        target = new Target();

        proxy.rely_65fae35e(address(ward));
    }

    function testProxyForwardsCallFromOwner() public {
        address result = Target(address(proxy._(address(target)))).funcA();

        assertEq(result, address(proxy));
    }

    function testProxyForwardsViewCallFromOwner() public {
        address result = Target(address(proxy._(address(target)))).funcB();

        assertEq(result, address(proxy));
    }

    function testProxyForwardsCallParametersFromOwner() public {
        bytes32 data = keccak256(abi.encodePacked("foo", "bar"));
        bytes32 result = Target(address(proxy._(address(target)))).funcC(data);

        assertEq(result, data);
    }

    function testProxyForwardsSentEtherToTargetFromOnwer() public {
        PayableTarget payableTarget = new PayableTarget();
        (address sender, uint256 value) = PayableTarget(proxy._(address(payableTarget))).funcA{value: 20 ether}();

        assertEq(sender, address(proxy));
        assertEq(value, 20 ether);
        assertEq(address(payableTarget).balance, 20 ether);
    }

    function testFailSendEtherToProxyFromOwner() public {
        payable(proxy).transfer(1 ether);
    }

    function testProxyForwardsCallFromWard() public {
        address result = Target(ward._(proxy._(address(target)))).funcA();

        assertEq(result, address(proxy));
    }

    function testFailProxyCannotForwardCallFromNonWard() public {
        address result = Target(notWard._(proxy._(address(target)))).funcA();
    }

    function testProxyForwardsCallParametersFromWard() public {
        bytes32 data = keccak256(abi.encodePacked("foo", "bar"));
        bytes32 result = Target(ward._(proxy._(address(target)))).funcC(data);

        assertEq(result, data);
    }

    function testFailProxyCannotForwardCallParametersFromNonWard() public {
        bytes32 data = keccak256(abi.encodePacked("foo", "bar"));
        Target(address(notWard._(proxy._(address(target))))).funcC(data);
    }

    function testProxyForwardsSentEtherToTargetFromWard() public {
        PayableTarget payableTarget = new PayableTarget();
        (address sender, uint256 value) = PayableTarget(ward._(proxy._(address(payableTarget)))).funcA{
            value: 20 ether
        }();

        assertEq(sender, address(proxy));
        assertEq(value, 20 ether);
        assertEq(address(payableTarget).balance, 20 ether);
    }

    function testFailProxyCannotForwardSentEtherToTargetFromNonWard() public {
        PayableTarget payableTarget = new PayableTarget();
        PayableTarget(notWard._(proxy._(address(payableTarget)))).funcA{value: 20 ether}();
    }
}
