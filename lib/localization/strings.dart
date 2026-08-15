import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';

/// Idioma actual de la app, persistido en `theme_settings` bajo la key
/// 'LANGUAGE' - mismo mecanismo que el resto de settings (ver
/// theme_provider.dart), así que no se necesitó una tabla nueva.
/// Valores válidos: 'en' (default) o 'es'.
final languageProvider = StreamProvider<String>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        "SELECT value FROM theme_settings WHERE key = 'LANGUAGE'",
        readsFrom: {db.themeSettings},
      )
      .watchSingleOrNull()
      .map((row) => (row?.data['value'] as String?) ?? 'en');
});

Future<void> setLanguage(AppDatabase db, String lang) async {
  await db.into(db.themeSettings).insertOnConflictUpdate(
        ThemeSettingsCompanion(
          key: const Value('LANGUAGE'),
          value: Value(lang),
        ),
      );
}

/// Traduce [en] al idioma actual. Si `lang` no es 'es', o si [en] no tiene
/// traducción registrada, devuelve el texto en inglés tal cual (nunca
/// revienta ni muestra texto vacío).
///
/// Los identificadores de estilo (C.WO, CRRNT.WO, THEME.MDFYR,
/// PURGE_SET, etc.) NO pasan por aquí a propósito - esos los renombra el
/// usuario directamente, no son "texto en inglés" a traducir.
String tr(String lang, String en) {
  if (lang == 'es') return esTranslations[en] ?? en;
  return enTranslations[en] ?? en;
}

/// Fecha completa localizada: "MONDAY, JUL 27, 2026" (en) /
/// "LUNES, JUL 27, 2026" (es). Día y mes salen de `esTranslations`; el
/// número de día/año no cambia. `withYear: false` da el formato corto
/// "MONDAY, JUL 27" (usado en popups sin año).
String formatLocalizedDate(String lang, DateTime d, {bool withYear = true}) {
  final day = tr(lang, DateFormat('EEEE').format(d).toUpperCase());
  final mon = tr(lang, DateFormat('MMM').format(d).toUpperCase());
  final base = '$day, $mon ${d.day}';
  return withYear ? '$base, ${d.year}' : base;
}

