

use('sample_mflix')

// PARTE A – CONSULTAS (find)

// ----- Punto 1 -----
// Películas Drama entre 2000 y 2010 con imdb.rating >= 8
// Proyección: title, year, imdb.rating (sin _id)
// Orden: rating descendente, límite 10, conteo total

db.movies.find(
  {
    genres: "Drama",
    year: { $gte: 2000, $lte: 2010 },
    "imdb.rating": { $gte: 8 }
  },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10)

db.movies.countDocuments({
  genres: "Drama",
  year: { $gte: 2000, $lte: 2010 },
  "imdb.rating": { $gte: 8 }
})

// ----- Punto 2 -----
// Películas con Tom Hanks donde el director NO sea Steven Spielberg

db.movies.find({
  cast: "Tom Hanks",
  directors: { $ne: "Steven Spielberg" }
})

// ----- Punto 3 -----
// Películas con exactamente 3 géneros que incluyan Comedy Y Romance
// $size verifica la cantidad exacta; $all verifica que ambos estén presentes

db.movies.find({
  genres: { $size: 3, $all: ["Comedy", "Romance"] }
})

// ----- Punto 4 -----
// Películas sin campo rated, o rated = "UNRATED" o "NOT RATED"
// $exists:false detecta la ausencia del campo; $in maneja los dos valores

db.movies.find({
  $or: [
    { rated: { $exists: false } },
    { rated: { $in: ["UNRATED", "NOT RATED"] } }
  ]
})

db.movies.countDocuments({
  $or: [
    { rated: { $exists: false } },
    { rated: { $in: ["UNRATED", "NOT RATED"] } }
  ]
})

// ----- Punto 5 -----
// Títulos que empiecen por "The" y terminen en "Man"
// Expresión regular con opción "i" para ignorar mayúsculas/minúsculas

db.movies.find(
  { title: { $regex: /^The\b.*Man$/i } },
  { _id: 0, title: 1 }
)


// PARTE B – AGREGACIÓN (aggregate)

// ----- Punto 6 -----
// Por cada género: número de películas, rating promedio (2 dec) y rating máximo
// Solo géneros con más de 500 películas, ordenados por promedio descendente
// Se filtra imdb.rating numérico ($type: "number") para excluir vacíos ("")

db.movies.aggregate([
  { $match: { "imdb.rating": { $type: "number" } } },
  { $unwind: "$genres" },
  { $group: {
      _id: "$genres",
      peliculas: { $sum: 1 },
      promedio:  { $avg: "$imdb.rating" },
      maximo:    { $max: "$imdb.rating" }
  } },
  { $match: { peliculas: { $gt: 500 } } },
  { $project: {
      _id: 0,
      genero: "$_id",
      peliculas: 1,
      promedio: { $round: ["$promedio", 2] },
      maximo: 1
  } },
  { $sort: { promedio: -1 } }
])

// ----- Punto 7 -----
// Top 5 directores con más películas con imdb.rating >= 7.5 (mínimo 5)
// Se muestra director, cantidad y lista de máximo 3 títulos

db.movies.aggregate([
  { $match: { "imdb.rating": { $gte: 7.5 } } },
  { $unwind: "$directors" },
  { $group: {
      _id: "$directors",
      cantidad: { $sum: 1 },
      titulos: { $push: "$title" }
  } },
  { $match: { cantidad: { $gte: 5 } } },
  { $sort: { cantidad: -1 } },
  { $limit: 5 },
  { $project: {
      _id: 0,
      director: "$_id",
      cantidad: 1,
      titulos: { $slice: ["$titulos", 3] }
  } }
])

// ----- Punto 8 -----
// Número de películas por década a partir de 1950
// Se calcula la década con $subtract y $mod sobre year

