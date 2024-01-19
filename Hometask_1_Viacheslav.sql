#Task_1
select first_name
from actor;

#Task_2
select *
from actor
order by last_name asc;

#Task_3
select distinct store_id
from customer;

#Task_4
select concat(first_name,': ', email) as "Name and e-mail"
from customer;

#Task_5
select sum(length) as "Total length", rating as "Rating"
from film
group by rating; 