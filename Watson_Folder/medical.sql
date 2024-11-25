
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS contact_info;
DROP TABLE IF EXISTS conditions;
DROP TABLE IF EXISTS doctor_type;

-- Main Tables
CREATE TABLE patients(
    patient_id int NOT NULL,
    age INT,
    gender ENUM('MALE', 'FEMAKE', 'OTHER') NOT NULL,
    patient_contact int NOT NULL,
    emergency_contact int NOT NULL,
    PRIMARY KEY (patient_id),
    FOREIGN KEY (emergency_contact) REFERENCES contact_info(contact_id),
    FOREIGN KEY (patient_contact) REFERENCES contact_info(contact_id)
)
CREATE TABLE doctors(
    doctor_id int NOT NULL,
    personal_statement varchar(255),
    photo VARBINARY(max),
    doctor_contact int NOT NULL,
    department int NOT NULL,
    doctor_type int NOT NULL,
    PRIMARY KEY (doctor_id),
    FOREIGN KEY (doctor_contact) REFERENCES contact_info(contact_id)
    FOREIGN KEY (department) REFERENCES department(department_id),
    FOREIGN KEY (doctor_type) REFERENCES doctor_type(doc_type_id),
)
CREATE TABLE invoices(
    invoice_id int NOT NULL,
    amount_billed int NOT NULL,
    amount_received int NOT NULL,
    appointment_id int NOT NULL,
    doctor_id int NOT NULL,
    patient_id int NOT NULL,
    PRIMARY KEY (invoice_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
)
CREATE TABLE appointments(
    date_time DATETIME NOT NULL,
    location varchar(255) NOT NULL,
    patient_id int NOT NULL,
    patient_notes varchar(255),
    doctor_id int NOT NULL,
    doctor_notes varchar(255),
    PRIMARY KEY (patient_id, doctor_id, date_time),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
)
CREATE TABLE prescriptions(
    prescription_id int NOT NULL,
    name varchar(255) NOT NULL,
    dosage varchar(255) NOT NULL,
    instructions varchar(255) NOT NULL,
    is_active BOOLEAN NOT NULL,
    patient_id int NOT NULL,
    doctor_id int NOT NULL,
    PRIMARY KEY (prescription_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
)

-- normalization tables
CREATE TABLE department(
    dep_id int NOT NULL,
    dep_head int NOT NULL,
    dep_location varchar(255),
    dep_name varchar(255),
    dep_description varchar(255) NOT NULL,
    PRIMARY KEY (departmewnt_id),
    FOREIGN KEY (dep_head) REFERENCES doctors(doctor_id)
)
CREATE TABLE contact_info(
    contact_id int NOT NULL,
    f_name varchar(255) NOT NULL,
    m_name varchar(255) NOT NULL,
    l_name varchar(255) NOT NULL,
    address varchar(255) NOT NULL,
    phone varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    PRIMARY KEY (contact_id)
)
CREATE TABLE conditions(
    condition_id int NOT NULL,
    patient_id int NOT NULL,
    condition_name varchar(255) NOT NULL,
    condition_notes varchar(255) NOT NULL,
    PRIMARY KEY (condition_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)

)
CREATE TABLE doctor_type(
    doc_type_id int NOT NULL,
    type_name varchar(255) NOT NULL,
    type_description varchar(255) NOT NULL,
    PRIMARY KEY (doc_type_id)
)