db.movies.aggregate([
  { $match: { year: { $gte: 1950 } } },
  { $group: {
      _id: { $subtract: ["$year", { $mod: ["$year", 10] }] },
      peliculas: { $sum: 1 }
  } },
  { $project: {
      _id: 0,
      decada: { $concat: [{ $toString: "$_id" }, "s"] },
      peliculas: 1
  } },
  { $sort: { decada: 1 } }
])

// ----- Punto 9 -----
// Top 10 películas más comentadas: título, año y número de comentarios
// $lookup entre comments y movies usando movie_id

db.comments.aggregate([
  { $group: {
      _id: "$movie_id",
      num_comentarios: { $sum: 1 }
  } },
  { $sort: { num_comentarios: -1 } },
  { $limit: 10 },
  { $lookup: {
      from: "movies",
      localField: "_id",
      foreignField: "_id",
      as: "pelicula"
  } },
  { $unwind: "$pelicula" },
  { $project: {
      _id: 0,
      titulo: "$pelicula.title",
      anio: "$pelicula.year",
      num_comentarios: 1
  } }
])

// ----- Punto 10 -----
// Usuarios (por email) con más de 250 comentarios
// Indicando fecha del primer y último comentario

db.comments.aggregate([
  { $group: {
      _id: "$email",
      total_comentarios: { $sum: 1 },
      primer_comentario: { $min: "$date" },
      ultimo_comentario: { $max: "$date" }
  } },
  { $match: { total_comentarios: { $gt: 250 } } },
  { $sort: { total_comentarios: -1 } },
  { $project: {
      _id: 0,
      email: "$_id",
      total_comentarios: 1,
      primer_comentario: 1,
      ultimo_comentario: 1
  } }
])



// PARTE C – ESCRITURA E ÍNDICES

// ----- Punto 11 -----
// Crear colección peliculas_pareja con películas de 2015
// Campos: título, géneros, rating, categoría calculada con $switch

db.movies.aggregate([
  { $match: { year: 2015 } },
  { $project: {
      _id: 0,
      titulo: "$title",
      generos: "$genres",
      rating: "$imdb.rating",
      categoria: {
        $switch: {
          branches: [
            { case: { $gte: ["$imdb.rating", 7.5] }, then: "Alta" },
            { case: { $gte: ["$imdb.rating", 6] },   then: "Media" }
          ],
          default: "Baja"
        }
      }
  } },
  { $out: "peliculas_pareja" }
])

// Verificación
db.peliculas_pareja.find().limit(5)
db.peliculas_pareja.countDocuments()

// ----- Punto 12 -----
// updateMany: agregar revisado: true e incrementar rating en 0.1
// para películas de categoría "Media"

let resultUpdate = db.peliculas_pareja.updateMany(
  { categoria: "Media" },
  {
    $set: { revisado: true },
    $inc: { rating: 0.1 }
  }
)
print("matchedCount:  " + resultUpdate.matchedCount)
print("modifiedCount: " + resultUpdate.modifiedCount)

// ----- Punto 13 -----
// deleteMany: eliminar películas de categoría "Baja"

let resultDelete = db.peliculas_pareja.deleteMany({ categoria: "Baja" })
print("Documentos eliminados: " + resultDelete.deletedCount)

// ----- Punto 14 -----
// explain ANTES del índice (punto 1)

print("=== ANTES del índice (COLLSCAN esperado) ===")
db.movies.find(
  {
    genres: "Drama",
    year: { $gte: 2000, $lte: 2010 },
    "imdb.rating": { $gte: 8 }
  },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10).explain("executionStats")

// Crear índice compuesto con regla ESR:
//   Equality: genres (valor exacto)
//   Sort:     imdb.rating (orden descendente)
//   Range:    year (rango entre 2000 y 2010)

db.movies.createIndex(
  { genres: 1, "imdb.rating": -1, year: 1 },
  { name: "idx_esr_drama_rating_year" }
)

print("=== DESPUÉS del índice (IXSCAN esperado) ===")
db.movies.find(
  {
    genres: "Drama",
    year: { $gte: 2000, $lte: 2010 },
    "imdb.rating": { $gte: 8 }
  },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10).explain("executionStats")

