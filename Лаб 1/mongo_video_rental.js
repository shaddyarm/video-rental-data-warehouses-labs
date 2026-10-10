// ЛР MongoDB на базе варианта 14: видеопрокат.
// Только учебная база video_rental_lab; повторный запуск детерминирован.
const video = db.getSiblingDB('video_rental_lab');
video.dropDatabase();

const categories = ['Драма', 'Комедия', 'Фантастика', 'Документальное кино'];
const films = Array.from({length: 12}, (_, j) => {
  const n = j + 1;
  return {
    _id: `FILM-${String(n).padStart(3, '0')}`,
    title: `Фильм ${String(n).padStart(3, '0')}`,
    category: categories[j % 4],
    releaseYear: 2005 + n,
    dailyRate: 90 + 10 * n,
    copies: Array.from({length: 30}, (_, k) => k + 1)
      .filter(copyNo => (copyNo - 1) % 12 === j)
      .map(copyNo => ({barcode: `COPY-${String(copyNo).padStart(3, '0')}`}))
  };
});
const customers = Array.from({length: 20}, (_, j) => {
  const n = j + 1;
  return {
    _id: `CARD-${String(n).padStart(3, '0')}`,
    fullName: `Клиент ${String(n).padStart(3, '0')}`,
    phone: `+7-900-${String(n).padStart(7, '0')}`
  };
});
video.films.insertMany(films);
video.customers.insertMany(customers);

const rentals = Array.from({length: 100}, (_, j) => {
  const n = j + 1;
  const copyNo = 1 + (j % 30);
  const filmNo = 1 + ((copyNo - 1) % 12);
  const customerNo = 1 + (j % 20);
  const film = films[filmNo - 1];
  return {
    _id: `RENT-${String(n).padStart(4, '0')}`,
    customer: {
      cardNumber: customers[customerNo - 1]._id,
      fullName: customers[customerNo - 1].fullName
    },
    item: {
      filmCode: film._id,
      title: film.title,
      category: film.category,
      barcode: `COPY-${String(copyNo).padStart(3, '0')}`
    },
    rentedAt: new Date(Date.UTC(2025, 0, 1 + n, 7)),
    dueAt: new Date(Date.UTC(2025, 0, 6 + n, 7)),
    returnedAt: n <= 70 ? new Date(Date.UTC(2025, 0, 5 + n, 7)) : null,
    paidAmount: n <= 70 ? film.dailyRate * 4 : 0
  };
});
video.rentals.insertMany(rentals);
video.rentals.createIndex({'customer.cardNumber': 1, rentedAt: -1});
video.rentals.createIndex({'item.filmCode': 1});
video.rentals.createIndex({returnedAt: 1, dueAt: 1});

function report(title, pipeline) {
  print(`\n${title}`);
  video.rentals.aggregate(pipeline).forEach(row => print(EJSON.stringify(row)));
}

print(`База: ${video.getName()}`);
print(`Коллекции: ${video.getCollectionNames().sort().join(', ')}`);
print(`Документы: films=${video.films.countDocuments({})}, customers=${video.customers.countDocuments({})}, rentals=${video.rentals.countDocuments({})}`);

report('ОТЧЕТ 1. Число выдач по жанрам', [
  {$group: {_id: '$item.category', rentals: {$sum: 1}}},
  {$sort: {rentals: -1, _id: 1}}
]);
report('ОТЧЕТ 2. Выручка по жанрам', [
  {$match: {returnedAt: {$ne: null}}},
  {$group: {_id: '$item.category', revenue: {$sum: '$paidAmount'}}},
  {$sort: {revenue: -1, _id: 1}}
]);
report('ОТЧЕТ 3. Пять самых активных клиентов', [
  {$group: {_id: '$customer.cardNumber', name: {$first: '$customer.fullName'}, rentals: {$sum: 1}}},
  {$sort: {rentals: -1, _id: 1}}, {$limit: 5}
]);
report('ОТЧЕТ 4. Просроченные открытые выдачи на 01.05.2025', [
  {$match: {returnedAt: null, dueAt: {$lt: new Date('2025-05-01T00:00:00Z')}}},
  {$group: {_id: null, overdueCount: {$sum: 1}}}
]);
report('ОТЧЕТ 5. Пять самых востребованных фильмов', [
  {$group: {_id: '$item.filmCode', title: {$first: '$item.title'}, rentals: {$sum: 1}}},
  {$sort: {rentals: -1, _id: 1}}, {$limit: 5}
]);
report('ОТЧЕТ 6. Открытые выдачи по клиентам', [
  {$match: {returnedAt: null}},
  {$group: {_id: '$customer.cardNumber', openRentals: {$sum: 1}}},
  {$sort: {openRentals: -1, _id: 1}}, {$limit: 5}
]);
