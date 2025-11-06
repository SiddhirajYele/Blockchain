// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleBank {
    struct Account {
        string name;
        string email;
        uint balance;
        bool exists;
    }

    mapping(address => Account) private accounts;

    // Create a new account with name and email
    function createAccount(string memory _name, string memory _email) public {
        require(!accounts[msg.sender].exists, "Account already exists");

        accounts[msg.sender] = Account({
            name: _name,
            email: _email,
            balance: 0,
            exists: true
        });
    }

    // Deposit ether into the account
    function deposit() public payable {
        require(accounts[msg.sender].exists, "Account does not exist");
        accounts[msg.sender].balance += msg.value;
    }

    // Withdraw ether from the account
    function withdraw(uint amount) public {
        require(accounts[msg.sender].exists, "Account does not exist");
        require(accounts[msg.sender].balance >= amount, "Insufficient balance");

        accounts[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Check your balance
    function checkBalance() public view returns (uint) {
        require(accounts[msg.sender].exists, "Account does not exist");
        return accounts[msg.sender].balance;
    }

    // View your account details
    function getAccountDetails() public view returns (string memory, string memory, uint) {
        require(accounts[msg.sender].exists, "Account does not exist");
        Account memory acc = accounts[msg.sender];
        return (acc.name, acc.email, acc.balance);
    }

    // Close your account
    function closeAccount() public {
        require(accounts[msg.sender].exists, "Account does not exist");
        uint amount = accounts[msg.sender].balance;
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].exists = false;
        payable(msg.sender).transfer(amount);
    }
}
