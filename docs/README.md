# GYMR LITE (web)

Versión mínima de GYMR para el proyecto de estadística aplicada: registra sesiones de
entrenamiento (sets con peso, reps, RPE, RIR, técnica), horas de sueño y hora de inicio
por sesión, y mediciones antropométricas — todo guardado localmente en el navegador
(`localStorage`), sin backend ni base de datos en la nube.

Es un solo archivo (`index.html`) sin dependencias externas: HTML/CSS/JS puro.

## Cómo correrla

### Opción A — GitHub Pages (recomendada, funciona igual en Android e iOS)

1. Sube esta carpeta a un repo de GitHub (puede ser este mismo repo o uno nuevo).
2. En el repo → Settings → Pages → Source: rama `main`, carpeta `/gymr-lite-web` (o mueve
   `index.html` a la raíz de un repo dedicado si prefieres la URL más corta).
3. GitHub te da una URL tipo `https://usuario.github.io/repo/`. Compártela con tus
   compañeros — la abren en Chrome (Android) o Safari (iOS), sin instalar nada.
4. Opcional: "Agregar a pantalla de inicio" desde el navegador para que se sienta como app.

### Opción B — Abrir el archivo directo

Funciona bien en Android Chrome. En iOS Safari es menos confiable (el almacenamiento
local puede no persistir igual al abrir por `file://`), así que si alguien tiene iPhone,
usa la Opción A.

## Datos

- Todo vive en el navegador de cada persona (`localStorage`). Nadie ve los datos de nadie
  — cada quien tiene su propia copia local.
- **Exportar** (pestaña HISTORIA/EXPORT): CSV de sets (una fila por set, con la metadata
  de sesión ya incluida — listo para R/Excel/Python), CSV de mediciones, y un backup
  JSON completo (útil para no perder datos si cambian de celular).
- **Importar backup**: sube un JSON exportado previamente para restaurar datos.
- Borrar el caché del navegador o desinstalar/reinstalar la PWA borra los datos —
  exporten seguido si van a usarla por varias semanas.
