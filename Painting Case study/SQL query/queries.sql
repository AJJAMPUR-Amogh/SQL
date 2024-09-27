SELECT * FROM artist ;
SELECT * FROM canvas_size ; 
SELECT * FROM image_link ;
SELECT * FROM museum ; 
SELECT * FROM museum_hours ;
SELECT * FROM product_size;
SELECT * FROM subject;
SELECT * FROM  work ; 

/* 1. Fetch all the paintings which are not displayed on any museums? */

SELECT name as painting FROM work 
where museum_id IS NULL ;

/*2. Are there museums without any paintings? */

SELECT DISTINCT w.museum_id FROM work w
LEFT JOIN museum m ON w.museum_id = m.museum_id
WHERE w.museum_id  IN (SELECT museum_id FROM museum);

/* 3. How many paintings have an asking price of more than their regular price? */

SELECT COUNT(work_id) FROM product_size
WHERE sale_price < regular_price ;

/* 4. Identify the paintings whose asking price is less than 50% of its regular price */

SELECT COUNT(work_id) FROM product_size
WHERE sale_price <  regular_price * 0.5 ;

/* 5. Which canva size costs the most? */

SELECT * 
FROM (SELECT work_id,label,p.sale_price,(DENSE_RANK() OVER (ORDER BY p.sale_price DESC )) AS ranking 
	  FROM product_size p
	  JOIN canvas_size c ON (CAST(c.size_id AS TEXT))= p.size_id )
WHERE ranking = 1

-- 6. Delete duplicate records from work, product_size, subject and image_link tables 
-- TO find the duplicate records 
SELECT work_id
			FROM 
				(SELECT work_id,name,artist_id, style, museum_id, COUNT(*) 
				FROM work
				GROUP BY work_id,name,artist_id, style, museum_id)	
WHERE count >1 ;

DELETE FROM WORK 
WHERE ctid NOT IN ( SELECT MAX(ctid)
						FROM WORK 
						GROUP BY work_id
						);
DELETE FROM product_size 
WHERE ctid NOT IN ( SELECT MAX(ctid)
						FROM  product_size
						GROUP BY work_id
						);
DELETE FROM subject 
WHERE ctid NOT IN ( SELECT MAX(ctid)
						FROM  subject
						GROUP BY work_id
						);
DELETE FROM image_link 
WHERE ctid NOT IN ( SELECT MAX(ctid)
						FROM  image_link
						GROUP BY work_id
						);
						

-- 7. Identify the museums with invalid city information in the given dataset

SELECT * FROM museum 
WHERE city SIMILAR TO '[1234567890]%';

SELECT * FROM museum 
WHERE city ~ '^[0-9]';

-- 8. Museum_Hours table has 1 invalid entry. Identify it and remove it.



SELECT DISTINCT day FROM museum_hours;

DELETE FROM  museum_hours
WHERE day = 'Thusday' 
RETURNING *;

SELECT * FROM museum_hours;

-- 9. Fetch the top 10 most famous painting subject

SELECT subject,count(*) FROM subject 
GROUP BY subject 
ORDER BY COUNT(*) DESC
LIMIT 10 ;

-- 10. Identify the museums which are open on both Sunday and Monday. Display museum name, city.

SELECT name ,city 
FROM museum m
INNER JOIN museum_hours mh ON m.museum_id = mh.museum_id 
WHERE day = 'Sunday' AND  EXISTS(SELECT * FROM museum_hours mh2 
								 WHERE mh2.museum_id=mh.museum_id 
			   					  mh2.day='Monday')

-- 11. How many museums are open every single day?

SELECT COUNT(*) AS num_of_museums
FROM
	(SELECT mh.museum_id, COUNT(*) FROM museum_hours mh
	LEFT JOIN museum m ON m.museum_id = mh.museum_id 
	GROUP BY mh.museum_id 
	HAVING count(*) = 7 ) x ;

-- 12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

SELECT name AS Museum_Name ,country,city
FROM museum
WHERE museum_id IN	(SELECT w.museum_id AS paintings FROM museum m
					INNER JOIN work w ON w.museum_id = m.museum_id 
					GROUP BY  w.museum_id 
					ORDER BY COUNT(*) DESC
					LIMIT 10 )
					
-- 13. Who are the top 5 most popular artist? (Popularity is defined based on most no ofpaintings done by an artist)

SELECT w.artist_id,full_name,COUNT(*) AS Paintings FROM work w
INNER JOIN artist a ON w.artist_id = a.artist_id
GROUP BY full_name, w.artist_id
ORDER BY COUNT(*) DESC
LIMIT 5


-- 14. Display the 3 least popular canva sizes


SELECT c.size_id,label FROM product_size p 
INNER JOIN canvas_size c ON p.size_id = CAST(c.size_id AS TEXT)
GROUP BY c.size_id,label 
ORDER BY COUNT(*) DESC
LIMIT 3 

