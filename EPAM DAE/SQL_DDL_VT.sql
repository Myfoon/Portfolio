/* Task 1 . Develop a database to track and manage the workloads, capacities, and operations of healthcare facilities within our city. 

The database should include information about each institution, such as their location, staff, available resources, capabilities (the amount of patients that given institution can handle daily), 
and records of patient visits.

Your database must be in 3NF and includes 6+ tables
Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
Create relationships between tables using primary and foreign keys.
Apply three check constraints (including NOT NULL) across the tables to restrict certain values
Populate the tables with the sample data generated, ensuring each table has at least 5+ rows (for a total of 30+ rows in all the tables) for the last 3 months. */



/*As a step 0 zero before running the script, please create database with following query:
 
CREATE DATABASE healthcare_facilities;

Having database created, please create new connection*/

--Let's assume that our city is Vilnius. 


--DROP SCHEMA IF EXISTS healthcare_facilities CASCADE;             --Please uncomment if you want to delete schema first
CREATE SCHEMA IF NOT EXISTS healthcare_facilities;


-----------------------------------------------------------------------------1.FACILITY_TYPE------------------------------------------------------------
DROP TABLE IF EXISTS healthcare_facilities.facility_type CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.facility_type (
    facility_type_id INT2 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,          --Hereinafter I use INT GENERATED ALWAYS AS IDENTITY instead of SERIAL  
    type_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO healthcare_facilities.facility_type (type_name)
VALUES('hospital'),
      ('orthopedic center'),
      ('blood bank'),
      ('outpatient clinic'),
      ('dental clinic')
ON CONFLICT DO NOTHING      
RETURNING *;

-----------------------------------------------------------------------------2.FACILITIES--------------------------------------------------------------
--Facility main departments are presented in this table 

DROP TABLE IF EXISTS healthcare_facilities.facilities CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.facilities (
    facility_id INT2 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    facility_name VARCHAR(100) NOT NULL UNIQUE,                             --We don't have healthcare facilities with the same name in one city
    address VARCHAR(255) NOT NULL,                                          --Potentially there can be several facilities in one bulding 
    phone VARCHAR(12) NOT NULL UNIQUE,
    facility_type_id INT2 REFERENCES healthcare_facilities.facility_type
);

INSERT INTO healthcare_facilities.facilities (facility_name, address, phone, facility_type_id)
SELECT 'Antakalnio poliklinika',
      'Antakalnio 59',
      '852342515',
      (SELECT facility_type_id 
       FROM healthcare_facilities.facility_type
       WHERE type_name = 'outpatient clinic')
UNION ALL
SELECT 'Šeškinės poliklinika',
      'Šeškinės 24',
      '+37052502000',
      (SELECT facility_type_id 
       FROM healthcare_facilities.facility_type
       WHERE type_name = 'outpatient clinic')
UNION ALL
SELECT 'Saulėtekio klinika',
      'Antakalnio 38',
      '852105488',
      (SELECT facility_type_id 
       FROM healthcare_facilities.facility_type
       WHERE type_name = 'dental clinic')
UNION ALL
SELECT 'Vilnius city clinical hospital',
      'Antakalnio 57',
      '+3702344519',
      (SELECT facility_type_id 
       FROM healthcare_facilities.facility_type
       WHERE type_name = 'hospital')
UNION ALL
SELECT 'National Blood Center',
      'Žolyno 34',
      '852392444',
      (SELECT facility_type_id 
       FROM healthcare_facilities.facility_type
       WHERE type_name = 'blood bank')
ON CONFLICT DO NOTHING      
RETURNING *;

-----------------------------------------------------------------------------3.STAFF--------------------------------------------------------------
--For simplicity I will consider only doctors in this table. I assume that doctor is not attached to one certain facility.
   
DROP TABLE IF EXISTS healthcare_facilities.staff CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.staff (              
    staff_id INT4 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    email VARCHAR(60) NOT NULL UNIQUE
);

INSERT INTO healthcare_facilities.staff (first_name, last_name, specialization, email)
VALUES ('Tomas', 'Ponas', 'physician', 'tom_pon@gmail.com'),
       ('Donatas', 'Vaikus', 'radiologist', 'don122@gmail.com'),
       ('Egle', 'Auskaite', 'dentist', 'egle.dent@klinika.com'),
       ('Alex', 'Weimer', 'radiologist', 'w.alex@gmail.com'),
       ('Petra', 'Svetlova', 'gastroenterologist', 'petra.svetl@gmail.com')
ON CONFLICT DO NOTHING      
RETURNING *;       
-----------------------------------------------------------------------------4.RESOURCES--------------------------------------------------------------
DROP TABLE IF EXISTS healthcare_facilities.resources CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.resources (
    resource_id INT2 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    facility_id INT2 NOT NULL REFERENCES healthcare_facilities.facilities,
    resource_name VARCHAR(100) NOT NULL,
    UNIQUE (facility_id, resource_name),
    quantity INT2 NOT NULL
);

INSERT INTO healthcare_facilities.resources (facility_id, resource_name, quantity)
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ANTAKALNIO POLIKLINIKA'),
       'ultrasound scanner',
       12
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       'MRI scanner',
       3
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'SAULĖTEKIO KLINIKA'),
       'dental x-ray',
       2
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'NATIONAL BLOOD CENTER'),
       'plasmolifting centrifuge',
       4
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       'endoscope',
       20
