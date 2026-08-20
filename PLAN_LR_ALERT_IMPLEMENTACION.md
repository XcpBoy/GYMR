# PLAN DE IMPLEMENTACIÓN — Feature "LR.ALERT" (análisis de asimetría izquierda/derecha)

> **Autor del plan:** DeepSeek Harness (solo exploración del código, sin modificaciones).
> **Ejecutor:** Claude Code (tiene más experiencia con este codebase).
> **Base:** mapa de código completo en `MAPA_DE_CODIGO_LR_ALERT.md` (en `C:\Users\Ginna\Desktop`). Léelo antes de tocar código.
> **Alcance elegido por el usuario:** Nivel 2 — screen dedicado `LR.ALERT` + card en hub + umbral configurable (default **10%**).

---

## 0. Resumen ejecutivo

Feature nativa en GYMR que calcula la asimetría izquierda/derecha por ejercicio a partir de los sets unilaterales ya logueados, y alerta cuando la brecha supera un umbral configurable. **CERO migración de base de datos**: el lado ya vive en `complex_metadata` de cada set.

---

## 1. Contexto de datos (lo que ya existe)

- Los sets reales logueados viven en la tabla **`workout_sets`** (`lib/database/database.dart` líneas 61–93), **no** en `workout_block_sets` (esa es la tabla de plantillas/Workout Blocks).
- `workout_sets` **NO tiene columna `side`**. El lado se guarda en `complexMetadata` (JSON) como `{"side":"RIGHT"}` / `{"side":"LEFT"}`.
- La sesión/día se agrupa por `log_id` → `workout_logs.date` (un `workout_logs` por día, creado lazy).
- Ejercicio unilateral = `base_exercises.is_unilateral` (columna `is_unilateral`, línea 33 de database.dart).
- Los pares RIGHT/LEFT se insertan en `_addExerciseToDate` y `_addNewSet` (`workout_manager.dart` ~1919–1968 y ~3494–3517): 2 filas, mismo `logId`/`orderIndex`, timestamp LEFT = RIGHT + 1ms.
- El PR ya es per-side (helper `sideOf(WorkoutSet)` en `workout_manager.dart` ~3798–3806).

---

## 2. La métrica (fórmula exacta, reutilizando la lógica existente)

### Carga total por set (mismo criterio canónico que export/charts/VP)
Regla de `_detectLoadDetails` (`lib/services/export_service.dart` ~19–23 y ~329–352):
- `LASTRE` → `weight + bw` (carga añadida sobre el cuerpo)
- `EXT.LOAD` → `weight`
- `JST.BW` → `bw` (el input de carga está deshabilitado)
- `UNMOVABLE` → `weight + bw`
- Restar `assistanceValue` del load bruto antes de sumar bw (ver `_applyAssistance` en `workout_manager.dart` ~3622–3627).

### EORM por lado
- `calculateEpley1RM(weight, reps)` de `lib/logic/calculator.dart`: `1RM = weight * (1 + reps/30)`. Usar para cada set, con `totalLoad` según la regla de carga total.

### Agregación por día
- Para cada lado (RIGHT/LEFT) y cada día: tomar el **mejor EORM** (top set del día). No sumar volumen — la comparación de fuerza debe ser por pico, no por volumen.

### Ventana móvil
- Promediar el mejor EORM de cada lado sobre la ventana (default **14 días**). Suficientemente corto para detectar un desbalance que se abre, sin ruido de un día raro.

### Métrica de asimetría (el número que alerta)
```
asymmetry% = (strongSide − weakSide) / strongSide × 100
```
- `strongSide` = max(promedioR, promedioL), `weakSide` = el otro.
- Siempre relativa al lado fuerte (5kg de diferencia es grave a 10kg, trivial a 80kg).

### Alerta
- Si `asymmetry% > umbral` (default **10%**) para ese ejercicio en la ventana → alerta. Marcado de lado débil.

### Métrica secundaria opcional (recomendada)
- **VP por lado** = `tonnage × (1 + ln(ordinal+1))` (fórmula exacta de `_computeVp()` en `workout_manager.dart` ~3629–3639). Útil para detectar asimetrías de *resistencia/volumen* incluso cuando el EORM es similar (ej: shruggs L falla por resistencia, no por pico). Panel secundario; la alerta principal es EORM.

