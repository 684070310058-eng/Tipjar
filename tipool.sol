// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RestaurantTipPool {
    
    // ตัวแปรสำหรับเก็บที่อยู่ของเจ้าของสัญญา (ผู้จัดการร้าน)
    address public owner;
    
    // อาร์เรย์สำหรับเก็บรายชื่อกระเป๋าเงินของพนักงาน
    address[] public workers;

    // Events เพื่อบันทึกเหตุการณ์ต่างๆ ลงใน Blockchain (Log)
    event TipReceived(address indexed customer, uint256 amount);
    event WorkerAdded(address indexed worker);
    event WorkerRemoved(address indexed worker);
    event TipsDistributed(uint256 totalAmount, uint256 amountPerWorker);

    // Modifier เพื่อกำหนดสิทธิ์ให้เฉพาะเจ้าของร้านเรียกใช้งานฟังก์ชันได้
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Constructor จะทำงานครั้งเดียวตอน Deploy สัญญา
    constructor() {
        owner = msg.sender; // กำหนดให้คนที่ Deploy เป็นเจ้าของร้าน
    }

    // ---------------------------------------------------------
    // 1. Put money into the pool (ใส่เงินลงในกองกลาง)
    // ---------------------------------------------------------
    // ฟังก์ชันนี้รับเงิน Ether เข้ามาในสัญญา
    function deposit() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        emit TipReceived(msg.sender, msg.value);
    }

    // ฟังก์ชันพิเศษ receive() ช่วยให้โอนเงินเข้า Address ของสัญญาโดยตรงได้เลย
    receive() external payable {
        emit TipReceived(msg.sender, msg.value);
    }

    // ---------------------------------------------------------
    // 2. View pool balance (ดูยอดเงินในกองกลาง)
    // ---------------------------------------------------------
    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ---------------------------------------------------------
    // 3. Add/Remove workers (เพิ่ม/ลบ รายชื่อพนักงาน)
    // ---------------------------------------------------------
    function addWorker(address _worker) public onlyOwner {
        require(_worker != address(0), "Invalid address");
        // ตรวจสอบว่ามีพนักงานคนนี้อยู่แล้วหรือไม่
        for(uint i = 0; i < workers.length; i++) {
            require(workers[i] != _worker, "Worker already exists");
        }
        workers.push(_worker);
        emit WorkerAdded(_worker);
    }

    function removeWorker(address _worker) public onlyOwner {
        bool found = false;
        for (uint i = 0; i < workers.length; i++) {
            if (workers[i] == _worker) {
                // ย้ายตัวสุดท้ายมาแทนที่ตัวที่จะลบ แล้วลบตัวสุดท้ายออก (เพื่อประหยัด Gas)
                workers[i] = workers[workers.length - 1];
                workers.pop();
                found = true;
                break;
            }
        }
        require(found, "Worker not found");
        emit WorkerRemoved(_worker);
    }

    // ---------------------------------------------------------
    // 4. View workers (ดูรายชื่อพนักงาน)
    // ---------------------------------------------------------
    function getWorkers() public view returns (address[] memory) {
        return workers;
    }

    // ---------------------------------------------------------
    // 5. Distribute tips (จัดสรร/แบ่งปันเงินทิป)
    // ---------------------------------------------------------
    function distributeTips() public onlyOwner {
        uint256 totalPool = address(this).balance;
        require(totalPool > 0, "No tips in the pool to distribute");
        require(workers.length > 0, "No workers registered");

        // คำนวณยอดเงินต่อคน
        uint256 amountPerWorker = totalPool / workers.length;

        // วนลูปโอนเงินให้พนักงานทุกคน
        for (uint i = 0; i < workers.length; i++) {
            // ใช้ .call เพื่อโอนเงิน (ปลอดภัยกว่า transfer)
            (bool success, ) = workers[i].call{value: amountPerWorker}("");
            require(success, "Transfer to worker failed");
        }

        emit TipsDistributed(totalPool, amountPerWorker);
    }
}