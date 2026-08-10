import '../models/product.dart';

/// Catálogo de demostración para presentarle la app a un bar.
///
/// Estos productos NO vienen del backend: son datos de ejemplo para
/// mostrar el flujo completo (mesas, comandas, barra/cocina, cobro)
/// sin depender de que el backend ya tenga el catálogo real cargado.
/// Se identifican con ids negativos para que nunca choquen con un id
/// real que llegue de la API.
///
/// Todavía no está conectado a ninguna pantalla ni provider — eso se
/// hace en una fase posterior, junto con la bandera de modo
/// local/remoto.
final List<Product> demoBarCatalog = [
  // Cervezas
  Product(
    id: -1,
    name: 'Cerveza nacional',
    price: 45,
    category: 'Cervezas',
    stock: 80,
  ),
  Product(
    id: -2,
    name: 'Cerveza artesanal',
    price: 75,
    category: 'Cervezas',
    stock: 50,
  ),
  Product(
    id: -3,
    name: 'Cubeta de cerveza',
    price: 320,
    category: 'Cervezas',
    stock: 20,
  ),

  // Cócteles
  Product(
    id: -4,
    name: 'Mojito',
    price: 95,
    category: 'Cócteles',
    stock: 40,
  ),
  Product(
    id: -5,
    name: 'Paloma',
    price: 90,
    category: 'Cócteles',
    stock: 40,
  ),
  Product(
    id: -6,
    name: 'Azulito',
    price: 100,
    category: 'Cócteles',
    stock: 40,
  ),
  Product(
    id: -7,
    name: 'Margarita',
    price: 110,
    category: 'Cócteles',
    stock: 40,
  ),

  // Destilados
  Product(
    id: -8,
    name: 'Tequila por copa',
    price: 85,
    category: 'Destilados',
    stock: 60,
  ),
  Product(
    id: -9,
    name: 'Whisky por copa',
    price: 120,
    category: 'Destilados',
    stock: 60,
  ),
  Product(
    id: -10,
    name: 'Ron por copa',
    price: 80,
    category: 'Destilados',
    stock: 60,
  ),

  // Bebidas sin alcohol
  Product(
    id: -11,
    name: 'Refresco',
    price: 35,
    category: 'Bebidas sin alcohol',
    stock: 100,
  ),
  Product(
    id: -12,
    name: 'Agua mineral',
    price: 40,
    category: 'Bebidas sin alcohol',
    stock: 100,
  ),
  Product(
    id: -13,
    name: 'Agua natural',
    price: 25,
    category: 'Bebidas sin alcohol',
    stock: 100,
  ),

  // Botanas
  Product(
    id: -14,
    name: 'Alitas',
    price: 140,
    category: 'Botanas',
    stock: 30,
  ),
  Product(
    id: -15,
    name: 'Nachos',
    price: 120,
    category: 'Botanas',
    stock: 30,
  ),
  Product(
    id: -16,
    name: 'Papas a la francesa',
    price: 90,
    category: 'Botanas',
    stock: 30,
  ),

  // Promociones
  Product(
    id: -17,
    name: 'Cubeta de 10 cervezas',
    price: 450,
    category: 'Promociones',
    stock: 15,
  ),
  Product(
    id: -18,
    name: '2 mojitos',
    price: 170,
    category: 'Promociones',
    stock: 15,
  ),
];