ON CONFLICT DO NOTHING      
RETURNING *;  

-----------------------------------------------------------------------------5.PATIENTS--------------------------------------------------------------
--I assume that patient is not attached to one certain facility.
   
DROP TABLE IF EXISTS healthcare_facilities.patients CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.patients (
    patient_id INT4 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    birth_date DATE NOT NULL,
    sex VARCHAR (6) NOT NULL CHECK (sex IN ('male','female')), 
    phone VARCHAR(12) NOT NULL UNIQUE,     
    email VARCHAR(60) UNIQUE,                                    --Let's say not every patient has email, but every patient has phone number
    clinical_history TEXT
);

INSERT INTO healthcare_facilities.patients(first_name, last_name, birth_date, sex, phone, email, clinical_history)
VALUES 
    ('John', 'Doe', '1991-11-02', 'male', '1234567890', 'john.doe@example.com', 'Fever'),
    ('Jane', 'Smith', '1981-02-22','female', '9876543210', 'jane.smith@example.com', 'Headache'),
    ('Michael', 'Johnson', '1972-03-02', 'male', '5555555322', 'michael.johnson@example.com','Sprained ankle'),
    ('Emily', 'Brown', '1959-10-27', 'female', '7772147777', NULL, 'Sore throat'),
    ('David', 'Wilson', '1993-05-26', 'male', '9999993122', 'david.wilson@example.com','Broken arm')
ON CONFLICT DO NOTHING      
RETURNING *;


-----------------------------------------------------------------------------6.BRANCHES--------------------------------------------------------------
--Let's say facilities can have one or several branches in addition to the main department (but it is not mandatory).   

DROP TABLE IF EXISTS healthcare_facilities.branches CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.branches (
    branch_id INT2 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    facility_id INT2 REFERENCES healthcare_facilities.facilities,
    latitude DECIMAL(7, 5) NOT NULL CHECK(latitude BETWEEN 54.47 AND 54.87),              --As far as our city is Vilnius, we can add such constraint
    longitude DECIMAL(7, 5) NOT NULL CHECK(longitude BETWEEN 24.97 AND 25.53),
    UNIQUE (latitude, longitude),
    max_capacity INT2 NOT NULL
);

INSERT INTO healthcare_facilities.branches (facility_id, latitude, longitude, max_capacity)
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       54.54211,
       25.02311,
       500
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       54.71211,
       25.19311,
       300
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'SAULĖTEKIO KLINIKA'),
       54.49211,
       25.22311,
       200
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'NATIONAL BLOOD CENTER'),
       54.48211,
       25.28311,
       250
UNION ALL
SELECT (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       54.69211,
       25.42311,
       120
ON CONFLICT DO NOTHING      
RETURNING *; 
-----------------------------------------------------------------------------7.VISIT_TYPE---------------------------------------------------------------------
DROP TABLE IF EXISTS healthcare_facilities.visit_type CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.visit_type (
    visit_type_id INT2 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    visit_type_name VARCHAR(40) NOT NULL UNIQUE
);    

INSERT INTO healthcare_facilities.visit_type (visit_type_name)
VALUES ('planned visit'),
       ('urgent visit'),
       ('preventive checkup'),
       ('scheduled surgery'),
       ('vaccination')
ON CONFLICT DO NOTHING      
RETURNING *; 

-----------------------------------------------------------------------------8.VISITS---------------------------------------------------------------------------

/*As it was already mentioned, patients and doctors in my DB are not tied to a single institution, so it appears that we have following many-to-many relations:
 patients-doctors, doctors-facilities and patients-facilities. To implement them, it is nice to use table "visits" because every visit has its patient, doctor and facility, and moreover 
 we can add some details about the visit itself in this table*/ 

DROP TABLE IF EXISTS healthcare_facilities.visits CASCADE;

CREATE TABLE IF NOT EXISTS healthcare_facilities.visits (
    visit_id INT4 GENERATED ALWAYS AS IDENTITY PRIMARY KEY,                 --We cannot use combination of (patient_id, staff_id, facility_id) as PK - this combo can have duplicates 
    patient_id INT4 NOT NULL REFERENCES healthcare_facilities.patients,
    staff_id INT4 NOT NULL REFERENCES healthcare_facilities.staff,
    facility_id INT2 NOT NULL REFERENCES healthcare_facilities.facilities,
    UNIQUE (patient_id, visit_date),                                           --Of course it is possible to add also UNIQUE (staff_id, visit_date) and maybe some more constraints 
    visit_type_id INT4 NOT NULL REFERENCES healthcare_facilities.visit_type,
    visit_results TEXT NOT NULL,
    visit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

INSERT INTO healthcare_facilities.visits (patient_id, staff_id, facility_id, visit_type_id, visit_results, visit_date)
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JOHN DOE 1991-11-02'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'PETRA SVETLOVA GASTROENTEROLOGIST'),
 /*Hereinafter I assume that it is enough to have (first name, last name, specialization) to unambiguously identify a doctor since we're talking about relatively small city of Vilnius.
  Of course, it is possible to add doctor's email in this combination if necessary */
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ANTAKALNIO POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'PLANNED VISIT'),
       'Recommended changing medications from A to B',
       '2024-03-05 12:15'::TIMESTAMP                                  --As far as we have some historical data, I put in visit date manually, despite of having DEFAULT CURRENT_TIMESTAMP
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JOHN DOE 1991-11-02'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'EGLE AUSKAITE DENTIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'SAULĖTEKIO KLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'PREVENTIVE CHECKUP'),
       'Recommended comprehensive oral hygiene',
       '2024-03-15 10:15'::TIMESTAMP
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JANE SMITH 1981-02-22'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'PLANNED VISIT'),
       'Preliminary diagnosis: cholecystitise. CT recommended for confirmation',
       '2024-03-15 12:23'::TIMESTAMP
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'EMILY BROWN 1959-10-27'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-03-23 11:37'::TIMESTAMP       
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'DAVID WILSON 1993-05-26'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'TOMAS PONAS PHYSICIAN'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'VACCINATION'),
       'First dose of encephalitis vaccine',
       '2024-03-19 15:41'::TIMESTAMP        

UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'DAVID WILSON 1993-05-26'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-03-23 11:37'::TIMESTAMP 
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JOHN DOE 1991-11-02'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-03-23 11:37'::TIMESTAMP 
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'MICHAEL JOHNSON 1972-03-02'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-03-23 11:37'::TIMESTAMP 

       
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JANE SMITH 1981-02-22'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'VILNIUS CITY CLINICAL HOSPITAL'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'PLANNED VISIT'),
       'Preliminary diagnosis: cholecystitise. CT recommended for confirmation',
       '2024-04-01 10:23'::TIMESTAMP
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'EMILY BROWN 1959-10-27'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-04-01 11:37'::TIMESTAMP       
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'DAVID WILSON 1993-05-26'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-04-01 12:45'::TIMESTAMP 
UNION ALL
SELECT (SELECT patient_id 
       FROM healthcare_facilities.patients
       WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'JOHN DOE 1991-11-02'),
       (SELECT staff_id 
       FROM healthcare_facilities.staff
       WHERE UPPER(first_name||' '||last_name||' '||specialization) = 'ALEX WEIMER RADIOLOGIST'),
       (SELECT facility_id 
       FROM healthcare_facilities.facilities
       WHERE UPPER(facility_name) = 'ŠEŠKINĖS POLIKLINIKA'),
       (SELECT visit_type_id 
       FROM healthcare_facilities.visit_type
       WHERE UPPER(visit_type_name) = 'URGENT VISIT'),
       'Hospitalization with further examination required',
       '2024-04-01 13:37'::TIMESTAMP      
ON CONFLICT DO NOTHING      
RETURNING *;       
 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
--Task 2. Write a sql query. Find doctors who have had a workload of fewer than 5 patients per each month over the last two months (current and previous).

 /*I assume that we can deal here with visits rather than with patients, because one doctor can have 5 visits of the same patient and I won't say that his workload in such case will be lower than 
  in case with 5 different patients. Nevertheless, if we are really intersted in the number of unique patients, we can use COUNT (DISTINCT patient_id).
   
  As I understood from discussion in Teams, if the doctor had less than 5 visits in one month, it is already enough to qualify him in our group.
  
  Of course, things become tricky in situations when certain doctor had zero visits in one or both months.  
  Obvious drawback of my solution: in case when doctor had 0 visits in one month and non-zero visits in other, we will see only the month with non-zero result.  
  On the other hand, we still can answer the question, because we can assume that if doctor is not presented for certain month it means he had 0 visits in that month. 
  It is also not great that in case when the doctor had zero visits in both months (as Donas Vaikus in my case) it is indicated as 0 visits in last month, but again maybe we can agree 
  that when we see 0 in visits_count, it automatically means 0 visits in every month.  
   **/
  
WITH all_doctors AS (
    SELECT
        staff_id,
        first_name||' '||last_name AS doctor_name
    FROM
        healthcare_facilities.staff
)
SELECT
    ad.staff_id,
    ad.doctor_name,
    COALESCE(COUNT(v.visit_id), 0) AS visits_count,
    DATE_TRUNC('month', COALESCE(v.visit_date, CURRENT_DATE)) AS visit_month
FROM
    all_doctors ad
LEFT JOIN
    healthcare_facilities.visits v ON ad.staff_id = v.staff_id
    AND v.visit_date >= CURRENT_DATE - INTERVAL '2 months'
    AND v.visit_date <= CURRENT_DATE
GROUP BY
    ad.staff_id, ad.doctor_name, DATE_TRUNC('month', COALESCE(v.visit_date, CURRENT_DATE))
HAVING COALESCE(COUNT(v.visit_id), 0) < 5                                                   --If we change the threshold from 5 to 6, we will see also Alex Weimer for March   
    
    

