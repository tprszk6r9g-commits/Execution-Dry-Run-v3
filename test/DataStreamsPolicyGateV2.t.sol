// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../src/DataStreamsPolicyGateV2.sol";

interface VmPolicy {
    function warp(uint256) external;
    function expectRevert(bytes4) external;
}

contract DataStreamsPolicyGateV2Test {
    VmPolicy constant vm =
        VmPolicy(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes32 constant FEED =
        0x000362205e10b3a147d02792eccee483dca6c7b44ecce7012cb8c6e0b68b3ae9;

    function fresh(bool verified) internal view
        returns (DataStreamsPolicyGateV2.VerifiedPrice memory r)
    {
        r = DataStreamsPolicyGateV2.VerifiedPrice({
            feedId: FEED,
            priceUsd18: 3_500e18,
            validFromTimestamp: uint64(block.timestamp - 10),
            observationsTimestamp: uint64(block.timestamp - 5),
            verified: verified
        });
    }

    function testFreshVerifiedFiveDollarTradePasses() public {
        vm.warp(2_000_000_000);
        DataStreamsPolicyGateV2 g = new DataStreamsPolicyGateV2();
        DataStreamsPolicyGateV2.VerifiedPrice memory r = fresh(true);
        require(g.validateTrade(r, 5e18), "expected pass");
    }

    function testOverFiveDollarsRejected() public {
        vm.warp(2_000_000_000);
        DataStreamsPolicyGateV2 g = new DataStreamsPolicyGateV2();
        DataStreamsPolicyGateV2.VerifiedPrice memory r = fresh(true);
        vm.expectRevert(DataStreamsPolicyGateV2.TradeLimitExceeded.selector);
        g.validateTrade(r, 5e18 + 1);
    }

    function testUnverifiedReportRejected() public {
        vm.warp(2_000_000_000);
        DataStreamsPolicyGateV2 g = new DataStreamsPolicyGateV2();
        DataStreamsPolicyGateV2.VerifiedPrice memory r = fresh(false);
        vm.expectRevert(DataStreamsPolicyGateV2.ReportNotVerified.selector);
        g.validateTrade(r, 1e18);
    }

    function testStaleReportRejected() public {
        vm.warp(2_000_000_000);
        DataStreamsPolicyGateV2 g = new DataStreamsPolicyGateV2();
        DataStreamsPolicyGateV2.VerifiedPrice memory r = fresh(true);
        r.observationsTimestamp = uint64(block.timestamp - 121);
        vm.expectRevert(DataStreamsPolicyGateV2.StaleReport.selector);
        g.validateTrade(r, 1e18);
    }

    function testWrongFeedRejected() public {
        vm.warp(2_000_000_000);
        DataStreamsPolicyGateV2 g = new DataStreamsPolicyGateV2();
        DataStreamsPolicyGateV2.VerifiedPrice memory r = fresh(true);
        r.feedId = bytes32(uint256(123));
        vm.expectRevert(DataStreamsPolicyGateV2.WrongFeed.selector);
        g.validateTrade(r, 1e18);
    }
}