// Comparar:
//   - totalDocsExamined: con COLLSCAN examina todos; con IXSCAN solo los necesarios
//   - executionTimeMillis: debe bajar con el índice
//   - winningPlan.stage: COLLSCAN -> IXSCAN

// Al finalizar, eliminar el índice
db.movies.dropIndex("idx_esr_drama_rating_year")
print("Índice eliminado")

// Índice para optimizar la consulta de pedidos por cliente en un rango de fecha
db.pedidos.createIndex({ "cliente.cliente_id": 1, "fecha": -1 }, { name: "idx_esr_cliente_fecha" });

// Índice para optimizar la búsqueda del Top 5 de restaurantes por ciudad y calificación promedio
db.restaurantes.createIndex({ "ciudad": 1, "calificacion_promedio": -1 }, { name: "idx_esr_ciudad_calificacion" });


// ------------------------------------------
// 2. DOCUMENTOS DE EJEMPLO POR COLECCIÓN
// ------------------------------------------

// Colección: restaurantes (Aplica Patrón Subset y Computed)
db.restaurantes.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"),
  nombre: "El Corral Gourmet",
  ciudad: "Bogotá",
  direccion: "Calle 100 #15-20",
  calificacion_promedio: 4.8,
  total_reseñas: 12500,
  ultimas_reseñas: [
    { 
      cliente_nombre: "Carlos P.", 
      calificacion: 5, 
      comentario: "Excelente servicio y rapidez.", 
      fecha: ISODate("2026-11-10T14:30:00Z") 
    }
  ]
});

// Colección: menus / productos (Aplica Patrón Attribute)
db.menus.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d02"),
  restaurante_id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"),
  nombre: "Hamburguesa Todoterreno",
  precio: 32000,
  categoria: "Hamburguesas",
  atributos: [
    { k: "apto_vegano", v: false },
    { k: "nivel_picante", v: "medio" },
    { k: "tamaño", v: "doble" }
  ]
});

// Colección: clientes
db.clientes.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d04"),
  nombre: "Gabriel Amórtegui",
  email: "gabriel@email.com",
  telefono: "3001234567",
  direcciones: [
    { alias: "Casa", direccion: "Calle 145 #90-10", lat: 4.7, lng: -74.0 }
  ]
});

// Colección: repartidores
db.repartidores.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d05"),
  nombre: "Andrés Gómez",
  vehiculo: "Moto",
  telefono: "3109876543"
});

// Colección: pedidos (Aplica Patrón Extended Reference y Computed)
db.pedidos.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d03"),
  cliente: { 
    cliente_id: ObjectId("654a1b2c3d4e5f6a7b8c9d04"), 
    nombre: "Gabriel Amórtegui" 
  },
  restaurante: { 
    restaurante_id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"), 
    nombre: "El Corral Gourmet" 
  },
  repartidor_id: ObjectId("654a1b2c3d4e5f6a7b8c9d05"),
  fecha: ISODate("2026-11-01T20:15:00Z"),
  estado: "Entregado",
  items: [
    { 
      plato_id: ObjectId("654a1b2c3d4e5f6a7b8c9d02"), 
      nombre_plato: "Hamburguesa Todoterreno", 
      precio_unitario: 32000, 
      cantidad: 2, 
      subtotal: 64000 
    }
  ],
  total_pagado: 64000
});

//CASO 1: DOMICILIOS / RAPPI

use("domicilios_db");

// 1. CREACIÓN DE COLECCIONES E ÍNDICES (REGLA ESR)

// Índice para optimizar la consulta de pedidos por cliente en un rango de fecha
db.pedidos.createIndex({ "cliente.cliente_id": 1, "fecha": -1 }, { name: "idx_esr_cliente_fecha" });

