// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Treasury
 * @dev Manages DAO funds and executes financial transactions
 */
contract Treasury is ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    address public immutable dao;
    
    // Token balance tracking
    mapping(address => uint256) public balances;
    
    event Deposited(address indexed token, address indexed from, uint256 amount);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event ExecutionComplete(address indexed target, uint256 value, bytes data);
    
    error Unauthorized();
    error InsufficientBalance();
    error TransferFailed();
    error InvalidAddress();

    constructor(address _dao) {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
    }

    modifier onlyDAO() {
        if (msg.sender != dao) revert Unauthorized();
        _;
    }

    // For receiving ETH
    receive() external payable {
        balances[address(0)] += msg.value;
        emit Deposited(address(0), msg.sender, msg.value);
    }

    /**
     * @dev Deposits ERC20 tokens into the treasury
     * @param token The token address (use address(0) for ETH)
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external nonReentrant whenNotPaused {
        if (token == address(0)) revert InvalidAddress();
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balances[token] += amount;
        
        emit Deposited(token, msg.sender, amount);
    }

    /**
     * @dev Withdraws tokens from the treasury
     * @param token The token address (use address(0) for ETH)
     * @param amount Amount to withdraw
     * @param to Recipient address
     */
    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyDAO nonReentrant whenNotPaused {
        if (to == address(0)) revert InvalidAddress();
        if (amount > balances[token]) revert InsufficientBalance();
        
        balances[token] -= amount;
        
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
        
        emit Withdrawn(token, to, amount);
    }

    /**
     * @dev Executes a transaction from the treasury
     * @param target Target contract address
     * @param value ETH value to send
     * @param data Transaction calldata
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyDAO nonReentrant whenNotPaused returns (bytes memory) {
        if (target == address(0)) revert InvalidAddress();
        if (value > balances[address(0)]) revert InsufficientBalance();
        
        balances[address(0)] -= value;
        
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) revert TransferFailed();
        
        emit ExecutionComplete(target, value, data);
        return result;
    }

    /**
     * @dev Emergency pause/unpause functionality
     */
    function togglePause() external onlyDAO {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
} 