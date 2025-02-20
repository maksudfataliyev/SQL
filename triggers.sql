1.

CREATE TRIGGER LIMITFORSTUDENTS
ON Student
INSTEAD OF INSERT
AS
BEGIN
    IF (SELECT COUNT(*) FROM Student WHERE GroupId = (SELECT GroupId FROM inserted)) >= 30
    BEGIN
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Student (Id, Name, GroupId)
        SELECT Id, Name, GroupId FROM inserted;
    END
END;



2.

 

CREATE TRIGGER UPDATECOUNTOFSTUDENTS
ON Student
AFTER INSERT, DELETE
AS
BEGIN
    UPDATE [Group]
    SET StudentsCount = (SELECT COUNT(*) FROM Student WHERE GroupId = [Group].Id);
END;



3.



CREATE TRIGGER ENROLLINGINTOCOURSE
ON Student
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Course WHERE Name = 'Введение в программирование')
    BEGIN
        INSERT INTO Enrollment (StudentId, CourseId)
        SELECT I.Id, C.Id FROM inserted I, Course C WHERE C.Name = 'Введение в программирование';
    END
END;



4.


CREATE TRIGGER BADGRADEALERT
ON Grade
AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO Warnings (StudentId, Reason, Date)
    SELECT StudentId, 'Низкая оценка', GETDATE()
    FROM inserted
    WHERE Grade < 3;
END;



5. 



CREATE TRIGGER PREVENTREMOVINGATEACHER
ON Teacher
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Course WHERE TeacherId IN (SELECT Id FROM Removed))
    BEGIN
        ROLLBACK;
    END
    ELSE
    BEGIN
        DELETE FROM Teacher WHERE Id IN (SELECT Id FROM Removed);
    END
END;




6.



CREATE TRIGGER HISTORYOFGRADES
ON Grade
AFTER UPDATE
AS
BEGIN
    INSERT INTO GradeHistory (StudentId, CourseId, OldGrade, NewGrade, ChangeDate)
    SELECT D.StudentId, D.CourseId, D.Grade, I.Grade, GETDATE()
    FROM Removed D
    JOIN inserted I ON D.StudentId = I.StudentId AND D.CourseId = I.CourseId;
END;




7.



CREATE TRIGGER CHECKATTENDANCE
ON Attendance
AFTER INSERT
AS
BEGIN
    INSERT INTO RetakeList (StudentId)
    SELECT StudentId FROM (
        SELECT StudentId, COUNT(*) AS MissedCount
        FROM Attendance
        WHERE Status = 'Пропущено'
        GROUP BY StudentId
        HAVING COUNT(*) > 5
    ) AS Retaker
END;



8.



CREATE TRIGGER PREVENTSTUDENTFROMBEINGDELETED
ON Student
INSTEAD OF DELETE
AS 
BEGIN
    IF EXISTS (
        SELECT 1 FROM Payments WHERE StudentId IN (SELECT Id FROM Deleted) AND Status = 'Не оплачено'
    ) OR EXISTS (
        SELECT 1 FROM Grade WHERE StudentId IN (SELECT Id FROM Deleted) AND Grade < 4.5
    )
    BEGIN
        ROLLBACK;
    END
    ELSE
    BEGIN
        DELETE FROM Student WHERE Id IN (SELECT Id FROM Deleted);
    END
END;


9.



CREATE TRIGGER UPDATEGPA
ON Grade
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Student
    SET AverageGrade = (SELECT AVG(Grade) FROM Grade WHERE StudentId = Student.Id);
END;
