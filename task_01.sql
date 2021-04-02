----------------------------------------------------------
-- При решении использовался синтетический датасет на локальной машние- база osa, схема test
-- SQL Server
use osa;


-- 1. Вывести самую объемную книгу

SELECT name
FROM test.books
WHERE pages = (SELECT MAX(pages)
                FROM test.books)
;


--2. Вывести всех студентов, что брали книгу name_1
-- (студент мог одну книгу брать несколько раз - таких студента нужно вывести только один раз)

SELECT DISTINCT o.name
FROM test.orders AS o
    INNER JOIN test.books b
        ON o.id_book = b.id
WHERE b.name = 'name_1'
;


--3. Какое кол-во студентов брали книгу name_2
-- (поле orders.name  - это уникальный ключ идентификатор студента)

SELECT COUNT(DISTINCT o.name) AS students_count
FROM test.orders AS o
    INNER JOIN test.books b
        ON o.id_book = b.id
WHERE b.name = 'name_2'
;


--4. Вывести в алфавитном порядке названия самых дорогих книг в каждом жанре.
-- C условием, что все цены уникальны

WITH price AS (
    SELECT *
        , RANK() over (
            PARTITION BY genre
            ORDER BY price DESC
        ) AS price_rank
    FROM test.books
)
SELECT genre, name as most_expensive_book_in_genre, price
FROM price
WHERE price_rank = 1
ORDER BY name ASC
;


--5. Вывести дату третьего заказа книги
--  каждого студента (если такой был)
-- Примечание - задание понято в смысле "вывести третий по счету заказ для студента"

WITH orders_num AS (
    SELECT *
    , ROW_NUMBER() over (
        PARTITION BY name
        ORDER BY TRY_CONVERT(datetime2, date, 103) ASC
        ) as order_step
    FROM test.orders
)
SELECT name, date, order_step AS third_order
FROM orders_num
WHERE order_step = 3
;


--6. Вывести имена последних трех студентов, бравших книги,
-- а также книги, которые они брали когда либо

WITH temp AS (
    SELECT *
    , RANK() over (
        PARTITION BY name
        ORDER BY TRY_CONVERT(datetime2, date, 103) DESC
        ) as rank_order
    FROM test.orders
),
temp2 AS(
    SELECT *
    , DENSE_RANK() over (
        ORDER BY TRY_CONVERT(datetime2, date, 103) DESC
        ) as rank_order2
    FROM temp
),
temp3 AS (
    SELECT distinct top (3) name, rank_order2
    FROM temp2
    WHERE rank_order = 1
    ORDER BY rank_order2 ASC
)
SELECT t3.name AS student_name
     , b.name AS book_name
FROM temp3 as t3
    INNER JOIN test.orders AS o
        ON o.name = t3.name
    INNER JOIN test.books AS b
        ON b.id = o.id_book
GROUP BY t3.name, b.name
;


-- 7. Вывести книги, которые студенты не брали в течении текущего месяца

WITH cur_month_orderes AS (
    SELECT *
         , MONTH(TRY_CONVERT(datetime2, date, 103)) AS month
         , (CASE
                WHEN MONTH(TRY_CONVERT(datetime2, date, 103)) = MONTH(GETDATE()) THEN 1
                ELSE 0
            END
        ) AS is_current_month
    FROM test.orders
)
SELECT
    b.name AS book_name
FROM cur_month_orderes AS cmo
    LEFT JOIN test.books AS b
        ON b.id = cmo.id_book
GROUP BY
         b.name
HAVING SUM(cmo.is_current_month) = 0
;

----------------------------------------------------------
