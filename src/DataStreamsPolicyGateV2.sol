// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Fork-review policy gate. It consumes already-verified report fields.
/// The workflow does NOT claim a live signed report was retrieved unless authenticated
/// Chainlink Data Streams credentials/report evidence are separately supplied.
contract DataStreamsPolicyGateV2 {
    bytes32 public constant ETH_USD_FEED_ID =
        0x000362205e10b3a147d02792eccee483dca6c7b44ecce7012cb8c6e0b68b3ae9;

    uint256 public constant MAX_TRADE_USD18 = 5e18;
    uint256 public constant MAX_REPORT_AGE = 120 seconds;

    error WrongFeed();
    error ReportNotVerified();
    error StaleReport();
    error FutureReport();
    error TradeLimitExceeded();

    struct VerifiedPrice {
        bytes32 feedId;
        uint256 priceUsd18;
        uint64 validFromTimestamp;
        uint64 observationsTimestamp;
        bool verified;
    }

    function validateTrade(
        VerifiedPrice calldata report,
        uint256 tradeUsd18
    ) external view returns (bool) {
        if (!report.verified) revert ReportNotVerified();
        if (report.feedId != ETH_USD_FEED_ID) revert WrongFeed();
        if (report.observationsTimestamp > block.timestamp) revert FutureReport();

        uint256 age = block.timestamp - report.observationsTimestamp;
        if (age > MAX_REPORT_AGE) revert StaleReport();
        if (tradeUsd18 > MAX_TRADE_USD18) revert TradeLimitExceeded();
        return true;
    }
}
