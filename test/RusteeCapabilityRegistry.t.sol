// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../src/RusteeCapabilityRegistry.sol";
contract RegistryTest is Test {
 RusteeCapabilityRegistry r; address o=address(0xA11CE); address e=address(0xB0B);
 address nft=address(0x1001); address tba=address(0x2002);
 function setUp() public {r=new RusteeCapabilityRegistry(o);vm.prank(o);r.setExecutor(e,true);}
 function cap(uint256 n,uint32 u) internal view returns(RusteeCapabilityRegistry.Capability memory c){
  c=RusteeCapabilityRegistry.Capability(nft,1,tba,1,keccak256("NVDA"),3,5e18,10e18,1,50,
  uint64(block.timestamp),uint64(block.timestamp+1 hours),n,u,0,e,false);
 }
 function testOneTime() public {vm.prank(o);bytes32 id=r.issue(cap(1,1));vm.prank(e);r.consume(id,keccak256("BUY"),nft,1,tba,1,block.chainid);assertFalse(r.isActive(id));}
 function testRevoke() public {vm.prank(o);bytes32 id=r.issue(cap(1,2));vm.prank(o);r.revoke(id);vm.prank(e);vm.expectRevert(RusteeCapabilityRegistry.CapabilityRevoked.selector);r.consume(id,keccak256("BUY"),nft,1,tba,1,block.chainid);}
 function testNonceFloor() public {vm.prank(o);bytes32 id=r.issue(cap(1,2));vm.prank(o);r.advanceNonceFloor(nft,1,2);assertFalse(r.isActive(id));}
 function testPause() public {vm.prank(o);bytes32 id=r.issue(cap(1,2));vm.prank(o);r.setPaused(true);vm.prank(e);vm.expectRevert(RusteeCapabilityRegistry.Paused.selector);r.consume(id,keccak256("BUY"),nft,1,tba,1,block.chainid);}
 function testWrongGeneration() public {vm.prank(o);bytes32 id=r.issue(cap(1,2));vm.prank(e);vm.expectRevert(RusteeCapabilityRegistry.WrongGeneration.selector);r.consume(id,keccak256("BUY"),nft,1,tba,2,block.chainid);}
 function testFuzzUseCap(uint8 u) public {vm.assume(u>0);vm.prank(o);bytes32 id=r.issue(cap(1,u));for(uint i;i<u;i++){vm.prank(e);r.consume(id,keccak256(abi.encode(i)),nft,1,tba,1,block.chainid);}vm.prank(e);vm.expectRevert(RusteeCapabilityRegistry.CapabilityExhausted.selector);r.consume(id,keccak256("x"),nft,1,tba,1,block.chainid);}
}
