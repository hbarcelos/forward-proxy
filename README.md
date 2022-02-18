# Forward Proxy

## Motivation

The `ForwardProxy` is useful for permissioned smart contracts systems in environments where EOAs are not available
(i.e.: tests written with [`ds-test`][1]) and there is a need to emulate different actors interacting with components of
the system.

## How it works?

The `ForwardProxy` provides a fallback function that forwards all calls to another contract using the EVM instruction
`call`. The success and return data of the call will be returned back to the caller of the proxy.

Notice that this is different from OpenZeppelin's base [`Proxy`][2] contract, which uses `delegatecall` instead.

This largely alleviates the security issues that come with `delegatecall`, since the call to the target contract will be
made on its own context, but this code has not been audited and **I DO NOT** recommend using it in production.

As it currently stands, this contract could be seen as a bare-bones permissionless 1-out-of-∞ multisig that allows
interacting with smart contracts.

## API

```solidity
interface ForwardProxyLike {
    function __to() external view returns (address);
    function _() external returns (address);
}
```

- `__to()`: returns the address of the target contract.
- `_()`: updates the address of the target contract.

The methods have these peculiar names for 2 reasons:
1. Keep it short, reducing the noise when reading the code.
2. Minimize the chances of clashing names, which would prevent the proxy from working properly.

The setter method `_()` implements [method chaining][3] to make it more ergonomic:

Instead of:

```solidity
proxy._(target);
Target(proxy).targetMethod();
```

You can write:

```solidity
Target(proxy._(target)).targetMethod();
```

This is specially useful when the proxy needs to be used with multiple targets:

```solidity
TargetA(proxy._(targetA)).targetAMethod();
TargetB(proxy._(targetB)).targetBMethod();
```

## What about `payable` methods?

I'm glad you asked!

`ForwardProxy` also forwards any `ether` sent through it to the target.

```solidity
contract PayableTarget {
    event A(address who, uint256 wad);

    function funcA() public payable returns (address, uint256) {
        emit A(msg.sender, msg.value);
        return (msg.sender, msg.value);
    }

    receive() external payable {}
}

PayableTarget payableTarget = new PayableTarget();

(address sender, uint256 value) = PayableTarget(
    proxy._(address(payableTarget))
).funcA{value: 20 ether}();
```

However, it's **NOT** possible to make plain `ether` transfers to a `ForwardProxy`:

```solidity
payable(proxy).transfer(1 ether); // This will REVERT!
```


## Alright, show me the code!

```solidity
ForwardProxy usr1 = new ForwardProxy();
ForwardProxy usr2 = new ForwardProxy();

System system = new System(/* ... */);
system.authorize(address(usr1), 'role-A');
system.authorize(address(usr2), 'role-B');

// "Impersonate" a contract of type `System`
System(
    // Set the `system` contract as the target `to` and gets the reference to the proxy address.
    usr1._(address(system))
)
    // Call a method in the proxy which will be forwarded to the system
    .authorizedMethodA();

// Do the same for `usr2`:
System(usr2._(address(system))).authorizedMethodB();
```

The example above is roughly equivalent to the following using `ethers.js`:

```javascript
const usr1 = new ethers.Wallet('<private key 1>');
const usr2 = new ethers.Wallet('<private key 2>');

const system = new ethers.Contract('<address>', '<abi>');

const tx1 = await system.authorize(address(usr1), 'role-A');
await tx1.wait()
const tx2 = await system.authorize(address(usr2), 'role-B');
await tx2.wait()

system.connect(usr1);
const tx3 = await system.authorizedMethodA();
await tx3.wait();

system.connect(usr2);
const tx4 = await system.authorizedMethodB();
await tx4.wait();
```

  [1]: https://github.com/dapphub/ds-test
  [2]: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
  [3]: https://en.wikipedia.org/wiki/Method_chaining