---

## 3. Arquitectura (respetando AGENTS.md)

### Capa de lógica pura (sin Flutter) — archivo nuevo
**`lib/logic/lr_asymmetry.dart`** — Dart puro, extension methods, sin side effects.
- Input: `List<({DateTime date, double load, double reps, String? side, int ordinal})>` + `bw`.
- Funciones:
  - `groupBySide(sets)` → separa por RIGHT/LEFT (ignora null).
  - `bestEormPerSidePerDay(sets, bw)` → para cada lado y día, el EORM máximo (con regla de carga total + Epley).
  - `computeAsymmetry(bestEormBySide, {double threshold})` → `({double asymmetryPct, double rightEorm, double leftEorm, String weakSide})` y un bool `isAlert`.
  - (opcional) `vpPerSide(sets, bw)` para la métrica secundaria.
- Reusar las fórmulas EXACTAS de las secciones anteriores (no reinventar load types).

### Provider DB-reactivo
**`lib/providers/charts_provider.dart`** (añadir) o archivo nuevo `lib/providers/lr_provider.dart`.
- `lrAsymmetryProvider = StreamProvider.family<LrAsymmetryResult, (int exerciseId, DateTimeRange?)>`.
- Copiar el patrón de `oneRmProgressionProvider` (líneas 230–303):
  - join `workout_sets` + `workout_logs` + `base_exercises`, filtro por `baseExerciseId`.
  - filtro temporal por `timestamp.isBetweenValues(...)` (o `workout_logs.date`).
  - cache de peso corporal por fecha con cutoff en **segundos** (`date.millisecondsSinceEpoch ~/ 1000`) — AGENTS.md advierte que Drift guarda fechas como unix seconds; NO usar raw milliseconds.
  - `customSelect` con `variables: [drift.Variable(...)]`, nunca interpolar datos de usuario en SQL.
- Parsear `side` de `complex_metadata` (jsonDecode, `try/catch`, null si no es unilateral o falla).
- Agrupar por (fecha, lado), aplicar la lógica pura de `lr_asymmetry.dart`.

### Chart widget
**`lib/ui/charts/chart_widgets.dart`** (añadir) — nuevo widget `LrAsymmetryChart`.
- `fl_chart` ya importado.
- Recomendación: un `BarChart` con **dos barras por fecha** (R con color `UI_UNILATERAL_RIGHT`, L con `UI_UNILATERAL_LEFT`), O un `SessionLineChart` con la `asymmetry%` por fecha + una **línea horizontal de umbral**.
- Envolver en `LabChartContainer` (convención de todo chart).
- Colores SOLO por `themeControllerProvider.getColor()` (excepciones: `LabColors.primary`, `Colors.grey[800]`).

### Screen dedicado — archivo nuevo
**`lib/ui/lr_alert_screen.dart`** — `ConsumerWidget` + `MainScaffold(screenKey: 'LR_ALERT', bottomNavigationBar: LabFooter())`.
- Contenido:
  1. **Tabla de todos los ejercicios unilaterales** con su `asymmetry%` (ventana 14 días) y lado débil, ordenados por peor primero. Fila en color de alerta si cruza el umbral.
  2. **Tap en un ejercicio** → el `LrAsymmetryChart` de ese ejercicio (con el `DateTimeRange` global).
  3. **Bloque de correlación con anomalías**: cruzar el lado débil con `somatic_logs` recientes del mismo lado → advertencia (ej: "LEFT = weak side AND recent LEFT pec anomaly → high risk"). Leer `somatic_logs` (tabla existente, ver AGENTS.md sección "Somatic logs"; `spectrum_value` negativo = anomalía).
- `LabButton.onPressed` nunca null (`() {}`).
- Sin `Expanded` directo en `MainScaffold.body` (usar `Column` + `Expanded` hijo, o copiar el build de un screen existente).
- Copiar el build de un screen existente y modificar (convención AGENTS.md).

### Card en el hub
**`lib/ui/main_hub_screen.dart`** (añadir).
- `_buildModuleButton(context, 'NN', 'LR.ALERT', <icono>, settings, tC, lang, defaultColor: <color>, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LrAlertScreen())))` dentro de `_buildCoreModulesGrid`.
- El label del botón `'LR.ALERT'` es la key de color del tema: la card leerá `DASHBOARD_CARD_LR.ALERT` / `_BG` automáticamente (AGENTS.md). CAUTION: no renombrar — el label ES la key.

