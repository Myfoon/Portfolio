/*Task. Create one function that reports all information for a particular client and timeframe

Customer's name, surname and email address;
Number of films rented during specified timeframe;
Comma-separated list of rented films at the end of specified time period;
Total number of payments made during specified time period;
Total amount paid during specified time period;

Function's input arguments: client_id, left_boundary, right_boundary.
The function must analyze specified timeframe [left_boundary, right_boundary] and output specified information for this timeframe.
Function's result format: table with 2 columns ‘metric_name’ and ‘metric_value’. */


/*I think in theory it is possible to solve the task using function with language SQL, but as far as it is good to have some checks and notices, plpgSQL is my only choice.
 My function returns table of 2 columns.*/

--DROP FUNCTION all_info_about_client(client_id INT, left_boundary TIMESTAMP, right_boundary TIMESTAMP);

CREATE OR REPLACE FUNCTION all_info_about_client(client_id INT, left_boundary TIMESTAMP, right_boundary TIMESTAMP)                                
RETURNS TABLE (metric_name VARCHAR(20),
               metric_value TEXT)
LANGUAGE plpgsql
AS 
$$
BEGIN
/*A couple of checks follow. I decided to use NOTICE and EXCEPTION quite randomly, just to demonstrate different options.
Maybe it makes more sense to use EXCEPTION also in case of unexisting client_id */ 	
IF client_id > (SELECT MAX(customer_id)                         
                FROM customer)
THEN 
    RAISE NOTICE 'There is no customer with id = %', client_id;
ELSIF client_id < 1
THEN
    RAISE NOTICE 'Client_id must be positive';
END IF;
IF left_boundary >= right_boundary
THEN
    RAISE EXCEPTION 'Right_boundary must be bigger than left_boundary'
		USING hint = 'Check the timeframe';
END IF;

RETURN QUERY
/*Following CTE gives us a table consisted of all rentals made by certain customer. Total payment amount and number of payments are already counted in this table*/
WITH all_rents_for_certain_customer AS 
(
SELECT c.first_name, c.last_name, c.email, MAX(f.title) AS customer_film, 
       SUM(p.amount) AS total_payment, COUNT(p.payment_id) AS payments_number,
       c.customer_id, MAX(p.payment_date) AS customer_payment_date, MAX(r.rental_date) AS customer_rental_date
/*I use MAX(f.title), MAX(p.payment_date) and MAX(r.rental_date) only in order not to use corresponding columns in GROUP BY. If I remember correctly, we can do this kind of a "trick". */
FROM rental r
RIGHT JOIN customer c ON r.customer_id = c.customer_id                 --RIGHT JOIN here because we can have customers with no records in "rental" table
LEFT JOIN payment p ON p.customer_id = c.customer_id                   --LEFT JOIN because some rentals can have no corresponding payment  
INNER JOIN inventory i ON i.inventory_id = r.inventory_id
INNER JOIN film f ON f.film_id = i.film_id 
WHERE c.customer_id = client_id                                         --Filtering by certain client
GROUP BY c.first_name, c.last_name, c.email, c.customer_id, r.rental_id
)
SELECT 'customers_info'::VARCHAR, INITCAP(first_name||' '||last_name)||', '||LOWER(email) 
FROM all_rents_for_certain_customer
GROUP BY first_name, last_name, email
UNION ALL
/*I have to use timeframe filtering in different way for "number of films"+"rented films" and for "number of payments"+"payments amount", because it is possible to have 
 no rentals and some payments in certain timeframe, and vice versa. */
SELECT 'num. of films rented'::VARCHAR, COUNT(customer_film)::TEXT
FROM all_rents_for_certain_customer
WHERE customer_rental_date >= left_boundary AND customer_rental_date < right_boundary                     
UNION ALL
SELECT 'rented films'' titles'::VARCHAR, COALESCE(STRING_AGG(customer_film, ', '), 'No films rented in this period')   --We decided to show all the films, even if they're repetitive
FROM all_rents_for_certain_customer
WHERE customer_rental_date >= left_boundary AND customer_rental_date < right_boundary
UNION ALL
SELECT 'num. of payments'::VARCHAR, COALESCE(MAX(payments_number), 0)::TEXT 
FROM all_rents_for_certain_customer
WHERE customer_payment_date >= left_boundary AND customer_payment_date < right_boundary
UNION ALL
SELECT 'payments amount'::VARCHAR, COALESCE(MAX(total_payment), 0)::TEXT 
FROM all_rents_for_certain_customer
WHERE customer_payment_date >= left_boundary AND customer_payment_date < right_boundary;
END;
$$;


SELECT * FROM all_info_about_client(41111, '2005-06-01', '2025-07-01') ;                    --Customer_id 541 is special


