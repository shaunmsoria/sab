// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;


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
    event FlashLoanReceived(address token, uint256 amount, uint256 fee);
    event FlashLoanRepaid(uint256 flashAmount, uint256 loanFee);
    event ProfitTracked(uint256 profit);
    event EventMessage(string message);
    event ReceiveFlashLoanMessage(string message);
    event ReceiveFlashLoanEvent(string message);

    uint256 public flashAmount;
    uint256 public loanFee;
    uint256 public token0Amount;
    uint256 public profit;

    constructor() {
        owner = msg.sender;
    }

    // Add this new function
    function queryOwner() external returns (address) {
        return owner;
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
    // ) external override onlyVault {
    ) external override {
        // emit ReceiveFlashLoanEvent();
        emit ReceiveFlashLoanEvent("ReceiveFlashLoanEvent fired");
        emit EventMessage("ReceiveFlashLoanEven fired");
        // emit ReceiveFlashLoanMessage(2);
        // emit ReceiveFlashLoanMessage("ReceiveFlashLoanMessage fired");
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

        flashAmount = amounts[0];
        loanFee = feeAmounts[0];

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

        OZ_IERC20 ierc20_token0 = OZ_IERC20(token0);

        // Replay flash loan + fee
        ierc20_token0.safeApprove(address(this), 0);
        ierc20_token0.safeApprove(address(this), flashAmount + loanFee);


        require(
            ierc20_token0.balanceOf(address(this)) >= flashAmount + loanFee,
            "Not enough balance to repay flash loan"
        );

        token0Amount = ierc20_token0.balanceOf(address(this));

        ierc20_token0.safeTransfer(address(vault), flashAmount + loanFee);

        emit FlashLoanRepaid(flashAmount, loanFee);

        emit ProfitTracked(ierc20_token0.balanceOf(address(this)));

        // Transfer remaining token0 to owner
        ierc20_token0.safeApprove(address(this), 0);
        ierc20_token0.safeApprove(address(this), ierc20_token0.balanceOf(address(this)));

        require(
            ierc20_token0.balanceOf(address(this)) >= 0,
            string(abi.encodePacked("No profit to transfer", Strings.toString(ierc20_token0.balanceOf(address(this)))))
        );
        
        ierc20_token0.safeTransfer(owner, ierc20_token0.balanceOf(address(this))); 

        profit = ierc20_token0.balanceOf(address(this));
    }

    function _executeSwap(
        address[] memory _routerPath,
        string[] memory _abiPath,
        uint24[] memory _feePath,
        address[] memory _tokenPath,
        uint256 _flashAmount
    ) internal {
        // emit ExecuteSwapFired("ExecuteSwapFired fired");
        
        emit ReceiveFlashLoanEvent("ExecuteSwapFired fired");

        if (keccak256(abi.encodePacked(_abiPath[0])) == keccak256(abi.encodePacked("uniswapV2"))) {
            IUniswapV2Router02 _startRouter = IUniswapV2Router02(_routerPath[0]);
            uint256 _startAmountIn = IERC20(_tokenPath[0]).balanceOf(
                address(this)
            );

            // First reset approval to 0 for tokens like USDT
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            // Then set the desired approval
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

            // First reset approval to 0 for tokens like USDT
            OZ_IERC20(_tokenPath[0]).safeApprove(address(_startRouter), 0);
            // Then set the desired approval
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

            // First reset approval to 0 for tokens like USDT
            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), 0);
            // Then set the desired approval
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

            // First reset approval to 0 for tokens like USDT
            OZ_IERC20(_tokenPath[1]).safeApprove(address(_endRouter), 0);
            // Then set the desired approval
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