### Umbral configurable
**`lib/ui/app_config_screen.dart`** (añadir fila numérica).
- No existe aún un toggle numérico (solo bool y string). Guardar como string en `theme_settings` KV.
- Key: `APPCFG_LR_ALERT_THRESHOLD`, valor `"10"`.
- Leer con `double.tryParse(tC.getValue(settings, key) ?? '10')`.
- Escribir con `tC.setValue(key, text)`.
- Validar 0–100%. Botón de reset al default.
- Sin tabla nueva (KV `theme_settings`).

### Localización
**`lib/localization/strings.dart`** (añadir claves EN + valores ES en `esTranslations`).
- Nuevas: `'ASYMMETRY'`, `'WEAK SIDE'`, `'THRESHOLD'`, `'LR.ALERT'` (si es prosa; si es identificador estilizado se renombra en código, no vía tr()).
- Reutilizar `'RIGHT_SIDE'` / `'LEFT_SIDE'` si ya existen (en `UnilateralPairFrame`).
- `tr(lang, 'ENGLISH TEXT')`; NO `tr()` dentro de `const`.

---

## 4. Navegación (opcional pero recomendado)

- (Opcional) `RibbonDestination(id: 'LRALERT', ..., screenBuilder: () => const LrAlertScreen())` en `kRibbonDestinations` (`lib/ui/lab_widgets.dart` ~35–91) para poder asignarlo a un slot en CONFIG.APP.

---

## 5. Archivos a tocar — resumen

| Archivo | Cambio |
|---|---|
| `lib/logic/lr_asymmetry.dart` | **NUEVO** — lógica pura de la métrica |
| `lib/providers/charts_provider.dart` (o `lr_provider.dart`) | **NUEVO provider** `lrAsymmetryProvider` |
| `lib/ui/charts/chart_widgets.dart` | **NUEVO** `LrAsymmetryChart` |
| `lib/ui/lr_alert_screen.dart` | **NUEVO** screen dedicado |
| `lib/ui/main_hub_screen.dart` | Card `LR.ALERT` |
| `lib/ui/app_config_screen.dart` | Fila umbral `APPCFG_LR_ALERT_THRESHOLD` |
| `lib/localization/strings.dart` | Claves EN + ES |
| `lib/database/database.dart` | **NINGÚN cambio** (el lado ya está en complex_metadata) |
| `lib/providers/theme_provider.dart` | **NINGÚN cambio** (ya tiene setValue/getValue) |

---

## 6. Verificación

1. `dart analyze lib` — limpio de errores.
2. `flutter test` — corre `test/wb_smoke_test.dart` (4 smoke tests). `test/widget_test.dart` falla pre-existente (ignorar).
3. Añadir un test unitario de `lr_asymmetry.dart` con datos reales (ej: un par donde L hace 20 reps y R hace 3 en shruggs → esperar `asymmetry%` alto con `weakSide='LEFT'`).
4. Cambios de UI → hot restart + inspección visual en el Redmi.

---

## 7. Convenciones a respetar (AGENTS.md — crítico)

- `lib/logic` = Dart puro, sin Flutter, extension methods, sin side effects.
- `lib/providers` NUNCA importa widgets/screens.
- `StreamProvider` para DB-reactivo; mutaciones que persisten llaman `_save()`-equivalentes.
- Migraciones aditivas solo; **no hay migración necesaria aquí**.
- `customSelect` con `variables: [drift.Variable(...)]`; nunca interpolar datos de usuario en SQL.
- Fechas de Drift = unix seconds (cutoff en `~/ 1000`).
- Colores SIEMPRE por `themeControllerProvider.getColor()` (excepciones `LabColors.primary`, `Colors.grey[800]`).
- `LabButton.onPressed` nunca null.
- Sin `Expanded` directo en `MainScaffold.body`.
- Localización con `tr(lang, 'EN')` + entrada EN→ES; no `tr()` en `const`; identificadores estilizados renombrados en código.
- Copiar-paste-modificar para UI; estructuras de formulario (no editores JSON crudos).
- Persistencia real en DB, no mocks.
