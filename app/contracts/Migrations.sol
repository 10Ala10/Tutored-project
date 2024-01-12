// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

/**
 * @title Migrations Contract
 * @dev This contract facilitates the migration of state variables from one deployment to another.
 */
contract Migrations {

    // Address of the contract owner
    address public owner;

    // Variable to store the last completed migration
    uint public last_completed_migration;

    // Modifier to restrict access to certain functions to only the contract owner
    modifier restricted() {
        require(msg.sender == owner, "Restricted to contract owner only");
        _;
    }

    /**
     * @dev Constructor function to set the owner as the deployer of the contract.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Function to set the last completed migration. Access is restricted to the contract owner.
     * @param completed The value to set as the last completed migration.
     */
    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    /**
     * @dev Function to upgrade the contract to a new address. Access is restricted to the contract owner.
     * @param new_address The address of the new contract to which the migration should occur.
     */
    function upgrade(address new_address) public restricted {
        // Create an instance of the new contract
        Migrations upgraded = Migrations(new_address);

        // Set the last completed migration of the new contract to the current contract's value
        upgraded.setCompleted(last_completed_migration);
    }
}
