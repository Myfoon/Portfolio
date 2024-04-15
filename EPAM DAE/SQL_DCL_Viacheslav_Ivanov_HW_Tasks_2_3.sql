/* Task 2. 
1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
3. Create a new user group called "rental" and add "rentaluser" to the group. 
4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
5. Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
6. Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
The customer's payment and rental history must not be empty. */


/*Create a new user with the username "rentaluser" and the password "rentalpassword": */
CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';

/*Use this command to check if new role is created: */
SELECT * FROM pg_catalog.pg_user;

/*Give the user the ability to connect to the database but no other permissions: */
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

/*We can use this to check if our new role got CONNECT permission: */
SELECT rolname, rolcanlogin
FROM pg_roles;

/*Grant "rentaluser" SELECT permission for the "customer" table: */
GRANT SELECT ON TABLE customer TO rentaluser;

/*We can use this command to check if our new role got SELECT permission on certain table: */
SELECT *
FROM information_schema.role_table_grants
WHERE grantee = 'rentaluser';

/*We need to change current role: */
SET ROLE rentaluser;

/*Let's check our current role: */
SELECT CURRENT_USER;

/*Following query works. If we try to select from different table, we will get an error*/
SELECT first_name||' '||last_name AS full_name
FROM customer;

/*Create a new user group called "rental" and add "rentaluser" to the group. */

/*First of all, lets reset our role to postgres: */
RESET ROLE;

/*Then we can create a new user group called "rental" and add "rentaluser" to this group: */
CREATE ROLE rental;
GRANT rental TO rentaluser;

/*Grant the "rental" group INSERT and UPDATE permissions for the "rental" table: */
GRANT UPDATE, INSERT ON TABLE rental TO rental;

/*We can check if role "rental" got necessary permissions on table "rental": */
SELECT *
FROM information_schema.role_table_grants
WHERE grantee = 'rental';


/*Insert a new row and update one existing row in the "rental" table under that role. */
SET ROLE rental;


/*In order to INSERT new row without hardcoding, I have to grant also following permissions: */
GRANT SELECT ON TABLE film, customer, staff, rental, inventory TO rental;
GRANT USAGE, SELECT ON SEQUENCE rental_rental_id_seq TO rental;

/*Check the permissions: */
SELECT *
FROM information_schema.role_table_grants
WHERE grantee = 'rental';


/*INSERT new row (this part is basically taken from DML homework):*/
WITH film_title_inventory AS                --CTE just to have film titles and inventory_ids in one table
(
SELECT MIN(inventory_id) AS inventory_id, f.title
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
GROUP BY f.title
),
   
my_customer_id AS                           --CTE to get my customer_id
(
SELECT customer_id
FROM customer
WHERE UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV'
)
        
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT '2024-04-02 12:22:21.156'::TIMESTAMPTZ,               --inserting rental_date

(SELECT inventory_id                                         --inserting inventory_id of certain film
 FROM film_title_inventory
 WHERE UPPER(title) = 'ACADEMY DINOSAUR'),
 
(SELECT customer_id                                          --inserting my customer_id
 FROM my_customer_id),

(SELECT staff_id                                              --Inserting staff_id (I suppose we know name of the person when we rent a film)
FROM staff 
WHERE UPPER(first_name||' '||last_name) = 'MIKE HILLYER')
ON CONFLICT DO NOTHING
RETURNING rental_date, inventory_id, customer_id, return_date, staff_id;


/*UPDATE one existing row:*/
WITH certain_customer_who_rented_certain_film AS                           
(
SELECT DISTINCT	c.customer_id, r.inventory_id
FROM customer c 
INNER JOIN rental r ON c.customer_id = r.customer_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film f ON f.film_id = i.film_id
WHERE UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV'
      AND UPPER(f.title) = 'THE MATRIX'
)

UPDATE rental
SET
	return_date = '2024-04-04 10:22:21.156'::TIMESTAMPTZ                    
WHERE customer_id = (SELECT customer_id 
                     FROM certain_customer_who_rented_certain_film) 
AND inventory_id = (SELECT inventory_id 
                    FROM certain_customer_who_rented_certain_film)
RETURNING rental_date, inventory_id, customer_id, return_date, staff_id;


/*Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.*/

/*First, reset role: */
RESET ROLE;

REVOKE INSERT ON rental FROM rental;

/*Lets check what happened with INSERT permission: */
SELECT *
FROM information_schema.role_table_grants
WHERE grantee = 'rental';

SET ROLE rental;

/*Let's try to INSERT (I guess it is fine to hardcode in such example). As expected, we get an error: */
INSERT INTO rental (inventory_id)
VALUES(3211); 


/*Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
The customer's payment and rental history must not be empty. */

/*As it was hinted in Teams, we can use function with two parameters to solve this task. 
 In case of successful new role creation it provides pg_roles table, where we can find our new role. */

--DROP FUNCTION personalized_role(p_first_name VARCHAR(20), p_last_name VARCHAR(20)); 

