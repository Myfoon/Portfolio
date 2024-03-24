--1. Choose your top-3 favorite movies and add them to the 'film' table. Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
/*Here we need to perform check before adding new film in the table to avoid duplicates. As we agreed in Teams, it is impossible to have two films 
 with the exact same title and release year. */

--I use UNION ALL here and provide inserted results with RETURNING

INSERT
	INTO
	film (title,
	release_year,
	language_id,
	rental_duration,
	rental_rate)
SELECT
	'THE MATRIX',
	'1999'::YEAR,
	(
	SELECT
		language_id
	FROM
		language
	WHERE
		UPPER(name) = 'ENGLISH'),
	7,
	4.99
WHERE
	NOT EXISTS (
	SELECT
		title,
		release_year
	FROM
		film
	WHERE
		UPPER(title) = 'THE MATRIX' AND release_year = '1999'
                 )
UNION ALL    

SELECT
	'FIGHT CLUB',
	'1999'::YEAR,
	(
	SELECT
		language_id
	FROM
		language
	WHERE
		UPPER(name) = 'ENGLISH'),
	14,
	9.99
WHERE
	NOT EXISTS (
	SELECT
		title,
		release_year
	FROM
		film
	WHERE
		UPPER(title) = 'FIGHT CLUB' AND release_year = '1999'
                 )
UNION ALL

SELECT
	'INTERSTELLAR',
	'2014'::YEAR,
	(
	SELECT
		language_id
	FROM
		language
	WHERE
		UPPER(name) = 'ENGLISH'),
	21,
	19.99
WHERE
	NOT EXISTS (
	SELECT
		title,
		release_year
	FROM
		film
	WHERE
		UPPER(title) = 'INTERSTELLAR' AND release_year = '2014'
                 )
RETURNING film_id,
	title,
	release_year,
	language_id,
	rental_duration,
	rental_rate;
                
  
--2. Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).

--Adding actors manually in "actor" table and providing actor_id, first_name, last_name of the added actors: 

INSERT INTO
	actor (first_name, last_name)
SELECT
	first_name,
	last_name
FROM
	(
	SELECT
		'MATTHEW' AS first_name,
		'MCCONAUGHEY' AS last_name
UNION ALL
	SELECT
		'ANNE' AS first_name,
		'HATHAWAY' AS last_name
UNION ALL
	SELECT
		'KEANU' AS first_name,
		'REEVES' AS last_name
UNION ALL
	SELECT
		'LAURENCE' AS first_name,
		'FISHBURNE' AS last_name
UNION ALL
	SELECT
		'BRAD' AS first_name,
		'PITT' AS last_name
UNION ALL
	SELECT
		'EDWARD' AS first_name,
		'NORTON' AS last_name
)
WHERE                                             --We need to perform this check to avoid inserting duplicates
	first_name || ' ' || last_name NOT IN (
	SELECT
		first_name || ' ' || last_name
	FROM
		actor)
RETURNING actor_id,
	first_name,
	last_name;


--Adding actors into "film_actor" table, providing actor_id and film_id:

INSERT INTO film_actor 
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='MATTHEW' AND a.last_name='MCCONAUGHEY'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='INTERSTELLAR')
UNION
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='ANNE' AND a.last_name='HATHAWAY'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='INTERSTELLAR')
UNION        
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='KEANU' AND a.last_name='REEVES'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='THE MATRIX')
UNION
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='LAURENCE' AND a.last_name='FISHBURNE'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='THE MATRIX')
UNION
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='BRAD' AND a.last_name='PITT'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='FIGHT CLUB')
UNION
SELECT  (SELECT MAX(a.actor_id)
        FROM actor a
        WHERE a.first_name='EDWARD' AND a.last_name='NORTON'),
        (SELECT MAX(f.film_id)
        FROM film f
        WHERE UPPER(f.title)='FIGHT CLUB')
ON CONFLICT DO NOTHING 
RETURNING actor_id, film_id;

/*Table "film_actor" has a constraint: composite PK formed by actor_id and film_id. That is why I think I
 can use ON CONFLICT here. This expression in DDL section corresponding this table creates this constraint:
 
 CONSTRAINT film_actor_pkey PRIMARY KEY (actor_id, film_id)*/

--Maybe we can also use this solution to add actors into "film_actor" (it seems we get the same result):
                                                                           
