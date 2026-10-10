// Вариант 14: граф видеопроката. Повторный запуск удаляет только данные
// отдельного учебного контейнера Neo4j, затем создает их заново.
MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT customer_id IF NOT EXISTS FOR (c:Customer) REQUIRE c.customerId IS UNIQUE;
CREATE CONSTRAINT film_id IF NOT EXISTS FOR (f:Film) REQUIRE f.filmId IS UNIQUE;
CREATE CONSTRAINT category_id IF NOT EXISTS FOR (g:Category) REQUIRE g.categoryId IS UNIQUE;
CREATE CONSTRAINT rental_id IF NOT EXISTS FOR (r:Rental) REQUIRE r.rentalId IS UNIQUE;

UNWIND range(1, 4) AS i
CREATE (:Category {categoryId: i,
                   name: ['Драма', 'Комедия', 'Фантастика', 'Документальное кино'][i - 1]});

UNWIND range(1, 120) AS i
CREATE (:Film {filmId: i,
               catalogCode: 'FILM-' + toString(i),
               title: 'Фильм ' + toString(i),
               dailyRate: 90 + (i % 12) * 10});

UNWIND range(1, 80) AS i
CREATE (:Customer {customerId: i,
                   cardNumber: 'CARD-' + toString(i),
                   name: 'Клиент ' + toString(i)});

MATCH (f:Film), (g:Category)
WHERE g.categoryId = 1 + ((f.filmId - 1) % 4)
MERGE (f)-[:IN_CATEGORY]->(g);

MATCH (c:Customer), (f:Film)
WHERE f.filmId = c.customerId
MERGE (c)-[:FAVORITE]->(f);

UNWIND range(1, 1000) AS i
WITH i, 1 + ((i - 1) % 80) AS cid, 1 + ((i - 1) % 120) AS fid
MATCH (c:Customer {customerId: cid})
MATCH (f:Film {filmId: fid})
CREATE (r:Rental {
  rentalId: i,
  rentalNumber: 'RENT-' + toString(i),
  rentedAt: date('2022-01-01') + duration({days: i}),
  dueAt: date('2022-01-01') + duration({days: i + 5}),
  returnedAt: CASE WHEN i <= 700
    THEN date('2022-01-01') + duration({days: i + 4}) ELSE null END,
  status: CASE WHEN i <= 700 THEN 'returned' ELSE 'open' END
})
CREATE (c)-[:MADE]->(r)
CREATE (r)-[:FOR_FILM]->(f);
