// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

import {DSTest} from "ds-test/test.sol";

import {ForwardProxy} from "./ForwardProxy.sol";

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

contract ForwardProxyTest is DSTest {
    ForwardProxy proxy;
    Target target;

    function setUp() public {
        proxy = new ForwardProxy();
        target = new Target();
    }

    function testProxySetToReturnsOwnAddress() public {
        address result = proxy._(address(target));

        assertEq(result, address(proxy));
    }

    function testProxyForwardsCall() public {
        address result = Target(address(proxy._(address(target)))).funcA();

        assertEq(result, address(proxy));
    }

    function testProxyForwardsViewCall() public {
        address result = Target(address(proxy._(address(target)))).funcB();

        assertEq(result, address(proxy));
    }

    function testProxyForwardsCallParameters() public {
        bytes32 data = keccak256(abi.encodePacked("foo", "bar"));
        bytes32 result = Target(address(proxy._(address(target)))).funcC(data);

        assertEq(result, data);
    }

    function testProxyForwardsSentEtherToTarget() public {
        PayableTarget payableTarget = new PayableTarget();
        (address sender, uint256 value) = PayableTarget(proxy._(address(payableTarget))).funcA{value: 20 ether}();

        assertEq(sender, address(proxy));
        assertEq(value, 20 ether);
        assertEq(address(payableTarget).balance, 20 ether);
    }

    function testFailSendEtherToProxy() public {
        payable(proxy).transfer(1 ether);
    }
}
