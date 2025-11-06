// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleBank
 * @notice A small bank-like contract for holding customer accounts (test usage).
 *         NOT for production / real money use. Designed for Remix & testnets.
 */
contract SimpleBank {
    address public bankOwner;

    struct Account {
        string name;
        uint256 balance;     // in wei
        bool exists;
        bool frozen;
        uint256 createdAt;
    }

    mapping(address => Account) private accounts;

    // Reentrancy guard
    bool private locked;

    // Events
    event AccountCreated(address indexed owner, string name);
    event Deposit(address indexed owner, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event TransferBetweenAccounts(address indexed from, address indexed to, uint256 amount);
    event AccountFrozen(address indexed owner);
    event AccountUnfrozen(address indexed owner);
    event AccountClosed(address indexed owner);
    event InterestApplied(address indexed owner, uint256 interestAmount);

    modifier onlyBankOwner() {
        require(msg.sender == bankOwner, "Only bank owner");
        _;
    }

    modifier onlyExistingAccount(address acc) {
        require(accounts[acc].exists, "Account does not exist");
        _;
    }

    modifier notFrozen(address acc) {
        require(!accounts[acc].frozen, "Account is frozen");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        bankOwner = msg.sender;
    }

    /// -------------------------
    /// Account lifecycle
    /// -------------------------

    /// @notice Create a bank account for msg.sender
    /// @param name Display name for the account (optional)
    function createAccount(string calldata name) external {
        require(!accounts[msg.sender].exists, "Account already exists");
        accounts[msg.sender] = Account({
            name: name,
            balance: 0,
            exists: true,
            frozen: false,
            createdAt: block.timestamp
        });
        emit AccountCreated(msg.sender, name);
    }

    /// @notice Close your account and withdraw remaining balance to your address
    function closeAccount() external onlyExistingAccount(msg.sender) nonReentrant {
        Account storage a = accounts[msg.sender];
        require(!a.frozen, "Account frozen");
        uint256 refund = a.balance;
        // delete account before external call (effects)
        delete accounts[msg.sender];
        if (refund > 0) {
            (bool sent, ) = msg.sender.call{value: refund}("");
            require(sent, "Refund failed");
        }
        emit AccountClosed(msg.sender);
    }

    /// -------------------------
    /// Deposits & Withdrawals
    /// -------------------------

    /// @notice Deposit Ether to your account (payable)
    function deposit() external payable onlyExistingAccount(msg.sender) notFrozen(msg.sender) {
        require(msg.value > 0, "Must send > 0");
        accounts[msg.sender].balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Bank owner can deposit to any customer's account (for tests/admin ops)
    /// @param to account address to credit
    function depositTo(address to) external payable onlyBankOwner onlyExistingAccount(to) {
        require(msg.value > 0, "Must send > 0");
        accounts[to].balance += msg.value;
        emit Deposit(to, msg.value);
    }

    /// @notice Withdraw from your account (pull pattern)
    /// @param amount amount in wei
    function withdraw(uint256 amount) external onlyExistingAccount(msg.sender) notFrozen(msg.sender) nonReentrant {
        Account storage a = accounts[msg.sender];
        require(amount > 0, "Amount must be > 0");
        require(a.balance >= amount, "Insufficient balance");

        // Effects first
        a.balance -= amount;

        // Interactions last
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    /// -------------------------
    /// Transfers between accounts
    /// -------------------------

    /// @notice Transfer money from your account to another customer's account
    /// @param to recipient address
    /// @param amount in wei
    function transferTo(address to, uint256 amount) external onlyExistingAccount(msg.sender) onlyExistingAccount(to) notFrozen(msg.sender) notFrozen(to) nonReentrant {
        require(to != msg.sender, "Use withdraw if sending to yourself");
        Account storage sender = accounts[msg.sender];
        Account storage receiver = accounts[to];

        require(amount > 0, "Must send > 0");
        require(sender.balance >= amount, "Insufficient balance");

        // Effects
        sender.balance -= amount;
        receiver.balance += amount;

        emit TransferBetweenAccounts(msg.sender, to, amount);
    }

    /// -------------------------
    /// Admin operations (bankOwner)
    /// -------------------------

    /// @notice Freeze an account (prevent withdraw/transfer/deposit)
    /// @param acc account address
    function freezeAccount(address acc) external onlyBankOwner onlyExistingAccount(acc) {
        accounts[acc].frozen = true;
        emit AccountFrozen(acc);
    }

    /// @notice Unfreeze an account
    /// @param acc account address
    function unfreezeAccount(address acc) external onlyBankOwner onlyExistingAccount(acc) {
        accounts[acc].frozen = false;
        emit AccountUnfrozen(acc);
    }

    /// @notice Apply simple interest to an account (owner-only). Interest is added immediately.
    /// @param acc account to apply interest to
    /// @param basisPoints interest in basis points (100 basis points = 1%)
    function applyInterest(address acc, uint256 basisPoints) external onlyBankOwner onlyExistingAccount(acc) {
        require(basisPoints <= 10000, "Interest too large"); // <= 100%
        Account storage a = accounts[acc];
        uint256 interest = (a.balance * basisPoints) / 10000;
        a.balance += interest;
        emit InterestApplied(acc, interest);
    }

    /// -------------------------
    /// Views / helpers
    /// -------------------------

    /// @notice Get basic account info (balance in wei returned)
    function getAccount(address acc) external view onlyExistingAccount(acc) returns (
        string memory name,
        uint256 balance,
        bool frozen,
        uint256 createdAt
    ) {
        Account storage a = accounts[acc];
        return (a.name, a.balance, a.frozen, a.createdAt);
    }

    /// @notice Convenience: get only the balance (in wei)
    function balanceOf(address acc) external view onlyExistingAccount(acc) returns (uint256) {
        return accounts[acc].balance;
    }

    /// @notice Fallbacks: reject direct plain transfers (encourage using deposit functions)
    receive() external payable {
        revert("Use deposit() after creating an account");
    }

    fallback() external payable {
        revert("Use deposit() after creating an account");
    }
}
