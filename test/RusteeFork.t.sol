// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface Vm {
    function deal(address who, uint256 newBalance) external;
    function startPrank(address msgSender) external;
    function stopPrank() external;
    function envUint(string calldata name) external returns (uint256);
    function writeFile(string calldata path, string calldata data) external;
    function toString(uint256 value) external pure returns (string memory);
}

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

interface IQuoterV2 {
    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

interface ISwapRouter02 {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

contract RusteeForkTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address constant TBA = 0x522f5637f2c556aad9b2245f3b8e6bf4dfd9a654;
    address constant WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;
    address constant NVDA = 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC;
    address constant ROUTER = 0xCaf681a66D020601342297493863E78C959E5cb2;
    address constant QUOTER = 0x33e885ed0ec9bf04ecfb19341582aadcb4c8a9e7;

    function testForkedFundedClassicRoute() public {
        uint256 target = vm.envUint("TARGET_NVDA_WEI");

        (uint256 in500,, ,) = IQuoterV2(QUOTER).quoteExactOutputSingle(
            IQuoterV2.QuoteExactOutputSingleParams(WETH,NVDA,target,500,0)
        );
        (uint256 in3000,, ,) = IQuoterV2(QUOTER).quoteExactOutputSingle(
            IQuoterV2.QuoteExactOutputSingleParams(WETH,NVDA,target,3000,0)
        );

        uint24 fee = in500 <= in3000 ? 500 : 3000;
        uint256 quoted = in500 <= in3000 ? in500 : in3000;
        uint256 maxIn = (quoted * 1005 + 999) / 1000;

        vm.deal(TBA, maxIn + 0.01 ether);
        vm.startPrank(TBA);
        IWETH(WETH).deposit{value:maxIn}();
        require(IWETH(WETH).approve(ROUTER,maxIn), "approve failed");

        uint256 beforeNvda = IERC20(NVDA).balanceOf(TBA);

        uint256 used = ISwapRouter02(ROUTER).exactOutputSingle(
            ISwapRouter02.ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: NVDA,
                fee: fee,
                recipient: TBA,
                amountOut: target,
                amountInMaximum: maxIn,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 afterNvda = IERC20(NVDA).balanceOf(TBA);
        vm.stopPrank();

        require(afterNvda >= beforeNvda + target, "NVDA output missing");
        require(used <= maxIn, "WETH max exceeded");

        string memory j = string.concat(
            '{"ok":true,"chainId":4663,"simulatedFunding":true,"simulatedApproval":true,',
            '"routerExecutionSucceeded":true,',
            '"bestFeeBps":', vm.toString(uint256(fee)), ',',
            '"quotedWethInWei":"', vm.toString(quoted), '",',
            '"maxWethInWei":"', vm.toString(maxIn), '",',
            '"wethActuallyUsedWei":"', vm.toString(used), '",',
            '"targetNvdaWei":"', vm.toString(target), '",',
            '"nvdaReceivedWei":"', vm.toString(afterNvda-beforeNvda), '",',
            '"nvdaReceived":"', _fmt18(afterNvda-beforeNvda), '"}'
        );
        vm.writeFile("data/fork-simulation.json", j);
    }

    function _fmt18(uint256 x) internal pure returns (string memory) {
        uint256 whole=x/1e18;
        uint256 frac=x%1e18;
        return string.concat(_utoa(whole),".",_pad18(frac));
    }

    function _utoa(uint256 v) internal pure returns (string memory) {
        if (v==0) return "0";
        uint256 n=v; uint256 len;
        while(n!=0){len++;n/=10;}
        bytes memory b=new bytes(len);
        while(v!=0){len--;b[len]=bytes1(uint8(48+v%10));v/=10;}
        return string(b);
    }

    function _pad18(uint256 v) internal pure returns (string memory) {
        bytes memory b=new bytes(18);
        for(uint256 i=18;i>0;i--){b[i-1]=bytes1(uint8(48+v%10));v/=10;}
        return string(b);
    }
}