INSERT INTO film_actor (actor_id, film_id)
SELECT a.actor_id, f.film_id
FROM actor a
JOIN film f ON (
    (a.first_name = 'KEANU' AND a.last_name = 'REEVES' AND f.title = 'THE MATRIX') or
    (a.first_name = 'LAURENCE' AND a.last_name = 'FISHBURNE' AND f.title = 'THE MATRIX') or
    (a.first_name = 'BRAD' AND a.last_name = 'PITT' AND f.title = 'FIGHT CLUB') or
    (a.first_name = 'EDWARD' AND a.last_name = 'NORTON' AND f.title = 'FIGHT CLUB') or
    (a.first_name = 'MATTHEW' AND a.last_name = 'MCCONAUGHEY' AND f.title = 'INTERSTELLAR') or 
    (a.first_name = 'ANNE' AND a.last_name = 'HATHAWAY' AND f.title = 'INTERSTELLAR') 
)
ON CONFLICT DO NOTHING 
RETURNING actor_id, film_id; 



--3. Add your favorite movies to any store's inventory.

/*During QA session we decided that it is ok to add to inventory one copy of every film. But if we want N copies, it is also possible to run this query N times.
 It appears that i use hardcoded store_id, but on the other hand we don't have a name for it, so here it is possible to think of it as a name of the store. */

INSERT	INTO
	inventory (film_id,	store_id)
 SELECT
	f.film_id,
	1
FROM
	film f
WHERE
	f.title = 'THE MATRIX'
UNION 
 SELECT
	f.film_id,
	1
FROM
	film f
WHERE
	f.title = 'FIGHT CLUB'
UNION
SELECT
	f.film_id,
	2
FROM
	film f
WHERE
	f.title = 'INTERSTELLAR' 
 RETURNING inventory_id,
	film_id,
	store_id;



/*4. Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). 
You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.*/
 
/*As far as we have a lot of customers with at least 43 rental and 43 payment records, I decided to use RANDOM to get one customer_id. Also I use random address. */

WITH random_customer_id AS    --This CTE gives us one random customer_id of a customer with at least 43 rental and 43 payment records
(
SELECT
	c.customer_id
FROM
	customer c
INNER JOIN payment p ON
	p.customer_id = c.customer_id
INNER JOIN rental r ON
	r.customer_id = c.customer_id
GROUP BY
	c.customer_id
HAVING
	(COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43)
ORDER BY
	RANDOM()
LIMIT 1
)

UPDATE
	customer
SET
	store_id = 2,                         --The same story with hardcoding store_id
	first_name = 'VIACHESLAV',
	last_name = 'IVANOV',
	email = 'mafon.ff@gmail.com',
	address_id = (
	SELECT
		address_id
	FROM
		address
	ORDER BY
		RANDOM()
	LIMIT 1),
	create_date = current_date
WHERE
	customer_id = (
	SELECT
		customer_id
	FROM
		random_customer_id)
	AND 'VIACHESLAV IVANOV' NOT IN (        --Here I use NOT IN to avoid replacing more than one customer 
	SELECT
		first_name || ' ' || last_name
	FROM
		customer)
RETURNING customer_id,
	store_id,
	first_name,
	last_name,
	email,
	address_id,
	create_date;
 

--5. Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

/*First of all, I don't think that table "inventory" is related to any customer, so no need to mention it here.
 I decided that tables related to me as a customer are "rental" and "payment" (they really have column customer_id).*/
 
WITH delete_from_rental AS                 --This CTE allow to perform removing all records with my customer_id from rental, and provide my customer_id
(    
DELETE
FROM
	rental
WHERE
	customer_id IN (
	SELECT
		c.customer_id
	FROM
		rental r
	INNER JOIN customer c ON
		c.customer_id = r.customer_id
	WHERE
		UPPER(c.first_name || ' ' || c.last_name) = 'VIACHESLAV IVANOV')
 RETURNING customer_id
 )
  
DELETE FROM
	payment
WHERE
	customer_id = (            --As far as CTE provided customer_id, we can use it to remove all corresponding records from payment also.
	SELECT
		max(customer_id)
	FROM 
		delete_from_rental);
	

/*6. Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the
first half of 2017)*/

