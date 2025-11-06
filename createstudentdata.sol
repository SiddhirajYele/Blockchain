// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentManagement {
    
    struct Student {
        int stud_id;
        string name;
        string department;
    }

    Student[] public students;

    // Add new student
    function addStud(int stud_id, string memory name, string memory department) public {
        Student memory stud = Student(stud_id, name, department);
        students.push(stud);
    }

    // Get student details by ID
    function getStudent(int stud_id) public view returns (string memory, string memory) {
        for (uint i = 0; i < students.length; i++) {
            Student memory stud = students[i];
            if (stud.stud_id == stud_id) {
                return (stud.name, stud.department);
            }
        }
        return ("not found", "not found");
    }
}
