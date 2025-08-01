INSERT INTO player (ID, Name, Nationality, Birth_date, Titles) VALUES(1,'Djokovic', 'Serbia', '1987-05-22', 81);
INSERT INTO player (ID, Name, Nationality, Birth_date, Titles) VALUES(2,'Monfils', 'France', '1986-09-01', 10);
INSERT INTO player (ID, Name, Nationality, Birth_date, Titles) VALUES(3,'Isner', 'USA', '1985-04-26', 15);
-- Reset the ID sequence to start after our manual inserts
ALTER TABLE player ALTER COLUMN id RESTART WITH 4;
