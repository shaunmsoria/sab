// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract SABV1 is IFlashLoanRecipient {
    IVault private constant vault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function executeTrade(
        address _token0,
        address _token1,
        IUniswapV2Router02 _router0,
        IUniswapV2Router02 _router1,
        uint256 _flashAmount
    ) external (
        // To do: ensure it's the owner of the smart contract who can call it

        // encode data about the transaction including tokens, and routers to be used in the receivedFlashLoan
        bytes memory data = abi.encode(_token0, _token1, _router0, _router1);

        // token to be flash loaned, only one for now
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_token0);

        // flash loaned amount
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount;

        // request the flash loan from balancer
        vault.flashLoan(this, tokens, amounts, data);
    )

}