// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

/**
 * @title Agent Contract
 * @dev This contract defines a simple healthcare management system with patients and doctors.
 */
contract Agent {

    // Struct to represent patient information
    struct Patient {
        string name;
        uint age;
        string did;
        string cnss;
        address[] doctorAccessList;
        uint[] diagnosis;
        string record;
    }

    // Struct to represent doctor information
    struct Doctor {
        string name;
        uint age;
        string did;
        string speciality;
        address[] patientAccessList;
    }

    // Global variable to track the credit pool for accessing patient records
    uint creditPool;

    // Arrays to store the list of patients and doctors
    address[] public patientList;
    address[] public doctorList;

    // Mapping to store patient and doctor information based on their addresses
    mapping (address => Patient) patientInfo;
    mapping (address => Doctor) doctorInfo;

    // Mapping to store an empty address
    mapping (address => address) Empty;

    // Mapping to store patient records based on their addresses
    mapping (address => string) patientRecords;

    /**
     * @dev Function to add a new agent (patient or doctor) to the system.
     * @param _name The name of the agent.
     * @param _age The age of the agent.
     * @param _designation The designation of the agent (0 for patient, 1 for doctor).
     * @param _hash The hash representing the agent's record (used for patients).
     * @param _did The unique identifier for the agent (e.g., Doctor ID or Patient ID).
     * @param _cnss The CNSS (Caisse Nationale de Sécurité Sociale) number for patients.
     * @param _speciality The speciality of the doctor (used for doctors).
     * @return The name of the added agent.
     */
    function add_agent(string memory _name, uint _age, uint _designation, string memory _hash, string memory _did, string memory _cnss, string memory _speciality) public returns(string memory){
        address addr = msg.sender;

        if(_designation == 0){
            // Adding a new patient
            Patient memory p;
            p.name = _name;
            p.age = _age;
            p.did = _did;
            p.cnss = _cnss;
            p.record = _hash;
            patientInfo[msg.sender] = p;
            patientList.push(addr)-1;
            return _name;
        }
        else if (_designation == 1){
            // Adding a new doctor
            doctorInfo[addr].name = _name;
            doctorInfo[addr].age = _age;
            doctorInfo[addr].did = _did;
            doctorInfo[addr].speciality = _speciality;
            doctorList.push(addr)-1;
            return _name;
        }
        else{
            // Revert if an invalid designation is provided
            revert();
        }
    }

    /**
     * @dev Function to get patient information based on their address.
     * @param addr The address of the patient.
     * @return A tuple containing patient information.
     */
    function get_patient(address addr) view public returns (string memory , uint, string memory, string memory, uint[] memory , address, string memory ){
        return (patientInfo[addr].name, patientInfo[addr].age, patientInfo[addr].did, patientInfo[addr].cnss, patientInfo[addr].diagnosis, Empty[addr], patientInfo[addr].record);
    }

    /**
     * @dev Function to get doctor information based on their address.
     * @param addr The address of the doctor.
     * @return A tuple containing doctor information.
     */
    function get_doctor(address addr) view public returns (string memory , uint, string memory, string memory){
        return (doctorInfo[addr].name, doctorInfo[addr].age, doctorInfo[addr].did, doctorInfo[addr].speciality);
    }

    /**
     * @dev Function to get the names of a patient and a doctor based on their addresses.
     * @param paddr The address of the patient.
     * @param daddr The address of the doctor.
     * @return A tuple containing the names of the patient and the doctor.
     */
    function get_patient_doctor_name(address paddr, address daddr) view public returns (string memory , string memory ){
        return (patientInfo[paddr].name, doctorInfo[daddr].name);
    }

    /**
     * @dev Function to permit access to a doctor's records by a patient.
     * @param addr The address of the doctor.
     */
    function permit_access(address addr) payable public {
        // Require payment of 2 ether to access patient records
        require(msg.value == 2 ether);

        // Update credit pool and add addresses to access lists
        creditPool += 2;
        doctorInfo[addr].patientAccessList.push(msg.sender)-1;
        patientInfo[msg.sender].doctorAccessList.push(addr)-1;
    }

    /**
     * @dev Function for a doctor to initiate an insurance claim for a patient.
     * @param paddr The address of the patient.
     * @param _diagnosis The diagnosis code for the insurance claim.
     * @param _hash The updated hash for the patient's record.
     */
    function insurance_claim(address paddr, uint _diagnosis, string memory  _hash) public {
        // Check if the patient has granted access to the calling doctor
        bool patientFound = false;
        for(uint i = 0; i < doctorInfo[msg.sender].patientAccessList.length; i++){
            if(doctorInfo[msg.sender].patientAccessList[i] == paddr){
                // Transfer funds from patient to doctor
                msg.sender.transfer(2 ether);
                creditPool -= 2;
                patientFound = true;
            }
        }

        // If patient access is found, update hash and remove patient from access lists
        if(patientFound == true){
            set_hash(paddr, _hash);
            remove_patient(paddr, msg.sender);
        } else {
            // Revert if patient access is not found
            revert();
        }

        // Check if the diagnosis code exists in the patient's records
        bool DiagnosisFound = false;
        for(uint j = 0; j < patientInfo[paddr].diagnosis.length; j++){
            if(patientInfo[paddr].diagnosis[j] == _diagnosis){
                DiagnosisFound = true;
            }
        }
    }

    /**
     * @dev Internal function to remove an element from a dynamic address array.
     * @param Array The dynamic address array.
     * @param addr The address to be removed.
     * @return The index of the removed address.
     */
    function remove_element_in_array(address[] storage Array, address addr) internal returns(uint) {
        bool check = false;
        uint del_index = 0;
        for(uint i = 0; i < Array.length; i++){
            if(Array[i] == addr){
                check = true;
                del_index = i;
            }
        }
        // Revert if the address is not found in the array
        if (!check) revert();
        else {
            // If the array has only one element, delete it directly
            if (Array.length == 1) {
                delete Array[del_index];
            } else {
                // Swap the element to be deleted with the last element and then delete
                Array[del_index] = Array[Array.length - 1];
                delete Array[Array.length - 1];
            }
            // Reduce the array length
            Array.length--;
        }
    }

    /**
     * @dev Function to remove a patient from both doctor and patient access lists.
     * @param paddr The address of the patient.
     * @param daddr The address of the doctor.
     */
    function remove_patient(address paddr, address daddr) public {
        remove_element_in_array(doctorInfo[daddr].patientAccessList, paddr);
        remove_element_in_array(patientInfo[paddr].doctorAccessList, daddr);
    }

    /**
     * @dev Function to retrieve the list of doctors who have accessed a specific patient's information.
     * @param addr The address of the patient.
     * @return An array of doctor addresses.
     */
    function get_accessed_doctorlist_for_patient(address addr) public view returns (address[] memory ) { 
        address[] storage doctoraddr = patientInfo[addr].doctorAccessList;
        return doctoraddr;
    }

    /**
     * @dev Function to retrieve the list of patients whose information a specific doctor has accessed.
     * @param addr The address of the doctor.
     * @return An array of patient addresses.
     */
    function get_accessed_patientlist_for_doctor(address addr) public view returns (address[] memory ) {
        return doctorInfo[addr].patientAccessList;
    }

    /**
     * @dev Function to revoke access to a doctor's records by a patient.
     * @param daddr The address of the doctor.
     */
    function revoke_access(address daddr) public payable {
        // Remove patient from access lists and refund the payment
        remove_patient(msg.sender, daddr);
        msg.sender.transfer(2 ether);
        creditPool -= 2;
    }

    /**
     * @dev Function to retrieve the list of all patient addresses.
     * @return An array of patient addresses.
     */
    function get_patient_list() public view returns(address[] memory ) {
        return patientList;
    }

    /**
     * @dev Function to retrieve the list of all doctor addresses.
     * @return An array of doctor addresses.
     */
    function get_doctor_list() public view returns(address[] memory ) {
        return doctorList;
    }

    /**
     * @dev Function to retrieve the record hash of a specific patient.
     * @param paddr The address of the patient.
     * @return The hash representing the patient's record.
     */
    function get_hash(address paddr) public view returns(string memory ) {
        return patientInfo[paddr].record;
    }

    /**
     * @dev Internal function to update the record hash of a specific patient.
     * @param paddr The address of the patient.
     * @param _hash The new hash to be set.
     */
    function set_hash(address paddr, string memory _hash) internal {
        patientInfo[paddr].record = _hash;
    }
}
