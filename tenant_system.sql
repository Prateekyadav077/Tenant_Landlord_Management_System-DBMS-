CREATE DATABASE tenant_System1;
USE tenant_System1;
CREATE TABLE Users (
    User_id INT PRIMARY KEY AUTO_INCREMENT,
    FName VARCHAR(50) NOT NULL,
    LName VARCHAR(50) NOT NULL,
    Gender ENUM('Male','Female','Other') NOT NULL,
    Contact VARCHAR(15) UNIQUE NOT NULL,
    Id_proof VARCHAR(50) NOT NULL
);
CREATE TABLE Login (
    Login_id INT PRIMARY KEY AUTO_INCREMENT,
    User_id INT NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FOREIGN KEY (User_id)
    REFERENCES Users(User_id)
);
CREATE TABLE Landlord (
    User_id INT PRIMARY KEY,
    FOREIGN KEY (User_id)
    REFERENCES Users(User_id)
);
CREATE TABLE Tenant (
    User_id INT PRIMARY KEY,
    FOREIGN KEY (User_id)
    REFERENCES Users(User_id)
);
CREATE TABLE Property (
    P_Id INT PRIMARY KEY AUTO_INCREMENT,
    Address VARCHAR(150) NOT NULL,
    Capacity INT NOT NULL,
    Rent_amount DECIMAL(10,2) NOT NULL,
    Availability_status ENUM('Available','Occupied')
    DEFAULT 'Available',

    Landlord_id INT NOT NULL,

    FOREIGN KEY (Landlord_id)
    REFERENCES Landlord(User_id)
);
CREATE TABLE Payment (
    Payment_id INT PRIMARY KEY AUTO_INCREMENT,

    Tenant_id INT NOT NULL,
    P_Id INT NOT NULL,

    Amount DECIMAL(10,2) NOT NULL,

    Status ENUM('Paid','Pending')
    DEFAULT 'Pending',

    Rent_Month DATE NOT NULL,

    Payment_date DATE,

    FOREIGN KEY (Tenant_id)
    REFERENCES Tenant(User_id),

    FOREIGN KEY (P_Id)
    REFERENCES Property(P_Id)
);
CREATE TABLE Allocated_To (
    Tenant_id INT NOT NULL,
    P_Id INT NOT NULL,

    Checkin_date DATE NOT NULL,
    Leased_time INT NOT NULL,

    PRIMARY KEY (Tenant_id,P_Id),

    FOREIGN KEY (Tenant_id)
    REFERENCES Tenant(User_id),

    FOREIGN KEY (P_Id)
    REFERENCES Property(P_Id)
);
DELIMITER //

CREATE TRIGGER after_allocation
AFTER INSERT ON Allocated_To
FOR EACH ROW
BEGIN

    UPDATE Property
    SET Availability_status='Occupied'
    WHERE P_Id=NEW.P_Id;

END//

DELIMITER ;
DELIMITER //

CREATE TRIGGER before_payment_insert
BEFORE INSERT ON Payment
FOR EACH ROW
BEGIN

    IF NEW.Payment_date IS NOT NULL THEN
        SET NEW.Status='Paid';
    END IF;

END//

DELIMITER ;
DELIMITER //

CREATE PROCEDURE AddPayment(
    IN t_id INT,
    IN p_id INT,
    IN amt DECIMAL(10,2),
    IN rent_month DATE,
    IN pay_date DATE
)
BEGIN

    INSERT INTO Payment
    (
        Tenant_id,
        P_Id,
        Amount,
        Payment_date,
        Rent_Month
    )
    VALUES
    (
        t_id,
        p_id,
        amt,
        pay_date,
        rent_month
    );

END//

DELIMITER ;
DELIMITER //

CREATE PROCEDURE GetTenantSummary(
    IN t_id INT
)
BEGIN

SELECT
    U.FName,
    U.LName,
    P.Address,
    Pay.Amount,
    Pay.Status,
    Pay.Rent_Month
FROM Payment Pay
JOIN Users U
ON Pay.Tenant_id=U.User_id
JOIN Property P
ON Pay.P_Id=P.P_Id
WHERE Pay.Tenant_id=t_id;

END//

DELIMITER ;
CREATE VIEW Tenant_Payment_Report AS

SELECT

    U.User_id,
    CONCAT(U.FName,' ',U.LName)
    AS Tenant_Name,

    P.Address,

    Pay.Amount,
    Pay.Status,
    Pay.Rent_Month,
    Pay.Payment_date

FROM Payment Pay

JOIN Users U
ON Pay.Tenant_id=U.User_id

JOIN Property P
ON Pay.P_Id=P.P_Id;
INSERT INTO Users
(FName,LName,Gender,Contact,Id_proof)
VALUES

('Rajesh','Kumar','Male',
'9876543210','Aadhar123'),

('Priya','Sharma','Female',
'9876543211','Aadhar124'),

('Amit','Singh','Male',
'9876543212','Aadhar125'),

('Sneha','Verma','Female',
'9876543213','Aadhar126');
INSERT INTO Landlord VALUES(1);

INSERT INTO Tenant VALUES(2);
INSERT INTO Tenant VALUES(3);
INSERT INTO Tenant VALUES(4);
INSERT INTO Property
(
Address,
Capacity,
Rent_amount,
Landlord_id
)
VALUES

('MG Road Patiala',2,8000,1),

('Civil Lines Patiala',3,12000,1),

('Model Town Patiala',1,6000,1);

INSERT INTO Login (User_id, PasswordHash)
VALUES
(1,'hash1'),
(2,'hash2'),
(3,'hash3'),
(4,'hash4');
INSERT INTO Allocated_To
VALUES

(2,1,'2025-01-01',12),

(3,2,'2025-02-01',6);
INSERT INTO Payment
(
Tenant_id,
P_Id,
Amount,
Rent_Month,
Payment_date
)
VALUES

(2,1,8000,'2025-01-01','2025-01-05'),

(2,1,8000,'2025-02-01','2025-02-05'),

(3,2,12000,'2025-02-01','2025-02-07');

SELECT
U.FName,
U.LName,
P.Address,
Pay.Amount,
Pay.Status

FROM Payment Pay

JOIN Users U
ON Pay.Tenant_id=U.User_id

JOIN Property P
ON Pay.P_Id=P.P_Id;

SELECT Address

FROM Property

WHERE P_Id IN

(
SELECT P_Id
FROM Payment
WHERE Status='Pending'
);

SELECT

P.Address,

SUM(Pay.Amount)
AS Total_Rent_Collected,

COUNT(Pay.Payment_id)
AS Number_Of_Payments

FROM Payment Pay

JOIN Property P
ON Pay.P_Id=P.P_Id

WHERE Pay.Status='Paid'

GROUP BY P.Address;

SELECT *
FROM Tenant_Payment_Report;

CALL GetTenantSummary(2);

CALL AddPayment
(
2,
1,
8000,
'2025-03-01',
'2025-03-05'
);

START TRANSACTION;

INSERT INTO Payment
(
Tenant_id,
P_Id,
Amount,
Rent_Month,
Payment_date
)
VALUES
(
2,
1,
8000,
'2025-04-01',
'2025-04-05'
);

COMMIT;

START TRANSACTION;

INSERT INTO Payment
(
Tenant_id,
P_Id,
Amount,
Rent_Month
)
VALUES
(
2,
1,
8000,
'2025-05-01'
);

ROLLBACK;
