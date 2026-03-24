# Proyecto: Sistema de Gestión Académica (ambito militar)

## Descripción
Sistema multiplataforma diseñado para administrar y optimizar los procesos académicos de una institución. Permite la gestión centralizada de usuarios, estudiantes, docentes, asignaturas y el registro de calificaciones de los alumnos, operando de manera eficiente con persistencia de información.

## Objetivo general
- Proveer una herramienta tecnológica y eficiente para administrar integralmente los procesos académicos y el control de notas en una institución educativa.

## Objetivos específicos (medibles)
- Implementar módulos de gestión (CRUD) funcionales para Estudiantes, Docentes, Cursos y Grupos.
- Desarrollar un sistema de inscripcion y registro histórico de calificaciones.
- Garantizar la persistencia integral de los datos utilizando almacenamiento local mediante SQLite.
- Integrar la exportación de reportes de calificaciones en formatos PDF y Excel.

## Alcance (qué incluye / qué NO incluye)
**Incluye:**
- Sistema de autenticación de usuarios.
- Gestión de roles con accesos específicos (Administradores, Docentes, Estudiantes).
- CRUD principal de directivos, docentes, estudiantes, cursos y periodos académicos.
- Sistema de control de grupos, inscripciones y evaluaciones.
- Generación de reportes locales y exportables a archivos (PDF, Excel).
- Almacenamiento independiente y local (SQLite de manera nativa).

**No incluye (por ahora):**
- Notificaciones en tiempo real, push o envío automático de correos electrónicos.
- Conexión a un servidor hospedado en la nube (Backend remoto).

## Stack tecnológico
- **Frontend / Cliente:** Flutter + Dart
- **Gestión de estado:** Provider
- **Base de datos:** SQLite (`sqflite` / `sqflite_common_ffi`)
- **Documentos & Reportes:** Librerías `pdf` y `excel`
- **Control de versiones:** Git (+ GitHub / GitLab)

## Arquitectura (resumen simple)
Aplicación Cliente (Flutter UI) → Controladores (Provider) → Capa de Repositorios (Lógica) → Base de Datos Local (SQLite)

*(Nota: Este proyecto fue desarrollado con un enfoque "local first", integrando la lógica y base de datos de forma directa en los dispositivos).*

## Módulos core (priorizados)
Debido a la naturaleza de la arquitectura, se reemplazan los Endpoints de API remota por los procesos internos core priorizados en el sistema:
1. `Auth / Users`: Gestión de inicios de sesión y validación de permisos.
2. `Enrollments / Groups`: Procesamiento de inscripciones de estudiantes por grupo y materias.
3. `Grades / Evaluations`: Registro completo de las calificaciones de las diferentes evaluaciones del alumno.
4. `Students / Teachers`: Gestión de perfiles de la comunidad académica.

## Cómo ejecutar el proyecto (local)
1. **Clonar repositorio**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   ```
2. **Obtener dependencias de Flutter**
   Asegúrate de tener Flutter instalado y ejecuta:
   ```bash
   flutter pub get
   ```
3. **Ejecutar la aplicación**
   El soporte principal permite correrlo en emuladores o plataformas de escritorio (ej: Windows):
   ```bash
   flutter run
   ```

## Variables de entorno (ejemplo)
El proyecto funciona de manera standalone con SQLite, por lo que **no** depende de variables de entorno globales desde un `.env` para conexión remota.
La creación y conexión de base de datos se autogestiona localmente en un archivo `.db` almacenado en el dispositivo.

## Equipo y roles
- **Nombre 1:** Frontend (Flutter UI / UX)
- **Nombre 2:** Backend Local (Repositorios de Dart, SQLite)
- **Nombre 3:** DevOps / QA (Testeo, Generación de reportes en PDF y Excel)

Cristhiam Zenon Zenteno Huarachi
