// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOracle {
    function latestAnswer() external view returns(int256);
}

contract KipuBank_v6 is AccessControl {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant ADMIN_ROLE = 0x00; // equivalente a DEFAULT_ADMIN_ROLE
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Custom errores
    error ZeroDeposit();
    error ZeroWithdrawal();
    error OverWithdrawal(uint256 requested, uint256 limit);
    error TransferFailed();
    error TokenNotSupported(address token);
    error FeedNotSet(address token);
    error FeedFailed(address token);
    error CapExceeded(uint256 attemptedUsd6, uint256 capUsd6);
    error NotAdmin();
    error InvalidAddress();

    // Eventos
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event BankCapUpdated(uint256 oldCapUsd6, uint256 newCapUsd6);
    event FeedSet(address indexed token, address indexed feed);

    // Constantes
    uint8 public constant USDC_DECIMALS = 6;
    address public immutable USDC_ADDRESS;

    // Mappings
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) public tokenSupported;
    mapping(address => address) public priceFeeds;

    uint256 public bankCapUsd6;
    uint256 public totalDepositedUsd6;

    // Modificador de acceso admin
    modifier onlyAdmin() {
        if(!hasRole(ADMIN_ROLE, msg.sender)) revert NotAdmin();
        _;
    }

    // Constructor
    constructor(address admin, address usdcAddress, uint256 initialCapUsd6) AccessControl() {
        if(admin == address(0) || usdcAddress == address(0)) revert InvalidAddress();
        _grantRole(ADMIN_ROLE, admin);
        grantRole(OPERATOR_ROLE, admin);
        USDC_ADDRESS = usdcAddress;
        bankCapUsd6 = initialCapUsd6;
    }

    // =========================
    // Admin functions
    // =========================
    function setTokenSupported(address token, bool supported) external onlyAdmin {
        tokenSupported[token] = supported;
    }

    function setPriceFeed(address token, address feed) external onlyAdmin {
        if(token == address(0)) revert InvalidAddress();
        priceFeeds[token] = feed;
        emit FeedSet(token, feed);
    }

    function setBankCapUsd6(uint256 newCapUsd6) external onlyAdmin {
        uint256 old = bankCapUsd6;
        bankCapUsd6 = newCapUsd6;
        emit BankCapUpdated(old, newCapUsd6);
    }

    // =========================
    // Deposits
    // =========================
    function depositETH() external payable {
        _deposit(address(0), msg.value);
    }

    function depositToken(address token, uint256 amount) external {
        if(!tokenSupported[token]) revert TokenNotSupported(token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(token, amount);
    }

    function _deposit(address token, uint256 amount) internal {
        if(amount == 0) revert ZeroDeposit();

        uint256 usd6 = _toUsd6(token, amount);
        _checkCapAndUpdate(usd6);

        balances[token][msg.sender] += amount;
        emit Deposit(msg.sender, token, amount);
    }

    // =========================
    // Withdrawals
    // =========================
    function withdrawETH(uint256 amount) external {
        _withdraw(address(0), amount);
        (bool sent,) = msg.sender.call{value: amount}("");
        if(!sent) revert TransferFailed();
    }

    function withdrawToken(address token, uint256 amount) external {
        if(!tokenSupported[token]) revert TokenNotSupported(token);
        _withdraw(token, amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function _withdraw(address token, uint256 amount) internal {
        if(amount == 0) revert ZeroWithdrawal();

        uint256 bal = balances[token][msg.sender];
        if(amount > bal) revert OverWithdrawal(amount, bal);

        unchecked { balances[token][msg.sender] = bal - amount; }

        uint256 usd6 = _toUsd6(token, amount);
        totalDepositedUsd6 = usd6 > totalDepositedUsd6 ? 0 : totalDepositedUsd6 - usd6;

        emit Withdrawal(msg.sender, token, amount);
    }

    // =========================
    // View functions
    // =========================
    function balanceOf(address token, address user) external view returns (uint256) {
        return balances[token][user];
    }

    // =========================
    // Internal functions
    // =========================
    function _toUsd6(address token, uint256 amount) internal view returns (uint256) {
        address feedAddr = priceFeeds[token];
        if(feedAddr == address(0)) revert FeedNotSet(token);

        uint256 price = _getFeedPrice(feedAddr, token);

        uint8 decimals = token == address(0) ? 18 : _tokenDecimals(token);

        return (amount * price * 10**USDC_DECIMALS) / (10**decimals * 10**8);
    }

    function _getFeedPrice(address feedAddr, address token) internal view returns (uint256 price) {
        try IOracle(feedAddr).latestAnswer() returns (int256 latest) {
            require(latest > 0, "Invalid price");
            price = uint256(latest);
        } catch {
            revert FeedFailed(token);
        }
    }

    function _tokenDecimals(address token) internal view returns (uint8) {
        (bool ok, bytes memory data) = token.staticcall(abi.encodeWithSignature("decimals()"));
        if(!ok || data.length == 0) return 18;
        return abi.decode(data, (uint8));
    }

    function _checkCapAndUpdate(uint256 usd6Amount) internal {
        uint256 newTotal = totalDepositedUsd6 + usd6Amount;
        if(newTotal > bankCapUsd6) revert CapExceeded(newTotal, bankCapUsd6);
        totalDepositedUsd6 = newTotal;
    }

    // =========================
    // Fallbacks
    // =========================
    receive() external payable {
        revert("Use depositETH for accounting");
    }

    fallback() external payable {
        revert("Function does not exist");
    }
}
