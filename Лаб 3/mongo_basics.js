// Базовые операции из выданной инструкции, адаптированные к видеопрокату.
// Работаем в отдельной учебной базе, чтобы не затронуть отчеты ЛР MongoDB.
const basics = db.getSiblingDB('video_basics_lab');
basics.dropDatabase();

print('Текущая база: ' + basics.getName());
print('insertOne: ' + EJSON.stringify(basics.customers.insertOne({
  name: 'Анна', age: 27,
  rentals: [{film: 'Матрица', year: 2024}, {film: 'Солярис', year: 2025}]
})));
print('insertMany: ' + EJSON.stringify(basics.customers.insertMany([
  {name: 'Иван', age: 25, rentals: [{film: 'Солярис', year: 2025}]},
  {name: 'Мария', age: 31, rentals: [{film: 'Сталкер', year: 2023}]},
  {name: 'Иван', age: 35, rentals: [{film: 'Матрица', year: 2022}]}
])));
print('Коллекции: ' + basics.getCollectionNames().join(', '));

function show(title, filter) {
  print(title);
  basics.customers.find(filter, {_id: 0}).sort({age: 1}).forEach(x => print(EJSON.stringify(x)));
}
show('Все документы', {});
show('Равенство: name = Иван', {name: 'Иван'});
show('Сравнение: 25 <= age < 35', {age: {$gte: 25, $lt: 35}});
show('Логическое ИЛИ через $in', {name: {$in: ['Анна', 'Мария']}});
show('Вложенное поле массива: первый фильм = Матрица', {'rentals.0.film': 'Матрица'});

print('Удалено документов с именем Иван: ' + basics.customers.deleteMany({name: 'Иван'}).deletedCount);
print('Осталось документов: ' + basics.customers.countDocuments({}));
basics.temporary.insertOne({purpose: 'проверка drop'});
print('Удалена временная коллекция: ' + basics.temporary.drop());
const temporaryDb = db.getSiblingDB('video_basics_temporary');
temporaryDb.temp.insertOne({purpose: 'проверка dropDatabase'});
print('Удалена временная база: ' + EJSON.stringify(temporaryDb.dropDatabase()));
