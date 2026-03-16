// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20 as OZ_IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

library SabLibrary {
    using SafeERC20 for OZ_IERC20;

    function executeSwap(
        address caller,
        address[] memory _routerPath,
        string[] memory _abiPath,
        uint24[] memory _feePath,
        address[] memory _tokenPath,
        uint256 _flashAmount
    ) internal returns (bool) {

        if (keccak256(abi.encodePacked(_abiPath[0])) == keccak256(abi.encodePacked("uniswapV2"))) {
            IUniswapV2Router02 _startRouter = IUniswapV2Router02(_routerPath[0]);
            uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(
                caller
            );

            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), _startAmountIn);

            _startRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _startAmountIn,
                0,
                _tokenPath,
                caller,
                (block.timestamp + 1200)
            );
        } else if ( keccak256(abi.encodePacked(_abiPath[0])) == keccak256(abi.encodePacked("uniswapV3"))) {
            ISwapRouter _startRouter = ISwapRouter(_routerPath[0]);
            uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(
                caller
            );

            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), _startAmountIn);

            _startRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenPath[0],
                    tokenOut: _tokenPath[1],
                    fee: _feePath[0],
                    recipient: caller,
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
                caller
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
                caller,
                (block.timestamp + 1200)
            );
        } else if (keccak256(abi.encodePacked(_abiPath[1])) == keccak256(abi.encodePacked("uniswapV3"))) {
            ISwapRouter _endRouter = ISwapRouter(_routerPath[1]);
            uint256 _endAmountIn = IERC20(_tokenPath[1]).balanceOf(
                caller
            );

            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), 0);
            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), _endAmountIn);

            _endRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenPath[1],
                    tokenOut: _tokenPath[0],
                    fee: _feePath[1],
                    recipient: caller,
                    deadline: (block.timestamp + 300),
                    amountIn: _endAmountIn,
                    amountOutMinimum: _flashAmount,
                    sqrtPriceLimitX96: 0
                })
            );
        }

        return true;
    }
}