CREATE TABLE payment_p2024_03 PARTITION OF payment        --Creating a new partition for payments in March 2024
FOR VALUES
FROM ('2024-03-01 00:00:00+03') TO ('2024-04-01 00:00:00+03');
  

--Part_1. Inserting into table "rental"

WITH film_title_inventory AS                --CTE just to have film titles and inventory_ids in one table
(
SELECT
	min(inventory_id) AS inventory_id,
	f.title
FROM
	film f
INNER JOIN inventory i ON
	f.film_id = i.film_id
GROUP BY
	f.title
),
   
my_customer_id AS                           --CTE to get my customer_id
(
SELECT
	customer_id
FROM
	customer
WHERE
	UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV'
)
        
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT '2024-03-02 12:22:21.156'::TIMESTAMPTZ,               --inserting rental_date

(SELECT inventory_id                                         --inserting inventory_id of certain film
 FROM film_title_inventory
 WHERE UPPER(title) = 'THE MATRIX'),
 
(SELECT customer_id                                          --inserting my customer_id
 FROM my_customer_id),
 
'2024-03-09 12:01:22.255'::TIMESTAMPTZ,                      --inserting return_date

(SELECT staff_id                                              --Inserting staff_id (I suppose we know name of the person when we rent a film)
FROM staff 
WHERE UPPER(first_name||' '||last_name) = 'MIKE HILLYER')

UNION 

SELECT '2024-03-01 16:23:03.322'::TIMESTAMPTZ,

(SELECT inventory_id 
 FROM film_title_inventory
 WHERE UPPER(title) = 'FIGHT CLUB'),
 
(SELECT customer_id 
 FROM my_customer_id),
 
'2024-03-29 12:22:32.533'::TIMESTAMPTZ,

(SELECT staff_id 
FROM staff 
WHERE UPPER(first_name||' '||last_name) = 'JON STEPHENS')

UNION

SELECT '2024-03-08 11:05:23.233'::TIMESTAMPTZ,
(SELECT inventory_id 
 FROM film_title_inventory
 WHERE UPPER(title) = 'INTERSTELLAR'),
 
(SELECT customer_id 
 FROM my_customer_id),

'2024-03-29 10:24:02.122'::TIMESTAMPTZ,

(SELECT staff_id 
 FROM staff 
 WHERE UPPER(first_name||' '||last_name) = 'PETER LOCKYARD')
 
ON CONFLICT DO NOTHING
RETURNING rental_date, inventory_id, customer_id, return_date, staff_id;


/*Table "rental" has a constraint that don't allow to have two rows with the same inventory_id, customer_id and rental_date at a time, that is why I think I
 can use ON CONFLICT here. If I am not wrong, this expression in DDL section corresponding this table creates this constraint:
 
CREATE UNIQUE INDEX idx_unq_rental_rental_date_inventory_id_customer_id ON public.rental USING btree (rental_date, inventory_id, customer_id) */

--Part_2. Inserting into table "payment"
 
--I use following formula to calculate amount of payment: [(return_date - rental_date)/rental_duration]*rental_rate


