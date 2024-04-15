/* Task 1.Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. 
The view should only display categories with at least one sale in the current quarter. 
Note: when the next quarter begins, it will be considered as the current quarter.*/

--DROP VIEW IF EXISTS sales_revenue_by_category_qtr;

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT c.name AS category_name, SUM(p.amount) AS total_revenue
FROM public.payment p
INNER JOIN public.rental r ON r.rental_id = p.rental_id
INNER JOIN public.inventory i ON i.inventory_id = r.inventory_id
INNER JOIN public.film_category fc ON fc.film_id = i.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE EXTRACT(QUARTER FROM p.payment_date) =  EXTRACT(QUARTER FROM CURRENT_TIMESTAMP)
      AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_TIMESTAMP)
GROUP BY c.name
HAVING COUNT(p.payment_id) > 0;

SELECT * FROM sales_revenue_by_category_qtr;
 

/*Task 2. Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing 
the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.*/

/*In fact, this function is a parameterized view. I want quarter and year to be inputed as following: 'Number of quarter_Year' (e.g. '2_2018')  */
DROP FUNCTION get_sales_revenue_by_category_qtr(IN quarter_year VARCHAR(6));                

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(IN quarter_year VARCHAR(6))
RETURNS TABLE (category_name VARCHAR(20),
               total_revenue DECIMAL(8,2))
AS $$
SELECT c.name AS category_name, SUM(p.amount) AS total_revenue
FROM public.payment p
INNER JOIN public.rental r ON r.rental_id = p.rental_id
INNER JOIN public.inventory i ON i.inventory_id = r.inventory_id
INNER JOIN public.film_category fc ON fc.film_id = i.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE EXTRACT(QUARTER FROM p.payment_date) = SUBSTRING(quarter_year, 1, 1)::INT2
      AND EXTRACT(YEAR FROM p.payment_date) = SUBSTRING(quarter_year, 3, 4)::INT2
GROUP BY c.name
HAVING count(p.payment_id) > 0
$$
LANGUAGE sql;


/*In current quarter and year we don't have rents: */
SELECT * FROM get_sales_revenue_by_category_qtr(EXTRACT(QUARTER FROM CURRENT_TIMESTAMP)||'_'||EXTRACT(YEAR FROM CURRENT_TIMESTAMP));

/*But we can check the function using year of 2017: */
SELECT * FROM get_sales_revenue_by_category_qtr('1_2017');


/*Task 3. Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
The function should format the result set as follows:
                    Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]); */

/* I decided to use fucntion returning a table. Loop cycle allows to populate the table row-by-row, and I use element of input array (country) as a loop counter.
  At every cycle step we also check if current array element (input country) presented in "country" table, if not - we provide RAISE NOTICE.
  In case we don't have rents in some country, I decided to indicate it providing record "no rents" in the output table. Maybe it is more logically to do such indication with
   RAISE NOTICE, as we do it for countries not presented in "country" table.  */

--DROP FUNCTION most_popular_films_by_countries(selected_countries TEXT[]); 

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(selected_countries TEXT[])       --Here we have an array as input parameter       
RETURNS TABLE (country TEXT,                                                              
               film TEXT,
               rating MPAA_rating,
               language BPCHAR(20),
               length INT2,
               release_year YEAR)
LANGUAGE plpgsql
AS
$$
DECLARE
    loop_counter INT;
BEGIN
	FOR loop_counter IN ARRAY_LOWER(selected_countries, 1)..ARRAY_UPPER(selected_countries, 1) LOOP
	    RETURN QUERY 	    
        SELECT co.country AS grouping_country, COALESCE (f.title,'no rents'), f.rating, l.name, f.length, f.release_year        
        FROM inventory i
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN film f ON f.film_id = i.film_id
        INNER JOIN language l ON l.language_id = f.language_id 
        RIGHT JOIN customer cu ON r.customer_id = cu.customer_id         --I decided to use Right join here in order not to loose countries without rents
        RIGHT JOIN address a ON a.address_id = cu.address_id 
        INNER JOIN city ci ON ci.city_id = a.city_id 
        INNER JOIN country co ON co.country_id = ci.country_id
        WHERE UPPER(co.country) = selected_countries[loop_counter]    
        GROUP BY i.film_id, f.title, f.rating, f.length, f.release_year, l.name, co.country
        ORDER BY COUNT(r.rental_id) DESC, f.title                         --In case of several films with the same popularity we take the first film alphabetically
        LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE'Country % could not be found in "country" table', selected_countries[loop_counter];
        END IF;
    END LOOP;

END;
$$;

/*Australia is particalarly interesting because if I am not wrong it is the only country without rents. And Atlantida gives us Output message.*/
SELECT * FROM most_popular_films_by_countries(ARRAY['BRAZIL','CANADA','AUSTRALIA','ATLANTIDA']);



/* Task 4. Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated counter field, starting from 1 and 
incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
Added from Teams: Please show the last customer who rent this film, and the date. */

