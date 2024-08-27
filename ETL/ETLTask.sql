CREATE TABLE Employee_Source (
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Position NVARCHAR(100),
    Salary DECIMAL(18, 2),
    UpdatedOn DATETIME DEFAULT GETDATE()
);

CREATE TABLE Employee_Target (
    TargetID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    Name NVARCHAR(100),
    Position NVARCHAR(100),
    Salary DECIMAL(18, 2),
    IsDeleted BIT DEFAULT 0,
    UpdatedOn DATETIME DEFAULT GETDATE()
);

INSERT INTO Employee_Source (EmployeeID, Name, Position, Salary)
VALUES 
    (1, 'Aslam', 'Software Engineer', 60000),
    (2, 'Tyson', 'Data Analyst', 55000),
    (3, 'Arnold', 'Manager', 75000),
    (4, 'ALI', 'UX Designer', 65000),
    (5, 'Spider', 'DevOps', 70000);

-- The Procedure
CREATE or ALTER PROCEDURE LoadEmployeeData
AS
BEGIN
 INSERT INTO Employee_Target (EmployeeID, Name, Position, Salary, UpdatedOn)
 SELECT EmployeeID, Name, Position, Salary, UpdatedOn
 FROM Employee_Source
 WHERE EmployeeID NOT IN (SELECT EmployeeID FROM Employee_Target);

INSERT INTO Employee_Target (EmployeeID, Name, Position, Salary, UpdatedOn)
SELECT src.EmployeeID, src.Name, src.Position, src.Salary, GETDATE() AS UpdatedOn
FROM Employee_Source AS src
JOIN (SELECT trg.EmployeeID, trg.Name, trg.Position, trg.Salary, trg.UpdatedOn
    FROM (
        SELECT EmployeeID, Name, Position, Salary, UpdatedOn,
               ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY UpdatedOn DESC) AS rn
        FROM Employee_Target
    ) AS trg
    WHERE trg.rn = 1) as trg_latest ON src.EmployeeID = trg_latest.EmployeeID
WHERE src.Name != trg_latest.Name OR src.Position != trg_latest.Position OR src.Salary != trg_latest.Salary;

UPDATE Employee_Target
SET IsDeleted = 1, UpdatedOn = GETDATE()
WHERE EmployeeID NOT IN (SELECT EmployeeID FROM Employee_Source);
END

execute LoadEmployeeData

CREATE TRIGGER insert_trigger
ON Employee_Source
AFTER INSERT
AS
BEGIN
    EXEC LoadEmployeeData;
END;

CREATE TRIGGER update_trigger
ON Employee_Source
AFTER UPDATE
AS
BEGIN
    EXEC LoadEmployeeData;
END;

CREATE TRIGGER delete_trigger
ON Employee_Source
AFTER DELETE
AS
BEGIN
    EXEC LoadEmployeeData;
END;


-- Select 
select * from Employee_Source;
select * from Employee_Target;


-- Operations
insert into Employee_Source (EmployeeID, Name, Position, Salary) values (10, 'John Wick', 'Software Engineer', 60000)
update Employee_Source set Name = 'aslam' where EmployeeID = 10
delete from Employee_Source where EmployeeID = 10