# ComandaPOS Bar — Cliente Flutter

Cliente móvil de ComandaPOS. Documentación completa del proyecto
(problema, roles, arquitectura, modelo de datos, endpoints, guion de
demo) en [`../README.md`](../README.md) y [`../docs/`](../docs/).

## Correr en desarrollo

```bash
flutter pub get
flutter run
```

Antes de correr contra un backend en otra máquina/celular, actualiza
la IP en `lib/main.dart` (comentario junto a `ApiClient`).

## Comandos útiles

```bash
flutter analyze   # análisis estático
flutter test      # pruebas unitarias y de widget (ver docs/pruebas.md)
```

## Estructura

Ver [`../docs/arquitectura.md`](../docs/arquitectura.md).