-- 15. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

SELECT name,state,day,CAST(close AS TIME),CAST(open AS TIME),
(CAST(close AS TIME) -CAST(open AS TIME)) AS Opening_hours, 
RANK() OVER (ORDER BY (CAST(close AS TIME) -CAST(open AS TIME)) DESC) 
FROM museum_hours mh
LEFT JOIN museum m ON m.museum_id = mh.museum_id
LIMIT 1 

-- Which museum has the most no of most popular painting style?


SELECT m.name AS museum_name, style,COUNT(*) AS Paintings_Count
FROM work w
LEFT JOIN museum m ON w.museum_id = m.museum_id
GROUP BY style,m.name 
HAVING style IN (SELECT style
				FROM work 
				GROUP BY style 
				ORDER BY COUNT(style) desc
				LIMIT 1)
			AND
			m.name IS NOT NULL
ORDER BY COUNT(*) DESC
LIMIT 1


-- 17. Identify the artists whose paintings are displayed in multiple countries
select  full_name,COUNT(country)
FROM
	(SELECT DISTINCT a.full_name,country
	FROM work w
	LEFT JOIN museum m ON m.museum_id = w.museum_id 
	LEFT JOIN artist a ON a.artist_id = w.artist_id 
	GROUP BY a.full_name,country
	HAVING country IS NOT NULL)
GROUP BY full_name
HAVING COUNT(country) > 1 
ORDER BY COUNT(country) DESC 


with cte as
		(select distinct a.full_name as artist
		--, w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;
	
'''
18. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them
with comma.
'''

SELECT  city,country,count(*) FROM museum 
GROUP BY city,country
HAVING city !~* '^[0-9]'
ORDER BY COUNT(*) DESC

'''
19. Identify the artist and the museum where the most expensive and least expensive
painting is placed. Display the artist name, sale_price, painting name, museum
name, museum city and canvas label
'''

WITH max_min AS
		(SELECT *,RANK() OVER (ORDER BY sale_price DESC) AS rnk_high, 
		 RANK() OVER (ORDER BY sale_price ASC) AS rnk_low
		 FROM product_size) 
SELECT DISTINCT a.full_name,w.work_id,max_min.sale_price,w.name AS painting_name,m.name AS museum_name,m.city,c.label
FROM max_min
JOIN work w ON w.work_id = max_min.work_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN museum m ON w.museum_id = m.museum_id
JOIN canvas_size c ON c.size_id = max_min.size_id::NUMERIC
WHERE rnk_high = 1 OR rnk_low = 1 

-- 20. Which country has the 5th highest no of paintings?
-- Method1 	
SELECT country,num_of_paintings
	FROM 
		(SELECT country, COUNT(*) AS num_of_paintings,
		 RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
		FROM work w 
		LEFT JOIN museum m ON w.museum_id =m.museum_id
		WHERE country IS NOT NULL 
		GROUP BY country
		ORDER BY 2 DESC) U
where rnk = 5 

-- Method2
WITH cte AS
			(SELECT country, COUNT(*) AS num_of_paintings,
			 RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
			 FROM work w 
			 LEFT JOIN museum m ON w.museum_id =m.museum_id
			 WHERE country IS NOT NULL 
			 GROUP BY country)
SELECT country,num_of_paintings
FROM cte 
WHERE rnk = 5 

-- 21. Which are the 3 most popular and 3 least popular painting styles?

WITH top_bottom AS 
				( SELECT style,COUNT(*) AS num_of_paintings,
				 	RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk_top,
				 	RANK() OVER (ORDER BY COUNT(*) ASC) AS rnk_bottom
				 	FROM work 
				 	WHERE style IS NOT NULL
				 	GROUP BY style			 	
				)
SELECT top_bottom.style,num_of_paintings
FROM top_bottom 
WHERE rnk_top IN (1,2,3) OR
		rnk_bottom IN (1,2,3)

''' 22. Which artist has the most no of Portraits diplayed outside USA paintings ?. Display artist
name, no of paintings and the artist nationality. '''

WITH portrait_arts AS
					( SELECT s.subject ,COUNT(s.subject) AS no_of_paintings,a.full_name,a.nationality FROM work w 
					  LEFT JOIN subject s ON s.work_id = w.work_id
					  LEFT JOIN artist a ON a.artist_id = w.artist_id
					  LEFT JOIN museum m ON m.museum_id = w.museum_id
					  WHERE s.subject = 'Portraits' AND m.country <> 'USA' 
					  GROUP BY s.subject,a.full_name,a.nationality 
					)
SELECT subject,full_name,nationality,no_of_paintings
FROM portrait_arts
ORDER BY no_of_paintings DESC 
LIMIT 2


	