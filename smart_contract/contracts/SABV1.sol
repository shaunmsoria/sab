// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract SABV1 is IFlashLoanRecipient {
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        // ensure it's the owner of the smart contract who can call it
        require(msg.sender == owner, "your are not the owner");
        _;
    }

    modifier onlyVault(){
        // ensure it's only the vault that can call this function
        require(msg.sender == address(vault), "your are not the vault");
        _;
    }

    function getString() public pure returns (string memory) {
        return "Hello World";
    }

    function executeTrade(
        address _token0,
        address _token1,
        IUniswapV2Router02 _router0,
        IUniswapV2Router02 _router1,
        uint256 _flashAmount
    ) external {
    // ) external onlyOwner {
        // encode data about the transaction including tokens, and routers to be used in the receivedFlashLoan
        bytes memory data = abi.encode(owner, _token0, _token1, _router0, _router1);

        // token to be flash loaned, only one for now
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_token0);

        // flash loaned amount
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount;

        // request the flash loan from balancer
        vault.flashLoan(this, tokens, amounts, data);
    }


    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override onlyVault {
        (
            address _ownerData, 
            address token0, 
            address token1, 
            IUniswapV2Router02 router0, 
            IUniswapV2Router02 router1
        ) = abi.decode(
            userData,
            (address, address, address, IUniswapV2Router02, IUniswapV2Router02)
        );

        // ensure data from balancer is for this contract
        require(_ownerData == owner, "this data isn't from the owner");

        // store flosh loan amount
        uint256 flashAmount = amounts[0];

        // router paths
        IUniswapV2Router02[] memory routerPath = new IUniswapV2Router02[](2);

        routerPath[0] = router0;
        routerPath[1] = router1;

        // token paths
        address[] memory tokenPath = new address[](2);

        tokenPath[0] = token0;
        tokenPath[1] = token1;

        _executeSwap(routerPath, tokenPath, flashAmount);

        IERC20(token0).transfer(address(vault), flashAmount);

        IERC20(token0).transfer(owner, IERC20(token0).balanceOf(address(this)));

    }

    function _executeSwap(
        IUniswapV2Router02[] memory _routerPath,
        address[] memory _tokenPath,
        uint256 _flashAmount
    ) internal {
        IUniswapV2Router02 _startRouter = _routerPath[0];
        // uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(address(this));

        require(
            IERC20(_tokenPath[0]).approve(address(_startRouter), _flashAmount),
            "start router  approval failed"
        );

        _startRouter.swapExactTokensForTokens(
            _flashAmount,
            0,
            _tokenPath,
            address(this),
            (block.timestamp + 1200)
        );

        IUniswapV2Router02 _endRouter = _routerPath[1];
        uint256 _endAmountIn = IERC20(_tokenPath[1]).balanceOf(address(this));

        require(
            IERC20(_tokenPath[1]).approve(address(_endRouter), _endAmountIn)
        );

        address token0 = _tokenPath[0];
        address token1 = _tokenPath[1];

        _tokenPath[0] = token1;
        _tokenPath[1] = token0;

        _endRouter.swapExactTokensForTokens(
            _endAmountIn,
            _flashAmount,
            _tokenPath,
            address(this),
            (block.timestamp + 1200)
        );
    }


}