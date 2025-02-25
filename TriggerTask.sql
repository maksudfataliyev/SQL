CREATE DATABASE CarDealership;
GO
USE CarDealership;
GO

CREATE TABLE Customers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Phone NVARCHAR(20) NOT NULL
);

CREATE TABLE Cars (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Brand NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    Year INT CHECK (Year >= 2000),
    Price DECIMAL(10,2) CHECK (Price > 0)
);

CREATE TABLE Orders (
    Id INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT FOREIGN KEY REFERENCES Customers(Id) ON DELETE CASCADE,
    CarId INT FOREIGN KEY REFERENCES Cars(Id) ON DELETE CASCADE,
    OrderDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE CarPriceHistory (
    Id INT PRIMARY KEY IDENTITY(1,1),
    CarId INT FOREIGN KEY REFERENCES Cars(Id) ON DELETE CASCADE,
    OldPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2),
    ChangeDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE DeletedOrdersLog (
    Id INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT,
    CustomerId INT,
    CarId INT,
    OrderDate DATETIME,
    DeletedAt DATETIME DEFAULT GETDATE()
);


INSERT INTO Customers (Name, Email, Phone) VALUES
('Иван Петров', 'ivan.petrov@email.com', '123-456-789'),
('Мария Сидорова', 'maria.sidorova@email.com', '987-654-321'),
('Алексей Смирнов', 'alex.smirnov@email.com', '555-666-777');

INSERT INTO Cars (Brand, Model, Year, Price) VALUES
('Toyota', 'Camry', 2022, 30000),
('BMW', 'X5', 2023, 60000),
('Mercedes', 'C-Class', 2021, 50000);

INSERT INTO Orders (CustomerId, CarId) VALUES
(1, 1),
(2, 2),
(3, 3);



1.


CREATE TRIGGER CarPriceUpdate_TRIGGER
ON Cars
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Price)
    BEGIN
        INSERT INTO CarPriceHistory (CarId, OldPrice, NewPrice, ChangeDate)
        SELECT D.Id, D.Price, I.Price, GETDATE()
        FROM DELETED D
        JOIN INSERTED I ON D.Id = D.Id
        WHERE D.Price != I.Price;
    END
END;

2.


CREATE TRIGGER PreventCustomerDeletion_TRIGGER
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Orders O
        JOIN DELETED D ON O.CustomerId = D.Id
    )
    BEGIN
        RETURN;
    END
    DELETE FROM Customers WHERE Id IN (SELECT Id FROM DEETED);
END;


3.

CREATE TRIGGER LogDeletedOrders_TRIGGER
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    INSERT INTO DeletedOrdersLog (OrderId, CustomerId, CarId, OrderDate, DeletedAt)
    SELECT Id, CustomerId, CarId, OrderDate, GETDATE()
    FROM DELETED;

    DELETE FROM Orders WHERE Id IN (SELECT Id FROM deleted);
END;


4.


CREATE TRIGGER AutoUpdatePrice_TRIGGER
ON Cars
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Year)
    BEGIN
        UPDATE Cars
        SET Price = Price * 0.95
        FROM Cars C
        JOIN INSETED I ON C.Id = I.Id
        WHERE I.Year <> (SELECT Year FROM DELETED WHERE Id = I.Id);
    END
END;


5.


CREATE TRIGGER PreventDuplicateOrders_TRIGGR
ON Orders
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Orders O
        JOIN INSETED I ON O.CustomerId = I.CustomerId AND O.CarId = I.CarId
        GROUP BY O.CustomerId, O.CarId
        HAVING COUNT(*) > 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
    END
END;
