// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;


import {IERC20 as OZ_IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Balancer interfaces (directly using what's needed)
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";


// Uniswap interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";




contract SABV2 is IFlashLoanRecipient {
    using SafeERC20 for OZ_IERC20;


    IVault private constant vault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address public owner;
    event swapReceipt(string uuid, uint256 flashAmount, uint256 loanFee, uint256 token0Amount, uint256 profit, uint256 remaining);

    uint256 public flashAmount;
    uint256 public loanFee;
    uint256 public token0Amount;
    uint256 public profit;
    uint256 public remaining;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyVault() {
        require(msg.sender == address(vault), "your are not the vault");
        _;
    }

    receive() external payable {}

    function queryOwner() external view returns (address) {
        return owner;
    }

    function withdrawToken(address tokenAddress) external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No token amount to withdraw");
        OZ_IERC20(tokenAddress).safeTransfer(owner, balance);
    }

    function withdrawEth() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "ETH transfer failed");
    }


    function executeTrade(
        address[] memory _tokens,
        address[] memory _routers,
        string calldata _router_abi_0,
        string calldata _router_abi_1,
        uint24[] memory _pool_fees,
        uint256 _flashAmount,
        string calldata _uuid
    ) external {


        bytes memory data = abi.encode(
            _tokens,
            _routers,
            _pool_fees,
            _router_abi_0,
            _router_abi_1,
            _uuid
        );

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_tokens[0]);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount;


        vault.flashLoan(this, tokens, amounts, data);

    }

    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {


        (
            address[] memory tokens,
            address[] memory routers,
            uint24[] memory pool_fees,
            string memory router0_abi,
            string memory router1_abi,
            string memory uuid
        ) = abi.decode(
                userData,
                (
                    address[], 
                    address[], 
                    uint24[], 
                    string, 
                    string, 
                    string
                )
            );


        flashAmount = amounts[0];
        loanFee = feeAmounts[0];
 

        address[] memory routerPath = new address[](2);

        routerPath[0] = routers[0];
        routerPath[1] = routers[1];

        string[] memory abiPath = new string[](2);

        abiPath[0] = router0_abi;
        abiPath[1] = router1_abi;

        uint24[] memory feePath = new uint24[](2);

        feePath[0] = pool_fees[0];
        feePath[1] = pool_fees[1];

        address[] memory tokenPath = new address[](2);

        tokenPath[0] = tokens[0];
        tokenPath[1] = tokens[1];

        _executeSwap(routerPath, abiPath, feePath, tokenPath, flashAmount);

        OZ_IERC20 ierc20_token0 = OZ_IERC20(tokens[0]);

        // Replay flash loan + fee
        ierc20_token0.safeApprove(address(this), 0);
        ierc20_token0.safeApprove(address(this), flashAmount + loanFee);


        require(
            ierc20_token0.balanceOf(address(this)) >= flashAmount + loanFee,
            "Not enough balance to repay flash loan"
        );

        token0Amount = ierc20_token0.balanceOf(address(this));

        ierc20_token0.safeTransfer(address(vault), flashAmount + loanFee);

        // Transfer remaining token0 to owner
        ierc20_token0.safeApprove(address(this), 0);
        ierc20_token0.safeApprove(address(this), ierc20_token0.balanceOf(address(this)));


        profit = ierc20_token0.balanceOf(address(this));

        require(
            ierc20_token0.balanceOf(address(this)) >= 0,
            string(abi.encodePacked("No profit to transfer: ", Strings.toString(ierc20_token0.balanceOf(address(this)))))
        );
        
        ierc20_token0.safeTransfer(owner, ierc20_token0.balanceOf(address(this))); 

        remaining = ierc20_token0.balanceOf(address(this));

        emit swapReceipt(uuid, flashAmount, loanFee, token0Amount, profit, remaining);
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

            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), _startAmountIn);

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

            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), _startAmountIn);

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

            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), 0);
            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), _endAmountIn);

            address token0 = _tokenPath[0];
            address token1 = _tokenPath[1];

            _tokenPath[0] = token1;
            _tokenPath[1] = token0;

            _endRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _endAmountIn,
                _flashAmount + _feePath[0] + _feePath[1],
                _tokenPath,
                address(this),
                (block.timestamp + 1200)
            );
        } else if (keccak256(abi.encodePacked(_abiPath[1])) == keccak256(abi.encodePacked("uniswapV3"))) {
            ISwapRouter _endRouter = ISwapRouter(_routerPath[1]);
            uint256 _endAmountIn = IERC20(_tokenPath[1]).balanceOf(
                address(this)
            );

            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), 0);
            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), _endAmountIn);

            _endRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenPath[1],
                    tokenOut: _tokenPath[0],
                    fee: _feePath[1],
                    recipient: address(this),
                    deadline: (block.timestamp + 300),
                    amountIn: _endAmountIn,
                    amountOutMinimum: _flashAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
}
