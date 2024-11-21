SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS doctor;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS billing;
CREATE TABLE patient(
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100),
    age INT, 
    telephone_number VARCHAR(15),
    gender ENUM ('male', 'female', 'non-binary'),
    pre_existing_conditions JSON, 
    previous_appointments JSON, 
    currently_taking_meds TINYINT(1),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone_number VARCHAR(15),
    prescription_id INT,
    foreign key (prescription_id) REFERENCES prescriptions(prescription_id)
);

CREATE TABLE doctor(
    doc_id INT  AUTO_INCREMENT PRIMARY KEY,
    doc_name VARCHAR(100),
    dept ENUM ('obstetrics', 'pediatrics', 'cardiology', 'orthopaedics'),
    job_description VARCHAR(100),
    doc_telephone_number VARCHAR(20),
    email VARCHAR(40),
    office_location ENUM ('Upper West Side', 'Upper East Side'),
    specializations VARCHAR(100),
    prescription_id INT,
    foreign key (prescription_id) REFERENCES prescriptions(prescription_id)
);

CREATE TABLE appointments(
    appt_id INT AUTO_INCREMENT PRIMARY KEY,
    appt_date DATETIME,
    doc_notes VARCHAR(200),
    patient_notes VARCHAR(200),
    active_appt TINYINT(1),
    office_location ENUM ('Upper West Side', 'Upper East Side'),
    patient_id INT,
    doc_id INT,
    prescription_id INT,
    foreign key (patient_id) REFERENCES patient(patient_id),
    foreign key (doc_id) REFERENCES doctor(doc_id),
    foreign key (prescription_id) REFERENCES prescriptions(prescription_id)
);
CREATE TABLE prescriptions(
    prescription_id INT PRIMARY KEY,
    med_name VARCHAR(100),
    dosage VARCHAR(100),
    patient_id INT,
    doc_id INT,
    foreign key (patient_id) REFERENCES patient(patient_id),
    foreign key (doc_id) REFERENCES doctor(doc_id)
);
CREATE TABLE billing(
    patient_id INT,
    appt_id INT,
    foreign key (patient_id) REFERENCES patient(patient_id),
    foreign key (appt_id) REFERENCES appointments(appt_id),
    amount_billed DECIMAL(10,2),
    amount_received DECIMAL (10,2),
    balance DECIMAL(10,2)
);
SET FOREIGN_KEY_CHECKS=1;
DELIMITER //
CREATE TRIGGER calculatebalance 
AFTER INSERT ON billing
FOR EACH ROW
BEGIN
UPDATE billing
SET balance = amount_billed - amount_received
WHERE patient_id = NEW.patient_id;
END //
DELIMITER ;