WITH info_about_MATRIX AS           --This CTE allow to get information about the first film I rented which I need for "payment" table
(
SELECT
	MAX(c.customer_id) AS my_customer_id,
	MAX(r.staff_id) AS staff_who_gave_me_the_film,
	MAX(r.rental_id) AS my_films_rental_id,
	
/*In theory, we can have several rental_ids for the same customer and film. I'll make an assumption that we process payment for the most recent rent.
 So MAX for staff_id, rental_id, return_date, rental_date have meaning here */
	
	((MAX(r.return_date)::DATE-MAX(r.rental_date)::DATE)/ MAX(f.rental_duration)* MAX(f.rental_rate)) AS payment_amount,
	f.title
FROM
	rental r
INNER JOIN customer c ON
	c.customer_id = r.customer_id
INNER JOIN inventory i ON
	r.inventory_id = i.inventory_id
INNER JOIN film f ON
	f.film_id = i.film_id
WHERE
	c.customer_id = (
	SELECT
		customer_id
	FROM
		customer
	WHERE
		UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV')
		AND UPPER(f.title) = 'THE MATRIX'
GROUP BY
	r.rental_id,
	f.title
),

info_about_FIGHT_CLUB AS           --This CTE allow to get information about the second film I rented which I need for "payment" table
(
SELECT
	MAX(c.customer_id) AS my_customer_id,
	MAX(r.staff_id) AS staff_who_gave_me_the_film,
	MAX(r.rental_id) AS my_films_rental_id,
    ((MAX(r.return_date)::DATE-MAX(r.rental_date)::DATE)/ MAX(f.rental_duration)* MAX(f.rental_rate)) AS payment_amount,
	f.title
FROM
	rental r
INNER JOIN customer c ON
	c.customer_id = r.customer_id
INNER JOIN inventory i ON
	r.inventory_id = i.inventory_id
INNER JOIN film f ON
	f.film_id = i.film_id
WHERE
	c.customer_id = (
	SELECT
		customer_id
	FROM
		customer
	WHERE
		UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV')
		AND UPPER(f.title) = 'FIGHT CLUB'
GROUP BY
	r.rental_id,
	f.title
),

info_about_INTERSTELLAR AS           --This CTE allow to get information about the third film I rented which I need for "payment" table
(
SELECT
	MAX(c.customer_id) AS my_customer_id,
	MAX(r.staff_id) AS staff_who_gave_me_the_film,
	MAX(r.rental_id) AS my_films_rental_id,	
	((MAX(r.return_date)::DATE-MAX(r.rental_date)::DATE)/ MAX(f.rental_duration)* MAX(f.rental_rate)) AS payment_amount,
	f.title
FROM
	rental r
INNER JOIN customer c ON
	c.customer_id = r.customer_id
INNER JOIN inventory i ON
	r.inventory_id = i.inventory_id
INNER JOIN film f ON
	f.film_id = i.film_id
WHERE
	c.customer_id = (
	SELECT
		customer_id
	FROM
		customer
	WHERE
		UPPER(first_name || ' ' || last_name) = 'VIACHESLAV IVANOV')
		AND UPPER(f.title) = 'INTERSTELLAR'
GROUP BY
	r.rental_id,
	f.title
)
        
INSERT INTO
	payment (customer_id,
	staff_id,
	rental_id,
	amount,
	payment_date)
SELECT
	(SELECT my_customer_id                                            --inserting my customer_id
	FROM info_about_MATRIX),
	
	(SELECT staff_who_gave_me_the_film                                --inserting staff_id of the person who rented me the film (I suppose he will also process the payment)
	FROM info_about_MATRIX),
	
	(SELECT my_films_rental_id                                        --inserting rental_id of the certain film
	FROM info_about_MATRIX),
	
	(SELECT payment_amount                                            --inserting amount of payment corresponding to this rental_id 
	FROM info_about_MATRIX),
	
	'2024-03-29 10:30'::TIMESTAMPTZ                                   --inserting time when payment was made
WHERE                                                                 
	(SELECT my_films_rental_id                                        --We cannot have two same rental_ids in "payment" table
	FROM info_about_MATRIX) 
	NOT IN (SELECT rental_id
	        FROM payment)
UNION ALL 
SELECT
	(SELECT my_customer_id                                            
	FROM info_about_FIGHT_CLUB),
	
	(SELECT staff_who_gave_me_the_film                                
	FROM info_about_FIGHT_CLUB),
	
	(SELECT my_films_rental_id                                        
	FROM info_about_FIGHT_CLUB),
	
	(SELECT payment_amount                                             
	FROM info_about_FIGHT_CLUB),
	
	'2024-03-29 10:34'::TIMESTAMPTZ                                  
WHERE                                                                 
	(SELECT my_films_rental_id                                       
	FROM info_about_FIGHT_CLUB) 
	NOT IN (SELECT rental_id
	        FROM payment)
UNION ALL
SELECT
	(SELECT my_customer_id                                            
	FROM info_about_INTERSTELLAR),
	
	(SELECT staff_who_gave_me_the_film                                
	FROM info_about_INTERSTELLAR),
	
	(SELECT my_films_rental_id                                        
	FROM info_about_INTERSTELLAR),
	
	(SELECT payment_amount                                             
	FROM info_about_INTERSTELLAR),
	
	'2024-03-29 10:36'::TIMESTAMPTZ                                  
WHERE                                                                 
	(SELECT my_films_rental_id                                       
	FROM info_about_INTERSTELLAR) 
	NOT IN (SELECT rental_id
	        FROM payment)
RETURNING customer_id,
	staff_id,
	rental_id,
	amount,
	payment_date;
