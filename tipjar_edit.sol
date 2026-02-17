// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

contract tips {
    // ลบ public ออกเพื่อให้ปุ่ม owner หายไป
    address owner; 
    // ลบ public ออกเพื่อให้ปุ่ม totalPercent หายไป
    uint totalPercent; 

    constructor() {
        owner = msg.sender;
    }

    struct Waitress {
        address payable walletAddress;
        string name;
        uint percent;
    }

    // ลบ public ออกเพื่อให้ปุ่ม waitress (แบบใส่เลข index) หายไป
    Waitress[] waitress; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _ ;
    }

    function addtips() public payable {}

    function viewtips() public view returns (uint) {
        return address(this).balance;
    }

    // ฟังก์ชันนี้ยังเก็บไว้เพื่อให้ดูรายชื่อ waitress ทั้งหมดได้ในปุ่มเดียว
    function viewWaitress() public view returns (Waitress[] memory) {
        return waitress;
    }

    function addWaitress(
        address payable walletAddress,
        string memory name,
        uint percent
    ) public onlyOwner {
        require(totalPercent + percent <= 100, "Total percentage cannot exceed 100%");

        bool waitressExist = false;
        for (uint i = 0; i < waitress.length; i++) {
            if (waitress[i].walletAddress == walletAddress) {
                waitressExist = true;
                break;
            }
        }

        if (waitressExist == false) {
            waitress.push(Waitress(walletAddress, name, percent));
            totalPercent += percent;
        } else {
            revert("Waitress already exists");
        }
    }

    function removeWaitress(address walletAddress) public onlyOwner {
        for (uint i = 0; i < waitress.length; i++) {
            if (waitress[i].walletAddress == walletAddress) {
                totalPercent -= waitress[i].percent;

                for (uint j = i; j < waitress.length - 1; j++) {
                    waitress[j] = waitress[j + 1];
                }
                waitress.pop();
                break;
            }
        }
    }

    function distributeBalance() public {
        require(address(this).balance > 0, "No Money");
        require(waitress.length > 0, "No Waitress added");

        uint totalAmount = address(this).balance;
        
        for (uint j = 0; j < waitress.length; j++) {
            uint distributeAmount = (totalAmount * waitress[j].percent) / 100;
            if (distributeAmount > 0) {
                _transferFunds(waitress[j].walletAddress, distributeAmount);
            }
        }
    }

    function _transferFunds(address payable recipient, uint amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}