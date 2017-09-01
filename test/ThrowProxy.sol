pragma solidity ^0.4.13;
import "truffle/Assert.sol";

/*
source: http://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests
*/

// Proxy contract for testing throws
contract ThrowProxy {
  address public target;
  bytes data;
  uint value;
  
  function ThrowProxy(address _target) {
    target = _target;
  }    

  //prime the data using the fallback function.
  function() payable {
    data = msg.data;
    value = msg.value;
  }

  function execute() returns (bool) {
    if(value > 0){
      return target.call.value(value)(data);
    }
    else {
      return target.call(data);
    }
  }
}

// Contract you're testing
contract Thrower {
  function doThrow() {
    assert(false);
  }

  function doNoThrow() {
  }
}

// Solidity test contract, meant to test Thrower
contract TestThrower {
  function testThrow() {
    Thrower thrower = new Thrower();
    ThrowProxy throwProxy = new ThrowProxy(address(thrower)); //set Thrower as the contract to forward requests to. The target.

    //prime the proxy.
    Thrower(address(throwProxy)).doThrow();
    //execute the call that is supposed to throw.
    //r will be false if it threw. r will be true if it didn't.
    //make sure you send enough gas for your contract method.
    bool r = throwProxy.execute.gas(200000)();

    Assert.isFalse(r, "Should be false, as it should throw");
  }
}