// Índice para optimizar la búsqueda del Top 5 de restaurantes por ciudad y calificación promedio
db.restaurantes.createIndex({ "ciudad": 1, "calificacion_promedio": -1 }, { name: "idx_esr_ciudad_calificacion" });



// 2. DOCUMENTOS DE EJEMPLO POR COLECCIÓN


// Colección: restaurantes (Aplica Patrón Subset y Computed)
db.restaurantes.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"),
  nombre: "El Corral Gourmet",
  ciudad: "Bogotá",
  direccion: "Calle 100 #15-20",
  calificacion_promedio: 4.8,
  total_reseñas: 12500,
  ultimas_reseñas: [
    { 
      cliente_nombre: "Carlos P.", 
      calificacion: 5, 
      comentario: "Excelente servicio y rapidez.", 
      fecha: ISODate("2026-11-10T14:30:00Z") 
    }
  ]
});

// Colección: menus / productos (Aplica Patrón Attribute)
db.menus.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d02"),
  restaurante_id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"),
  nombre: "Hamburguesa Todoterreno",
  precio: 32000,
  categoria: "Hamburguesas",
  atributos: [
    { k: "apto_vegano", v: false },
    { k: "nivel_picante", v: "medio" },
    { k: "tamaño", v: "doble" }
  ]
});

// Colección: clientes
db.clientes.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d04"),
  nombre: "Gabriel Amórtegui",
  email: "gabriel@email.com",
  telefono: "3001234567",
  direcciones: [
    { alias: "Casa", direccion: "Calle 145 #90-10", lat: 4.7, lng: -74.0 }
  ]
});

// Colección: repartidores
db.repartidores.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d05"),
  nombre: "Andrés Gómez",
  vehiculo: "Moto",
  telefono: "3109876543"
});

// Colección: pedidos (Aplica Patrón Extended Reference y Computed)
db.pedidos.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d03"),
  cliente: { 
    cliente_id: ObjectId("654a1b2c3d4e5f6a7b8c9d04"), 
    nombre: "Gabriel Amórtegui" 
  },
  restaurante: { 
    restaurante_id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"), 
    nombre: "El Corral Gourmet" 
  },
  repartidor_id: ObjectId("654a1b2c3d4e5f6a7b8c9d05"),
  fecha: ISODate("2026-11-01T20:15:00Z"),
  estado: "Entregado",
  items: [
    { 
      plato_id: ObjectId("654a1b2c3d4e5f6a7b8c9d02"), 
      nombre_plato: "Hamburguesa Todoterreno", 
      precio_unitario: 32000, 
      cantidad: 2, 
      subtotal: 64000 
    }
  ],
  total_pagado: 64000
});

// Colección: reseñas (Histórico masivo de +50k elementos que desbordan el Subset)
db.reseñas.insertOne({
  _id: ObjectId("654a1b2c3d4e5f6a7b8c9d06"),
  restaurante_id: ObjectId("654a1b2c3d4e5f6a7b8c9d01"),
  cilente_id: ObjectId("654a1b2c3d4e5f6a7b8c9d04"),
  calificacion: 5,
  comentario: "Excelente servicio y rapidez.",
  fecha: ISODate("2026-11-10T14:30:00Z")
});

// 3. CONSULTAS MQL DE NEGOCIO

// Pregunta (a): Pedidos de un cliente en el último mes con el total pagado
db.pedidos.find(
  {
    "cliente.cliente_id": ObjectId("654a1b2c3d4e5f6a7b8c9d04"),
    "fecha": { 
      $gte: ISODate("2026-10-11T00:00:00Z"), 
      $lt: ISODate("2026-11-11T23:59:59Z") 
    }
  },
  { 
    "_id": 1, 
    "fecha": 1, 
    "restaurante.nombre": 1, 
    "items": 1, 
    "total_pagado": 1 
  }
);


