# Dummi - Proyecto Flutter

Proyecto Flutter con arquitectura organizada para evitar código spaghetti.

## Estructura del Proyecto

```
dummi/
├── lib/
│   ├── main.dart                 # Punto de entrada de la aplicación
│   └── views/                    # Carpeta de vistas
│       ├── modelo/               # Vista de Modelo
│       │   └── modelo_view.dart
│       └── cuestionario/         # Vista de Cuestionario
│           └── cuestionario_view.dart
```

## Características

- ✅ Arquitectura organizada por carpetas
- ✅ Separación de vistas
- ✅ Navegación por tabs (Bottom Navigation Bar)
- ✅ Dos vistas principales:
  - **Modelo**: Gestión del modelo
  - **Cuestionario**: Gestión de cuestionarios

## Cómo ejecutar

```bash
cd dummi
flutter run
```

## Expandir el proyecto

Para agregar nuevas vistas:
1. Crear una nueva carpeta en `lib/views/nombre_vista/`
2. Crear el archivo `nombre_vista_view.dart`
3. Agregar la vista al array `_views` en `main.dart`
4. Agregar el item correspondiente en el `BottomNavigationBar`

## Recomendaciones de arquitectura

A medida que el proyecto crezca, considera agregar:
- `lib/models/` - Para modelos de datos
- `lib/services/` - Para servicios y lógica de negocio
- `lib/widgets/` - Para widgets reutilizables
- `lib/utils/` - Para utilidades y helpers
- `lib/constants/` - Para constantes de la aplicación
