// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CourseMarketplace {
    address public owner;

    struct Course {
        string courseId;
        uint256 price; // in wei
        address instructor;
        bool isActive;
    }

    struct Certificate {
        string courseId;
        address student;
        uint256 timestamp;
        string metadataUrl; // IPFS hash or similar
    }

    // Mapping from courseId to Course details
    mapping(string => Course) public courses;
    
    // Mapping from student address to list of enrolled courseIds
    mapping(address => string[]) public studentEnrollments;

    // Mapping from student address to courseId to bool (isEnrolled)
    mapping(address => mapping(string => bool)) public isEnrolled;

    // Mapping from student address to list of certificates
    mapping(address => Certificate[]) public studentCertificates;

    event CourseCreated(string courseId, uint256 price, address instructor);
    event CoursePurchased(string courseId, address student);
    event CertificateIssued(string courseId, address student, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    // Register a course on the blockchain
    function createCourse(string memory _courseId, uint256 _price) public {
        require(bytes(_courseId).length > 0, "Invalid course ID");
        // Update or create
        courses[_courseId] = Course({
            courseId: _courseId,
            price: _price,
            instructor: msg.sender,
            isActive: true
        });
        emit CourseCreated(_courseId, _price, msg.sender);
    }

    // Purchase a course
    function purchaseCourse(string memory _courseId) public payable {
        Course memory course = courses[_courseId];
        require(course.isActive, "Course is not active");
        require(msg.value >= course.price, "Insufficient payment");
        require(!isEnrolled[msg.sender][_courseId], "Already enrolled");

        // Transfer funds to instructor
        payable(course.instructor).transfer(msg.value);

        // Enroll student
        studentEnrollments[msg.sender].push(_courseId);
        isEnrolled[msg.sender][_courseId] = true;

        emit CoursePurchased(_courseId, msg.sender);
    }

    // Issue a certificate (Instructor only)
    function issueCertificate(string memory _courseId, address _student, string memory _metadataUrl) public {
        Course memory course = courses[_courseId];
        require(msg.sender == course.instructor, "Only instructor can issue certificate");
        require(isEnrolled[_student][_courseId], "Student not enrolled");

        Certificate memory newCert = Certificate({
            courseId: _courseId,
            student: _student,
            timestamp: block.timestamp,
            metadataUrl: _metadataUrl
        });

        studentCertificates[_student].push(newCert);

        emit CertificateIssued(_courseId, _student, block.timestamp);
    }

    // Get enrolled courses for a student
    function getEnrolledCourses(address _student) public view returns (string[] memory) {
        return studentEnrollments[_student];
    }
}