CREATE OR REPLACE FUNCTION personalized_role(p_first_name VARCHAR(20), p_last_name VARCHAR(20))          
RETURNS SETOF pg_catalog.pg_roles                                                              
LANGUAGE plpgsql
AS 
$$
BEGIN
	/*Basic check for customer presence in our "customer" table: */
    IF (UPPER(p_first_name||' '||p_last_name) NOT IN (SELECT first_name||' '||last_name 
                                                      FROM customer )) 
    THEN
        RAISE NOTICE 'There is no customer "% %" in "customer" table', p_first_name, p_last_name;
    ELSE
        /*I want to check that customer's payment and rental history are not empty (if not empty - create the role, if empty - provide message) */
        IF EXISTS 
            (SELECT c.customer_id
            FROM customer c
            INNER JOIN rental r ON r.customer_id = c.customer_id
            WHERE UPPER(first_name||' '||last_name) = UPPER(p_first_name||' '||p_last_name)
            )
        AND EXISTS 
            (SELECT c.customer_id
            FROM customer c
            INNER JOIN payment p ON p.customer_id = c.customer_id
            WHERE UPPER(first_name||' '||last_name) = UPPER(p_first_name||' '||p_last_name)            
            )
        THEN
            /*I want to check if the role client_{first_name}_{last_name} already exists. If yes - we will not create it and provide message */
            IF NOT EXISTS (SELECT rolname 
                           FROM pg_catalog.pg_roles 
                           WHERE rolname = FORMAT('client_%s_%s', p_first_name, p_last_name) 
                           )
            THEN           
	                  EXECUTE FORMAT('CREATE ROLE client_%s_%s LOGIN PASSWORD ''default_password''', p_first_name, p_last_name);   
                      RETURN QUERY
                      SELECT * 
                      FROM pg_catalog.pg_roles 
                      ORDER BY oid DESC ;           --Our new role will be provided in the first row of output table
            ELSE 
                RAISE NOTICE 'Role already exists. Skipping.';
            END IF;
        ELSE
           RAISE NOTICE 'For customer "% %" payment or rental history is empty', p_first_name, p_last_name;
        END IF;
    END IF;
END;
$$;    

SELECT * FROM personalized_role('mary','smith');


/*Task 3. Implement row-level security. 
  Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.*/

/*I decided to solve this task via function, because I thought that we want opportunity to create policies for any given customer. 
  Maybe the part with creating policies could be implemented in more elegant way. To be honest, I don't quite understand the difference between s, I and L types of format conversion, I have 
  a feeling that I use them quite randomly here. */

--DROP FUNCTION row_level_role(p_first_name VARCHAR(20), p_last_name VARCHAR(20)); 

CREATE OR REPLACE FUNCTION row_level_role(p_first_name VARCHAR(20), p_last_name VARCHAR(20))          
RETURNS VOID
LANGUAGE plpgsql
AS 
$$
BEGIN
	/*Basic check for customer presence in our "customer" table: */
	IF (UPPER(p_first_name||' '||p_last_name) NOT IN (SELECT first_name||' '||last_name 
                                                      FROM customer )) 
    THEN
        RAISE NOTICE 'There is no customer "% %" in "customer" table', p_first_name, p_last_name;
    ELSE
        /*I want to check if the role {first_name}_{last_name} already exists. If yes - we will not create it and provide message */
        IF NOT EXISTS (SELECT rolname 
                       FROM pg_catalog.pg_roles 
                       WHERE rolname = FORMAT('%s_%s', p_first_name, p_last_name) 
                       )
        THEN           
            EXECUTE FORMAT('CREATE ROLE %I_%I LOGIN PASSWORD %L', p_first_name, p_last_name, 'default_password');
            ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
            /*If I am correct, we have to enable RWS and to create policy for our customer on the table "customer", because we reference it in the USING section when applying
            policies on tables "rental" and "payment". I think this is not an issue because the customer can get only his profile from the table "customer". */
            ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
            ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
            EXECUTE FORMAT('CREATE POLICY user_policy_customer_%I_%I ON customer TO %I_%I USING 
            (LOWER(first_name||''_''||last_name) = %L)', p_first_name, p_last_name, p_first_name, p_last_name, p_first_name||'_'||p_last_name);
            EXECUTE FORMAT('CREATE POLICY user_policy_rental_%I_%I ON rental TO %I_%I USING 
            (customer_id = (SELECT customer_id 
                            FROM customer 
                            WHERE LOWER(first_name||''_''||last_name) = %L))', p_first_name, p_last_name, p_first_name, p_last_name, p_first_name||'_'||p_last_name);
            EXECUTE FORMAT('CREATE POLICY user_policy_payment_%I_%I ON payment TO %I_%I USING 
            (customer_id = (SELECT customer_id 
                            FROM customer 
                            WHERE LOWER(first_name||''_''||last_name) = %L))', p_first_name, p_last_name, p_first_name, p_last_name, p_first_name||'_'||p_last_name);
    
            EXECUTE FORMAT('GRANT SELECT ON customer, rental, payment TO %I_%I', p_first_name, p_last_name);
        ELSE 
            RAISE NOTICE 'Role already exists. Skipping.';
        END IF;
    END IF;
END;
$$;

SELECT * FROM row_level_role('mary','smith');


/*We can check created policies:*/
 SELECT * 
 FROM pg_catalog.pg_policies;

/*Let's change current role to the new one:*/
SET ROLE mary_smith;

/*As output of this query we get only rows where customer_id=1: */
SELECT * FROM rental r
LEFT JOIN payment p ON p.rental_id = r.rental_id;

