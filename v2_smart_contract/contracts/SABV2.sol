// SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.4;
pragma solidity 0.8.28;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
// import "https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IVault.sol";


import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
// import "https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IFlashLoanRecipient.sol";


import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";


import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";


contract SABV2 is IFlashLoanRecipient {
    IVault private constant vault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address public owner;
    // Add this event to track execution
    event FlashLoanReceived(address token, uint256 amount, uint256 fee);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyVault() {
        require(msg.sender == address(vault), "your are not the vault");
        _;
    }

    receive() external payable {}

    function testSimpleFlashLoan(address token, uint256 amount) external {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // Simplified data with minimal processing
        bytes memory data = abi.encode(
            owner,
            token,
            token,
            address(0),
            "",
            uint24(0),
            address(0),
            "",
            uint24(0)
        );

        vault.flashLoan(this, tokens, amounts, data);
    }

  

    function executeTrade(
        address _token0,
        address _token1,
        address _router0,
        string calldata _router0_abi,
        uint24 _pool0_fee,
        address _router1,
        string calldata _router1_abi,
        uint24 _pool1_fee,
        uint256 _flashAmount
    ) external {
        bytes memory data = abi.encode(
            owner,
            _token0,
            _token1,
            _router0,
            _router0_abi,
            _pool0_fee,
            _router1,
            _router1_abi,
            _pool1_fee
        );

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_token0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount;



        vault.flashLoan(this, tokens, amounts, data);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override onlyVault {
        emit FlashLoanReceived(address(tokens[0]), amounts[0], feeAmounts[0]);

        (
            address _ownerData,
            address token0,
            address token1,
            address router0,
            string memory router0_abi,
            uint24 pool0_fee,
            address router1,
            string memory router1_abi,
            uint24 pool1_fee
        ) = abi.decode(
                userData,
                (address, address, address, address, string, uint24, address, string, uint24)
            );

        uint256 flashAmount = amounts[0];
        uint256 loanFee = feeAmounts[0];

        address[] memory routerPath = new address[](2);

        routerPath[0] = router0;
        routerPath[1] = router1;

        string[] memory abiPath = new string[](2);

        abiPath[0] = router0_abi;
        abiPath[1] = router1_abi;

        uint24[] memory feePath = new uint24[](2);

        feePath[0] = pool0_fee;
        feePath[1] = pool1_fee;

        address[] memory tokenPath = new address[](2);

        tokenPath[0] = token0;
        tokenPath[1] = token1;

        _executeSwap(routerPath, abiPath, feePath, tokenPath, flashAmount);

        IERC20 ierc20_token0 = IERC20(token0);

        // Replay flash loan + fee
        ierc20_token0.transfer(address(vault), flashAmount + loanFee);

        // Transfer remaining token0 to owner
        ierc20_token0.transfer(owner, ierc20_token0.balanceOf(address(this)));
    }

    function _executeSwap(
        address[] memory _routerPath,
        string[] memory _abiPath,
        uint24[] memory _feePath,
        address[] memory _tokenPath,
        uint256 _flashAmount
    ) internal {
        if (keccak256(abi.encodePacked(_abiPath[0])) == keccak256(abi.encodePacked("uniswapV2"))) {
            IUniswapV2Router02 _startRouter = IUniswapV2Router02(_routerPath[0]);
            uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(
                address(this)
            );

            require(
                IERC20(_tokenPath[0]).approve(
                    address(_startRouter),
                    _startAmountIn
                ),
                "start router approval failed"
            );

            _startRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _startAmountIn,
                0,
                _tokenPath,
                address(this),
                (block.timestamp + 1200)
            );
        } else if ( keccak256(abi.encodePacked(_abiPath[0])) == keccak256(abi.encodePacked("uniswapV3"))) {
            ISwapRouter _startRouter = ISwapRouter(_routerPath[0]);
            uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(
                address(this)
            );

            require(
                IERC20(_tokenPath[0]).approve(
                    address(_startRouter),
                    _startAmountIn
                ),
                "start router approval failed"
            );

            _startRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenPath[0],
                    tokenOut: _tokenPath[1],
                    fee: _feePath[0],
                    recipient: address(this),
                    deadline: (block.timestamp + 1200),
                    amountIn: _startAmountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }

        if (keccak256(abi.encodePacked(_abiPath[1])) == keccak256(abi.encodePacked("uniswapV2"))) {
            IUniswapV2Router02 _endRouter = IUniswapV2Router02(_routerPath[1]);
            uint256 _endAmountIn = IERC20(_tokenPath[1]).balanceOf(
                address(this)
            );

            require(
                IERC20(_tokenPath[1]).approve(
                    address(_endRouter),
                    _endAmountIn
                ),
                "end router approval failed"
            );

            address token0 = _tokenPath[0];
            address token1 = _tokenPath[1];

            _tokenPath[0] = token1;
            _tokenPath[1] = token0;

            _endRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _endAmountIn,
                _flashAmount,
                _tokenPath,
                address(this),
                (block.timestamp + 1200)
            );
        } else if (keccak256(abi.encodePacked(_abiPath[1])) == keccak256(abi.encodePacked("uniswapV3"))) {
            ISwapRouter _endRouter = ISwapRouter(_routerPath[1]);
            uint256 _endAmountIn = IERC20(_tokenPath[1]).balanceOf(
                address(this)
            );

            require(
                IERC20(_tokenPath[1]).approve(
                    address(_endRouter),
                    _endAmountIn
                ),
                "end router approval failed"
            );

            // Calculate minimum required with 5% slippage tolerance
            // uint256 minAmountOut = (_flashAmount * 95) / 100;

            _endRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenPath[1],
                    tokenOut: _tokenPath[0],
                    fee: _feePath[1],
                    recipient: address(this),
                    deadline: (block.timestamp + 300),
                    amountIn: _endAmountIn,
                    // amountOutMinimum: minAmountOut,
                    amountOutMinimum: _flashAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
}
