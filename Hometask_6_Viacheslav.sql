# 1. Create a table with three columns. Name, surname, date of birth. Name the table "Customers."
create table  Customers (
						Name VARCHAR(50),
						Surname VARCHAR(50),
                        Date_of_birth DATE);
                        
       
#2. Place three entries in the "Customers" table

insert into Customers (Name, Surname, Date_of_birth)
values  ('John', 'Johns', '1984-05-27'),
		('Peter', 'Peters', '1967-11-05'),
		('Steven', 'Stevens', '1956-08-26');
		
        
#3. In the "Customers" table, delete the "Surname" column.

alter table Customers
drop column Surname; 

#4. Change the date of birth of John Johns to 01-01-1980

update Customers
set Date_of_birth = '1980-01-01'
where Name = "John"; 

#5. In the "Customers" table, delete all information about Steven Stevens.

delete from Customers
where Name = "Steven";

#6. Delete the "Customers" table.

drop table Customers;

                        