/// Mapa maestro inglés -> español. Se llena por pantalla; cada bloque de
/// comentario indica de qué archivo vienen esas líneas para poder
/// mantenerlo ordenado según el proyecto crece.
final Map<String, String> esTranslations = {
  // --- dashboard/hub identifiers (EN/ES stylized pairs) ---
  'CRRNT.WO': 'RTNA.ACTL',
  'KNS.INVTRY': 'INVTRO.KNS',
  'WO.BLCKS': 'BLQS.ENTR',
  'WO.BLKCS': 'BLQS.ENTR',
  'ANTRPMT.DT': 'DTS.ANTRPMT',
  'VSR.STATS': 'VSLZA.DT',
  'THEME.MDFYR': 'MDFCDR.TMA',
  'APP.CONFIG': 'CONFIG.APP',
  'SOMATIC_SPECTRUM': 'SPECTRO.SOMTCO',
  'DB.EDIT': 'INSPECTOR.DB',
  'DB_INSPECTOR': 'INSPECTOR.DB',
  '10 OVARCH PLAN': '10 PLAN.GENRL',
  // --- app_config_screen.dart ---
  'RESET COLORS TO DEFAULT': 'RESTAURAR COLORES POR DEFECTO',
  'This will erase every color you\'ve customized across the whole app and restore defaults. Wallpaper and toggle settings are not affected.\n\nThis cannot be undone.':
      'Esto borrará todos los colores que hayas personalizado en toda la app y restaurará los valores por defecto. El wallpaper y los toggles no se ven afectados.\n\nEsto no se puede deshacer.',
  'CANCEL': 'CANCELAR',
  'RESET': 'RESTAURAR',

  // --- pr_logic_screen.dart ---
  'The core metric for theoretical peak performance. Normalizes different rep ranges to a single intensity value.':
      'La métrica central para el rendimiento teórico máximo. Normaliza distintos rangos de repeticiones a un solo valor de intensidad.',
  'Measures performance relative to rest intervals. Higher density workouts yield higher efficiency.':
      'Mide el rendimiento en relación con los intervalos de descanso. Los entrenamientos de mayor densidad producen mayor eficiencia.',
  'Adjusts potential based on perceived exertion. A lower RPE for the same load indicates higher systemic recovery.':
      'Ajusta el potencial según el esfuerzo percibido. Un RPE más bajo para la misma carga indica una mayor recuperación sistémica.',
  'Multiplies theoretical peak by form quality (0.5x to 1.5x). Prioritizes execution over raw weight.':
      'Multiplica el pico teórico por la calidad de ejecución (0.5x a 1.5x). Prioriza la técnica sobre el peso bruto.',
  'Current Load > Historical Max Load': 'Carga Actual > Carga Máxima Histórica',
  'Reps > Historical Max Reps for the specific Load':
      'Repeticiones > Repeticiones Máximas Históricas para esa Carga',
  'Current e1RM > Historical Max e1RM': 'e1RM Actual > e1RM Máximo Histórico',
  'Current Efficiency > Historical Max Efficiency':
      'Eficiencia Actual > Eficiencia Máxima Histórica',
  'Current Recovery-Adj > Historical Max Recovery-Adj':
      'Recuperación Ajustada Actual > Recuperación Ajustada Máxima Histórica',
  'The Rainbow Trophy activates when ANY quality surpasses historical data. The Red Trophy (SMART PR) only activates for the absolute best theoretical performance of the session.':
      'El Trofeo Arcoíris se activa cuando CUALQUIER cualidad supera los datos históricos. El Trofeo Rojo (PR INTELIGENTE) solo se activa para el mejor rendimiento teórico absoluto de la sesión.',

  // --- timeline_calendar_screen.dart ---
  'MON': 'LUN',
  'TUE': 'MAR',
  'WED': 'MIE',
  'THU': 'JUE',
  'FRI': 'VIE',
  'SAT': 'SAB',
  'SUN': 'DOM',
  'CLOSE': 'CERRAR',

  // --- timeline_screen.dart / full_dataset_screen.dart / export_service.dart ---
  'CHRONO_HISTORY': 'CRONO_HISTORIA',
  'FILTER_BY_MOVE_OR_FIELD': 'FILTRAR_POR_MOVIMIENTO_O_CAMPO',
  'PR_ONLY': 'SOLO_PR',
  'NO_DATA_FOR_THIS_PERIOD': 'SIN_DATOS_PARA_ESTE_PERÍODO',
  'GOTO_SESSION': 'IR_A_SESIÓN',
  'KNS_SUMMARY:': 'RESUMEN_KNS:',
  'TOTAL_VOLUME:': 'VOLUMEN_TOTAL:',
  'FULL_DATASET_EXPLORER': 'EXPLORADOR_DATASET_COMPLETO',
  'SETS': 'SERIES',
  'WEIGHT': 'PESO',
  'ANTROPMT': 'ANTROPOM',
  'LIMIT:': 'LÍMITE:',
  'TIME_RANGE: ALL': 'RANGO_DE_TIEMPO: TODO',
  'NO_NOTES_FOUND': 'NO_SE_ENCONTRARON_NOTAS',
  'SHOWING TOP {n} RECORDS': 'MOSTRANDO LOS {n} PRIMEROS REGISTROS',
  'SET': 'SERIE',

  // --- workout_manager.dart / WB.editor.dart (C.WO fechas + utilidades) ---
  'EDIT_MOVEMENT_UTILITY': 'EDITAR UTILIDAD DE MOVIMIENTO',
  'MONDAY': 'LUNES',
  'TUESDAY': 'MARTES',
  'WEDNESDAY': 'MIÉRCOLES',
  'THURSDAY': 'JUEVES',
  'FRIDAY': 'VIERNES',
  'SATURDAY': 'SÁBADO',
  'SUNDAY': 'DOMINGO',
  'JAN': 'ENE',
  'FEB': 'FEB',
  'MAR': 'MAR',
  'APR': 'ABR',
  'MAY': 'MAY',
  'JUN': 'JUN',
  'JUL': 'JUL',
  'AUG': 'AGO',
  'SEP': 'SEP',
  'OCT': 'OCT',
  'NOV': 'NOV',
  'DEC': 'DIC',

  // --- charts/chart_widgets.dart ---
  'OTHER': 'OTRO',

  // --- exercise_history_screen.dart / anthropometric_data_screen.dart / main_hub_screen.dart / exercise_form_screen.dart ---
  'JUMP TO GRFCL HISTORY': 'IR AL HISTORIAL GRÁFICO',
  'LOADING...': 'CARGANDO...',
  'Save Weight': 'Guardar Peso',
  'Inject Metric': 'Inyectar Métrica',
  'IMPORT & EXPORT DATA': 'IMPORTAR Y EXPORTAR DATOS',
  'Add Movement': 'Agregar Movimiento',

  // --- shared across exercise_form_screen.dart / kinisi_tree_screen.dart / complex_metadata_screen.dart ---
  'Copy Existing Movement': 'Copiar Movimiento Existente',
  'Complex Metadata Input': 'Ingreso de Metadatos Complejos',
  'Field / Discipline': 'Campo / Disciplina',
  'Technical Description / Notes': 'Descripción Técnica / Notas',
  'Primary Muscle': 'Músculo Primario',
  'Secondary Muscle': 'Músculo Secundario',
  'Pattern Type': 'Tipo de Patrón',
  'Purpose / Intention': 'Propósito / Intención',
  'Type of Tissue': 'Tipo de Tejido',
  'Name of Tissue': 'Nombre del Tejido',
  'Number of Phases': 'Número de Fases',
  'Phase': 'Fase',
  'Update Movement': 'Actualizar Movimiento',

  // --- kinisi_tree_screen.dart ---
  'UP: PROGRESSIONS': 'ARRIBA: PROGRESIONES',
  'DOWN: REGRESSIONS': 'ABAJO: REGRESIONES',

  // --- complex_metadata_screen.dart ---
  'Commit Metadata': 'Confirmar Metadatos',
  'Abort changes': 'Descartar cambios',
  'Toggle Name (e.g. CHALK)': 'Nombre del interruptor (ej. CHALK)',
  'ADD': 'AGREGAR',
  'Search exercise name...': 'Buscar nombre de ejercicio...',
  'Search toggle name...': 'Buscar nombre de interruptor...',
  'BASE NAME (E.G : VERTICAL PULL)': 'NOMBRE BASE (EJ: JALÓN VERTICAL)',
  'Abort': 'Cancelar',

  // --- WO.Blocks.manager.dart ---
  'DELETE ALL BLOCKS': 'ELIMINAR TODOS LOS BLOQUES',
  'Delete every workout block from WO.BLCKS?':
      '¿Eliminar todos los bloques de entrenamiento de WO.BLCKS?',
  'DELETE ALL': 'ELIMINAR TODO',
  'DEL PAST': 'ELIM. PASADOS',
  'Aggressively delete stale WBs that are not currently visible in WO.BLCKS. If the current WO.BLCKS list is empty, this deletes all possible WBs.':
      'Elimina agresivamente los bloques obsoletos que no están visibles actualmente en WO.BLCKS. Si la lista actual de WO.BLCKS está vacía, esto elimina todos los bloques posibles.',
  'DELETE PAST': 'ELIMINAR PASADOS',
  'CREATE WB': 'CREAR BLOQUE',
  'BLOCK NAME': 'NOMBRE DEL BLOQUE',
  'FOLDER (OPTIONAL)': 'CARPETA (OPCIONAL)',
  'Create Block': 'Crear Bloque',
  'RENAME WB': 'RENOMBRAR BLOQUE',
  'SET FOLDER': 'ASIGNAR CARPETA',
  'DELETE WB': 'ELIMINAR BLOQUE',
  'SAVE': 'GUARDAR',
  'FOLDER NAME': 'NOMBRE DE CARPETA',
  'ASSIGN': 'ASIGNAR',
  'Remove': 'Eliminar',
  'DELETE': 'ELIMINAR',

  // --- export_service.dart ---
  'LOAD': 'CARGA',
  'TOGGLES': 'INTERRUPTORES',
  'EXERCISE': 'EJERCICIO',
  'NOTES': 'NOTAS',
  'DATE': 'FECHA',
  'COMPONENTS': 'COMPONENTES',
  '--- DAY SEGMENT ---': '--- SEGMENTO DEL DÍA ---',
  'SET #': 'SET #',
  'NATURE': 'NATURALEZA',
  'SOMATIC': 'SOMÁTICO',
  'FAILURE': 'FALLO',
  'Generated on:': 'Generado el:',

  // --- lab_widgets.dart / somatic_spectrum_screen.dart / ledger_screen.dart / theme_modding_screen.dart ---
  'UPDATE': 'ACTUALIZAR',
  'REMOVING "{tag}" WILL CLEAR IT FROM ALL RECORDS.':
      'ELIMINAR "{tag}" LO QUITARÁ DE TODOS LOS REGISTROS.',
  'Filter...': 'Filtrar...',
  'FOLDERS': 'CARPETAS',
  'CREATE': 'CREAR',
  'LOGS': 'REGISTROS',
  'TOTAL': 'TOTAL',
  'ANOMALY': 'ANOMALÍA',
  'RECOVERY': 'RECUPERACIÓN',
  'SEARCH...': 'BUSCAR...',
  'SELECTED': 'SELECCIONADO(S)',
  'ADD TO FOLDER': 'AGREGAR A CARPETA',
  'ADD {n} LOG(S) TO FOLDER': 'AGREGAR {n} REGISTRO(S) A CARPETA',
  'NO_FOLDERS_YET — create one below.': 'NO_FOLDERS_YET — crea una abajo.',
  '+ NEW FOLDER': '+ NUEVA CARPETA',
  'DELETE FOLDER?': '¿ELIMINAR CARPETA?',
  'This removes "{name}" — logs stay, only the grouping is deleted.':
      'Esto elimina "{name}" — los registros permanecen, solo se borra la agrupación.',
  'REMOVE FROM FOLDER': 'QUITAR DE CARPETA',
  'LIST': 'LISTA',
  'ERROR:': 'ERROR:',
  'MOST USED': 'MÁS USADO',
  'LEAST USED': 'MENOS USADO',
  'MOST RECENT': 'MÁS RECIENTE',
  'LEAST RECENT': 'MENOS RECIENTE',
  'NO USE FIRST': 'SIN USO PRIMERO',
  'MOVEMENTS': 'MOVIMIENTOS',
  'UNUSED': 'SIN USAR',
  'FAVORITES': 'FAVORITOS',
  'FAVORITE': 'FAVORITO',
  'SEARCH': 'BUSCAR',
  'NO BATCHES YET — Create workout sets with a batch name in complex_metadata to register colors here.':
      'AÚN NO HAY LOTES — Crea series de entrenamiento con un nombre de lote en complex_metadata para registrar colores aquí.',

  // --- db_inspector_screen.dart ---
  'UNDO': 'DESHACER',
  'UNDO ERROR': 'ERROR AL DESHACER',
  'CONFIRM': 'CONFIRMAR',
  'PROCEED': 'CONTINUAR',
  'CONFIRM AGAIN': 'CONFIRMAR DE NUEVO',
  'This action will modify the database.': 'Esta acción modificará la base de datos.',
  'Type CONFIRM to proceed:': 'Escribe CONFIRMAR para continuar:',
  'ABORT': 'CANCELAR',
  'FIND & REPLACE': 'BUSCAR Y REEMPLAZAR',
  'APPLY TO ALL TEXT COLUMNS': 'APLICAR A TODAS LAS COLUMNAS DE TEXTO',
  'Column': 'Columna',
  'Find text': 'Buscar texto',
  'Replace with': 'Reemplazar con',
  'WHOLE WORD ONLY (unchecked: "FL" also matches inside "FLOATING")':
      'SOLO PALABRA COMPLETA (sin marcar: "FL" también coincide dentro de "FLOATING")',
  'REPLACE ALL': 'REEMPLAZAR TODO',
  'REPLACE COMPLETE': 'REEMPLAZO COMPLETADO',
  'ERROR': 'ERROR',
  'NORMALIZE COLUMN': 'NORMALIZAR COLUMNA',
  'UPPERCASE': 'MAYÚSCULAS',
  'Trims/collapses whitespace on the selected column only. Never merges or deletes rows — two different exercises stay two rows.':
      'Recorta/colapsa los espacios en blanco solo en la columna seleccionada. Nunca fusiona ni elimina filas — dos ejercicios diferentes siguen siendo dos filas.',
  'PREVIEW': 'VISTA PREVIA',
  'Table': 'Tabla',
  'AFFECTED ROWS': 'FILAS AFECTADAS',
  'and': 'y',
  'more': 'más',
  'NORMALIZE COMPLETE': 'NORMALIZACIÓN COMPLETADA',
  'rows': 'filas',
  'TO REPLACE': 'A REEMPLAZAR',
  'REPLACE WITH': 'REEMPLAZAR CON',
  'CATEGORY REPLACE': 'REEMPLAZO DE CATEGORÍA',
  'CATEGORY REPLACE COMPLETE': 'REEMPLAZO DE CATEGORÍA COMPLETADO',
  'REPAIR COLUMN TYPES': 'REPARAR TIPOS DE COLUMNA',
  'This will fix all columns in': 'Esto corregirá todas las columnas en',
  'that have wrong SQL types.': 'que tienen tipos SQL incorrectos.',
  'Required after a buggy REINDEX changed REAL/INTEGER columns to TEXT.':
      'Necesario después de que un REINDEX con errores cambiara columnas REAL/INTEGER a TEXT.',
  'REPAIR': 'REPARACIÓN',
  'Fixed table schema (types + defaults)': 'Esquema de tabla corregido (tipos + valores por defecto)',
  'REPAIR ERROR': 'ERROR DE REPARACIÓN',
  'REPAIR TYPES': 'REPARAR TIPOS',
  'Fixing': 'Corrigiendo',
  'columns in': 'columnas en',
  'REPAIR COMPLETE': 'REPARACIÓN COMPLETADA',
  'columns fixed in': 'columnas corregidas en',
  'REINDEX ROWS': 'REINDEXAR FILAS',
  'This will reassign sequential IDs (1,2,3...) to all rows in':
      'Esto reasignará IDs secuenciales (1,2,3...) a todas las filas en',
  'All FK references in other tables will be updated.': 'Todas las referencias FK en otras tablas se actualizarán.',
  'This operation is IRREVERSIBLE.': 'Esta operación es IRREVERSIBLE.',
  'REINDEX': 'REINDEXAR',
  'Already sequential, no changes needed': 'Ya es secuencial, no se necesitan cambios',
  'REINDEX COMPLETE': 'REINDEXACIÓN COMPLETADA',
  'IDs remapped': 'IDs reasignados',
  'REINDEX ERROR': 'ERROR DE REINDEXACIÓN',
  'MERGE ROWS': 'FUSIONAR FILAS',
  'PK to KEEP (survives):': 'PK a CONSERVAR (sobrevive):',
  'PK 1 (keep)': 'PK 1 (conservar)',
  'PK to DELETE (merge into PK 1):': 'PK a ELIMINAR (fusionar en PK 1):',
  'PK 2 (delete)': 'PK 2 (eliminar)',
  'All FK references to PK 2 will be updated to point to PK 1.':
      'Todas las referencias FK a PK 2 se actualizarán para apuntar a PK 1.',
  'MERGE': 'FUSIONAR',
  'MERGED': 'FUSIONADO',
  'FK tables updated': 'tablas FK actualizadas',
  'MERGE ERROR': 'ERROR DE FUSIÓN',
  'UNDO HISTORY': 'HISTORIAL DE DESHACER',
  'VIEW': 'VER',
  'VIEW CONFIG': 'VER CONFIGURACIÓN',
  'EDIT': 'EDITAR',
  'FIND & REPLACE ALL': 'BUSCAR Y REEMPLAZAR TODO',
  'DESTRUCTIVE': 'DESTRUCTIVO',
  'PAGE SIZE / COLUMNS': 'TAMAÑO DE PÁGINA / COLUMNAS',
  'JUMP TO PAGE': 'IR A PÁGINA',
  'GO': 'IR',
  'CONFIG': 'CONFIGURACIÓN',
  'ROWS PER PAGE': 'FILAS POR PÁGINA',
  'VISIBLE COLUMNS  (drag ⋮⋮ to reorder)': 'COLUMNAS VISIBLES  (arrastra ⋮⋮ para reordenar)',
  'APPLY': 'APLICAR',
  'EDIT CELL': 'EDITAR CELDA',
  'PK': 'PK',
  'From': 'De',
  'To': 'A',
  'CELL UPDATED': 'CELDA ACTUALIZADA',
  'Revert': 'Revertir',
  'COLUMN': 'COLUMNA',
  'APPLY REPLACE': 'APLICAR REEMPLAZO',

  // --- ovarch_plan_screen.dart / wb_shared/wb_shared_widgets.dart / nexus_screen.dart ---
  'CREATE THE FIRST PLAN AND BUILD WEEK / DAY / WB FOLDERS.':
      'CREA EL PRIMER PLAN Y ARMA LAS CARPETAS DE SEMANA / DÍA / WB.',
  'TAP TO MANAGE DAYBLOCKS': 'TOCA PARA GESTIONAR LOS DAYBLOCKS',
  'LIVE WB REFERENCE': 'REFERENCIA WB EN VIVO',
  'ADD LIVE REFERENCES TO WORKOUT BLOCKS. WB CHANGES REFLECT HERE AUTOMATICALLY.':
      'AGREGA REFERENCIAS EN VIVO A WORKOUT BLOCKS. LOS CAMBIOS EN WB SE REFLEJAN AQUÍ AUTOMÁTICAMENTE.',
  'DELETE THIS WEEK AND ALL DAYS / DAYBLOCKS INSIDE IT?':
      '¿ELIMINAR ESTA SEMANA Y TODOS LOS DÍAS / DAYBLOCKS QUE CONTIENE?',
  'DELETE THIS DAY AND ALL DAYBLOCK REFERENCES?': '¿ELIMINAR ESTE DÍA Y TODAS LAS REFERENCIAS DE DAYBLOCK?',
  'REMOVE THIS LIVE WB REFERENCE FROM THE DAY? THE WORKOUT BLOCK ITSELF STAYS INTACT.':
      '¿QUITAR ESTA REFERENCIA WB EN VIVO DEL DÍA? EL WORKOUT BLOCK EN SÍ SIGUE INTACTO.',
  'DELETE "{name}" AND ALL WEEKS / DAYS / DAYBLOCKS?': '¿ELIMINAR "{name}" Y TODAS LAS SEMANAS / DÍAS / DAYBLOCKS?',
  'DELETE "{name}" AND EVERYTHING INSIDE IT?': '¿ELIMINAR "{name}" Y TODO LO QUE CONTIENE?',
  'REMOVE': 'QUITAR',
  'Compiles training blocks into a technical diagnostic document.':
      'Compila los bloques de entrenamiento en un documento de diagnóstico técnico.',
  'Generates a structured .md file replicating the PDF table architecture.':
      'Genera un archivo .md estructurado que replica la arquitectura de tablas del PDF.',
  'Generates a complete spreadsheet for deep data analysis.':
      'Genera una hoja de cálculo completa para un análisis de datos a fondo.',
  "THIS WILL OVERWRITE '{name}' AND REQUIRE AN IMMEDIATE APP RESTART. PROCEED?":
      "ESTO SOBRESCRIBIRÁ '{name}' Y REQUERIRÁ REINICIAR LA APP DE INMEDIATO. ¿CONTINUAR?",
  "DATABASE '{name}' HAS BEEN REPLACED SUCCESSFULLY. PLEASE RESTART THE APP MANUALLY NOW TO LOAD NEW DATA.":
      "LA BASE DE DATOS '{name}' SE REEMPLAZÓ CORRECTAMENTE. POR FAVOR REINICIA LA APP MANUALMENTE AHORA PARA CARGAR LOS DATOS NUEVOS.",
  'UNDERSTOOD': 'ENTENDIDO',
  'SHARE': 'COMPARTIR',
  'DOWNLOAD': 'DESCARGAR',
  'IMPORT': 'IMPORTAR',
  'Search...': 'Buscar...',
  'EMPTY': 'VACÍO',
  'FILTER BY LOAD TYPE': 'FILTRAR POR TIPO DE CARGA',
  'FILTER BY IMPL': 'FILTRAR POR IMPLEMENTO',
  'CLEAR ALL FILTERS': 'BORRAR TODOS LOS FILTROS',
  'CLEAR': 'BORRAR',
  'RESULTS': 'RESULTADOS',
  'RESUME': 'REANUDAR',

  // --- WB.editor.dart ---
  'DELETE ALL LOGGED SETS FOR THIS SESSION?': '¿ELIMINAR TODAS LAS SERIES REGISTRADAS DE ESTA SESIÓN?',
  'PURGE_ALL': 'PURGAR_TODO',
  'NAME_YOUR_TEMPLATE...': 'NOMBRA_TU_PLANTILLA...',
  'GENERATE': 'GENERAR',
  'BLUEPRINT_CREATED_SUCCESSFULLY': 'BLUEPRINT_CREADO_CON_ÉXITO',
  'NO_DATA_FOUND_FOR_SELECTED_DATE': 'NO_SE_ENCONTRARON_DATOS_PARA_LA_FECHA_SELECCIONADA',
  'SESSION_CLONED_SUCCESSFULLY': 'SESIÓN_CLONADA_CON_ÉXITO',
  'COPY_FROM_SPECIFIC_DAY_FAILED': 'COPIA_DESDE_DÍA_ESPECÍFICO_FALLIDA',
  'Individual Movement': 'Movimiento Individual',
  'Copy From Specific Day': 'Copiar Desde Día Específico',
  'Add Set': 'Agregar Serie',
  'EDIT MOVEMENT': 'EDITAR MOVIMIENTO',
  'PURGE': 'PURGAR',
  'MOVE TO TOP': 'MOVER AL PRINCIPIO',
  'MOVE TO BOTTOM': 'MOVER AL FINAL',
  'RENAME': 'RENOMBRAR',
  'Delete batch': 'Eliminar lote',
  'This will remove it from all sets.': 'Esto lo eliminará de todas las series.',
  'SUPERSET_DISSOLVED': 'SUPERSET_DISUELTO',
  'SELECT MOVEMENTS TO LINK:': 'SELECCIONA MOVIMIENTOS PARA VINCULAR:',
  'ALREADY LINKED': 'YA VINCULADO',
  'Forge Link': 'Forjar Vínculo',
  'Apply Utility': 'Aplicar Utilidad',
  'DELETE ALL SETS?': '¿ELIMINAR TODAS LAS SERIES?',
  'NO_PREVIOUS_SESSION_FOUND': 'NO_SE_ENCONTRÓ_SESIÓN_ANTERIOR',
  'PREVIOUS_DATA_COPIED': 'DATOS_ANTERIORES_COPIADOS',
  'DESCRIPTION': 'DESCRIPCIÓN',
  'NO_RECOVERY_LOGS_YET': 'AÚN_NO_HAY_REGISTROS_DE_RECUPERACIÓN',
  'NO_ANOMALIES_REGISTERED_YET': 'AÚN_NO_HAY_ANOMALÍAS_REGISTRADAS',
  'MAKE BLUEPRINT\nFROM CURRENT': 'HACER BLUEPRINT\nDESDE ACTUAL',
  'DELETE\nALL SETS': 'ELIMINAR\nTODAS LAS SERIES',

  // --- workout_manager.dart ---
  'Workout Block': 'Bloque de Entrenamiento',
  'Plan Day': 'Día del Plan',
  'SELECT WORKOUT BLOCK': 'SELECCIONAR BLOQUE DE ENTRENAMIENTO',
  'INJECTION TYPE': 'TIPO DE INYECCIÓN',
  'INJECT': 'INYECTAR',
  'PERFORMANCE OVERVIEW': 'RESUMEN DE RENDIMIENTO',
  'ASSIGN BATCH': 'ASIGNAR LOTE',
  'ALREADY LINKED:': 'YA VINCULADO:',
  'BODYWEIGHT': 'PESO CORPORAL',
  'ADDED': 'AGREGADO',
  'TONNAGE': 'TONELAJE',
  'FAILURE PHASE': 'FASE DE FALLO',
  'TAGS (COMMA_SEPARATED)': 'ETIQUETAS (SEPARADAS_POR_COMA)',
  'INJECTED TODAY': 'INYECTADO HOY',
  'PURPOSE:': 'PROPÓSITO:',
  'SET 1: (NO DATA)': 'SERIE 1: (SIN DATOS)',
  'REP RANGE:': 'RANGO DE REPETICIONES:',
  'MAKE BLUEPRINT FROM CURRENT': 'CREAR PLANTILLA DESDE ACTUAL',
  'DELETE ALL SETS': 'ELIMINAR TODAS LAS SERIES',
  'MAINTAIN EXTENDED ON': 'MANTENER EXPANDIDO ACTIVADO',
  'MAINTAIN EXTENDED': 'MANTENER EXPANDIDO',

  // --- follow-up batch: specific gaps requested by owner ---
  'CURRENT WORKOUT': 'ENTRENAMIENTO ACTUAL',
  'WORKOUT OPTS': 'OPCIONES DE ENTRENAMIENTO',
  'NO_MOVEMENTS_LOGGED_FOR_THIS_PERIOD': 'Sin movimientos registrados',
  'RAW_DATA_VIEW_ONLY': 'SOLO VISTA DE DATOS CRUDOS',
  'VISUAL_INTERFACE_CUSTOMIZATION': 'PERSONALIZACIÓN DE LA INTERFAZ VISUAL',
  'APP_WIDE_SETTINGS': 'CONFIGURACIÓN GENERAL DE LA APP',
  'SEARCH INVENTORY...': 'BUSCAR EN INVENTARIO...',
  'DELETE ALL KNS?': '¿ELIMINAR TODOS LOS KNS?',
  'This will remove all exercises from this WB.': 'Esto eliminará todos los ejercicios de este WB.',
  'DELETE ALL KNS': 'ELIMINAR TODOS LOS KNS',

  // --- app_config_screen.dart (round 2) ---
  'GENERAL': 'GENERAL',
  'VISUALS': 'VISUALES',
  'LANGUAGE': 'IDIOMA',
  'KNS CARD FACE': 'CARA DE TARJETA KNS',
  'NEW': 'NUEVO',
  'ORIGINAL': 'ORIGINAL',

  // --- somatic_spectrum_screen.dart (round 2) ---
  'NO_FOLDERS_YET': 'AÚN_NO_HAY_CARPETAS',
  'SPECTRUM_OVERVIEW': 'RESUMEN_DEL_ESPECTRO',
  'NO_SOMATIC_LOGS_YET': 'AÚN_NO_HAY_REGISTROS_SOMÁTICOS',
  'CREATE_FOLDER': 'CREAR_CARPETA',
  'FOLDER_NAME': 'NOMBRE_DE_CARPETA',
  'EMPTY_FOLDER': 'CARPETA_VACÍA',

  // --- theme_modding_screen.dart (round 2) ---
  'WORKOUT': 'ENTRENAMIENTO',
  'GLOBAL': 'GLOBAL',
  'DATA': 'DATOS',
  'LIBRARY': 'BIBLIOTECA',
  'HEADER & OPTS': 'ENCABEZADO Y OPCIONES',
  'TAG FILTERS': 'FILTROS DE ETIQUETAS',
  'KNS TAG LABELS': 'ETIQUETAS DE KNS',
  'UTILS': 'UTILIDADES',
  'BATCH COLORS': 'COLORES DE LOTE',
  'INJECTION TYPE COLORS': 'COLORES DE TIPO DE INYECCIÓN',
  'NO_ITEMS': 'SIN_ELEMENTOS',
  'EMPTY_REFERENCE': 'REFERENCIA_VACÍA',
  'RGB_MANUAL_TUNING': 'AJUSTE_MANUAL_RGB',
  'TRANSPARENCY_TUNING': 'AJUSTE_DE_TRANSPARENCIA',
  'APPLY_CONFIGURATION': 'APLICAR_CONFIGURACIÓN',
  'COLOR_SELECTOR': 'SELECTOR_DE_COLOR',

  // --- WB.editor.dart (round 2) ---
  'BLOCK DESCRIPTION...': 'DESCRIPCIÓN DEL BLOQUE...',
  'KNS PURPOSE...': 'PROPÓSITO DEL KNS...',
  'SEARCH INTENT...': 'BUSCAR INTENCIÓN...',
  'INTENT NAME': 'NOMBRE DE INTENCIÓN',
  'COLOR HEX (e.g. #FF5722)': 'COLOR HEX (ej. #FF5722)',
  'NAME': 'NOMBRE',
  'COLOR HEX': 'COLOR HEX',
};

/// Mapa de overrides para el modo inglés: solo se usa cuando el
/// identificador estilizado mostrado en pantalla debe cambiar SIN tocar
/// el string usado como key de personalización de color en DB (que sigue
/// siendo el string original, p. ej. "SOMATIC_SPECTRUM"). Si un string no
/// está acá, `tr()` lo devuelve tal cual.
final Map<String, String> enTranslations = {
  'SOMATIC_SPECTRUM': 'SMTC.SPCTRM',
};
