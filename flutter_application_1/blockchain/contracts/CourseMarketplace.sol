// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// =============================================================================
// COURSE MARKETPLACE SMART CONTRACT
// =============================================================================
// WHAT IS THIS?
// This is a Solidity smart contract that runs on the Ethereum blockchain.
// It handles course purchases and certificate issuance WITHOUT a middleman!
//
// WHY BLOCKCHAIN?
// - No intermediary (like Udemy) taking 37% of the payment
// - Payments go directly from student to instructor
// - Certificates are permanent and cannot be faked
// - All transactions are transparent and verifiable
//
// HOW IT WORKS:
// 1. Instructor creates a course with a price in ETH
// 2. Student pays ETH to purchase the course
// 3. ETH goes directly to instructor's wallet
// 4. After completion, instructor issues a certificate on-chain
// =============================================================================

contract CourseMarketplace {
    // The address of the contract owner (who deployed it)
    address public owner;

    // =========================================================================
    // DATA STRUCTURES - How we store course and certificate information
    // =========================================================================
    
    // Course structure - stores all info about a course
    struct Course {
        string courseId;       // Unique ID (e.g., "javascript_101")
        uint256 price;         // Price in Wei (1 ETH = 10^18 Wei)
        address instructor;    // Instructor's wallet address
        bool isActive;         // Is the course available for purchase?
    }

    // Certificate structure - proof of course completion
    struct Certificate {
        string courseId;       // Which course was completed
        address student;       // Student's wallet address
        uint256 timestamp;     // When the certificate was issued (Unix time)
        string metadataUrl;    // Link to certificate details (IPFS)
    }

    // =========================================================================
    // STORAGE MAPPINGS - Like database tables on the blockchain
    // =========================================================================
    
    // courseId => Course details
    // Example: "javascript_101" => {price: 0.05 ETH, instructor: 0x123...}
    mapping(string => Course) public courses;
    
    // student address => list of enrolled course IDs
    // Example: 0xABC... => ["javascript_101", "react_basics"]
    mapping(address => string[]) public studentEnrollments;

    // student address => courseId => true/false (is enrolled?)
    // Example: 0xABC... => "javascript_101" => true
    mapping(address => mapping(string => bool)) public isEnrolled;

    // student address => list of certificates
    mapping(address => Certificate[]) public studentCertificates;

    // =========================================================================
    // EVENTS - Notify the frontend when something happens
    // =========================================================================
    event CourseCreated(string courseId, uint256 price, address instructor);
    event CoursePurchased(string courseId, address student);
    event CertificateIssued(string courseId, address student, uint256 timestamp);

    // =========================================================================
    // CONSTRUCTOR - Runs once when contract is first deployed
    // =========================================================================
    constructor() {
        owner = msg.sender;  // msg.sender = whoever deploys the contract
    }

    // Modifier to restrict certain functions to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;  // Continue with the function
    }

    // =========================================================================
    // FUNCTION 1: CREATE COURSE (Instructor calls this)
    // =========================================================================
    // Creates a new course on the blockchain
    // Anyone can create a course (they become the instructor)
    function createCourse(string memory _courseId, uint256 _price) public {
        // Validate: course ID cannot be empty
        require(bytes(_courseId).length > 0, "Invalid course ID");
        
        // Save course to blockchain storage
        courses[_courseId] = Course({
            courseId: _courseId,
            price: _price,
            instructor: msg.sender,  // msg.sender = whoever called this function
            isActive: true
        });
        
        // Emit event so frontend knows a course was created
        emit CourseCreated(_courseId, _price, msg.sender);
    }

    // =========================================================================
    // FUNCTION 2: PURCHASE COURSE (Student calls this)
    // =========================================================================
    // Student pays ETH to enroll in a course
    // The "payable" keyword means this function can receive ETH
    function purchaseCourse(string memory _courseId) public payable {
        // Load course from storage
        Course memory course = courses[_courseId];
        
        // VALIDATION CHECKS:
        require(course.isActive, "Course is not active");
        require(msg.value >= course.price, "Insufficient payment");  // msg.value = ETH sent
        require(!isEnrolled[msg.sender][_courseId], "Already enrolled");

        // =====================================================================
        // PAYMENT: Transfer ETH directly to instructor (no middleman!)
        // This is the key benefit of blockchain - direct peer-to-peer payment
        // =====================================================================
        payable(course.instructor).transfer(msg.value);

        // Record the enrollment on blockchain
        studentEnrollments[msg.sender].push(_courseId);
        isEnrolled[msg.sender][_courseId] = true;

        // Emit event so frontend knows purchase succeeded
        emit CoursePurchased(_courseId, msg.sender);
    }

    // =========================================================================
    // FUNCTION 3: ISSUE CERTIFICATE (Instructor calls this after student finishes)
    // =========================================================================
    // Only the instructor of the course can issue certificates
    function issueCertificate(
        string memory _courseId, 
        address _student, 
        string memory _metadataUrl
    ) public {
        Course memory course = courses[_courseId];
        
        // VALIDATION: Only instructor can issue certificate for their course
        require(msg.sender == course.instructor, "Only instructor can issue certificate");
        require(isEnrolled[_student][_courseId], "Student not enrolled");

        // Create certificate and store on blockchain (permanent!)
        Certificate memory newCert = Certificate({
            courseId: _courseId,
            student: _student,
            timestamp: block.timestamp,  // Current blockchain time
            metadataUrl: _metadataUrl    // Link to certificate image/PDF
        });

        // Add to student's certificate list
        studentCertificates[_student].push(newCert);

        // Emit event
        emit CertificateIssued(_courseId, _student, block.timestamp);
    }

    // =========================================================================
    // FUNCTION 4: GET ENROLLED COURSES (View function - free to call)
    // =========================================================================
    // Returns list of course IDs a student is enrolled in
    // "view" means it only reads data, doesn't modify blockchain (no gas cost)
    function getEnrolledCourses(address _student) public view returns (string[] memory) {
        return studentEnrollments[_student];
    }
}
