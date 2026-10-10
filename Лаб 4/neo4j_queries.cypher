// Практические запросы по мотивам лекции: вершины, связи,
// поиск по свойству, соседи, агрегаты и кратчайший путь.
MATCH (n) RETURN labels(n) AS labels, count(*) AS nodes ORDER BY labels;
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS links ORDER BY relation;
MATCH (r:Rental) RETURN count(r) AS rental_records;

MATCH (f:Film {filmId: 1})-[:IN_CATEGORY]->(g:Category)
RETURN f.title AS film, g.name AS category;

MATCH (c:Customer {customerId: 1})-[:MADE]->(r:Rental)-[:FOR_FILM]->(f:Film)
RETURN c.name AS customer, count(r) AS rentals, collect(f.title)[0..5] AS sample_films;

MATCH (f:Film)<-[:FOR_FILM]-(r:Rental)
RETURN f.filmId AS film_id, f.title AS title, count(r) AS rentals
ORDER BY rentals DESC, film_id LIMIT 5;

MATCH (c:Customer {customerId: 1}), (f:Film {filmId: 1})
MATCH p = shortestPath((c)-[:MADE|FOR_FILM*..4]-(f))
RETURN length(p) AS path_length, [n IN nodes(p) | labels(n)[0]] AS path_labels;

MATCH (n) WHERE NOT (n)--()
RETURN count(n) AS isolated_nodes;
