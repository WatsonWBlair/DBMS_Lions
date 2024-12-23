--  Patients 表
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Gender VARCHAR(10),
    Age INT,
    PhoneNumber VARCHAR(15),
    Address VARCHAR(255)
);

--  Doctors 表
CREATE TABLE Doctors (
    DocID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Specialty VARCHAR(100),
    PhoneNumber VARCHAR(15),
    ExperienceYears INT
);

--  Appointments 表
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT NOT NULL,
    DocID INT NOT NULL,
    AppointmentDate DATE NOT NULL,
    Notes TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (DocID) REFERENCES Doctors(DocID) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

--  Prescriptions 表
CREATE TABLE Prescriptions (
    PrescriptionID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT NOT NULL,
    DocID INT NOT NULL,
    MedicationName VARCHAR(100),
    Dosage VARCHAR(50),
    Frequency VARCHAR(50),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (DocID) REFERENCES Doctors(DocID) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

--  Billing 表
CREATE TABLE Billing (
    BillID INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentStatus VARCHAR(20),
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO Patients (Name, Gender, Age, PhoneNumber, Address)
VALUES 
('leo', 'Male', 30, '1234567890', '123 street'),
('lu', 'Female', 25, '9876543210', '456 street'),
('Zhang San', 'Male', 45, '4561237890', '789 street'),
('Li Si', 'Female', 35, '3216549870', '321 street'),
('Wang Wu', 'Male', 40, '6547893210', '654 street');

INSERT INTO Doctors (Name, Specialty, PhoneNumber, ExperienceYears)
VALUES 
('Dr. A', 'Cardiology', '1112223333', 10),
('Dr. B', 'Dermatology', '4445556666', 8),
('Dr. C', 'Neurology', '7778889999', 12),
('Dr. D', 'Pediatrics', '1231231234', 6),
('Dr. E', 'Orthopedics', '9879879870', 15);

INSERT INTO Appointments (PatientID, DocID, AppointmentDate, Notes)
VALUES 
(1, 1, '2024-11-01', 'Routine check-up'),
(2, 3, '2024-11-05', 'Neurological assessment'),
(3, 2, '2024-11-10', 'Skin allergy treatment'),
(4, 4, '2024-11-15', 'Child vaccination'),
(5, 5, '2024-11-20', 'Joint pain consultation');

INSERT INTO Prescriptions (PatientID, DocID, MedicationName, Dosage, Frequency)
VALUES 
(1, 1, 'Aspirin', '100mg', 'Once a day'),
(2, 3, 'Ibuprofen', '200mg', 'Twice a day'),
(3, 2, 'Cetirizine', '10mg', 'Once a day'),
(4, 4, 'Amoxicillin', '500mg', 'Three times a day'),
(5, 5, 'Paracetamol', '500mg', 'Twice a day');

INSERT INTO Billing (AppointmentID, Amount, PaymentStatus)
VALUES 
(1, 200.00, 'Paid'),
(2, 300.00, 'Pending'),
(3, 150.00, 'Paid'),
(4, 250.00, 'Paid'),
(5, 400.00, 'Pending');