/* Here I also use fucntion returning a table. I've got 2 variables: my_row RECORD is for holding a row (this row is taken one-by-one from the output of SELECT statement 
 * in which I specify all the requirements to provide film with title having partial title match, latest rental date for this certain film and corresponding customer),
 *  and next_id INT is just as increment for row_num. I use simple LOOP cycle (without loop counter) to iterate through all the films. If there are no films in my SELECT statement,
 *  we get the message in Output. */

--DROP FUNCTION films_in_stock_by_title(title_pattern VARCHAR(100));  

CREATE OR REPLACE FUNCTION films_in_stock_by_title(title_pattern VARCHAR(100))              
RETURNS TABLE (row_num INT, 
               film_title TEXT,
               language TEXT,
               customer_name TEXT,
               rental_date TIMESTAMPTZ)
LANGUAGE plpgsql
AS 
$$
DECLARE
    next_id INT := 1;
    my_row RECORD;
BEGIN
	FOR my_row IN
	WITH films_in_stock_having_partial_title_match  AS                --I hope the name of this CTE is self-explaining
	(
    SELECT f.title, l.name, c.first_name||' '||c.last_name AS customer_full_name, MAX(r.rental_date) as max_rental_date_for_customer
	FROM film f
	INNER JOIN public.language l ON l.language_id = f.language_id 
	LEFT JOIN inventory i ON i.film_id = f.film_id
	INNER JOIN rental r ON r.inventory_id = i.inventory_id
	INNER JOIN customer c ON r.customer_id = c.customer_id 
	WHERE f.title LIKE title_pattern
	AND r.return_date IS NOT NULL	
    GROUP BY f.title, l.name, c.first_name||' '||c.last_name
    ) 
    SELECT title, name, customer_full_name, max_rental_date_for_customer
    FROM films_in_stock_having_partial_title_match
    WHERE max_rental_date_for_customer IN (SELECT MAX(max_rental_date_for_customer)   --That's how we get latest rental date for certain film rented by certain customer
                                           FROM films_in_stock_having_partial_title_match
                                           GROUP BY title) 
    GROUP BY title, max_rental_date_for_customer, name, customer_full_name
    LOOP
       row_num := next_id;                         --Autoincrement of the row number 
       next_id := next_id + 1;
       film_title := my_row.title;
       language := my_row.name;
       customer_name := my_row.customer_full_name;
       rental_date := my_row.max_rental_date_for_customer;
       RETURN NEXT;
    END LOOP;
    IF NOT FOUND THEN
       RAISE NOTICE'No film in stock with title containing %', title_pattern;
    END IF;    
END;
$$;


SELECT * FROM films_in_stock_by_title('%GOLD%');


/* Task 5. Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table. 
The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
The release year and language are optional and by default should be current year and Klingon respectively. The function should also verify that 
the language exists in the 'language' table. Then, ensure that no such function has been created before; if so, replace it. */   


/*I decided to use 3 parameters here: new_movie_title, new_release_year with default value and new_language with default value.
  The only output of the function (not counting Output messages) is INT value giving us id of the inserted film.*/

DROP FUNCTION new_movie(new_movie_title VARCHAR, new_release_year YEAR, new_language BPCHAR(20)); 

CREATE OR REPLACE FUNCTION new_movie(new_movie_title VARCHAR, new_release_year YEAR DEFAULT EXTRACT(YEAR FROM CURRENT_TIMESTAMP), new_language BPCHAR(20) DEFAULT 'Klingon')             
RETURNS INT
LANGUAGE plpgsql
AS 
$$
DECLARE
    inserted_film_id INT;
BEGIN
	IF new_language                              --If new language is not in "language" table, we insert it there and give a message
	NOT IN (SELECT name FROM language) THEN
	    INSERT INTO language (name)
	    VALUES (new_language);
	    RAISE NOTICE 'Language % was inserted into table "language"', new_language;
	END IF;

    IF NOT EXISTS (                            --We need to check if there is a film with same title and release year before we insert
	    SELECT title
	    FROM film
	    WHERE title = new_movie_title 
        AND release_year = new_release_year)
    THEN
	   INSERT INTO film (title, release_year, language_id, rental_duration, rental_rate, replacement_cost)
       SELECT
       new_movie_title,
       new_release_year,
       (SELECT language_id 
        FROM language 
        WHERE name = new_language),
	    3,
	    4.99,
	    19.99;
	 
       SELECT film_id 
       FROM film 
       WHERE title = new_movie_title                                   
       INTO inserted_film_id; 
       RAISE NOTICE 'Film % was inserted', new_movie_title;
    ELSE inserted_film_id = -1;                                       --Negative id indicates that the movie was not inserted
       RAISE NOTICE 'Film % is already in the list', new_movie_title;
    END IF;   
    RETURN inserted_film_id;                                           --We return id of the inserted film
END;
$$;    
    
    
SELECT * FROM new_movie('NEW_MOVIE');

delete from film where title = 'NEW_MOVIE'