// Pregunta (b): Top 5 restaurantes mejor calificados de una ciudad
db.restaurantes.find(
  { "ciudad": "Bogotá" },
  { 
    "nombre": 1, 
    "direccion": 1, 
    "calificacion_promedio": 1, 
    "ultimas_reseñas": 1 
  }
)
.sort({ "calificacion_promedio": -1 })
.limit(5);

// CASO 2: MONITOREO DE CALIDAD DEL AIRE EN BOGOTÁ (IoT)

use("calidad_aire_db");

// 1. CREACIÓN DE COLECCIONES E ÍNDICES


// Evita buckets duplicados y soporta el upsert por sensor y hora
db.lecturas_horarias.createIndex({ sensor_id: 1, inicio: 1 }, { unique: true });

// Soporta consulta (a): igualdad en localidad y rango de tiempo
db.lecturas_horarias.createIndex({ localidad: 1, inicio: 1 });

// Índice parcial para alertas activas (Consulta b)
db.lecturas_horarias.createIndex({ inicio: 1 }, { partialFilterExpression: { "pm25.alertas": { $gt: 0 } } });

// Índice para la colección de sensores por localidad
db.sensores.createIndex({ localidad: 1 });


// 2. DOCUMENTOS DE EJEMPLO

// Colección: sensores
db.sensores.insertOne({
  _id: "S-045",
  localidad: "Kennedy",
  ubicacion: {
    type: "Point",
    Coordenadas: [-74.1475, 4.6286]
  },
  modelo: "AQ-200",
  mide: ["pm25"],
  instalado: ISODate("2026-03-12T00:00:00Z")
});

// Colección: lecturas_horarias (Patrón Bucket, Computed y Schema Versioning v2)
db.lecturas_horarias.insertOne({
  _id: ObjectId("6732f9a1bcf1234567890abc"),
  sensor_id: "S-045",
  localidad: "Kennedy",
  inicio: ISODate("2026-11-09T14:00:00Z"),
  total_mediciones: 3,
  pm25: {
    suma: 118.4,
    max: 44.0,
    alertas: 2
  },
  mediciones: [
    {
      tiempo_exacto: ISODate("2026-11-09T14:00:00Z"),
      pm25: 35.2, pm10: 61.0, temp: 14.5, hum: 78, co2: 520
    },
    {
      tiempo_exacto: ISODate("2026-11-09T14:01:00Z"),
      pm25: 39.2, pm10: 64.3, temp: 14.5, hum: 78, co2: 524
    },
    {
      tiempo_exacto: ISODate("2026-11-09T14:02:00Z"),
      pm25: 44.0, pm10: 70.8, temp: 14.6, hum: 77, co2: 531
    }
  ],
  schema_version: 2
});


// 3. CONSULTAS MQL DE NEGOCIO


// (a) Promedio horario de PM2.5 de una localidad en un día
db.lecturas_horarias.aggregate([
  { $match: { 
      localidad: "Kennedy", 
      inicio: { $gte: ISODate("2026-11-09T05:00:00Z"), $lt: ISODate("2026-11-10T05:00:00Z") } 
  } },
  { $group: { 
      _id: "$inicio", 
      suma: { $sum: "$pm25.suma" }, 
      n: { $sum: "$total_mediciones" } 
  } },
  { $project: { 
      _id: 0, 
      hora: "$_id", 
      pm25_promedio: { $round: [{ $divide: ["$suma", "$n"] }, 2] } 
  } },
  { $sort: { hora: 1 } }
]);


// (b) Sensores que generaron alertas en la última semana
db.lecturas_horarias.aggregate([
  { $match: { 
      inicio: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
      "pm25.alertas": { $gt: 0 } 
  } },
  { $group: { 
      _id: "$sensor_id",
      localidad: { $first: "$localidad" },
      horas_con_alerta: { $sum: 1 },
      mediciones_en_alerta: { $sum: "$pm25.alertas" },
      pico_pm25: { $max: "$pm25.max" }
  } },
  { $sort: { mediciones_en_alerta: -1 } }
]);