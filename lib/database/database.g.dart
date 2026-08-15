// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BaseExercisesTable extends BaseExercises
    with TableInfo<$BaseExercisesTable, BaseExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BaseExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prefixesMeta =
      const VerificationMeta('prefixes');
  @override
  late final GeneratedColumn<String> prefixes = GeneratedColumn<String>(
      'prefixes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _implementsMeta =
      const VerificationMeta('implements');
  @override
  late final GeneratedColumn<String> implements = GeneratedColumn<String>(
      'implements', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyPositionsMeta =
      const VerificationMeta('bodyPositions');
  @override
  late final GeneratedColumn<String> bodyPositions = GeneratedColumn<String>(
      'body_positions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _suffixesMeta =
      const VerificationMeta('suffixes');
  @override
  late final GeneratedColumn<String> suffixes = GeneratedColumn<String>(
      'suffixes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _primaryMuscleGroupMeta =
      const VerificationMeta('primaryMuscleGroup');
  @override
  late final GeneratedColumn<String> primaryMuscleGroup =
      GeneratedColumn<String>('primary_muscle_group', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _secondaryMuscleGroupMeta =
      const VerificationMeta('secondaryMuscleGroup');
  @override
  late final GeneratedColumn<String> secondaryMuscleGroup =
      GeneratedColumn<String>('secondary_muscle_group', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
      'field', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tissueTypeMeta =
      const VerificationMeta('tissueType');
  @override
  late final GeneratedColumn<String> tissueType = GeneratedColumn<String>(
      'tissue_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tissueNameMeta =
      const VerificationMeta('tissueName');
  @override
  late final GeneratedColumn<String> tissueName = GeneratedColumn<String>(
      'tissue_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _numPhasesMeta =
      const VerificationMeta('numPhases');
  @override
  late final GeneratedColumn<int> numPhases = GeneratedColumn<int>(
      'num_phases', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _phaseDescriptionsMeta =
      const VerificationMeta('phaseDescriptions');
  @override
  late final GeneratedColumn<String> phaseDescriptions =
      GeneratedColumn<String>('phase_descriptions', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _intentionMeta =
      const VerificationMeta('intention');
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
      'intention', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _patternTypeMeta =
      const VerificationMeta('patternType');
  @override
  late final GeneratedColumn<String> patternType = GeneratedColumn<String>(
      'pattern_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _complexMetadataMeta =
      const VerificationMeta('complexMetadata');
  @override
  late final GeneratedColumn<String> complexMetadata = GeneratedColumn<String>(
      'complex_metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isUnilateralMeta =
      const VerificationMeta('isUnilateral');
  @override
  late final GeneratedColumn<bool> isUnilateral = GeneratedColumn<bool>(
      'is_unilateral', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_unilateral" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _assistanceTypesMeta =
      const VerificationMeta('assistanceTypes');
  @override
  late final GeneratedColumn<String> assistanceTypes = GeneratedColumn<String>(
      'assistance_types', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameOrderMeta =
      const VerificationMeta('nameOrder');
  @override
  late final GeneratedColumn<String> nameOrder = GeneratedColumn<String>(
      'name_order', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        prefixes,
        implements,
        bodyPositions,
        suffixes,
        primaryMuscleGroup,
        secondaryMuscleGroup,
        field,
        tissueType,
        tissueName,
        numPhases,
        orderIndex,
        phaseDescriptions,
        intention,
        patternType,
        complexMetadata,
        isUnilateral,
        assistanceTypes,
        nameOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'base_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<BaseExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('prefixes')) {
      context.handle(_prefixesMeta,
          prefixes.isAcceptableOrUnknown(data['prefixes']!, _prefixesMeta));
    }
    if (data.containsKey('implements')) {
      context.handle(
          _implementsMeta,
          implements.isAcceptableOrUnknown(
              data['implements']!, _implementsMeta));
    }
    if (data.containsKey('body_positions')) {
      context.handle(
          _bodyPositionsMeta,
          bodyPositions.isAcceptableOrUnknown(
              data['body_positions']!, _bodyPositionsMeta));
    }
    if (data.containsKey('suffixes')) {
      context.handle(_suffixesMeta,
          suffixes.isAcceptableOrUnknown(data['suffixes']!, _suffixesMeta));
    }
    if (data.containsKey('primary_muscle_group')) {
      context.handle(
          _primaryMuscleGroupMeta,
          primaryMuscleGroup.isAcceptableOrUnknown(
              data['primary_muscle_group']!, _primaryMuscleGroupMeta));
    }
    if (data.containsKey('secondary_muscle_group')) {
      context.handle(
          _secondaryMuscleGroupMeta,
          secondaryMuscleGroup.isAcceptableOrUnknown(
              data['secondary_muscle_group']!, _secondaryMuscleGroupMeta));
    }
    if (data.containsKey('field')) {
      context.handle(
          _fieldMeta, field.isAcceptableOrUnknown(data['field']!, _fieldMeta));
    }
    if (data.containsKey('tissue_type')) {
      context.handle(
          _tissueTypeMeta,
          tissueType.isAcceptableOrUnknown(
              data['tissue_type']!, _tissueTypeMeta));
    }
    if (data.containsKey('tissue_name')) {
      context.handle(
          _tissueNameMeta,
          tissueName.isAcceptableOrUnknown(
              data['tissue_name']!, _tissueNameMeta));
    }
    if (data.containsKey('num_phases')) {
      context.handle(_numPhasesMeta,
          numPhases.isAcceptableOrUnknown(data['num_phases']!, _numPhasesMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    if (data.containsKey('phase_descriptions')) {
      context.handle(
          _phaseDescriptionsMeta,
          phaseDescriptions.isAcceptableOrUnknown(
              data['phase_descriptions']!, _phaseDescriptionsMeta));
    }
    if (data.containsKey('intention')) {
      context.handle(_intentionMeta,
          intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta));
    }
    if (data.containsKey('pattern_type')) {
      context.handle(
          _patternTypeMeta,
          patternType.isAcceptableOrUnknown(
              data['pattern_type']!, _patternTypeMeta));
    }
    if (data.containsKey('complex_metadata')) {
      context.handle(
          _complexMetadataMeta,
          complexMetadata.isAcceptableOrUnknown(
              data['complex_metadata']!, _complexMetadataMeta));
    }
    if (data.containsKey('is_unilateral')) {
      context.handle(
          _isUnilateralMeta,
          isUnilateral.isAcceptableOrUnknown(
              data['is_unilateral']!, _isUnilateralMeta));
    }
    if (data.containsKey('assistance_types')) {
      context.handle(
          _assistanceTypesMeta,
          assistanceTypes.isAcceptableOrUnknown(
              data['assistance_types']!, _assistanceTypesMeta));
    }
    if (data.containsKey('name_order')) {
      context.handle(_nameOrderMeta,
          nameOrder.isAcceptableOrUnknown(data['name_order']!, _nameOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BaseExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaseExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      prefixes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prefixes']),
      implements: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}implements']),
      bodyPositions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_positions']),
      suffixes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suffixes']),
      primaryMuscleGroup: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}primary_muscle_group']),
      secondaryMuscleGroup: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}secondary_muscle_group']),
      field: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field']),
      tissueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tissue_type']),
      tissueName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tissue_name']),
      numPhases: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num_phases']),
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      phaseDescriptions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}phase_descriptions']),
      intention: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}intention']),
      patternType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_type']),
      complexMetadata: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}complex_metadata']),
      isUnilateral: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_unilateral'])!,
      assistanceTypes: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}assistance_types']),
      nameOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_order']),
    );
  }

  @override
  $BaseExercisesTable createAlias(String alias) {
    return $BaseExercisesTable(attachedDatabase, alias);
  }
}

class BaseExercise extends DataClass implements Insertable<BaseExercise> {
  final int id;
  final String name;
  final String? prefixes;
  final String? implements;
  final String? bodyPositions;
  final String? suffixes;
  final String? primaryMuscleGroup;
  final String? secondaryMuscleGroup;
  final String? field;
  final String? tissueType;
  final String? tissueName;
  final int? numPhases;
  final int orderIndex;
  final String? phaseDescriptions;
  final String? intention;
  final String? patternType;
  final String? complexMetadata;
  final bool isUnilateral;
  final String? assistanceTypes;
  final String? nameOrder;
  const BaseExercise(
      {required this.id,
      required this.name,
      this.prefixes,
      this.implements,
      this.bodyPositions,
      this.suffixes,
      this.primaryMuscleGroup,
      this.secondaryMuscleGroup,
      this.field,
      this.tissueType,
      this.tissueName,
      this.numPhases,
      required this.orderIndex,
      this.phaseDescriptions,
      this.intention,
      this.patternType,
      this.complexMetadata,
      required this.isUnilateral,
      this.assistanceTypes,
      this.nameOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || prefixes != null) {
      map['prefixes'] = Variable<String>(prefixes);
    }
    if (!nullToAbsent || implements != null) {
      map['implements'] = Variable<String>(implements);
    }
    if (!nullToAbsent || bodyPositions != null) {
      map['body_positions'] = Variable<String>(bodyPositions);
    }
    if (!nullToAbsent || suffixes != null) {
      map['suffixes'] = Variable<String>(suffixes);
    }
    if (!nullToAbsent || primaryMuscleGroup != null) {
      map['primary_muscle_group'] = Variable<String>(primaryMuscleGroup);
    }
    if (!nullToAbsent || secondaryMuscleGroup != null) {
      map['secondary_muscle_group'] = Variable<String>(secondaryMuscleGroup);
    }
    if (!nullToAbsent || field != null) {
      map['field'] = Variable<String>(field);
    }
    if (!nullToAbsent || tissueType != null) {
      map['tissue_type'] = Variable<String>(tissueType);
    }
    if (!nullToAbsent || tissueName != null) {
      map['tissue_name'] = Variable<String>(tissueName);
    }
    if (!nullToAbsent || numPhases != null) {
      map['num_phases'] = Variable<int>(numPhases);
    }
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || phaseDescriptions != null) {
      map['phase_descriptions'] = Variable<String>(phaseDescriptions);
    }
    if (!nullToAbsent || intention != null) {
      map['intention'] = Variable<String>(intention);
    }
    if (!nullToAbsent || patternType != null) {
      map['pattern_type'] = Variable<String>(patternType);
    }
    if (!nullToAbsent || complexMetadata != null) {
      map['complex_metadata'] = Variable<String>(complexMetadata);
    }
    map['is_unilateral'] = Variable<bool>(isUnilateral);
    if (!nullToAbsent || assistanceTypes != null) {
      map['assistance_types'] = Variable<String>(assistanceTypes);
    }
    if (!nullToAbsent || nameOrder != null) {
      map['name_order'] = Variable<String>(nameOrder);
    }
    return map;
  }

  BaseExercisesCompanion toCompanion(bool nullToAbsent) {
    return BaseExercisesCompanion(
      id: Value(id),
      name: Value(name),
      prefixes: prefixes == null && nullToAbsent
          ? const Value.absent()
          : Value(prefixes),
      implements: implements == null && nullToAbsent
          ? const Value.absent()
          : Value(implements),
      bodyPositions: bodyPositions == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyPositions),
      suffixes: suffixes == null && nullToAbsent
          ? const Value.absent()
          : Value(suffixes),
      primaryMuscleGroup: primaryMuscleGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryMuscleGroup),
      secondaryMuscleGroup: secondaryMuscleGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryMuscleGroup),
      field:
          field == null && nullToAbsent ? const Value.absent() : Value(field),
      tissueType: tissueType == null && nullToAbsent
          ? const Value.absent()
          : Value(tissueType),
      tissueName: tissueName == null && nullToAbsent
          ? const Value.absent()
          : Value(tissueName),
      numPhases: numPhases == null && nullToAbsent
          ? const Value.absent()
          : Value(numPhases),
      orderIndex: Value(orderIndex),
      phaseDescriptions: phaseDescriptions == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseDescriptions),
      intention: intention == null && nullToAbsent
          ? const Value.absent()
          : Value(intention),
      patternType: patternType == null && nullToAbsent
          ? const Value.absent()
          : Value(patternType),
      complexMetadata: complexMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(complexMetadata),
      isUnilateral: Value(isUnilateral),
      assistanceTypes: assistanceTypes == null && nullToAbsent
          ? const Value.absent()
          : Value(assistanceTypes),
      nameOrder: nameOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(nameOrder),
    );
  }

  factory BaseExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaseExercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      prefixes: serializer.fromJson<String?>(json['prefixes']),
      implements: serializer.fromJson<String?>(json['implements']),
      bodyPositions: serializer.fromJson<String?>(json['bodyPositions']),
      suffixes: serializer.fromJson<String?>(json['suffixes']),
      primaryMuscleGroup:
          serializer.fromJson<String?>(json['primaryMuscleGroup']),
      secondaryMuscleGroup:
          serializer.fromJson<String?>(json['secondaryMuscleGroup']),
      field: serializer.fromJson<String?>(json['field']),
      tissueType: serializer.fromJson<String?>(json['tissueType']),
      tissueName: serializer.fromJson<String?>(json['tissueName']),
      numPhases: serializer.fromJson<int?>(json['numPhases']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      phaseDescriptions:
          serializer.fromJson<String?>(json['phaseDescriptions']),
      intention: serializer.fromJson<String?>(json['intention']),
      patternType: serializer.fromJson<String?>(json['patternType']),
      complexMetadata: serializer.fromJson<String?>(json['complexMetadata']),
      isUnilateral: serializer.fromJson<bool>(json['isUnilateral']),
      assistanceTypes: serializer.fromJson<String?>(json['assistanceTypes']),
      nameOrder: serializer.fromJson<String?>(json['nameOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'prefixes': serializer.toJson<String?>(prefixes),
      'implements': serializer.toJson<String?>(implements),
      'bodyPositions': serializer.toJson<String?>(bodyPositions),
      'suffixes': serializer.toJson<String?>(suffixes),
      'primaryMuscleGroup': serializer.toJson<String?>(primaryMuscleGroup),
      'secondaryMuscleGroup': serializer.toJson<String?>(secondaryMuscleGroup),
      'field': serializer.toJson<String?>(field),
      'tissueType': serializer.toJson<String?>(tissueType),
      'tissueName': serializer.toJson<String?>(tissueName),
      'numPhases': serializer.toJson<int?>(numPhases),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'phaseDescriptions': serializer.toJson<String?>(phaseDescriptions),
      'intention': serializer.toJson<String?>(intention),
      'patternType': serializer.toJson<String?>(patternType),
      'complexMetadata': serializer.toJson<String?>(complexMetadata),
      'isUnilateral': serializer.toJson<bool>(isUnilateral),
      'assistanceTypes': serializer.toJson<String?>(assistanceTypes),
      'nameOrder': serializer.toJson<String?>(nameOrder),
    };
  }

  BaseExercise copyWith(
          {int? id,
          String? name,
          Value<String?> prefixes = const Value.absent(),
          Value<String?> implements = const Value.absent(),
          Value<String?> bodyPositions = const Value.absent(),
          Value<String?> suffixes = const Value.absent(),
          Value<String?> primaryMuscleGroup = const Value.absent(),
          Value<String?> secondaryMuscleGroup = const Value.absent(),
          Value<String?> field = const Value.absent(),
          Value<String?> tissueType = const Value.absent(),
          Value<String?> tissueName = const Value.absent(),
          Value<int?> numPhases = const Value.absent(),
          int? orderIndex,
          Value<String?> phaseDescriptions = const Value.absent(),
          Value<String?> intention = const Value.absent(),
          Value<String?> patternType = const Value.absent(),
          Value<String?> complexMetadata = const Value.absent(),
          bool? isUnilateral,
          Value<String?> assistanceTypes = const Value.absent(),
          Value<String?> nameOrder = const Value.absent()}) =>
      BaseExercise(
        id: id ?? this.id,
        name: name ?? this.name,
        prefixes: prefixes.present ? prefixes.value : this.prefixes,
        implements: implements.present ? implements.value : this.implements,
        bodyPositions:
            bodyPositions.present ? bodyPositions.value : this.bodyPositions,
        suffixes: suffixes.present ? suffixes.value : this.suffixes,
        primaryMuscleGroup: primaryMuscleGroup.present
            ? primaryMuscleGroup.value
            : this.primaryMuscleGroup,
        secondaryMuscleGroup: secondaryMuscleGroup.present
            ? secondaryMuscleGroup.value
            : this.secondaryMuscleGroup,
        field: field.present ? field.value : this.field,
        tissueType: tissueType.present ? tissueType.value : this.tissueType,
        tissueName: tissueName.present ? tissueName.value : this.tissueName,
        numPhases: numPhases.present ? numPhases.value : this.numPhases,
        orderIndex: orderIndex ?? this.orderIndex,
        phaseDescriptions: phaseDescriptions.present
            ? phaseDescriptions.value
            : this.phaseDescriptions,
        intention: intention.present ? intention.value : this.intention,
        patternType: patternType.present ? patternType.value : this.patternType,
        complexMetadata: complexMetadata.present
            ? complexMetadata.value
            : this.complexMetadata,
        isUnilateral: isUnilateral ?? this.isUnilateral,
        assistanceTypes: assistanceTypes.present
            ? assistanceTypes.value
            : this.assistanceTypes,
        nameOrder: nameOrder.present ? nameOrder.value : this.nameOrder,
      );
  BaseExercise copyWithCompanion(BaseExercisesCompanion data) {
    return BaseExercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      prefixes: data.prefixes.present ? data.prefixes.value : this.prefixes,
      implements:
          data.implements.present ? data.implements.value : this.implements,
      bodyPositions: data.bodyPositions.present
          ? data.bodyPositions.value
          : this.bodyPositions,
      suffixes: data.suffixes.present ? data.suffixes.value : this.suffixes,
      primaryMuscleGroup: data.primaryMuscleGroup.present
          ? data.primaryMuscleGroup.value
          : this.primaryMuscleGroup,
      secondaryMuscleGroup: data.secondaryMuscleGroup.present
          ? data.secondaryMuscleGroup.value
          : this.secondaryMuscleGroup,
      field: data.field.present ? data.field.value : this.field,
      tissueType:
          data.tissueType.present ? data.tissueType.value : this.tissueType,
      tissueName:
          data.tissueName.present ? data.tissueName.value : this.tissueName,
      numPhases: data.numPhases.present ? data.numPhases.value : this.numPhases,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      phaseDescriptions: data.phaseDescriptions.present
          ? data.phaseDescriptions.value
          : this.phaseDescriptions,
      intention: data.intention.present ? data.intention.value : this.intention,
      patternType:
          data.patternType.present ? data.patternType.value : this.patternType,
      complexMetadata: data.complexMetadata.present
          ? data.complexMetadata.value
          : this.complexMetadata,
      isUnilateral: data.isUnilateral.present
          ? data.isUnilateral.value
          : this.isUnilateral,
      assistanceTypes: data.assistanceTypes.present
          ? data.assistanceTypes.value
          : this.assistanceTypes,
      nameOrder: data.nameOrder.present ? data.nameOrder.value : this.nameOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaseExercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('prefixes: $prefixes, ')
          ..write('implements: $implements, ')
          ..write('bodyPositions: $bodyPositions, ')
          ..write('suffixes: $suffixes, ')
          ..write('primaryMuscleGroup: $primaryMuscleGroup, ')
          ..write('secondaryMuscleGroup: $secondaryMuscleGroup, ')
          ..write('field: $field, ')
          ..write('tissueType: $tissueType, ')
          ..write('tissueName: $tissueName, ')
          ..write('numPhases: $numPhases, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('phaseDescriptions: $phaseDescriptions, ')
          ..write('intention: $intention, ')
          ..write('patternType: $patternType, ')
          ..write('complexMetadata: $complexMetadata, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('assistanceTypes: $assistanceTypes, ')
          ..write('nameOrder: $nameOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      prefixes,
      implements,
      bodyPositions,
      suffixes,
      primaryMuscleGroup,
      secondaryMuscleGroup,
      field,
      tissueType,
      tissueName,
      numPhases,
      orderIndex,
      phaseDescriptions,
      intention,
      patternType,
      complexMetadata,
      isUnilateral,
      assistanceTypes,
      nameOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaseExercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.prefixes == this.prefixes &&
          other.implements == this.implements &&
          other.bodyPositions == this.bodyPositions &&
          other.suffixes == this.suffixes &&
          other.primaryMuscleGroup == this.primaryMuscleGroup &&
          other.secondaryMuscleGroup == this.secondaryMuscleGroup &&
          other.field == this.field &&
          other.tissueType == this.tissueType &&
          other.tissueName == this.tissueName &&
          other.numPhases == this.numPhases &&
          other.orderIndex == this.orderIndex &&
          other.phaseDescriptions == this.phaseDescriptions &&
          other.intention == this.intention &&
          other.patternType == this.patternType &&
          other.complexMetadata == this.complexMetadata &&
          other.isUnilateral == this.isUnilateral &&
          other.assistanceTypes == this.assistanceTypes &&
          other.nameOrder == this.nameOrder);
}

class BaseExercisesCompanion extends UpdateCompanion<BaseExercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> prefixes;
  final Value<String?> implements;
  final Value<String?> bodyPositions;
  final Value<String?> suffixes;
  final Value<String?> primaryMuscleGroup;
  final Value<String?> secondaryMuscleGroup;
  final Value<String?> field;
  final Value<String?> tissueType;
  final Value<String?> tissueName;
  final Value<int?> numPhases;
  final Value<int> orderIndex;
  final Value<String?> phaseDescriptions;
  final Value<String?> intention;
  final Value<String?> patternType;
  final Value<String?> complexMetadata;
  final Value<bool> isUnilateral;
  final Value<String?> assistanceTypes;
  final Value<String?> nameOrder;
  const BaseExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.prefixes = const Value.absent(),
    this.implements = const Value.absent(),
    this.bodyPositions = const Value.absent(),
    this.suffixes = const Value.absent(),
    this.primaryMuscleGroup = const Value.absent(),
    this.secondaryMuscleGroup = const Value.absent(),
    this.field = const Value.absent(),
    this.tissueType = const Value.absent(),
    this.tissueName = const Value.absent(),
    this.numPhases = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.phaseDescriptions = const Value.absent(),
    this.intention = const Value.absent(),
    this.patternType = const Value.absent(),
    this.complexMetadata = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    this.assistanceTypes = const Value.absent(),
    this.nameOrder = const Value.absent(),
  });
  BaseExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.prefixes = const Value.absent(),
    this.implements = const Value.absent(),
    this.bodyPositions = const Value.absent(),
    this.suffixes = const Value.absent(),
    this.primaryMuscleGroup = const Value.absent(),
    this.secondaryMuscleGroup = const Value.absent(),
    this.field = const Value.absent(),
    this.tissueType = const Value.absent(),
    this.tissueName = const Value.absent(),
    this.numPhases = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.phaseDescriptions = const Value.absent(),
    this.intention = const Value.absent(),
    this.patternType = const Value.absent(),
    this.complexMetadata = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    this.assistanceTypes = const Value.absent(),
    this.nameOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<BaseExercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? prefixes,
    Expression<String>? implements,
    Expression<String>? bodyPositions,
    Expression<String>? suffixes,
    Expression<String>? primaryMuscleGroup,
    Expression<String>? secondaryMuscleGroup,
    Expression<String>? field,
    Expression<String>? tissueType,
    Expression<String>? tissueName,
    Expression<int>? numPhases,
    Expression<int>? orderIndex,
    Expression<String>? phaseDescriptions,
    Expression<String>? intention,
    Expression<String>? patternType,
    Expression<String>? complexMetadata,
    Expression<bool>? isUnilateral,
    Expression<String>? assistanceTypes,
    Expression<String>? nameOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (prefixes != null) 'prefixes': prefixes,
      if (implements != null) 'implements': implements,
      if (bodyPositions != null) 'body_positions': bodyPositions,
      if (suffixes != null) 'suffixes': suffixes,
      if (primaryMuscleGroup != null)
        'primary_muscle_group': primaryMuscleGroup,
      if (secondaryMuscleGroup != null)
        'secondary_muscle_group': secondaryMuscleGroup,
      if (field != null) 'field': field,
      if (tissueType != null) 'tissue_type': tissueType,
      if (tissueName != null) 'tissue_name': tissueName,
      if (numPhases != null) 'num_phases': numPhases,
      if (orderIndex != null) 'order_index': orderIndex,
      if (phaseDescriptions != null) 'phase_descriptions': phaseDescriptions,
      if (intention != null) 'intention': intention,
      if (patternType != null) 'pattern_type': patternType,
      if (complexMetadata != null) 'complex_metadata': complexMetadata,
      if (isUnilateral != null) 'is_unilateral': isUnilateral,
      if (assistanceTypes != null) 'assistance_types': assistanceTypes,
      if (nameOrder != null) 'name_order': nameOrder,
    });
  }

  BaseExercisesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? prefixes,
      Value<String?>? implements,
      Value<String?>? bodyPositions,
      Value<String?>? suffixes,
      Value<String?>? primaryMuscleGroup,
      Value<String?>? secondaryMuscleGroup,
      Value<String?>? field,
      Value<String?>? tissueType,
      Value<String?>? tissueName,
      Value<int?>? numPhases,
      Value<int>? orderIndex,
      Value<String?>? phaseDescriptions,
      Value<String?>? intention,
      Value<String?>? patternType,
      Value<String?>? complexMetadata,
      Value<bool>? isUnilateral,
      Value<String?>? assistanceTypes,
      Value<String?>? nameOrder}) {
    return BaseExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      prefixes: prefixes ?? this.prefixes,
      implements: implements ?? this.implements,
      bodyPositions: bodyPositions ?? this.bodyPositions,
      suffixes: suffixes ?? this.suffixes,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscleGroup: secondaryMuscleGroup ?? this.secondaryMuscleGroup,
      field: field ?? this.field,
      tissueType: tissueType ?? this.tissueType,
      tissueName: tissueName ?? this.tissueName,
      numPhases: numPhases ?? this.numPhases,
      orderIndex: orderIndex ?? this.orderIndex,
      phaseDescriptions: phaseDescriptions ?? this.phaseDescriptions,
      intention: intention ?? this.intention,
      patternType: patternType ?? this.patternType,
      complexMetadata: complexMetadata ?? this.complexMetadata,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      assistanceTypes: assistanceTypes ?? this.assistanceTypes,
      nameOrder: nameOrder ?? this.nameOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (prefixes.present) {
      map['prefixes'] = Variable<String>(prefixes.value);
    }
    if (implements.present) {
      map['implements'] = Variable<String>(implements.value);
    }
    if (bodyPositions.present) {
      map['body_positions'] = Variable<String>(bodyPositions.value);
    }
    if (suffixes.present) {
      map['suffixes'] = Variable<String>(suffixes.value);
    }
    if (primaryMuscleGroup.present) {
      map['primary_muscle_group'] = Variable<String>(primaryMuscleGroup.value);
    }
    if (secondaryMuscleGroup.present) {
      map['secondary_muscle_group'] =
          Variable<String>(secondaryMuscleGroup.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (tissueType.present) {
      map['tissue_type'] = Variable<String>(tissueType.value);
    }
    if (tissueName.present) {
      map['tissue_name'] = Variable<String>(tissueName.value);
    }
    if (numPhases.present) {
      map['num_phases'] = Variable<int>(numPhases.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (phaseDescriptions.present) {
      map['phase_descriptions'] = Variable<String>(phaseDescriptions.value);
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    if (patternType.present) {
      map['pattern_type'] = Variable<String>(patternType.value);
    }
    if (complexMetadata.present) {
      map['complex_metadata'] = Variable<String>(complexMetadata.value);
    }
    if (isUnilateral.present) {
      map['is_unilateral'] = Variable<bool>(isUnilateral.value);
    }
    if (assistanceTypes.present) {
      map['assistance_types'] = Variable<String>(assistanceTypes.value);
    }
    if (nameOrder.present) {
      map['name_order'] = Variable<String>(nameOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BaseExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('prefixes: $prefixes, ')
          ..write('implements: $implements, ')
          ..write('bodyPositions: $bodyPositions, ')
          ..write('suffixes: $suffixes, ')
          ..write('primaryMuscleGroup: $primaryMuscleGroup, ')
          ..write('secondaryMuscleGroup: $secondaryMuscleGroup, ')
          ..write('field: $field, ')
          ..write('tissueType: $tissueType, ')
          ..write('tissueName: $tissueName, ')
          ..write('numPhases: $numPhases, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('phaseDescriptions: $phaseDescriptions, ')
          ..write('intention: $intention, ')
          ..write('patternType: $patternType, ')
          ..write('complexMetadata: $complexMetadata, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('assistanceTypes: $assistanceTypes, ')
          ..write('nameOrder: $nameOrder')
          ..write(')'))
        .toString();
  }
}

class $PrefixesTable extends Prefixes with TableInfo<$PrefixesTable, Prefixe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefixesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefixes';
  @override
  VerificationContext validateIntegrity(Insertable<Prefixe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prefixe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prefixe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $PrefixesTable createAlias(String alias) {
    return $PrefixesTable(attachedDatabase, alias);
  }
}

class Prefixe extends DataClass implements Insertable<Prefixe> {
  final int id;
  final String name;
  const Prefixe({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  PrefixesCompanion toCompanion(bool nullToAbsent) {
    return PrefixesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Prefixe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prefixe(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Prefixe copyWith({int? id, String? name}) => Prefixe(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Prefixe copyWithCompanion(PrefixesCompanion data) {
    return Prefixe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prefixe(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prefixe && other.id == this.id && other.name == this.name);
}

class PrefixesCompanion extends UpdateCompanion<Prefixe> {
  final Value<int> id;
  final Value<String> name;
  const PrefixesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  PrefixesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Prefixe> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  PrefixesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return PrefixesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefixesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SuffixesTable extends Suffixes with TableInfo<$SuffixesTable, Suffixe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuffixesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suffixes';
  @override
  VerificationContext validateIntegrity(Insertable<Suffixe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Suffixe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Suffixe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $SuffixesTable createAlias(String alias) {
    return $SuffixesTable(attachedDatabase, alias);
  }
}

class Suffixe extends DataClass implements Insertable<Suffixe> {
  final int id;
  final String name;
  const Suffixe({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  SuffixesCompanion toCompanion(bool nullToAbsent) {
    return SuffixesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Suffixe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Suffixe(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Suffixe copyWith({int? id, String? name}) => Suffixe(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Suffixe copyWithCompanion(SuffixesCompanion data) {
    return Suffixe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Suffixe(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Suffixe && other.id == this.id && other.name == this.name);
}

class SuffixesCompanion extends UpdateCompanion<Suffixe> {
  final Value<int> id;
  final Value<String> name;
  const SuffixesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  SuffixesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Suffixe> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  SuffixesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return SuffixesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuffixesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ExerciseVariantsTable extends ExerciseVariants
    with TableInfo<$ExerciseVariantsTable, ExerciseVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _baseIdMeta = const VerificationMeta('baseId');
  @override
  late final GeneratedColumn<int> baseId = GeneratedColumn<int>(
      'base_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES base_exercises (id)'));
  static const VerificationMeta _prefixIdMeta =
      const VerificationMeta('prefixId');
  @override
  late final GeneratedColumn<int> prefixId = GeneratedColumn<int>(
      'prefix_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES prefixes (id)'));
  static const VerificationMeta _suffixIdMeta =
      const VerificationMeta('suffixId');
  @override
  late final GeneratedColumn<int> suffixId = GeneratedColumn<int>(
      'suffix_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES suffixes (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, baseId, prefixId, suffixId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_variants';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseVariant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_id')) {
      context.handle(_baseIdMeta,
          baseId.isAcceptableOrUnknown(data['base_id']!, _baseIdMeta));
    } else if (isInserting) {
      context.missing(_baseIdMeta);
    }
    if (data.containsKey('prefix_id')) {
      context.handle(_prefixIdMeta,
          prefixId.isAcceptableOrUnknown(data['prefix_id']!, _prefixIdMeta));
    }
    if (data.containsKey('suffix_id')) {
      context.handle(_suffixIdMeta,
          suffixId.isAcceptableOrUnknown(data['suffix_id']!, _suffixIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseVariant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      baseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_id'])!,
      prefixId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prefix_id']),
      suffixId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}suffix_id']),
    );
  }

  @override
  $ExerciseVariantsTable createAlias(String alias) {
    return $ExerciseVariantsTable(attachedDatabase, alias);
  }
}

class ExerciseVariant extends DataClass implements Insertable<ExerciseVariant> {
  final int id;
  final int baseId;
  final int? prefixId;
  final int? suffixId;
  const ExerciseVariant(
      {required this.id, required this.baseId, this.prefixId, this.suffixId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_id'] = Variable<int>(baseId);
    if (!nullToAbsent || prefixId != null) {
      map['prefix_id'] = Variable<int>(prefixId);
    }
    if (!nullToAbsent || suffixId != null) {
      map['suffix_id'] = Variable<int>(suffixId);
    }
    return map;
  }

  ExerciseVariantsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseVariantsCompanion(
      id: Value(id),
      baseId: Value(baseId),
      prefixId: prefixId == null && nullToAbsent
          ? const Value.absent()
          : Value(prefixId),
      suffixId: suffixId == null && nullToAbsent
          ? const Value.absent()
          : Value(suffixId),
    );
  }

  factory ExerciseVariant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseVariant(
      id: serializer.fromJson<int>(json['id']),
      baseId: serializer.fromJson<int>(json['baseId']),
      prefixId: serializer.fromJson<int?>(json['prefixId']),
      suffixId: serializer.fromJson<int?>(json['suffixId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseId': serializer.toJson<int>(baseId),
      'prefixId': serializer.toJson<int?>(prefixId),
      'suffixId': serializer.toJson<int?>(suffixId),
    };
  }

  ExerciseVariant copyWith(
          {int? id,
          int? baseId,
          Value<int?> prefixId = const Value.absent(),
          Value<int?> suffixId = const Value.absent()}) =>
      ExerciseVariant(
        id: id ?? this.id,
        baseId: baseId ?? this.baseId,
        prefixId: prefixId.present ? prefixId.value : this.prefixId,
        suffixId: suffixId.present ? suffixId.value : this.suffixId,
      );
  ExerciseVariant copyWithCompanion(ExerciseVariantsCompanion data) {
    return ExerciseVariant(
      id: data.id.present ? data.id.value : this.id,
      baseId: data.baseId.present ? data.baseId.value : this.baseId,
      prefixId: data.prefixId.present ? data.prefixId.value : this.prefixId,
      suffixId: data.suffixId.present ? data.suffixId.value : this.suffixId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseVariant(')
          ..write('id: $id, ')
          ..write('baseId: $baseId, ')
          ..write('prefixId: $prefixId, ')
          ..write('suffixId: $suffixId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, baseId, prefixId, suffixId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseVariant &&
          other.id == this.id &&
          other.baseId == this.baseId &&
          other.prefixId == this.prefixId &&
          other.suffixId == this.suffixId);
}

class ExerciseVariantsCompanion extends UpdateCompanion<ExerciseVariant> {
  final Value<int> id;
  final Value<int> baseId;
  final Value<int?> prefixId;
  final Value<int?> suffixId;
  const ExerciseVariantsCompanion({
    this.id = const Value.absent(),
    this.baseId = const Value.absent(),
    this.prefixId = const Value.absent(),
    this.suffixId = const Value.absent(),
  });
  ExerciseVariantsCompanion.insert({
    this.id = const Value.absent(),
    required int baseId,
    this.prefixId = const Value.absent(),
    this.suffixId = const Value.absent(),
  }) : baseId = Value(baseId);
  static Insertable<ExerciseVariant> custom({
    Expression<int>? id,
    Expression<int>? baseId,
    Expression<int>? prefixId,
    Expression<int>? suffixId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseId != null) 'base_id': baseId,
      if (prefixId != null) 'prefix_id': prefixId,
      if (suffixId != null) 'suffix_id': suffixId,
    });
  }

  ExerciseVariantsCompanion copyWith(
      {Value<int>? id,
      Value<int>? baseId,
      Value<int?>? prefixId,
      Value<int?>? suffixId}) {
    return ExerciseVariantsCompanion(
      id: id ?? this.id,
      baseId: baseId ?? this.baseId,
      prefixId: prefixId ?? this.prefixId,
      suffixId: suffixId ?? this.suffixId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseId.present) {
      map['base_id'] = Variable<int>(baseId.value);
    }
    if (prefixId.present) {
      map['prefix_id'] = Variable<int>(prefixId.value);
    }
    if (suffixId.present) {
      map['suffix_id'] = Variable<int>(suffixId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseVariantsCompanion(')
          ..write('id: $id, ')
          ..write('baseId: $baseId, ')
          ..write('prefixId: $prefixId, ')
          ..write('suffixId: $suffixId')
          ..write(')'))
        .toString();
  }
}

class $ProgressionEdgesTable extends ProgressionEdges
    with TableInfo<$ProgressionEdgesTable, ProgressionEdge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressionEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fromVariantIdMeta =
      const VerificationMeta('fromVariantId');
  @override
  late final GeneratedColumn<int> fromVariantId = GeneratedColumn<int>(
      'from_variant_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES exercise_variants (id)'));
  static const VerificationMeta _toVariantIdMeta =
      const VerificationMeta('toVariantId');
  @override
  late final GeneratedColumn<int> toVariantId = GeneratedColumn<int>(
      'to_variant_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES exercise_variants (id)'));
  @override
  late final GeneratedColumnWithTypeConverter<ProgressionType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ProgressionType>(
              $ProgressionEdgesTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [id, fromVariantId, toVariantId, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progression_edges';
  @override
  VerificationContext validateIntegrity(Insertable<ProgressionEdge> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_variant_id')) {
      context.handle(
          _fromVariantIdMeta,
          fromVariantId.isAcceptableOrUnknown(
              data['from_variant_id']!, _fromVariantIdMeta));
    } else if (isInserting) {
      context.missing(_fromVariantIdMeta);
    }
    if (data.containsKey('to_variant_id')) {
      context.handle(
          _toVariantIdMeta,
          toVariantId.isAcceptableOrUnknown(
              data['to_variant_id']!, _toVariantIdMeta));
    } else if (isInserting) {
      context.missing(_toVariantIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressionEdge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressionEdge(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fromVariantId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_variant_id'])!,
      toVariantId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_variant_id'])!,
      type: $ProgressionEdgesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
    );
  }

  @override
  $ProgressionEdgesTable createAlias(String alias) {
    return $ProgressionEdgesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProgressionType, int, int> $convertertype =
      const EnumIndexConverter<ProgressionType>(ProgressionType.values);
}

class ProgressionEdge extends DataClass implements Insertable<ProgressionEdge> {
  final int id;
  final int fromVariantId;
  final int toVariantId;
  final ProgressionType type;
  const ProgressionEdge(
      {required this.id,
      required this.fromVariantId,
      required this.toVariantId,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_variant_id'] = Variable<int>(fromVariantId);
    map['to_variant_id'] = Variable<int>(toVariantId);
    {
      map['type'] =
          Variable<int>($ProgressionEdgesTable.$convertertype.toSql(type));
    }
    return map;
  }

  ProgressionEdgesCompanion toCompanion(bool nullToAbsent) {
    return ProgressionEdgesCompanion(
      id: Value(id),
      fromVariantId: Value(fromVariantId),
      toVariantId: Value(toVariantId),
      type: Value(type),
    );
  }

  factory ProgressionEdge.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressionEdge(
      id: serializer.fromJson<int>(json['id']),
      fromVariantId: serializer.fromJson<int>(json['fromVariantId']),
      toVariantId: serializer.fromJson<int>(json['toVariantId']),
      type: $ProgressionEdgesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromVariantId': serializer.toJson<int>(fromVariantId),
      'toVariantId': serializer.toJson<int>(toVariantId),
      'type': serializer
          .toJson<int>($ProgressionEdgesTable.$convertertype.toJson(type)),
    };
  }

  ProgressionEdge copyWith(
          {int? id,
          int? fromVariantId,
          int? toVariantId,
          ProgressionType? type}) =>
      ProgressionEdge(
        id: id ?? this.id,
        fromVariantId: fromVariantId ?? this.fromVariantId,
        toVariantId: toVariantId ?? this.toVariantId,
        type: type ?? this.type,
      );
  ProgressionEdge copyWithCompanion(ProgressionEdgesCompanion data) {
    return ProgressionEdge(
      id: data.id.present ? data.id.value : this.id,
      fromVariantId: data.fromVariantId.present
          ? data.fromVariantId.value
          : this.fromVariantId,
      toVariantId:
          data.toVariantId.present ? data.toVariantId.value : this.toVariantId,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionEdge(')
          ..write('id: $id, ')
          ..write('fromVariantId: $fromVariantId, ')
          ..write('toVariantId: $toVariantId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromVariantId, toVariantId, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressionEdge &&
          other.id == this.id &&
          other.fromVariantId == this.fromVariantId &&
          other.toVariantId == this.toVariantId &&
          other.type == this.type);
}

class ProgressionEdgesCompanion extends UpdateCompanion<ProgressionEdge> {
  final Value<int> id;
  final Value<int> fromVariantId;
  final Value<int> toVariantId;
  final Value<ProgressionType> type;
  const ProgressionEdgesCompanion({
    this.id = const Value.absent(),
    this.fromVariantId = const Value.absent(),
    this.toVariantId = const Value.absent(),
    this.type = const Value.absent(),
  });
  ProgressionEdgesCompanion.insert({
    this.id = const Value.absent(),
    required int fromVariantId,
    required int toVariantId,
    required ProgressionType type,
  })  : fromVariantId = Value(fromVariantId),
        toVariantId = Value(toVariantId),
        type = Value(type);
  static Insertable<ProgressionEdge> custom({
    Expression<int>? id,
    Expression<int>? fromVariantId,
    Expression<int>? toVariantId,
    Expression<int>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromVariantId != null) 'from_variant_id': fromVariantId,
      if (toVariantId != null) 'to_variant_id': toVariantId,
      if (type != null) 'type': type,
    });
  }

  ProgressionEdgesCompanion copyWith(
      {Value<int>? id,
      Value<int>? fromVariantId,
      Value<int>? toVariantId,
      Value<ProgressionType>? type}) {
    return ProgressionEdgesCompanion(
      id: id ?? this.id,
      fromVariantId: fromVariantId ?? this.fromVariantId,
      toVariantId: toVariantId ?? this.toVariantId,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromVariantId.present) {
      map['from_variant_id'] = Variable<int>(fromVariantId.value);
    }
    if (toVariantId.present) {
      map['to_variant_id'] = Variable<int>(toVariantId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $ProgressionEdgesTable.$convertertype.toSql(type.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressionEdgesCompanion(')
          ..write('id: $id, ')
          ..write('fromVariantId: $fromVariantId, ')
          ..write('toVariantId: $toVariantId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $WorkoutLogsTable extends WorkoutLogs
    with TableInfo<$WorkoutLogsTable, WorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _workoutStartTimeMeta =
      const VerificationMeta('workoutStartTime');
  @override
  late final GeneratedColumn<DateTime> workoutStartTime =
      GeneratedColumn<DateTime>('workout_start_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _accumulatedSecondsMeta =
      const VerificationMeta('accumulatedSeconds');
  @override
  late final GeneratedColumn<int> accumulatedSeconds = GeneratedColumn<int>(
      'accumulated_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, durationMinutes, workoutStartTime, accumulatedSeconds, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('workout_start_time')) {
      context.handle(
          _workoutStartTimeMeta,
          workoutStartTime.isAcceptableOrUnknown(
              data['workout_start_time']!, _workoutStartTimeMeta));
    }
    if (data.containsKey('accumulated_seconds')) {
      context.handle(
          _accumulatedSecondsMeta,
          accumulatedSeconds.isAcceptableOrUnknown(
              data['accumulated_seconds']!, _accumulatedSecondsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes']),
      workoutStartTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}workout_start_time']),
      accumulatedSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}accumulated_seconds'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $WorkoutLogsTable createAlias(String alias) {
    return $WorkoutLogsTable(attachedDatabase, alias);
  }
}

class WorkoutLog extends DataClass implements Insertable<WorkoutLog> {
  final int id;
  final DateTime date;
  final int? durationMinutes;
  final DateTime? workoutStartTime;
  final int accumulatedSeconds;
  final String? notes;
  const WorkoutLog(
      {required this.id,
      required this.date,
      this.durationMinutes,
      this.workoutStartTime,
      required this.accumulatedSeconds,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || workoutStartTime != null) {
      map['workout_start_time'] = Variable<DateTime>(workoutStartTime);
    }
    map['accumulated_seconds'] = Variable<int>(accumulatedSeconds);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutLogsCompanion(
      id: Value(id),
      date: Value(date),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      workoutStartTime: workoutStartTime == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutStartTime),
      accumulatedSeconds: Value(accumulatedSeconds),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      workoutStartTime:
          serializer.fromJson<DateTime?>(json['workoutStartTime']),
      accumulatedSeconds: serializer.fromJson<int>(json['accumulatedSeconds']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'workoutStartTime': serializer.toJson<DateTime?>(workoutStartTime),
      'accumulatedSeconds': serializer.toJson<int>(accumulatedSeconds),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutLog copyWith(
          {int? id,
          DateTime? date,
          Value<int?> durationMinutes = const Value.absent(),
          Value<DateTime?> workoutStartTime = const Value.absent(),
          int? accumulatedSeconds,
          Value<String?> notes = const Value.absent()}) =>
      WorkoutLog(
        id: id ?? this.id,
        date: date ?? this.date,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        workoutStartTime: workoutStartTime.present
            ? workoutStartTime.value
            : this.workoutStartTime,
        accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
        notes: notes.present ? notes.value : this.notes,
      );
  WorkoutLog copyWithCompanion(WorkoutLogsCompanion data) {
    return WorkoutLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      workoutStartTime: data.workoutStartTime.present
          ? data.workoutStartTime.value
          : this.workoutStartTime,
      accumulatedSeconds: data.accumulatedSeconds.present
          ? data.accumulatedSeconds.value
          : this.accumulatedSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('workoutStartTime: $workoutStartTime, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, durationMinutes, workoutStartTime, accumulatedSeconds, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.durationMinutes == this.durationMinutes &&
          other.workoutStartTime == this.workoutStartTime &&
          other.accumulatedSeconds == this.accumulatedSeconds &&
          other.notes == this.notes);
}

class WorkoutLogsCompanion extends UpdateCompanion<WorkoutLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int?> durationMinutes;
  final Value<DateTime?> workoutStartTime;
  final Value<int> accumulatedSeconds;
  final Value<String?> notes;
  const WorkoutLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.workoutStartTime = const Value.absent(),
    this.accumulatedSeconds = const Value.absent(),
    this.notes = const Value.absent(),
  });
  WorkoutLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.durationMinutes = const Value.absent(),
    this.workoutStartTime = const Value.absent(),
    this.accumulatedSeconds = const Value.absent(),
    this.notes = const Value.absent(),
  }) : date = Value(date);
  static Insertable<WorkoutLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? durationMinutes,
    Expression<DateTime>? workoutStartTime,
    Expression<int>? accumulatedSeconds,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (workoutStartTime != null) 'workout_start_time': workoutStartTime,
      if (accumulatedSeconds != null) 'accumulated_seconds': accumulatedSeconds,
      if (notes != null) 'notes': notes,
    });
  }

  WorkoutLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int?>? durationMinutes,
      Value<DateTime?>? workoutStartTime,
      Value<int>? accumulatedSeconds,
      Value<String?>? notes}) {
    return WorkoutLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      workoutStartTime: workoutStartTime ?? this.workoutStartTime,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (workoutStartTime.present) {
      map['workout_start_time'] = Variable<DateTime>(workoutStartTime.value);
    }
    if (accumulatedSeconds.present) {
      map['accumulated_seconds'] = Variable<int>(accumulatedSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('workoutStartTime: $workoutStartTime, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<int> logId = GeneratedColumn<int>(
      'log_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_logs (id)'));
  static const VerificationMeta _baseExerciseIdMeta =
      const VerificationMeta('baseExerciseId');
  @override
  late final GeneratedColumn<int> baseExerciseId = GeneratedColumn<int>(
      'base_exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES base_exercises (id)'));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<double> reps = GeneratedColumn<double>(
      'reps', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
      'rpe', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<double> rir = GeneratedColumn<double>(
      'rir', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _techniqueMeta =
      const VerificationMeta('technique');
  @override
  late final GeneratedColumn<int> technique = GeneratedColumn<int>(
      'technique', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _failurePhaseMeta =
      const VerificationMeta('failurePhase');
  @override
  late final GeneratedColumn<int> failurePhase = GeneratedColumn<int>(
      'failure_phase', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _restTimeSecondsMeta =
      const VerificationMeta('restTimeSeconds');
  @override
  late final GeneratedColumn<int> restTimeSeconds = GeneratedColumn<int>(
      'rest_time_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _trackNameMeta =
      const VerificationMeta('trackName');
  @override
  late final GeneratedColumn<String> trackName = GeneratedColumn<String>(
      'track_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hypeLevelMeta =
      const VerificationMeta('hypeLevel');
  @override
  late final GeneratedColumn<int> hypeLevel = GeneratedColumn<int>(
      'hype_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isPrSongMeta =
      const VerificationMeta('isPrSong');
  @override
  late final GeneratedColumn<bool> isPrSong = GeneratedColumn<bool>(
      'is_pr_song', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pr_song" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPrMeta = const VerificationMeta('isPr');
  @override
  late final GeneratedColumn<bool> isPr = GeneratedColumn<bool>(
      'is_pr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pr" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _complexMetadataMeta =
      const VerificationMeta('complexMetadata');
  @override
  late final GeneratedColumn<String> complexMetadata = GeneratedColumn<String>(
      'complex_metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetGroupIdMeta =
      const VerificationMeta('supersetGroupId');
  @override
  late final GeneratedColumn<String> supersetGroupId = GeneratedColumn<String>(
      'superset_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetNameMeta =
      const VerificationMeta('supersetName');
  @override
  late final GeneratedColumn<String> supersetName = GeneratedColumn<String>(
      'superset_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assistanceValueMeta =
      const VerificationMeta('assistanceValue');
  @override
  late final GeneratedColumn<double> assistanceValue = GeneratedColumn<double>(
      'assistance_value', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _assistanceTypeMeta =
      const VerificationMeta('assistanceType');
  @override
  late final GeneratedColumn<String> assistanceType = GeneratedColumn<String>(
      'assistance_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        logId,
        baseExerciseId,
        weight,
        reps,
        rpe,
        rir,
        technique,
        failurePhase,
        restTimeSeconds,
        notes,
        trackName,
        hypeLevel,
        isPrSong,
        isPr,
        isCompleted,
        orderIndex,
        timestamp,
        complexMetadata,
        priority,
        supersetGroupId,
        supersetName,
        assistanceValue,
        assistanceType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('log_id')) {
      context.handle(
          _logIdMeta, logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta));
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('base_exercise_id')) {
      context.handle(
          _baseExerciseIdMeta,
          baseExerciseId.isAcceptableOrUnknown(
              data['base_exercise_id']!, _baseExerciseIdMeta));
    } else if (isInserting) {
      context.missing(_baseExerciseIdMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('rpe')) {
      context.handle(
          _rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('technique')) {
      context.handle(_techniqueMeta,
          technique.isAcceptableOrUnknown(data['technique']!, _techniqueMeta));
    }
    if (data.containsKey('failure_phase')) {
      context.handle(
          _failurePhaseMeta,
          failurePhase.isAcceptableOrUnknown(
              data['failure_phase']!, _failurePhaseMeta));
    }
    if (data.containsKey('rest_time_seconds')) {
      context.handle(
          _restTimeSecondsMeta,
          restTimeSeconds.isAcceptableOrUnknown(
              data['rest_time_seconds']!, _restTimeSecondsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('track_name')) {
      context.handle(_trackNameMeta,
          trackName.isAcceptableOrUnknown(data['track_name']!, _trackNameMeta));
    }
    if (data.containsKey('hype_level')) {
      context.handle(_hypeLevelMeta,
          hypeLevel.isAcceptableOrUnknown(data['hype_level']!, _hypeLevelMeta));
    }
    if (data.containsKey('is_pr_song')) {
      context.handle(_isPrSongMeta,
          isPrSong.isAcceptableOrUnknown(data['is_pr_song']!, _isPrSongMeta));
    }
    if (data.containsKey('is_pr')) {
      context.handle(
          _isPrMeta, isPr.isAcceptableOrUnknown(data['is_pr']!, _isPrMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('complex_metadata')) {
      context.handle(
          _complexMetadataMeta,
          complexMetadata.isAcceptableOrUnknown(
              data['complex_metadata']!, _complexMetadataMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('superset_group_id')) {
      context.handle(
          _supersetGroupIdMeta,
          supersetGroupId.isAcceptableOrUnknown(
              data['superset_group_id']!, _supersetGroupIdMeta));
    }
    if (data.containsKey('superset_name')) {
      context.handle(
          _supersetNameMeta,
          supersetName.isAcceptableOrUnknown(
              data['superset_name']!, _supersetNameMeta));
    }
    if (data.containsKey('assistance_value')) {
      context.handle(
          _assistanceValueMeta,
          assistanceValue.isAcceptableOrUnknown(
              data['assistance_value']!, _assistanceValueMeta));
    }
    if (data.containsKey('assistance_type')) {
      context.handle(
          _assistanceTypeMeta,
          assistanceType.isAcceptableOrUnknown(
              data['assistance_type']!, _assistanceTypeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      logId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}log_id'])!,
      baseExerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_exercise_id'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reps'])!,
      rpe: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rpe']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rir']),
      technique: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}technique']),
      failurePhase: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}failure_phase']),
      restTimeSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_time_seconds']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      trackName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_name']),
      hypeLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hype_level']),
      isPrSong: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pr_song'])!,
      isPr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pr'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      complexMetadata: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}complex_metadata']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority']),
      supersetGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}superset_group_id']),
      supersetName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}superset_name']),
      assistanceValue: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}assistance_value']),
      assistanceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assistance_type']),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final int id;
  final int logId;
  final int baseExerciseId;
  final double weight;
  final double reps;
  final double? rpe;
  final double? rir;
  final int? technique;
  final int? failurePhase;
  final int? restTimeSeconds;
  final String? notes;
  final String? trackName;
  final int? hypeLevel;
  final bool isPrSong;
  final bool isPr;
  final bool isCompleted;
  final int orderIndex;
  final DateTime timestamp;
  final String? complexMetadata;
  final String? priority;
  final String? supersetGroupId;
  final String? supersetName;
  final double? assistanceValue;
  final String? assistanceType;
  const WorkoutSet(
      {required this.id,
      required this.logId,
      required this.baseExerciseId,
      required this.weight,
      required this.reps,
      this.rpe,
      this.rir,
      this.technique,
      this.failurePhase,
      this.restTimeSeconds,
      this.notes,
      this.trackName,
      this.hypeLevel,
      required this.isPrSong,
      required this.isPr,
      required this.isCompleted,
      required this.orderIndex,
      required this.timestamp,
      this.complexMetadata,
      this.priority,
      this.supersetGroupId,
      this.supersetName,
      this.assistanceValue,
      this.assistanceType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['log_id'] = Variable<int>(logId);
    map['base_exercise_id'] = Variable<int>(baseExerciseId);
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<double>(reps);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<double>(rir);
    }
    if (!nullToAbsent || technique != null) {
      map['technique'] = Variable<int>(technique);
    }
    if (!nullToAbsent || failurePhase != null) {
      map['failure_phase'] = Variable<int>(failurePhase);
    }
    if (!nullToAbsent || restTimeSeconds != null) {
      map['rest_time_seconds'] = Variable<int>(restTimeSeconds);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || trackName != null) {
      map['track_name'] = Variable<String>(trackName);
    }
    if (!nullToAbsent || hypeLevel != null) {
      map['hype_level'] = Variable<int>(hypeLevel);
    }
    map['is_pr_song'] = Variable<bool>(isPrSong);
    map['is_pr'] = Variable<bool>(isPr);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['order_index'] = Variable<int>(orderIndex);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || complexMetadata != null) {
      map['complex_metadata'] = Variable<String>(complexMetadata);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<String>(supersetGroupId);
    }
    if (!nullToAbsent || supersetName != null) {
      map['superset_name'] = Variable<String>(supersetName);
    }
    if (!nullToAbsent || assistanceValue != null) {
      map['assistance_value'] = Variable<double>(assistanceValue);
    }
    if (!nullToAbsent || assistanceType != null) {
      map['assistance_type'] = Variable<String>(assistanceType);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      logId: Value(logId),
      baseExerciseId: Value(baseExerciseId),
      weight: Value(weight),
      reps: Value(reps),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      technique: technique == null && nullToAbsent
          ? const Value.absent()
          : Value(technique),
      failurePhase: failurePhase == null && nullToAbsent
          ? const Value.absent()
          : Value(failurePhase),
      restTimeSeconds: restTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restTimeSeconds),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      trackName: trackName == null && nullToAbsent
          ? const Value.absent()
          : Value(trackName),
      hypeLevel: hypeLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hypeLevel),
      isPrSong: Value(isPrSong),
      isPr: Value(isPr),
      isCompleted: Value(isCompleted),
      orderIndex: Value(orderIndex),
      timestamp: Value(timestamp),
      complexMetadata: complexMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(complexMetadata),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
      supersetName: supersetName == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetName),
      assistanceValue: assistanceValue == null && nullToAbsent
          ? const Value.absent()
          : Value(assistanceValue),
      assistanceType: assistanceType == null && nullToAbsent
          ? const Value.absent()
          : Value(assistanceType),
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<int>(json['id']),
      logId: serializer.fromJson<int>(json['logId']),
      baseExerciseId: serializer.fromJson<int>(json['baseExerciseId']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<double>(json['reps']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      rir: serializer.fromJson<double?>(json['rir']),
      technique: serializer.fromJson<int?>(json['technique']),
      failurePhase: serializer.fromJson<int?>(json['failurePhase']),
      restTimeSeconds: serializer.fromJson<int?>(json['restTimeSeconds']),
      notes: serializer.fromJson<String?>(json['notes']),
      trackName: serializer.fromJson<String?>(json['trackName']),
      hypeLevel: serializer.fromJson<int?>(json['hypeLevel']),
      isPrSong: serializer.fromJson<bool>(json['isPrSong']),
      isPr: serializer.fromJson<bool>(json['isPr']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      complexMetadata: serializer.fromJson<String?>(json['complexMetadata']),
      priority: serializer.fromJson<String?>(json['priority']),
      supersetGroupId: serializer.fromJson<String?>(json['supersetGroupId']),
      supersetName: serializer.fromJson<String?>(json['supersetName']),
      assistanceValue: serializer.fromJson<double?>(json['assistanceValue']),
      assistanceType: serializer.fromJson<String?>(json['assistanceType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'logId': serializer.toJson<int>(logId),
      'baseExerciseId': serializer.toJson<int>(baseExerciseId),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<double>(reps),
      'rpe': serializer.toJson<double?>(rpe),
      'rir': serializer.toJson<double?>(rir),
      'technique': serializer.toJson<int?>(technique),
      'failurePhase': serializer.toJson<int?>(failurePhase),
      'restTimeSeconds': serializer.toJson<int?>(restTimeSeconds),
      'notes': serializer.toJson<String?>(notes),
      'trackName': serializer.toJson<String?>(trackName),
      'hypeLevel': serializer.toJson<int?>(hypeLevel),
      'isPrSong': serializer.toJson<bool>(isPrSong),
      'isPr': serializer.toJson<bool>(isPr),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'complexMetadata': serializer.toJson<String?>(complexMetadata),
      'priority': serializer.toJson<String?>(priority),
      'supersetGroupId': serializer.toJson<String?>(supersetGroupId),
      'supersetName': serializer.toJson<String?>(supersetName),
      'assistanceValue': serializer.toJson<double?>(assistanceValue),
      'assistanceType': serializer.toJson<String?>(assistanceType),
    };
  }

  WorkoutSet copyWith(
          {int? id,
          int? logId,
          int? baseExerciseId,
          double? weight,
          double? reps,
          Value<double?> rpe = const Value.absent(),
          Value<double?> rir = const Value.absent(),
          Value<int?> technique = const Value.absent(),
          Value<int?> failurePhase = const Value.absent(),
          Value<int?> restTimeSeconds = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> trackName = const Value.absent(),
          Value<int?> hypeLevel = const Value.absent(),
          bool? isPrSong,
          bool? isPr,
          bool? isCompleted,
          int? orderIndex,
          DateTime? timestamp,
          Value<String?> complexMetadata = const Value.absent(),
          Value<String?> priority = const Value.absent(),
          Value<String?> supersetGroupId = const Value.absent(),
          Value<String?> supersetName = const Value.absent(),
          Value<double?> assistanceValue = const Value.absent(),
          Value<String?> assistanceType = const Value.absent()}) =>
      WorkoutSet(
        id: id ?? this.id,
        logId: logId ?? this.logId,
        baseExerciseId: baseExerciseId ?? this.baseExerciseId,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        rpe: rpe.present ? rpe.value : this.rpe,
        rir: rir.present ? rir.value : this.rir,
        technique: technique.present ? technique.value : this.technique,
        failurePhase:
            failurePhase.present ? failurePhase.value : this.failurePhase,
        restTimeSeconds: restTimeSeconds.present
            ? restTimeSeconds.value
            : this.restTimeSeconds,
        notes: notes.present ? notes.value : this.notes,
        trackName: trackName.present ? trackName.value : this.trackName,
        hypeLevel: hypeLevel.present ? hypeLevel.value : this.hypeLevel,
        isPrSong: isPrSong ?? this.isPrSong,
        isPr: isPr ?? this.isPr,
        isCompleted: isCompleted ?? this.isCompleted,
        orderIndex: orderIndex ?? this.orderIndex,
        timestamp: timestamp ?? this.timestamp,
        complexMetadata: complexMetadata.present
            ? complexMetadata.value
            : this.complexMetadata,
        priority: priority.present ? priority.value : this.priority,
        supersetGroupId: supersetGroupId.present
            ? supersetGroupId.value
            : this.supersetGroupId,
        supersetName:
            supersetName.present ? supersetName.value : this.supersetName,
        assistanceValue: assistanceValue.present
            ? assistanceValue.value
            : this.assistanceValue,
        assistanceType:
            assistanceType.present ? assistanceType.value : this.assistanceType,
      );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      logId: data.logId.present ? data.logId.value : this.logId,
      baseExerciseId: data.baseExerciseId.present
          ? data.baseExerciseId.value
          : this.baseExerciseId,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      technique: data.technique.present ? data.technique.value : this.technique,
      failurePhase: data.failurePhase.present
          ? data.failurePhase.value
          : this.failurePhase,
      restTimeSeconds: data.restTimeSeconds.present
          ? data.restTimeSeconds.value
          : this.restTimeSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
      trackName: data.trackName.present ? data.trackName.value : this.trackName,
      hypeLevel: data.hypeLevel.present ? data.hypeLevel.value : this.hypeLevel,
      isPrSong: data.isPrSong.present ? data.isPrSong.value : this.isPrSong,
      isPr: data.isPr.present ? data.isPr.value : this.isPr,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      complexMetadata: data.complexMetadata.present
          ? data.complexMetadata.value
          : this.complexMetadata,
      priority: data.priority.present ? data.priority.value : this.priority,
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
      supersetName: data.supersetName.present
          ? data.supersetName.value
          : this.supersetName,
      assistanceValue: data.assistanceValue.present
          ? data.assistanceValue.value
          : this.assistanceValue,
      assistanceType: data.assistanceType.present
          ? data.assistanceType.value
          : this.assistanceType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('technique: $technique, ')
          ..write('failurePhase: $failurePhase, ')
          ..write('restTimeSeconds: $restTimeSeconds, ')
          ..write('notes: $notes, ')
          ..write('trackName: $trackName, ')
          ..write('hypeLevel: $hypeLevel, ')
          ..write('isPrSong: $isPrSong, ')
          ..write('isPr: $isPr, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('timestamp: $timestamp, ')
          ..write('complexMetadata: $complexMetadata, ')
          ..write('priority: $priority, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetName: $supersetName, ')
          ..write('assistanceValue: $assistanceValue, ')
          ..write('assistanceType: $assistanceType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        logId,
        baseExerciseId,
        weight,
        reps,
        rpe,
        rir,
        technique,
        failurePhase,
        restTimeSeconds,
        notes,
        trackName,
        hypeLevel,
        isPrSong,
        isPr,
        isCompleted,
        orderIndex,
        timestamp,
        complexMetadata,
        priority,
        supersetGroupId,
        supersetName,
        assistanceValue,
        assistanceType
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.logId == this.logId &&
          other.baseExerciseId == this.baseExerciseId &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.technique == this.technique &&
          other.failurePhase == this.failurePhase &&
          other.restTimeSeconds == this.restTimeSeconds &&
          other.notes == this.notes &&
          other.trackName == this.trackName &&
          other.hypeLevel == this.hypeLevel &&
          other.isPrSong == this.isPrSong &&
          other.isPr == this.isPr &&
          other.isCompleted == this.isCompleted &&
          other.orderIndex == this.orderIndex &&
          other.timestamp == this.timestamp &&
          other.complexMetadata == this.complexMetadata &&
          other.priority == this.priority &&
          other.supersetGroupId == this.supersetGroupId &&
          other.supersetName == this.supersetName &&
          other.assistanceValue == this.assistanceValue &&
          other.assistanceType == this.assistanceType);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<int> id;
  final Value<int> logId;
  final Value<int> baseExerciseId;
  final Value<double> weight;
  final Value<double> reps;
  final Value<double?> rpe;
  final Value<double?> rir;
  final Value<int?> technique;
  final Value<int?> failurePhase;
  final Value<int?> restTimeSeconds;
  final Value<String?> notes;
  final Value<String?> trackName;
  final Value<int?> hypeLevel;
  final Value<bool> isPrSong;
  final Value<bool> isPr;
  final Value<bool> isCompleted;
  final Value<int> orderIndex;
  final Value<DateTime> timestamp;
  final Value<String?> complexMetadata;
  final Value<String?> priority;
  final Value<String?> supersetGroupId;
  final Value<String?> supersetName;
  final Value<double?> assistanceValue;
  final Value<String?> assistanceType;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.logId = const Value.absent(),
    this.baseExerciseId = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.technique = const Value.absent(),
    this.failurePhase = const Value.absent(),
    this.restTimeSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.trackName = const Value.absent(),
    this.hypeLevel = const Value.absent(),
    this.isPrSong = const Value.absent(),
    this.isPr = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.complexMetadata = const Value.absent(),
    this.priority = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetName = const Value.absent(),
    this.assistanceValue = const Value.absent(),
    this.assistanceType = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    this.id = const Value.absent(),
    required int logId,
    required int baseExerciseId,
    required double weight,
    required double reps,
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.technique = const Value.absent(),
    this.failurePhase = const Value.absent(),
    this.restTimeSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.trackName = const Value.absent(),
    this.hypeLevel = const Value.absent(),
    this.isPrSong = const Value.absent(),
    this.isPr = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.complexMetadata = const Value.absent(),
    this.priority = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetName = const Value.absent(),
    this.assistanceValue = const Value.absent(),
    this.assistanceType = const Value.absent(),
  })  : logId = Value(logId),
        baseExerciseId = Value(baseExerciseId),
        weight = Value(weight),
        reps = Value(reps);
  static Insertable<WorkoutSet> custom({
    Expression<int>? id,
    Expression<int>? logId,
    Expression<int>? baseExerciseId,
    Expression<double>? weight,
    Expression<double>? reps,
    Expression<double>? rpe,
    Expression<double>? rir,
    Expression<int>? technique,
    Expression<int>? failurePhase,
    Expression<int>? restTimeSeconds,
    Expression<String>? notes,
    Expression<String>? trackName,
    Expression<int>? hypeLevel,
    Expression<bool>? isPrSong,
    Expression<bool>? isPr,
    Expression<bool>? isCompleted,
    Expression<int>? orderIndex,
    Expression<DateTime>? timestamp,
    Expression<String>? complexMetadata,
    Expression<String>? priority,
    Expression<String>? supersetGroupId,
    Expression<String>? supersetName,
    Expression<double>? assistanceValue,
    Expression<String>? assistanceType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (logId != null) 'log_id': logId,
      if (baseExerciseId != null) 'base_exercise_id': baseExerciseId,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (technique != null) 'technique': technique,
      if (failurePhase != null) 'failure_phase': failurePhase,
      if (restTimeSeconds != null) 'rest_time_seconds': restTimeSeconds,
      if (notes != null) 'notes': notes,
      if (trackName != null) 'track_name': trackName,
      if (hypeLevel != null) 'hype_level': hypeLevel,
      if (isPrSong != null) 'is_pr_song': isPrSong,
      if (isPr != null) 'is_pr': isPr,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (orderIndex != null) 'order_index': orderIndex,
      if (timestamp != null) 'timestamp': timestamp,
      if (complexMetadata != null) 'complex_metadata': complexMetadata,
      if (priority != null) 'priority': priority,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (supersetName != null) 'superset_name': supersetName,
      if (assistanceValue != null) 'assistance_value': assistanceValue,
      if (assistanceType != null) 'assistance_type': assistanceType,
    });
  }

  WorkoutSetsCompanion copyWith(
      {Value<int>? id,
      Value<int>? logId,
      Value<int>? baseExerciseId,
      Value<double>? weight,
      Value<double>? reps,
      Value<double?>? rpe,
      Value<double?>? rir,
      Value<int?>? technique,
      Value<int?>? failurePhase,
      Value<int?>? restTimeSeconds,
      Value<String?>? notes,
      Value<String?>? trackName,
      Value<int?>? hypeLevel,
      Value<bool>? isPrSong,
      Value<bool>? isPr,
      Value<bool>? isCompleted,
      Value<int>? orderIndex,
      Value<DateTime>? timestamp,
      Value<String?>? complexMetadata,
      Value<String?>? priority,
      Value<String?>? supersetGroupId,
      Value<String?>? supersetName,
      Value<double?>? assistanceValue,
      Value<String?>? assistanceType}) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      logId: logId ?? this.logId,
      baseExerciseId: baseExerciseId ?? this.baseExerciseId,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      technique: technique ?? this.technique,
      failurePhase: failurePhase ?? this.failurePhase,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      notes: notes ?? this.notes,
      trackName: trackName ?? this.trackName,
      hypeLevel: hypeLevel ?? this.hypeLevel,
      isPrSong: isPrSong ?? this.isPrSong,
      isPr: isPr ?? this.isPr,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
      timestamp: timestamp ?? this.timestamp,
      complexMetadata: complexMetadata ?? this.complexMetadata,
      priority: priority ?? this.priority,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      supersetName: supersetName ?? this.supersetName,
      assistanceValue: assistanceValue ?? this.assistanceValue,
      assistanceType: assistanceType ?? this.assistanceType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (logId.present) {
      map['log_id'] = Variable<int>(logId.value);
    }
    if (baseExerciseId.present) {
      map['base_exercise_id'] = Variable<int>(baseExerciseId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<double>(reps.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<double>(rir.value);
    }
    if (technique.present) {
      map['technique'] = Variable<int>(technique.value);
    }
    if (failurePhase.present) {
      map['failure_phase'] = Variable<int>(failurePhase.value);
    }
    if (restTimeSeconds.present) {
      map['rest_time_seconds'] = Variable<int>(restTimeSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (trackName.present) {
      map['track_name'] = Variable<String>(trackName.value);
    }
    if (hypeLevel.present) {
      map['hype_level'] = Variable<int>(hypeLevel.value);
    }
    if (isPrSong.present) {
      map['is_pr_song'] = Variable<bool>(isPrSong.value);
    }
    if (isPr.present) {
      map['is_pr'] = Variable<bool>(isPr.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (complexMetadata.present) {
      map['complex_metadata'] = Variable<String>(complexMetadata.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<String>(supersetGroupId.value);
    }
    if (supersetName.present) {
      map['superset_name'] = Variable<String>(supersetName.value);
    }
    if (assistanceValue.present) {
      map['assistance_value'] = Variable<double>(assistanceValue.value);
    }
    if (assistanceType.present) {
      map['assistance_type'] = Variable<String>(assistanceType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('technique: $technique, ')
          ..write('failurePhase: $failurePhase, ')
          ..write('restTimeSeconds: $restTimeSeconds, ')
          ..write('notes: $notes, ')
          ..write('trackName: $trackName, ')
          ..write('hypeLevel: $hypeLevel, ')
          ..write('isPrSong: $isPrSong, ')
          ..write('isPr: $isPr, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('timestamp: $timestamp, ')
          ..write('complexMetadata: $complexMetadata, ')
          ..write('priority: $priority, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetName: $supersetName, ')
          ..write('assistanceValue: $assistanceValue, ')
          ..write('assistanceType: $assistanceType')
          ..write(')'))
        .toString();
  }
}

class $DiscomfortTagsTable extends DiscomfortTags
    with TableInfo<$DiscomfortTagsTable, DiscomfortTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscomfortTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discomfort_tags';
  @override
  VerificationContext validateIntegrity(Insertable<DiscomfortTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiscomfortTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscomfortTag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $DiscomfortTagsTable createAlias(String alias) {
    return $DiscomfortTagsTable(attachedDatabase, alias);
  }
}

class DiscomfortTag extends DataClass implements Insertable<DiscomfortTag> {
  final int id;
  final String name;
  const DiscomfortTag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  DiscomfortTagsCompanion toCompanion(bool nullToAbsent) {
    return DiscomfortTagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory DiscomfortTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscomfortTag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  DiscomfortTag copyWith({int? id, String? name}) => DiscomfortTag(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  DiscomfortTag copyWithCompanion(DiscomfortTagsCompanion data) {
    return DiscomfortTag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortTag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscomfortTag &&
          other.id == this.id &&
          other.name == this.name);
}

class DiscomfortTagsCompanion extends UpdateCompanion<DiscomfortTag> {
  final Value<int> id;
  final Value<String> name;
  const DiscomfortTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DiscomfortTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<DiscomfortTag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DiscomfortTagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return DiscomfortTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $DiscomfortLogsTable extends DiscomfortLogs
    with TableInfo<$DiscomfortLogsTable, DiscomfortLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscomfortLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<int> setId = GeneratedColumn<int>(
      'set_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_sets (id) ON DELETE CASCADE'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intensityMeta =
      const VerificationMeta('intensity');
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
      'intensity', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, setId, description, intensity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discomfort_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DiscomfortLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(_intensityMeta,
          intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiscomfortLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscomfortLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      intensity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}intensity']),
    );
  }

  @override
  $DiscomfortLogsTable createAlias(String alias) {
    return $DiscomfortLogsTable(attachedDatabase, alias);
  }
}

class DiscomfortLog extends DataClass implements Insertable<DiscomfortLog> {
  final int id;
  final int setId;
  final String description;
  final int? intensity;
  const DiscomfortLog(
      {required this.id,
      required this.setId,
      required this.description,
      this.intensity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['set_id'] = Variable<int>(setId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || intensity != null) {
      map['intensity'] = Variable<int>(intensity);
    }
    return map;
  }

  DiscomfortLogsCompanion toCompanion(bool nullToAbsent) {
    return DiscomfortLogsCompanion(
      id: Value(id),
      setId: Value(setId),
      description: Value(description),
      intensity: intensity == null && nullToAbsent
          ? const Value.absent()
          : Value(intensity),
    );
  }

  factory DiscomfortLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscomfortLog(
      id: serializer.fromJson<int>(json['id']),
      setId: serializer.fromJson<int>(json['setId']),
      description: serializer.fromJson<String>(json['description']),
      intensity: serializer.fromJson<int?>(json['intensity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'setId': serializer.toJson<int>(setId),
      'description': serializer.toJson<String>(description),
      'intensity': serializer.toJson<int?>(intensity),
    };
  }

  DiscomfortLog copyWith(
          {int? id,
          int? setId,
          String? description,
          Value<int?> intensity = const Value.absent()}) =>
      DiscomfortLog(
        id: id ?? this.id,
        setId: setId ?? this.setId,
        description: description ?? this.description,
        intensity: intensity.present ? intensity.value : this.intensity,
      );
  DiscomfortLog copyWithCompanion(DiscomfortLogsCompanion data) {
    return DiscomfortLog(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      description:
          data.description.present ? data.description.value : this.description,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortLog(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('description: $description, ')
          ..write('intensity: $intensity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, setId, description, intensity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscomfortLog &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.description == this.description &&
          other.intensity == this.intensity);
}

class DiscomfortLogsCompanion extends UpdateCompanion<DiscomfortLog> {
  final Value<int> id;
  final Value<int> setId;
  final Value<String> description;
  final Value<int?> intensity;
  const DiscomfortLogsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.description = const Value.absent(),
    this.intensity = const Value.absent(),
  });
  DiscomfortLogsCompanion.insert({
    this.id = const Value.absent(),
    required int setId,
    required String description,
    this.intensity = const Value.absent(),
  })  : setId = Value(setId),
        description = Value(description);
  static Insertable<DiscomfortLog> custom({
    Expression<int>? id,
    Expression<int>? setId,
    Expression<String>? description,
    Expression<int>? intensity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (description != null) 'description': description,
      if (intensity != null) 'intensity': intensity,
    });
  }

  DiscomfortLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? setId,
      Value<String>? description,
      Value<int?>? intensity}) {
    return DiscomfortLogsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      description: description ?? this.description,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<int>(setId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortLogsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('description: $description, ')
          ..write('intensity: $intensity')
          ..write(')'))
        .toString();
  }
}

class $DiscomfortLogTagsTable extends DiscomfortLogTags
    with TableInfo<$DiscomfortLogTagsTable, DiscomfortLogTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscomfortLogTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<int> logId = GeneratedColumn<int>(
      'log_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discomfort_logs (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discomfort_tags (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [logId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discomfort_log_tags';
  @override
  VerificationContext validateIntegrity(Insertable<DiscomfortLogTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('log_id')) {
      context.handle(
          _logIdMeta, logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta));
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  DiscomfortLogTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscomfortLogTag(
      logId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}log_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $DiscomfortLogTagsTable createAlias(String alias) {
    return $DiscomfortLogTagsTable(attachedDatabase, alias);
  }
}

class DiscomfortLogTag extends DataClass
    implements Insertable<DiscomfortLogTag> {
  final int logId;
  final int tagId;
  const DiscomfortLogTag({required this.logId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['log_id'] = Variable<int>(logId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  DiscomfortLogTagsCompanion toCompanion(bool nullToAbsent) {
    return DiscomfortLogTagsCompanion(
      logId: Value(logId),
      tagId: Value(tagId),
    );
  }

  factory DiscomfortLogTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscomfortLogTag(
      logId: serializer.fromJson<int>(json['logId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'logId': serializer.toJson<int>(logId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  DiscomfortLogTag copyWith({int? logId, int? tagId}) => DiscomfortLogTag(
        logId: logId ?? this.logId,
        tagId: tagId ?? this.tagId,
      );
  DiscomfortLogTag copyWithCompanion(DiscomfortLogTagsCompanion data) {
    return DiscomfortLogTag(
      logId: data.logId.present ? data.logId.value : this.logId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortLogTag(')
          ..write('logId: $logId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(logId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscomfortLogTag &&
          other.logId == this.logId &&
          other.tagId == this.tagId);
}

class DiscomfortLogTagsCompanion extends UpdateCompanion<DiscomfortLogTag> {
  final Value<int> logId;
  final Value<int> tagId;
  final Value<int> rowid;
  const DiscomfortLogTagsCompanion({
    this.logId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscomfortLogTagsCompanion.insert({
    required int logId,
    required int tagId,
    this.rowid = const Value.absent(),
  })  : logId = Value(logId),
        tagId = Value(tagId);
  static Insertable<DiscomfortLogTag> custom({
    Expression<int>? logId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (logId != null) 'log_id': logId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscomfortLogTagsCompanion copyWith(
      {Value<int>? logId, Value<int>? tagId, Value<int>? rowid}) {
    return DiscomfortLogTagsCompanion(
      logId: logId ?? this.logId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (logId.present) {
      map['log_id'] = Variable<int>(logId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscomfortLogTagsCompanion(')
          ..write('logId: $logId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlueprintsTable extends Blueprints
    with TableInfo<$BlueprintsTable, Blueprint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlueprintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intentionMeta =
      const VerificationMeta('intention');
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
      'intention', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, intention, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blueprints';
  @override
  VerificationContext validateIntegrity(Insertable<Blueprint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('intention')) {
      context.handle(_intentionMeta,
          intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta));
    } else if (isInserting) {
      context.missing(_intentionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Blueprint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Blueprint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      intention: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}intention'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $BlueprintsTable createAlias(String alias) {
    return $BlueprintsTable(attachedDatabase, alias);
  }
}

class Blueprint extends DataClass implements Insertable<Blueprint> {
  final int id;
  final String name;
  final String intention;
  final DateTime? createdAt;
  const Blueprint(
      {required this.id,
      required this.name,
      required this.intention,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['intention'] = Variable<String>(intention);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  BlueprintsCompanion toCompanion(bool nullToAbsent) {
    return BlueprintsCompanion(
      id: Value(id),
      name: Value(name),
      intention: Value(intention),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Blueprint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Blueprint(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      intention: serializer.fromJson<String>(json['intention']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'intention': serializer.toJson<String>(intention),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Blueprint copyWith(
          {int? id,
          String? name,
          String? intention,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      Blueprint(
        id: id ?? this.id,
        name: name ?? this.name,
        intention: intention ?? this.intention,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  Blueprint copyWithCompanion(BlueprintsCompanion data) {
    return Blueprint(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      intention: data.intention.present ? data.intention.value : this.intention,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Blueprint(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('intention: $intention, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, intention, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Blueprint &&
          other.id == this.id &&
          other.name == this.name &&
          other.intention == this.intention &&
          other.createdAt == this.createdAt);
}

class BlueprintsCompanion extends UpdateCompanion<Blueprint> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> intention;
  final Value<DateTime?> createdAt;
  const BlueprintsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.intention = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BlueprintsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String intention,
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        intention = Value(intention);
  static Insertable<Blueprint> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? intention,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (intention != null) 'intention': intention,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BlueprintsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? intention,
      Value<DateTime?>? createdAt}) {
    return BlueprintsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      intention: intention ?? this.intention,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlueprintsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('intention: $intention, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BlueprintExercisesTable extends BlueprintExercises
    with TableInfo<$BlueprintExercisesTable, BlueprintExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlueprintExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _blueprintIdMeta =
      const VerificationMeta('blueprintId');
  @override
  late final GeneratedColumn<int> blueprintId = GeneratedColumn<int>(
      'blueprint_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES blueprints (id)'));
  static const VerificationMeta _baseExerciseIdMeta =
      const VerificationMeta('baseExerciseId');
  @override
  late final GeneratedColumn<int> baseExerciseId = GeneratedColumn<int>(
      'base_exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES base_exercises (id)'));
  static const VerificationMeta _targetSetsRepsMeta =
      const VerificationMeta('targetSetsReps');
  @override
  late final GeneratedColumn<String> targetSetsReps = GeneratedColumn<String>(
      'target_sets_reps', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetGroupIdMeta =
      const VerificationMeta('supersetGroupId');
  @override
  late final GeneratedColumn<String> supersetGroupId = GeneratedColumn<String>(
      'superset_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetNameMeta =
      const VerificationMeta('supersetName');
  @override
  late final GeneratedColumn<String> supersetName = GeneratedColumn<String>(
      'superset_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        blueprintId,
        baseExerciseId,
        targetSetsReps,
        orderIndex,
        priority,
        supersetGroupId,
        supersetName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blueprint_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<BlueprintExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('blueprint_id')) {
      context.handle(
          _blueprintIdMeta,
          blueprintId.isAcceptableOrUnknown(
              data['blueprint_id']!, _blueprintIdMeta));
    } else if (isInserting) {
      context.missing(_blueprintIdMeta);
    }
    if (data.containsKey('base_exercise_id')) {
      context.handle(
          _baseExerciseIdMeta,
          baseExerciseId.isAcceptableOrUnknown(
              data['base_exercise_id']!, _baseExerciseIdMeta));
    } else if (isInserting) {
      context.missing(_baseExerciseIdMeta);
    }
    if (data.containsKey('target_sets_reps')) {
      context.handle(
          _targetSetsRepsMeta,
          targetSetsReps.isAcceptableOrUnknown(
              data['target_sets_reps']!, _targetSetsRepsMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('superset_group_id')) {
      context.handle(
          _supersetGroupIdMeta,
          supersetGroupId.isAcceptableOrUnknown(
              data['superset_group_id']!, _supersetGroupIdMeta));
    }
    if (data.containsKey('superset_name')) {
      context.handle(
          _supersetNameMeta,
          supersetName.isAcceptableOrUnknown(
              data['superset_name']!, _supersetNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlueprintExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlueprintExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      blueprintId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}blueprint_id'])!,
      baseExerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_exercise_id'])!,
      targetSetsReps: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_sets_reps']),
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority']),
      supersetGroupId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}superset_group_id']),
      supersetName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}superset_name']),
    );
  }

  @override
  $BlueprintExercisesTable createAlias(String alias) {
    return $BlueprintExercisesTable(attachedDatabase, alias);
  }
}

class BlueprintExercise extends DataClass
    implements Insertable<BlueprintExercise> {
  final int id;
  final int blueprintId;
  final int baseExerciseId;
  final String? targetSetsReps;
  final int orderIndex;
  final String? priority;
  final String? supersetGroupId;
  final String? supersetName;
  const BlueprintExercise(
      {required this.id,
      required this.blueprintId,
      required this.baseExerciseId,
      this.targetSetsReps,
      required this.orderIndex,
      this.priority,
      this.supersetGroupId,
      this.supersetName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['blueprint_id'] = Variable<int>(blueprintId);
    map['base_exercise_id'] = Variable<int>(baseExerciseId);
    if (!nullToAbsent || targetSetsReps != null) {
      map['target_sets_reps'] = Variable<String>(targetSetsReps);
    }
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<String>(supersetGroupId);
    }
    if (!nullToAbsent || supersetName != null) {
      map['superset_name'] = Variable<String>(supersetName);
    }
    return map;
  }

  BlueprintExercisesCompanion toCompanion(bool nullToAbsent) {
    return BlueprintExercisesCompanion(
      id: Value(id),
      blueprintId: Value(blueprintId),
      baseExerciseId: Value(baseExerciseId),
      targetSetsReps: targetSetsReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSetsReps),
      orderIndex: Value(orderIndex),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
      supersetName: supersetName == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetName),
    );
  }

  factory BlueprintExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlueprintExercise(
      id: serializer.fromJson<int>(json['id']),
      blueprintId: serializer.fromJson<int>(json['blueprintId']),
      baseExerciseId: serializer.fromJson<int>(json['baseExerciseId']),
      targetSetsReps: serializer.fromJson<String?>(json['targetSetsReps']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      priority: serializer.fromJson<String?>(json['priority']),
      supersetGroupId: serializer.fromJson<String?>(json['supersetGroupId']),
      supersetName: serializer.fromJson<String?>(json['supersetName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blueprintId': serializer.toJson<int>(blueprintId),
      'baseExerciseId': serializer.toJson<int>(baseExerciseId),
      'targetSetsReps': serializer.toJson<String?>(targetSetsReps),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'priority': serializer.toJson<String?>(priority),
      'supersetGroupId': serializer.toJson<String?>(supersetGroupId),
      'supersetName': serializer.toJson<String?>(supersetName),
    };
  }

  BlueprintExercise copyWith(
          {int? id,
          int? blueprintId,
          int? baseExerciseId,
          Value<String?> targetSetsReps = const Value.absent(),
          int? orderIndex,
          Value<String?> priority = const Value.absent(),
          Value<String?> supersetGroupId = const Value.absent(),
          Value<String?> supersetName = const Value.absent()}) =>
      BlueprintExercise(
        id: id ?? this.id,
        blueprintId: blueprintId ?? this.blueprintId,
        baseExerciseId: baseExerciseId ?? this.baseExerciseId,
        targetSetsReps:
            targetSetsReps.present ? targetSetsReps.value : this.targetSetsReps,
        orderIndex: orderIndex ?? this.orderIndex,
        priority: priority.present ? priority.value : this.priority,
        supersetGroupId: supersetGroupId.present
            ? supersetGroupId.value
            : this.supersetGroupId,
        supersetName:
            supersetName.present ? supersetName.value : this.supersetName,
      );
  BlueprintExercise copyWithCompanion(BlueprintExercisesCompanion data) {
    return BlueprintExercise(
      id: data.id.present ? data.id.value : this.id,
      blueprintId:
          data.blueprintId.present ? data.blueprintId.value : this.blueprintId,
      baseExerciseId: data.baseExerciseId.present
          ? data.baseExerciseId.value
          : this.baseExerciseId,
      targetSetsReps: data.targetSetsReps.present
          ? data.targetSetsReps.value
          : this.targetSetsReps,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      priority: data.priority.present ? data.priority.value : this.priority,
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
      supersetName: data.supersetName.present
          ? data.supersetName.value
          : this.supersetName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlueprintExercise(')
          ..write('id: $id, ')
          ..write('blueprintId: $blueprintId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('targetSetsReps: $targetSetsReps, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('priority: $priority, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetName: $supersetName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, blueprintId, baseExerciseId,
      targetSetsReps, orderIndex, priority, supersetGroupId, supersetName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlueprintExercise &&
          other.id == this.id &&
          other.blueprintId == this.blueprintId &&
          other.baseExerciseId == this.baseExerciseId &&
          other.targetSetsReps == this.targetSetsReps &&
          other.orderIndex == this.orderIndex &&
          other.priority == this.priority &&
          other.supersetGroupId == this.supersetGroupId &&
          other.supersetName == this.supersetName);
}

class BlueprintExercisesCompanion extends UpdateCompanion<BlueprintExercise> {
  final Value<int> id;
  final Value<int> blueprintId;
  final Value<int> baseExerciseId;
  final Value<String?> targetSetsReps;
  final Value<int> orderIndex;
  final Value<String?> priority;
  final Value<String?> supersetGroupId;
  final Value<String?> supersetName;
  const BlueprintExercisesCompanion({
    this.id = const Value.absent(),
    this.blueprintId = const Value.absent(),
    this.baseExerciseId = const Value.absent(),
    this.targetSetsReps = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.priority = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetName = const Value.absent(),
  });
  BlueprintExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int blueprintId,
    required int baseExerciseId,
    this.targetSetsReps = const Value.absent(),
    required int orderIndex,
    this.priority = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetName = const Value.absent(),
  })  : blueprintId = Value(blueprintId),
        baseExerciseId = Value(baseExerciseId),
        orderIndex = Value(orderIndex);
  static Insertable<BlueprintExercise> custom({
    Expression<int>? id,
    Expression<int>? blueprintId,
    Expression<int>? baseExerciseId,
    Expression<String>? targetSetsReps,
    Expression<int>? orderIndex,
    Expression<String>? priority,
    Expression<String>? supersetGroupId,
    Expression<String>? supersetName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blueprintId != null) 'blueprint_id': blueprintId,
      if (baseExerciseId != null) 'base_exercise_id': baseExerciseId,
      if (targetSetsReps != null) 'target_sets_reps': targetSetsReps,
      if (orderIndex != null) 'order_index': orderIndex,
      if (priority != null) 'priority': priority,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (supersetName != null) 'superset_name': supersetName,
    });
  }

  BlueprintExercisesCompanion copyWith(
      {Value<int>? id,
      Value<int>? blueprintId,
      Value<int>? baseExerciseId,
      Value<String?>? targetSetsReps,
      Value<int>? orderIndex,
      Value<String?>? priority,
      Value<String?>? supersetGroupId,
      Value<String?>? supersetName}) {
    return BlueprintExercisesCompanion(
      id: id ?? this.id,
      blueprintId: blueprintId ?? this.blueprintId,
      baseExerciseId: baseExerciseId ?? this.baseExerciseId,
      targetSetsReps: targetSetsReps ?? this.targetSetsReps,
      orderIndex: orderIndex ?? this.orderIndex,
      priority: priority ?? this.priority,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      supersetName: supersetName ?? this.supersetName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blueprintId.present) {
      map['blueprint_id'] = Variable<int>(blueprintId.value);
    }
    if (baseExerciseId.present) {
      map['base_exercise_id'] = Variable<int>(baseExerciseId.value);
    }
    if (targetSetsReps.present) {
      map['target_sets_reps'] = Variable<String>(targetSetsReps.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<String>(supersetGroupId.value);
    }
    if (supersetName.present) {
      map['superset_name'] = Variable<String>(supersetName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlueprintExercisesCompanion(')
          ..write('id: $id, ')
          ..write('blueprintId: $blueprintId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('targetSetsReps: $targetSetsReps, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('priority: $priority, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetName: $supersetName')
          ..write(')'))
        .toString();
  }
}

class $TrainingPlansTable extends TrainingPlans
    with TableInfo<$TrainingPlansTable, TrainingPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, notes, isActive, isPinned, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_plans';
  @override
  VerificationContext validateIntegrity(Insertable<TrainingPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TrainingPlansTable createAlias(String alias) {
    return $TrainingPlansTable(attachedDatabase, alias);
  }
}

class TrainingPlan extends DataClass implements Insertable<TrainingPlan> {
  final int id;
  final String name;
  final String? notes;
  final bool isActive;
  final bool isPinned;
  final DateTime createdAt;
  const TrainingPlan(
      {required this.id,
      required this.name,
      this.notes,
      required this.isActive,
      required this.isPinned,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrainingPlansCompanion toCompanion(bool nullToAbsent) {
    return TrainingPlansCompanion(
      id: Value(id),
      name: Value(name),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isActive: Value(isActive),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
    );
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingPlan(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TrainingPlan copyWith(
          {int? id,
          String? name,
          Value<String?> notes = const Value.absent(),
          bool? isActive,
          bool? isPinned,
          DateTime? createdAt}) =>
      TrainingPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes.present ? notes.value : this.notes,
        isActive: isActive ?? this.isActive,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
      );
  TrainingPlan copyWithCompanion(TrainingPlansCompanion data) {
    return TrainingPlan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, notes, isActive, isPinned, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingPlan &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt);
}

class TrainingPlansCompanion extends UpdateCompanion<TrainingPlan> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  const TrainingPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TrainingPlansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<TrainingPlan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<bool>? isPinned,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TrainingPlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? notes,
      Value<bool>? isActive,
      Value<bool>? isPinned,
      Value<DateTime>? createdAt}) {
    return TrainingPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlanWeeksTable extends PlanWeeks
    with TableInfo<$PlanWeeksTable, PlanWeek> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanWeeksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES training_plans (id) ON DELETE CASCADE'));
  static const VerificationMeta _weekNumberMeta =
      const VerificationMeta('weekNumber');
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
      'week_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, planId, weekNumber, purpose];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_weeks';
  @override
  VerificationContext validateIntegrity(Insertable<PlanWeek> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('week_number')) {
      context.handle(
          _weekNumberMeta,
          weekNumber.isAcceptableOrUnknown(
              data['week_number']!, _weekNumberMeta));
    } else if (isInserting) {
      context.missing(_weekNumberMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanWeek map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanWeek(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id'])!,
      weekNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}week_number'])!,
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose']),
    );
  }

  @override
  $PlanWeeksTable createAlias(String alias) {
    return $PlanWeeksTable(attachedDatabase, alias);
  }
}

class PlanWeek extends DataClass implements Insertable<PlanWeek> {
  final int id;
  final int planId;
  final int weekNumber;
  final String? purpose;
  const PlanWeek(
      {required this.id,
      required this.planId,
      required this.weekNumber,
      this.purpose});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['week_number'] = Variable<int>(weekNumber);
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    return map;
  }

  PlanWeeksCompanion toCompanion(bool nullToAbsent) {
    return PlanWeeksCompanion(
      id: Value(id),
      planId: Value(planId),
      weekNumber: Value(weekNumber),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
    );
  }

  factory PlanWeek.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanWeek(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      weekNumber: serializer.fromJson<int>(json['weekNumber']),
      purpose: serializer.fromJson<String?>(json['purpose']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'weekNumber': serializer.toJson<int>(weekNumber),
      'purpose': serializer.toJson<String?>(purpose),
    };
  }

  PlanWeek copyWith(
          {int? id,
          int? planId,
          int? weekNumber,
          Value<String?> purpose = const Value.absent()}) =>
      PlanWeek(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        weekNumber: weekNumber ?? this.weekNumber,
        purpose: purpose.present ? purpose.value : this.purpose,
      );
  PlanWeek copyWithCompanion(PlanWeeksCompanion data) {
    return PlanWeek(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      weekNumber:
          data.weekNumber.present ? data.weekNumber.value : this.weekNumber,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanWeek(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, weekNumber, purpose);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanWeek &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.weekNumber == this.weekNumber &&
          other.purpose == this.purpose);
}

class PlanWeeksCompanion extends UpdateCompanion<PlanWeek> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> weekNumber;
  final Value<String?> purpose;
  const PlanWeeksCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.purpose = const Value.absent(),
  });
  PlanWeeksCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int weekNumber,
    this.purpose = const Value.absent(),
  })  : planId = Value(planId),
        weekNumber = Value(weekNumber);
  static Insertable<PlanWeek> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? weekNumber,
    Expression<String>? purpose,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (weekNumber != null) 'week_number': weekNumber,
      if (purpose != null) 'purpose': purpose,
    });
  }

  PlanWeeksCompanion copyWith(
      {Value<int>? id,
      Value<int>? planId,
      Value<int>? weekNumber,
      Value<String?>? purpose}) {
    return PlanWeeksCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanWeeksCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }
}

class $PlanDaysTable extends PlanDays with TableInfo<$PlanDaysTable, PlanDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _weekIdMeta = const VerificationMeta('weekId');
  @override
  late final GeneratedColumn<int> weekId = GeneratedColumn<int>(
      'week_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES plan_weeks (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayNumberMeta =
      const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
      'day_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _blueprintIdMeta =
      const VerificationMeta('blueprintId');
  @override
  late final GeneratedColumn<int> blueprintId = GeneratedColumn<int>(
      'blueprint_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES blueprints (id)'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, weekId, dayNumber, blueprintId, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_days';
  @override
  VerificationContext validateIntegrity(Insertable<PlanDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_id')) {
      context.handle(_weekIdMeta,
          weekId.isAcceptableOrUnknown(data['week_id']!, _weekIdMeta));
    } else if (isInserting) {
      context.missing(_weekIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta,
          dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('blueprint_id')) {
      context.handle(
          _blueprintIdMeta,
          blueprintId.isAcceptableOrUnknown(
              data['blueprint_id']!, _blueprintIdMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      weekId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}week_id'])!,
      dayNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      blueprintId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}blueprint_id']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
    );
  }

  @override
  $PlanDaysTable createAlias(String alias) {
    return $PlanDaysTable(attachedDatabase, alias);
  }
}

class PlanDay extends DataClass implements Insertable<PlanDay> {
  final int id;
  final int weekId;
  final int dayNumber;
  final int? blueprintId;
  final String? label;
  const PlanDay(
      {required this.id,
      required this.weekId,
      required this.dayNumber,
      this.blueprintId,
      this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_id'] = Variable<int>(weekId);
    map['day_number'] = Variable<int>(dayNumber);
    if (!nullToAbsent || blueprintId != null) {
      map['blueprint_id'] = Variable<int>(blueprintId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  PlanDaysCompanion toCompanion(bool nullToAbsent) {
    return PlanDaysCompanion(
      id: Value(id),
      weekId: Value(weekId),
      dayNumber: Value(dayNumber),
      blueprintId: blueprintId == null && nullToAbsent
          ? const Value.absent()
          : Value(blueprintId),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
    );
  }

  factory PlanDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDay(
      id: serializer.fromJson<int>(json['id']),
      weekId: serializer.fromJson<int>(json['weekId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      blueprintId: serializer.fromJson<int?>(json['blueprintId']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekId': serializer.toJson<int>(weekId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'blueprintId': serializer.toJson<int?>(blueprintId),
      'label': serializer.toJson<String?>(label),
    };
  }

  PlanDay copyWith(
          {int? id,
          int? weekId,
          int? dayNumber,
          Value<int?> blueprintId = const Value.absent(),
          Value<String?> label = const Value.absent()}) =>
      PlanDay(
        id: id ?? this.id,
        weekId: weekId ?? this.weekId,
        dayNumber: dayNumber ?? this.dayNumber,
        blueprintId: blueprintId.present ? blueprintId.value : this.blueprintId,
        label: label.present ? label.value : this.label,
      );
  PlanDay copyWithCompanion(PlanDaysCompanion data) {
    return PlanDay(
      id: data.id.present ? data.id.value : this.id,
      weekId: data.weekId.present ? data.weekId.value : this.weekId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      blueprintId:
          data.blueprintId.present ? data.blueprintId.value : this.blueprintId,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDay(')
          ..write('id: $id, ')
          ..write('weekId: $weekId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('blueprintId: $blueprintId, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weekId, dayNumber, blueprintId, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDay &&
          other.id == this.id &&
          other.weekId == this.weekId &&
          other.dayNumber == this.dayNumber &&
          other.blueprintId == this.blueprintId &&
          other.label == this.label);
}

class PlanDaysCompanion extends UpdateCompanion<PlanDay> {
  final Value<int> id;
  final Value<int> weekId;
  final Value<int> dayNumber;
  final Value<int?> blueprintId;
  final Value<String?> label;
  const PlanDaysCompanion({
    this.id = const Value.absent(),
    this.weekId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.blueprintId = const Value.absent(),
    this.label = const Value.absent(),
  });
  PlanDaysCompanion.insert({
    this.id = const Value.absent(),
    required int weekId,
    required int dayNumber,
    this.blueprintId = const Value.absent(),
    this.label = const Value.absent(),
  })  : weekId = Value(weekId),
        dayNumber = Value(dayNumber);
  static Insertable<PlanDay> custom({
    Expression<int>? id,
    Expression<int>? weekId,
    Expression<int>? dayNumber,
    Expression<int>? blueprintId,
    Expression<String>? label,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekId != null) 'week_id': weekId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (blueprintId != null) 'blueprint_id': blueprintId,
      if (label != null) 'label': label,
    });
  }

  PlanDaysCompanion copyWith(
      {Value<int>? id,
      Value<int>? weekId,
      Value<int>? dayNumber,
      Value<int?>? blueprintId,
      Value<String?>? label}) {
    return PlanDaysCompanion(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      dayNumber: dayNumber ?? this.dayNumber,
      blueprintId: blueprintId ?? this.blueprintId,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekId.present) {
      map['week_id'] = Variable<int>(weekId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (blueprintId.present) {
      map['blueprint_id'] = Variable<int>(blueprintId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('weekId: $weekId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('blueprintId: $blueprintId, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }
}

class $WorkoutBlocksTable extends WorkoutBlocks
    with TableInfo<$WorkoutBlocksTable, WorkoutBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intentionMeta =
      const VerificationMeta('intention');
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
      'intention', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, intention, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('intention')) {
      context.handle(_intentionMeta,
          intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      intention: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}intention']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WorkoutBlocksTable createAlias(String alias) {
    return $WorkoutBlocksTable(attachedDatabase, alias);
  }
}

class WorkoutBlock extends DataClass implements Insertable<WorkoutBlock> {
  final int id;
  final String name;
  final String? intention;
  final String? description;
  final DateTime createdAt;
  const WorkoutBlock(
      {required this.id,
      required this.name,
      this.intention,
      this.description,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || intention != null) {
      map['intention'] = Variable<String>(intention);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkoutBlocksCompanion toCompanion(bool nullToAbsent) {
    return WorkoutBlocksCompanion(
      id: Value(id),
      name: Value(name),
      intention: intention == null && nullToAbsent
          ? const Value.absent()
          : Value(intention),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutBlock(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      intention: serializer.fromJson<String?>(json['intention']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'intention': serializer.toJson<String?>(intention),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkoutBlock copyWith(
          {int? id,
          String? name,
          Value<String?> intention = const Value.absent(),
          Value<String?> description = const Value.absent(),
          DateTime? createdAt}) =>
      WorkoutBlock(
        id: id ?? this.id,
        name: name ?? this.name,
        intention: intention.present ? intention.value : this.intention,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkoutBlock copyWithCompanion(WorkoutBlocksCompanion data) {
    return WorkoutBlock(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      intention: data.intention.present ? data.intention.value : this.intention,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlock(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('intention: $intention, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, intention, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutBlock &&
          other.id == this.id &&
          other.name == this.name &&
          other.intention == this.intention &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class WorkoutBlocksCompanion extends UpdateCompanion<WorkoutBlock> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> intention;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  const WorkoutBlocksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.intention = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutBlocksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.intention = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<WorkoutBlock> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? intention,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (intention != null) 'intention': intention,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutBlocksCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? intention,
      Value<String?>? description,
      Value<DateTime>? createdAt}) {
    return WorkoutBlocksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      intention: intention ?? this.intention,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlocksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('intention: $intention, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlanDayBlocksTable extends PlanDayBlocks
    with TableInfo<$PlanDayBlocksTable, PlanDayBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDayBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
      'day_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES plan_days (id) ON DELETE CASCADE'));
  static const VerificationMeta _blockIdMeta =
      const VerificationMeta('blockId');
  @override
  late final GeneratedColumn<int> blockId = GeneratedColumn<int>(
      'block_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_blocks (id) ON DELETE CASCADE'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, dayId, blockId, orderIndex, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_day_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<PlanDayBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
          _dayIdMeta, dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta));
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(_blockIdMeta,
          blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta));
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanDayBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDayBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_id'])!,
      blockId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}block_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $PlanDayBlocksTable createAlias(String alias) {
    return $PlanDayBlocksTable(attachedDatabase, alias);
  }
}

class PlanDayBlock extends DataClass implements Insertable<PlanDayBlock> {
  final int id;
  final int dayId;
  final int blockId;
  final int orderIndex;
  final String? notes;
  const PlanDayBlock(
      {required this.id,
      required this.dayId,
      required this.blockId,
      required this.orderIndex,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['block_id'] = Variable<int>(blockId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PlanDayBlocksCompanion toCompanion(bool nullToAbsent) {
    return PlanDayBlocksCompanion(
      id: Value(id),
      dayId: Value(dayId),
      blockId: Value(blockId),
      orderIndex: Value(orderIndex),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory PlanDayBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDayBlock(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      blockId: serializer.fromJson<int>(json['blockId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'blockId': serializer.toJson<int>(blockId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PlanDayBlock copyWith(
          {int? id,
          int? dayId,
          int? blockId,
          int? orderIndex,
          Value<String?> notes = const Value.absent()}) =>
      PlanDayBlock(
        id: id ?? this.id,
        dayId: dayId ?? this.dayId,
        blockId: blockId ?? this.blockId,
        orderIndex: orderIndex ?? this.orderIndex,
        notes: notes.present ? notes.value : this.notes,
      );
  PlanDayBlock copyWithCompanion(PlanDayBlocksCompanion data) {
    return PlanDayBlock(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDayBlock(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('blockId: $blockId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, blockId, orderIndex, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDayBlock &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.blockId == this.blockId &&
          other.orderIndex == this.orderIndex &&
          other.notes == this.notes);
}

class PlanDayBlocksCompanion extends UpdateCompanion<PlanDayBlock> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<int> blockId;
  final Value<int> orderIndex;
  final Value<String?> notes;
  const PlanDayBlocksCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PlanDayBlocksCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required int blockId,
    this.orderIndex = const Value.absent(),
    this.notes = const Value.absent(),
  })  : dayId = Value(dayId),
        blockId = Value(blockId);
  static Insertable<PlanDayBlock> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<int>? blockId,
    Expression<int>? orderIndex,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (blockId != null) 'block_id': blockId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (notes != null) 'notes': notes,
    });
  }

  PlanDayBlocksCompanion copyWith(
      {Value<int>? id,
      Value<int>? dayId,
      Value<int>? blockId,
      Value<int>? orderIndex,
      Value<String?>? notes}) {
    return PlanDayBlocksCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      blockId: blockId ?? this.blockId,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<int>(blockId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDayBlocksCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('blockId: $blockId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $AnthropometricLogsTable extends AnthropometricLogs
    with TableInfo<$AnthropometricLogsTable, AnthropometricLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnthropometricLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFlexedMeta =
      const VerificationMeta('isFlexed');
  @override
  late final GeneratedColumn<bool> isFlexed = GeneratedColumn<bool>(
      'is_flexed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_flexed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPumpedMeta =
      const VerificationMeta('isPumped');
  @override
  late final GeneratedColumn<bool> isPumped = GeneratedColumn<bool>(
      'is_pumped', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pumped" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, label, value, unit, isFlexed, isPumped, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anthropometric_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AnthropometricLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('is_flexed')) {
      context.handle(_isFlexedMeta,
          isFlexed.isAcceptableOrUnknown(data['is_flexed']!, _isFlexedMeta));
    }
    if (data.containsKey('is_pumped')) {
      context.handle(_isPumpedMeta,
          isPumped.isAcceptableOrUnknown(data['is_pumped']!, _isPumpedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnthropometricLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnthropometricLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      isFlexed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_flexed'])!,
      isPumped: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pumped'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AnthropometricLogsTable createAlias(String alias) {
    return $AnthropometricLogsTable(attachedDatabase, alias);
  }
}

class AnthropometricLog extends DataClass
    implements Insertable<AnthropometricLog> {
  final int id;
  final DateTime date;
  final String label;
  final double value;
  final String unit;
  final bool isFlexed;
  final bool isPumped;
  final DateTime createdAt;
  const AnthropometricLog(
      {required this.id,
      required this.date,
      required this.label,
      required this.value,
      required this.unit,
      required this.isFlexed,
      required this.isPumped,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['label'] = Variable<String>(label);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['is_flexed'] = Variable<bool>(isFlexed);
    map['is_pumped'] = Variable<bool>(isPumped);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnthropometricLogsCompanion toCompanion(bool nullToAbsent) {
    return AnthropometricLogsCompanion(
      id: Value(id),
      date: Value(date),
      label: Value(label),
      value: Value(value),
      unit: Value(unit),
      isFlexed: Value(isFlexed),
      isPumped: Value(isPumped),
      createdAt: Value(createdAt),
    );
  }

  factory AnthropometricLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnthropometricLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      label: serializer.fromJson<String>(json['label']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      isFlexed: serializer.fromJson<bool>(json['isFlexed']),
      isPumped: serializer.fromJson<bool>(json['isPumped']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'label': serializer.toJson<String>(label),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'isFlexed': serializer.toJson<bool>(isFlexed),
      'isPumped': serializer.toJson<bool>(isPumped),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnthropometricLog copyWith(
          {int? id,
          DateTime? date,
          String? label,
          double? value,
          String? unit,
          bool? isFlexed,
          bool? isPumped,
          DateTime? createdAt}) =>
      AnthropometricLog(
        id: id ?? this.id,
        date: date ?? this.date,
        label: label ?? this.label,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        isFlexed: isFlexed ?? this.isFlexed,
        isPumped: isPumped ?? this.isPumped,
        createdAt: createdAt ?? this.createdAt,
      );
  AnthropometricLog copyWithCompanion(AnthropometricLogsCompanion data) {
    return AnthropometricLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      label: data.label.present ? data.label.value : this.label,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      isFlexed: data.isFlexed.present ? data.isFlexed.value : this.isFlexed,
      isPumped: data.isPumped.present ? data.isPumped.value : this.isPumped,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnthropometricLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('isFlexed: $isFlexed, ')
          ..write('isPumped: $isPumped, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, label, value, unit, isFlexed, isPumped, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnthropometricLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.label == this.label &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.isFlexed == this.isFlexed &&
          other.isPumped == this.isPumped &&
          other.createdAt == this.createdAt);
}

class AnthropometricLogsCompanion extends UpdateCompanion<AnthropometricLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> label;
  final Value<double> value;
  final Value<String> unit;
  final Value<bool> isFlexed;
  final Value<bool> isPumped;
  final Value<DateTime> createdAt;
  const AnthropometricLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.label = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.isFlexed = const Value.absent(),
    this.isPumped = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnthropometricLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String label,
    required double value,
    required String unit,
    this.isFlexed = const Value.absent(),
    this.isPumped = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        label = Value(label),
        value = Value(value),
        unit = Value(unit);
  static Insertable<AnthropometricLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? label,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<bool>? isFlexed,
    Expression<bool>? isPumped,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (isFlexed != null) 'is_flexed': isFlexed,
      if (isPumped != null) 'is_pumped': isPumped,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnthropometricLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? label,
      Value<double>? value,
      Value<String>? unit,
      Value<bool>? isFlexed,
      Value<bool>? isPumped,
      Value<DateTime>? createdAt}) {
    return AnthropometricLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      isFlexed: isFlexed ?? this.isFlexed,
      isPumped: isPumped ?? this.isPumped,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isFlexed.present) {
      map['is_flexed'] = Variable<bool>(isFlexed.value);
    }
    if (isPumped.present) {
      map['is_pumped'] = Variable<bool>(isPumped.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnthropometricLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('isFlexed: $isFlexed, ')
          ..write('isPumped: $isPumped, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ThemeSettingsTable extends ThemeSettings
    with TableInfo<$ThemeSettingsTable, ThemeSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThemeSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, colorHex, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'theme_settings';
  @override
  VerificationContext validateIntegrity(Insertable<ThemeSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ThemeSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThemeSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $ThemeSettingsTable createAlias(String alias) {
    return $ThemeSettingsTable(attachedDatabase, alias);
  }
}

class ThemeSetting extends DataClass implements Insertable<ThemeSetting> {
  final String key;
  final String? colorHex;
  final String? value;
  const ThemeSetting({required this.key, this.colorHex, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  ThemeSettingsCompanion toCompanion(bool nullToAbsent) {
    return ThemeSettingsCompanion(
      key: Value(key),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory ThemeSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThemeSetting(
      key: serializer.fromJson<String>(json['key']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'colorHex': serializer.toJson<String?>(colorHex),
      'value': serializer.toJson<String?>(value),
    };
  }

  ThemeSetting copyWith(
          {String? key,
          Value<String?> colorHex = const Value.absent(),
          Value<String?> value = const Value.absent()}) =>
      ThemeSetting(
        key: key ?? this.key,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        value: value.present ? value.value : this.value,
      );
  ThemeSetting copyWithCompanion(ThemeSettingsCompanion data) {
    return ThemeSetting(
      key: data.key.present ? data.key.value : this.key,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThemeSetting(')
          ..write('key: $key, ')
          ..write('colorHex: $colorHex, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, colorHex, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThemeSetting &&
          other.key == this.key &&
          other.colorHex == this.colorHex &&
          other.value == this.value);
}

class ThemeSettingsCompanion extends UpdateCompanion<ThemeSetting> {
  final Value<String> key;
  final Value<String?> colorHex;
  final Value<String?> value;
  final Value<int> rowid;
  const ThemeSettingsCompanion({
    this.key = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThemeSettingsCompanion.insert({
    required String key,
    this.colorHex = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<ThemeSetting> custom({
    Expression<String>? key,
    Expression<String>? colorHex,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (colorHex != null) 'color_hex': colorHex,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThemeSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String?>? colorHex,
      Value<String?>? value,
      Value<int>? rowid}) {
    return ThemeSettingsCompanion(
      key: key ?? this.key,
      colorHex: colorHex ?? this.colorHex,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThemeSettingsCompanion(')
          ..write('key: $key, ')
          ..write('colorHex: $colorHex, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutBlockKnsTable extends WorkoutBlockKns
    with TableInfo<$WorkoutBlockKnsTable, WorkoutBlockKn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutBlockKnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _blockIdMeta =
      const VerificationMeta('blockId');
  @override
  late final GeneratedColumn<int> blockId = GeneratedColumn<int>(
      'block_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_blocks (id) ON DELETE CASCADE'));
  static const VerificationMeta _baseExerciseIdMeta =
      const VerificationMeta('baseExerciseId');
  @override
  late final GeneratedColumn<int> baseExerciseId = GeneratedColumn<int>(
      'base_exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES base_exercises (id)'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _utilitiesMeta =
      const VerificationMeta('utilities');
  @override
  late final GeneratedColumn<String> utilities = GeneratedColumn<String>(
      'utilities', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _batchNameMeta =
      const VerificationMeta('batchName');
  @override
  late final GeneratedColumn<String> batchName = GeneratedColumn<String>(
      'batch_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, blockId, baseExerciseId, orderIndex, utilities, batchName, metadata];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_block_kns';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutBlockKn> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('block_id')) {
      context.handle(_blockIdMeta,
          blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta));
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('base_exercise_id')) {
      context.handle(
          _baseExerciseIdMeta,
          baseExerciseId.isAcceptableOrUnknown(
              data['base_exercise_id']!, _baseExerciseIdMeta));
    } else if (isInserting) {
      context.missing(_baseExerciseIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    if (data.containsKey('utilities')) {
      context.handle(_utilitiesMeta,
          utilities.isAcceptableOrUnknown(data['utilities']!, _utilitiesMeta));
    }
    if (data.containsKey('batch_name')) {
      context.handle(_batchNameMeta,
          batchName.isAcceptableOrUnknown(data['batch_name']!, _batchNameMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutBlockKn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutBlockKn(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      blockId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}block_id'])!,
      baseExerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_exercise_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      utilities: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}utilities']),
      batchName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_name']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $WorkoutBlockKnsTable createAlias(String alias) {
    return $WorkoutBlockKnsTable(attachedDatabase, alias);
  }
}

class WorkoutBlockKn extends DataClass implements Insertable<WorkoutBlockKn> {
  final int id;
  final int blockId;
  final int baseExerciseId;
  final int orderIndex;
  final String? utilities;
  final String? batchName;
  final String? metadata;
  const WorkoutBlockKn(
      {required this.id,
      required this.blockId,
      required this.baseExerciseId,
      required this.orderIndex,
      this.utilities,
      this.batchName,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['block_id'] = Variable<int>(blockId);
    map['base_exercise_id'] = Variable<int>(baseExerciseId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || utilities != null) {
      map['utilities'] = Variable<String>(utilities);
    }
    if (!nullToAbsent || batchName != null) {
      map['batch_name'] = Variable<String>(batchName);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  WorkoutBlockKnsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutBlockKnsCompanion(
      id: Value(id),
      blockId: Value(blockId),
      baseExerciseId: Value(baseExerciseId),
      orderIndex: Value(orderIndex),
      utilities: utilities == null && nullToAbsent
          ? const Value.absent()
          : Value(utilities),
      batchName: batchName == null && nullToAbsent
          ? const Value.absent()
          : Value(batchName),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory WorkoutBlockKn.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutBlockKn(
      id: serializer.fromJson<int>(json['id']),
      blockId: serializer.fromJson<int>(json['blockId']),
      baseExerciseId: serializer.fromJson<int>(json['baseExerciseId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      utilities: serializer.fromJson<String?>(json['utilities']),
      batchName: serializer.fromJson<String?>(json['batchName']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blockId': serializer.toJson<int>(blockId),
      'baseExerciseId': serializer.toJson<int>(baseExerciseId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'utilities': serializer.toJson<String?>(utilities),
      'batchName': serializer.toJson<String?>(batchName),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  WorkoutBlockKn copyWith(
          {int? id,
          int? blockId,
          int? baseExerciseId,
          int? orderIndex,
          Value<String?> utilities = const Value.absent(),
          Value<String?> batchName = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      WorkoutBlockKn(
        id: id ?? this.id,
        blockId: blockId ?? this.blockId,
        baseExerciseId: baseExerciseId ?? this.baseExerciseId,
        orderIndex: orderIndex ?? this.orderIndex,
        utilities: utilities.present ? utilities.value : this.utilities,
        batchName: batchName.present ? batchName.value : this.batchName,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  WorkoutBlockKn copyWithCompanion(WorkoutBlockKnsCompanion data) {
    return WorkoutBlockKn(
      id: data.id.present ? data.id.value : this.id,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      baseExerciseId: data.baseExerciseId.present
          ? data.baseExerciseId.value
          : this.baseExerciseId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      utilities: data.utilities.present ? data.utilities.value : this.utilities,
      batchName: data.batchName.present ? data.batchName.value : this.batchName,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlockKn(')
          ..write('id: $id, ')
          ..write('blockId: $blockId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('utilities: $utilities, ')
          ..write('batchName: $batchName, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, blockId, baseExerciseId, orderIndex, utilities, batchName, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutBlockKn &&
          other.id == this.id &&
          other.blockId == this.blockId &&
          other.baseExerciseId == this.baseExerciseId &&
          other.orderIndex == this.orderIndex &&
          other.utilities == this.utilities &&
          other.batchName == this.batchName &&
          other.metadata == this.metadata);
}

class WorkoutBlockKnsCompanion extends UpdateCompanion<WorkoutBlockKn> {
  final Value<int> id;
  final Value<int> blockId;
  final Value<int> baseExerciseId;
  final Value<int> orderIndex;
  final Value<String?> utilities;
  final Value<String?> batchName;
  final Value<String?> metadata;
  const WorkoutBlockKnsCompanion({
    this.id = const Value.absent(),
    this.blockId = const Value.absent(),
    this.baseExerciseId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.utilities = const Value.absent(),
    this.batchName = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  WorkoutBlockKnsCompanion.insert({
    this.id = const Value.absent(),
    required int blockId,
    required int baseExerciseId,
    this.orderIndex = const Value.absent(),
    this.utilities = const Value.absent(),
    this.batchName = const Value.absent(),
    this.metadata = const Value.absent(),
  })  : blockId = Value(blockId),
        baseExerciseId = Value(baseExerciseId);
  static Insertable<WorkoutBlockKn> custom({
    Expression<int>? id,
    Expression<int>? blockId,
    Expression<int>? baseExerciseId,
    Expression<int>? orderIndex,
    Expression<String>? utilities,
    Expression<String>? batchName,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blockId != null) 'block_id': blockId,
      if (baseExerciseId != null) 'base_exercise_id': baseExerciseId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (utilities != null) 'utilities': utilities,
      if (batchName != null) 'batch_name': batchName,
      if (metadata != null) 'metadata': metadata,
    });
  }

  WorkoutBlockKnsCompanion copyWith(
      {Value<int>? id,
      Value<int>? blockId,
      Value<int>? baseExerciseId,
      Value<int>? orderIndex,
      Value<String?>? utilities,
      Value<String?>? batchName,
      Value<String?>? metadata}) {
    return WorkoutBlockKnsCompanion(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      baseExerciseId: baseExerciseId ?? this.baseExerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      utilities: utilities ?? this.utilities,
      batchName: batchName ?? this.batchName,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<int>(blockId.value);
    }
    if (baseExerciseId.present) {
      map['base_exercise_id'] = Variable<int>(baseExerciseId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (utilities.present) {
      map['utilities'] = Variable<String>(utilities.value);
    }
    if (batchName.present) {
      map['batch_name'] = Variable<String>(batchName.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlockKnsCompanion(')
          ..write('id: $id, ')
          ..write('blockId: $blockId, ')
          ..write('baseExerciseId: $baseExerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('utilities: $utilities, ')
          ..write('batchName: $batchName, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }
}

class $WorkoutBlockSetsTable extends WorkoutBlockSets
    with TableInfo<$WorkoutBlockSetsTable, WorkoutBlockSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutBlockSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _knsIdMeta = const VerificationMeta('knsId');
  @override
  late final GeneratedColumn<int> knsId = GeneratedColumn<int>(
      'kns_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_block_kns (id) ON DELETE CASCADE'));
  static const VerificationMeta _setNumberMeta =
      const VerificationMeta('setNumber');
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
      'set_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repsMinMeta =
      const VerificationMeta('repsMin');
  @override
  late final GeneratedColumn<double> repsMin = GeneratedColumn<double>(
      'reps_min', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _repsMaxMeta =
      const VerificationMeta('repsMax');
  @override
  late final GeneratedColumn<double> repsMax = GeneratedColumn<double>(
      'reps_max', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ploadMeta = const VerificationMeta('pload');
  @override
  late final GeneratedColumn<double> pload = GeneratedColumn<double>(
      'pload', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
      'rpe', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<double> rir = GeneratedColumn<double>(
      'rir', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _setIntentionMeta =
      const VerificationMeta('setIntention');
  @override
  late final GeneratedColumn<String> setIntention = GeneratedColumn<String>(
      'set_intention', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
      'side', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        knsId,
        setNumber,
        repsMin,
        repsMax,
        pload,
        rpe,
        rir,
        setIntention,
        side,
        tags,
        metadata
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_block_sets';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutBlockSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kns_id')) {
      context.handle(
          _knsIdMeta, knsId.isAcceptableOrUnknown(data['kns_id']!, _knsIdMeta));
    } else if (isInserting) {
      context.missing(_knsIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(_setNumberMeta,
          setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta));
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('reps_min')) {
      context.handle(_repsMinMeta,
          repsMin.isAcceptableOrUnknown(data['reps_min']!, _repsMinMeta));
    }
    if (data.containsKey('reps_max')) {
      context.handle(_repsMaxMeta,
          repsMax.isAcceptableOrUnknown(data['reps_max']!, _repsMaxMeta));
    }
    if (data.containsKey('pload')) {
      context.handle(
          _ploadMeta, pload.isAcceptableOrUnknown(data['pload']!, _ploadMeta));
    }
    if (data.containsKey('rpe')) {
      context.handle(
          _rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('set_intention')) {
      context.handle(
          _setIntentionMeta,
          setIntention.isAcceptableOrUnknown(
              data['set_intention']!, _setIntentionMeta));
    }
    if (data.containsKey('side')) {
      context.handle(
          _sideMeta, side.isAcceptableOrUnknown(data['side']!, _sideMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutBlockSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutBlockSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      knsId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kns_id'])!,
      setNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_number'])!,
      repsMin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reps_min']),
      repsMax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reps_max']),
      pload: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pload']),
      rpe: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rpe']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rir']),
      setIntention: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_intention']),
      side: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}side']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $WorkoutBlockSetsTable createAlias(String alias) {
    return $WorkoutBlockSetsTable(attachedDatabase, alias);
  }
}

class WorkoutBlockSet extends DataClass implements Insertable<WorkoutBlockSet> {
  final int id;
  final int knsId;
  final int setNumber;
  final double? repsMin;
  final double? repsMax;
  final double? pload;
  final double? rpe;
  final double? rir;
  final String? setIntention;
  final String? side;
  final String? tags;
  final String? metadata;
  const WorkoutBlockSet(
      {required this.id,
      required this.knsId,
      required this.setNumber,
      this.repsMin,
      this.repsMax,
      this.pload,
      this.rpe,
      this.rir,
      this.setIntention,
      this.side,
      this.tags,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kns_id'] = Variable<int>(knsId);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || repsMin != null) {
      map['reps_min'] = Variable<double>(repsMin);
    }
    if (!nullToAbsent || repsMax != null) {
      map['reps_max'] = Variable<double>(repsMax);
    }
    if (!nullToAbsent || pload != null) {
      map['pload'] = Variable<double>(pload);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<double>(rir);
    }
    if (!nullToAbsent || setIntention != null) {
      map['set_intention'] = Variable<String>(setIntention);
    }
    if (!nullToAbsent || side != null) {
      map['side'] = Variable<String>(side);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  WorkoutBlockSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutBlockSetsCompanion(
      id: Value(id),
      knsId: Value(knsId),
      setNumber: Value(setNumber),
      repsMin: repsMin == null && nullToAbsent
          ? const Value.absent()
          : Value(repsMin),
      repsMax: repsMax == null && nullToAbsent
          ? const Value.absent()
          : Value(repsMax),
      pload:
          pload == null && nullToAbsent ? const Value.absent() : Value(pload),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      setIntention: setIntention == null && nullToAbsent
          ? const Value.absent()
          : Value(setIntention),
      side: side == null && nullToAbsent ? const Value.absent() : Value(side),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory WorkoutBlockSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutBlockSet(
      id: serializer.fromJson<int>(json['id']),
      knsId: serializer.fromJson<int>(json['knsId']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      repsMin: serializer.fromJson<double?>(json['repsMin']),
      repsMax: serializer.fromJson<double?>(json['repsMax']),
      pload: serializer.fromJson<double?>(json['pload']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      rir: serializer.fromJson<double?>(json['rir']),
      setIntention: serializer.fromJson<String?>(json['setIntention']),
      side: serializer.fromJson<String?>(json['side']),
      tags: serializer.fromJson<String?>(json['tags']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'knsId': serializer.toJson<int>(knsId),
      'setNumber': serializer.toJson<int>(setNumber),
      'repsMin': serializer.toJson<double?>(repsMin),
      'repsMax': serializer.toJson<double?>(repsMax),
      'pload': serializer.toJson<double?>(pload),
      'rpe': serializer.toJson<double?>(rpe),
      'rir': serializer.toJson<double?>(rir),
      'setIntention': serializer.toJson<String?>(setIntention),
      'side': serializer.toJson<String?>(side),
      'tags': serializer.toJson<String?>(tags),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  WorkoutBlockSet copyWith(
          {int? id,
          int? knsId,
          int? setNumber,
          Value<double?> repsMin = const Value.absent(),
          Value<double?> repsMax = const Value.absent(),
          Value<double?> pload = const Value.absent(),
          Value<double?> rpe = const Value.absent(),
          Value<double?> rir = const Value.absent(),
          Value<String?> setIntention = const Value.absent(),
          Value<String?> side = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      WorkoutBlockSet(
        id: id ?? this.id,
        knsId: knsId ?? this.knsId,
        setNumber: setNumber ?? this.setNumber,
        repsMin: repsMin.present ? repsMin.value : this.repsMin,
        repsMax: repsMax.present ? repsMax.value : this.repsMax,
        pload: pload.present ? pload.value : this.pload,
        rpe: rpe.present ? rpe.value : this.rpe,
        rir: rir.present ? rir.value : this.rir,
        setIntention:
            setIntention.present ? setIntention.value : this.setIntention,
        side: side.present ? side.value : this.side,
        tags: tags.present ? tags.value : this.tags,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  WorkoutBlockSet copyWithCompanion(WorkoutBlockSetsCompanion data) {
    return WorkoutBlockSet(
      id: data.id.present ? data.id.value : this.id,
      knsId: data.knsId.present ? data.knsId.value : this.knsId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      repsMin: data.repsMin.present ? data.repsMin.value : this.repsMin,
      repsMax: data.repsMax.present ? data.repsMax.value : this.repsMax,
      pload: data.pload.present ? data.pload.value : this.pload,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      setIntention: data.setIntention.present
          ? data.setIntention.value
          : this.setIntention,
      side: data.side.present ? data.side.value : this.side,
      tags: data.tags.present ? data.tags.value : this.tags,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlockSet(')
          ..write('id: $id, ')
          ..write('knsId: $knsId, ')
          ..write('setNumber: $setNumber, ')
          ..write('repsMin: $repsMin, ')
          ..write('repsMax: $repsMax, ')
          ..write('pload: $pload, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('setIntention: $setIntention, ')
          ..write('side: $side, ')
          ..write('tags: $tags, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, knsId, setNumber, repsMin, repsMax, pload,
      rpe, rir, setIntention, side, tags, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutBlockSet &&
          other.id == this.id &&
          other.knsId == this.knsId &&
          other.setNumber == this.setNumber &&
          other.repsMin == this.repsMin &&
          other.repsMax == this.repsMax &&
          other.pload == this.pload &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.setIntention == this.setIntention &&
          other.side == this.side &&
          other.tags == this.tags &&
          other.metadata == this.metadata);
}

class WorkoutBlockSetsCompanion extends UpdateCompanion<WorkoutBlockSet> {
  final Value<int> id;
  final Value<int> knsId;
  final Value<int> setNumber;
  final Value<double?> repsMin;
  final Value<double?> repsMax;
  final Value<double?> pload;
  final Value<double?> rpe;
  final Value<double?> rir;
  final Value<String?> setIntention;
  final Value<String?> side;
  final Value<String?> tags;
  final Value<String?> metadata;
  const WorkoutBlockSetsCompanion({
    this.id = const Value.absent(),
    this.knsId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.repsMin = const Value.absent(),
    this.repsMax = const Value.absent(),
    this.pload = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.setIntention = const Value.absent(),
    this.side = const Value.absent(),
    this.tags = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  WorkoutBlockSetsCompanion.insert({
    this.id = const Value.absent(),
    required int knsId,
    required int setNumber,
    this.repsMin = const Value.absent(),
    this.repsMax = const Value.absent(),
    this.pload = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.setIntention = const Value.absent(),
    this.side = const Value.absent(),
    this.tags = const Value.absent(),
    this.metadata = const Value.absent(),
  })  : knsId = Value(knsId),
        setNumber = Value(setNumber);
  static Insertable<WorkoutBlockSet> custom({
    Expression<int>? id,
    Expression<int>? knsId,
    Expression<int>? setNumber,
    Expression<double>? repsMin,
    Expression<double>? repsMax,
    Expression<double>? pload,
    Expression<double>? rpe,
    Expression<double>? rir,
    Expression<String>? setIntention,
    Expression<String>? side,
    Expression<String>? tags,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (knsId != null) 'kns_id': knsId,
      if (setNumber != null) 'set_number': setNumber,
      if (repsMin != null) 'reps_min': repsMin,
      if (repsMax != null) 'reps_max': repsMax,
      if (pload != null) 'pload': pload,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (setIntention != null) 'set_intention': setIntention,
      if (side != null) 'side': side,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
    });
  }

  WorkoutBlockSetsCompanion copyWith(
      {Value<int>? id,
      Value<int>? knsId,
      Value<int>? setNumber,
      Value<double?>? repsMin,
      Value<double?>? repsMax,
      Value<double?>? pload,
      Value<double?>? rpe,
      Value<double?>? rir,
      Value<String?>? setIntention,
      Value<String?>? side,
      Value<String?>? tags,
      Value<String?>? metadata}) {
    return WorkoutBlockSetsCompanion(
      id: id ?? this.id,
      knsId: knsId ?? this.knsId,
      setNumber: setNumber ?? this.setNumber,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      pload: pload ?? this.pload,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      setIntention: setIntention ?? this.setIntention,
      side: side ?? this.side,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (knsId.present) {
      map['kns_id'] = Variable<int>(knsId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (repsMin.present) {
      map['reps_min'] = Variable<double>(repsMin.value);
    }
    if (repsMax.present) {
      map['reps_max'] = Variable<double>(repsMax.value);
    }
    if (pload.present) {
      map['pload'] = Variable<double>(pload.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<double>(rir.value);
    }
    if (setIntention.present) {
      map['set_intention'] = Variable<String>(setIntention.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutBlockSetsCompanion(')
          ..write('id: $id, ')
          ..write('knsId: $knsId, ')
          ..write('setNumber: $setNumber, ')
          ..write('repsMin: $repsMin, ')
          ..write('repsMax: $repsMax, ')
          ..write('pload: $pload, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('setIntention: $setIntention, ')
          ..write('side: $side, ')
          ..write('tags: $tags, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BaseExercisesTable baseExercises = $BaseExercisesTable(this);
  late final $PrefixesTable prefixes = $PrefixesTable(this);
  late final $SuffixesTable suffixes = $SuffixesTable(this);
  late final $ExerciseVariantsTable exerciseVariants =
      $ExerciseVariantsTable(this);
  late final $ProgressionEdgesTable progressionEdges =
      $ProgressionEdgesTable(this);
  late final $WorkoutLogsTable workoutLogs = $WorkoutLogsTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $DiscomfortTagsTable discomfortTags = $DiscomfortTagsTable(this);
  late final $DiscomfortLogsTable discomfortLogs = $DiscomfortLogsTable(this);
  late final $DiscomfortLogTagsTable discomfortLogTags =
      $DiscomfortLogTagsTable(this);
  late final $BlueprintsTable blueprints = $BlueprintsTable(this);
  late final $BlueprintExercisesTable blueprintExercises =
      $BlueprintExercisesTable(this);
  late final $TrainingPlansTable trainingPlans = $TrainingPlansTable(this);
  late final $PlanWeeksTable planWeeks = $PlanWeeksTable(this);
  late final $PlanDaysTable planDays = $PlanDaysTable(this);
  late final $WorkoutBlocksTable workoutBlocks = $WorkoutBlocksTable(this);
  late final $PlanDayBlocksTable planDayBlocks = $PlanDayBlocksTable(this);
  late final $AnthropometricLogsTable anthropometricLogs =
      $AnthropometricLogsTable(this);
  late final $ThemeSettingsTable themeSettings = $ThemeSettingsTable(this);
  late final $WorkoutBlockKnsTable workoutBlockKns =
      $WorkoutBlockKnsTable(this);
  late final $WorkoutBlockSetsTable workoutBlockSets =
      $WorkoutBlockSetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        baseExercises,
        prefixes,
        suffixes,
        exerciseVariants,
        progressionEdges,
        workoutLogs,
        workoutSets,
        discomfortTags,
        discomfortLogs,
        discomfortLogTags,
        blueprints,
        blueprintExercises,
        trainingPlans,
        planWeeks,
        planDays,
        workoutBlocks,
        planDayBlocks,
        anthropometricLogs,
        themeSettings,
        workoutBlockKns,
        workoutBlockSets
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_sets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('discomfort_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('discomfort_logs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('discomfort_log_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('discomfort_tags',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('discomfort_log_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('training_plans',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('plan_weeks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('plan_weeks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('plan_days', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('plan_days',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('plan_day_blocks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_blocks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('plan_day_blocks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_blocks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workout_block_kns', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('workout_block_kns',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('workout_block_sets', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$BaseExercisesTableCreateCompanionBuilder = BaseExercisesCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> prefixes,
  Value<String?> implements,
  Value<String?> bodyPositions,
  Value<String?> suffixes,
  Value<String?> primaryMuscleGroup,
  Value<String?> secondaryMuscleGroup,
  Value<String?> field,
  Value<String?> tissueType,
  Value<String?> tissueName,
  Value<int?> numPhases,
  Value<int> orderIndex,
  Value<String?> phaseDescriptions,
  Value<String?> intention,
  Value<String?> patternType,
  Value<String?> complexMetadata,
  Value<bool> isUnilateral,
  Value<String?> assistanceTypes,
  Value<String?> nameOrder,
});
typedef $$BaseExercisesTableUpdateCompanionBuilder = BaseExercisesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> prefixes,
  Value<String?> implements,
  Value<String?> bodyPositions,
  Value<String?> suffixes,
  Value<String?> primaryMuscleGroup,
  Value<String?> secondaryMuscleGroup,
  Value<String?> field,
  Value<String?> tissueType,
  Value<String?> tissueName,
  Value<int?> numPhases,
  Value<int> orderIndex,
  Value<String?> phaseDescriptions,
  Value<String?> intention,
  Value<String?> patternType,
  Value<String?> complexMetadata,
  Value<bool> isUnilateral,
  Value<String?> assistanceTypes,
  Value<String?> nameOrder,
});

final class $$BaseExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $BaseExercisesTable, BaseExercise> {
  $$BaseExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseVariantsTable, List<ExerciseVariant>>
      _exerciseVariantsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exerciseVariants,
              aliasName: $_aliasNameGenerator(
                  db.baseExercises.id, db.exerciseVariants.baseId));

  $$ExerciseVariantsTableProcessedTableManager get exerciseVariantsRefs {
    final manager =
        $$ExerciseVariantsTableTableManager($_db, $_db.exerciseVariants)
            .filter((f) => f.baseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_exerciseVariantsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
      _workoutSetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutSets,
              aliasName: $_aliasNameGenerator(
                  db.baseExercises.id, db.workoutSets.baseExerciseId));

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.baseExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BlueprintExercisesTable, List<BlueprintExercise>>
      _blueprintExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.blueprintExercises,
              aliasName: $_aliasNameGenerator(
                  db.baseExercises.id, db.blueprintExercises.baseExerciseId));

  $$BlueprintExercisesTableProcessedTableManager get blueprintExercisesRefs {
    final manager = $$BlueprintExercisesTableTableManager(
            $_db, $_db.blueprintExercises)
        .filter((f) => f.baseExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_blueprintExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutBlockKnsTable, List<WorkoutBlockKn>>
      _workoutBlockKnsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutBlockKns,
              aliasName: $_aliasNameGenerator(
                  db.baseExercises.id, db.workoutBlockKns.baseExerciseId));

  $$WorkoutBlockKnsTableProcessedTableManager get workoutBlockKnsRefs {
    final manager = $$WorkoutBlockKnsTableTableManager(
            $_db, $_db.workoutBlockKns)
        .filter((f) => f.baseExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutBlockKnsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BaseExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $BaseExercisesTable> {
  $$BaseExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prefixes => $composableBuilder(
      column: $table.prefixes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get implements => $composableBuilder(
      column: $table.implements, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyPositions => $composableBuilder(
      column: $table.bodyPositions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get suffixes => $composableBuilder(
      column: $table.suffixes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryMuscleGroup => $composableBuilder(
      column: $table.primaryMuscleGroup,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secondaryMuscleGroup => $composableBuilder(
      column: $table.secondaryMuscleGroup,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tissueType => $composableBuilder(
      column: $table.tissueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tissueName => $composableBuilder(
      column: $table.tissueName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numPhases => $composableBuilder(
      column: $table.numPhases, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phaseDescriptions => $composableBuilder(
      column: $table.phaseDescriptions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assistanceTypes => $composableBuilder(
      column: $table.assistanceTypes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameOrder => $composableBuilder(
      column: $table.nameOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> exerciseVariantsRefs(
      Expression<bool> Function($$ExerciseVariantsTableFilterComposer f) f) {
    final $$ExerciseVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.baseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutSetsRefs(
      Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.baseExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> blueprintExercisesRefs(
      Expression<bool> Function($$BlueprintExercisesTableFilterComposer f) f) {
    final $$BlueprintExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.blueprintExercises,
        getReferencedColumn: (t) => t.baseExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintExercisesTableFilterComposer(
              $db: $db,
              $table: $db.blueprintExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutBlockKnsRefs(
      Expression<bool> Function($$WorkoutBlockKnsTableFilterComposer f) f) {
    final $$WorkoutBlockKnsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.baseExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BaseExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $BaseExercisesTable> {
  $$BaseExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prefixes => $composableBuilder(
      column: $table.prefixes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get implements => $composableBuilder(
      column: $table.implements, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyPositions => $composableBuilder(
      column: $table.bodyPositions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get suffixes => $composableBuilder(
      column: $table.suffixes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryMuscleGroup => $composableBuilder(
      column: $table.primaryMuscleGroup,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secondaryMuscleGroup => $composableBuilder(
      column: $table.secondaryMuscleGroup,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tissueType => $composableBuilder(
      column: $table.tissueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tissueName => $composableBuilder(
      column: $table.tissueName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numPhases => $composableBuilder(
      column: $table.numPhases, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phaseDescriptions => $composableBuilder(
      column: $table.phaseDescriptions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assistanceTypes => $composableBuilder(
      column: $table.assistanceTypes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameOrder => $composableBuilder(
      column: $table.nameOrder, builder: (column) => ColumnOrderings(column));
}

class $$BaseExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BaseExercisesTable> {
  $$BaseExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get prefixes =>
      $composableBuilder(column: $table.prefixes, builder: (column) => column);

  GeneratedColumn<String> get implements => $composableBuilder(
      column: $table.implements, builder: (column) => column);

  GeneratedColumn<String> get bodyPositions => $composableBuilder(
      column: $table.bodyPositions, builder: (column) => column);

  GeneratedColumn<String> get suffixes =>
      $composableBuilder(column: $table.suffixes, builder: (column) => column);

  GeneratedColumn<String> get primaryMuscleGroup => $composableBuilder(
      column: $table.primaryMuscleGroup, builder: (column) => column);

  GeneratedColumn<String> get secondaryMuscleGroup => $composableBuilder(
      column: $table.secondaryMuscleGroup, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get tissueType => $composableBuilder(
      column: $table.tissueType, builder: (column) => column);

  GeneratedColumn<String> get tissueName => $composableBuilder(
      column: $table.tissueName, builder: (column) => column);

  GeneratedColumn<int> get numPhases =>
      $composableBuilder(column: $table.numPhases, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get phaseDescriptions => $composableBuilder(
      column: $table.phaseDescriptions, builder: (column) => column);

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);

  GeneratedColumn<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => column);

  GeneratedColumn<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata, builder: (column) => column);

  GeneratedColumn<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral, builder: (column) => column);

  GeneratedColumn<String> get assistanceTypes => $composableBuilder(
      column: $table.assistanceTypes, builder: (column) => column);

  GeneratedColumn<String> get nameOrder =>
      $composableBuilder(column: $table.nameOrder, builder: (column) => column);

  Expression<T> exerciseVariantsRefs<T extends Object>(
      Expression<T> Function($$ExerciseVariantsTableAnnotationComposer a) f) {
    final $$ExerciseVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.baseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutSetsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.baseExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> blueprintExercisesRefs<T extends Object>(
      Expression<T> Function($$BlueprintExercisesTableAnnotationComposer a) f) {
    final $$BlueprintExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.blueprintExercises,
            getReferencedColumn: (t) => t.baseExerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$BlueprintExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.blueprintExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> workoutBlockKnsRefs<T extends Object>(
      Expression<T> Function($$WorkoutBlockKnsTableAnnotationComposer a) f) {
    final $$WorkoutBlockKnsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.baseExerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BaseExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BaseExercisesTable,
    BaseExercise,
    $$BaseExercisesTableFilterComposer,
    $$BaseExercisesTableOrderingComposer,
    $$BaseExercisesTableAnnotationComposer,
    $$BaseExercisesTableCreateCompanionBuilder,
    $$BaseExercisesTableUpdateCompanionBuilder,
    (BaseExercise, $$BaseExercisesTableReferences),
    BaseExercise,
    PrefetchHooks Function(
        {bool exerciseVariantsRefs,
        bool workoutSetsRefs,
        bool blueprintExercisesRefs,
        bool workoutBlockKnsRefs})> {
  $$BaseExercisesTableTableManager(_$AppDatabase db, $BaseExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BaseExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BaseExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BaseExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> prefixes = const Value.absent(),
            Value<String?> implements = const Value.absent(),
            Value<String?> bodyPositions = const Value.absent(),
            Value<String?> suffixes = const Value.absent(),
            Value<String?> primaryMuscleGroup = const Value.absent(),
            Value<String?> secondaryMuscleGroup = const Value.absent(),
            Value<String?> field = const Value.absent(),
            Value<String?> tissueType = const Value.absent(),
            Value<String?> tissueName = const Value.absent(),
            Value<int?> numPhases = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> phaseDescriptions = const Value.absent(),
            Value<String?> intention = const Value.absent(),
            Value<String?> patternType = const Value.absent(),
            Value<String?> complexMetadata = const Value.absent(),
            Value<bool> isUnilateral = const Value.absent(),
            Value<String?> assistanceTypes = const Value.absent(),
            Value<String?> nameOrder = const Value.absent(),
          }) =>
              BaseExercisesCompanion(
            id: id,
            name: name,
            prefixes: prefixes,
            implements: implements,
            bodyPositions: bodyPositions,
            suffixes: suffixes,
            primaryMuscleGroup: primaryMuscleGroup,
            secondaryMuscleGroup: secondaryMuscleGroup,
            field: field,
            tissueType: tissueType,
            tissueName: tissueName,
            numPhases: numPhases,
            orderIndex: orderIndex,
            phaseDescriptions: phaseDescriptions,
            intention: intention,
            patternType: patternType,
            complexMetadata: complexMetadata,
            isUnilateral: isUnilateral,
            assistanceTypes: assistanceTypes,
            nameOrder: nameOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> prefixes = const Value.absent(),
            Value<String?> implements = const Value.absent(),
            Value<String?> bodyPositions = const Value.absent(),
            Value<String?> suffixes = const Value.absent(),
            Value<String?> primaryMuscleGroup = const Value.absent(),
            Value<String?> secondaryMuscleGroup = const Value.absent(),
            Value<String?> field = const Value.absent(),
            Value<String?> tissueType = const Value.absent(),
            Value<String?> tissueName = const Value.absent(),
            Value<int?> numPhases = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> phaseDescriptions = const Value.absent(),
            Value<String?> intention = const Value.absent(),
            Value<String?> patternType = const Value.absent(),
            Value<String?> complexMetadata = const Value.absent(),
            Value<bool> isUnilateral = const Value.absent(),
            Value<String?> assistanceTypes = const Value.absent(),
            Value<String?> nameOrder = const Value.absent(),
          }) =>
              BaseExercisesCompanion.insert(
            id: id,
            name: name,
            prefixes: prefixes,
            implements: implements,
            bodyPositions: bodyPositions,
            suffixes: suffixes,
            primaryMuscleGroup: primaryMuscleGroup,
            secondaryMuscleGroup: secondaryMuscleGroup,
            field: field,
            tissueType: tissueType,
            tissueName: tissueName,
            numPhases: numPhases,
            orderIndex: orderIndex,
            phaseDescriptions: phaseDescriptions,
            intention: intention,
            patternType: patternType,
            complexMetadata: complexMetadata,
            isUnilateral: isUnilateral,
            assistanceTypes: assistanceTypes,
            nameOrder: nameOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BaseExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {exerciseVariantsRefs = false,
              workoutSetsRefs = false,
              blueprintExercisesRefs = false,
              workoutBlockKnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseVariantsRefs) db.exerciseVariants,
                if (workoutSetsRefs) db.workoutSets,
                if (blueprintExercisesRefs) db.blueprintExercises,
                if (workoutBlockKnsRefs) db.workoutBlockKns
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseVariantsRefs)
                    await $_getPrefetchedData<BaseExercise, $BaseExercisesTable,
                            ExerciseVariant>(
                        currentTable: table,
                        referencedTable: $$BaseExercisesTableReferences
                            ._exerciseVariantsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BaseExercisesTableReferences(db, table, p0)
                                .exerciseVariantsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.baseId == item.id),
                        typedResults: items),
                  if (workoutSetsRefs)
                    await $_getPrefetchedData<BaseExercise, $BaseExercisesTable,
                            WorkoutSet>(
                        currentTable: table,
                        referencedTable: $$BaseExercisesTableReferences
                            ._workoutSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BaseExercisesTableReferences(db, table, p0)
                                .workoutSetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.baseExerciseId == item.id),
                        typedResults: items),
                  if (blueprintExercisesRefs)
                    await $_getPrefetchedData<BaseExercise, $BaseExercisesTable,
                            BlueprintExercise>(
                        currentTable: table,
                        referencedTable: $$BaseExercisesTableReferences
                            ._blueprintExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BaseExercisesTableReferences(db, table, p0)
                                .blueprintExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.baseExerciseId == item.id),
                        typedResults: items),
                  if (workoutBlockKnsRefs)
                    await $_getPrefetchedData<BaseExercise, $BaseExercisesTable, WorkoutBlockKn>(
                        currentTable: table,
                        referencedTable: $$BaseExercisesTableReferences
                            ._workoutBlockKnsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BaseExercisesTableReferences(db, table, p0)
                                .workoutBlockKnsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.baseExerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BaseExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BaseExercisesTable,
    BaseExercise,
    $$BaseExercisesTableFilterComposer,
    $$BaseExercisesTableOrderingComposer,
    $$BaseExercisesTableAnnotationComposer,
    $$BaseExercisesTableCreateCompanionBuilder,
    $$BaseExercisesTableUpdateCompanionBuilder,
    (BaseExercise, $$BaseExercisesTableReferences),
    BaseExercise,
    PrefetchHooks Function(
        {bool exerciseVariantsRefs,
        bool workoutSetsRefs,
        bool blueprintExercisesRefs,
        bool workoutBlockKnsRefs})>;
typedef $$PrefixesTableCreateCompanionBuilder = PrefixesCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$PrefixesTableUpdateCompanionBuilder = PrefixesCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$PrefixesTableReferences
    extends BaseReferences<_$AppDatabase, $PrefixesTable, Prefixe> {
  $$PrefixesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseVariantsTable, List<ExerciseVariant>>
      _exerciseVariantsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exerciseVariants,
              aliasName: $_aliasNameGenerator(
                  db.prefixes.id, db.exerciseVariants.prefixId));

  $$ExerciseVariantsTableProcessedTableManager get exerciseVariantsRefs {
    final manager =
        $$ExerciseVariantsTableTableManager($_db, $_db.exerciseVariants)
            .filter((f) => f.prefixId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_exerciseVariantsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PrefixesTableFilterComposer
    extends Composer<_$AppDatabase, $PrefixesTable> {
  $$PrefixesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> exerciseVariantsRefs(
      Expression<bool> Function($$ExerciseVariantsTableFilterComposer f) f) {
    final $$ExerciseVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.prefixId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrefixesTableOrderingComposer
    extends Composer<_$AppDatabase, $PrefixesTable> {
  $$PrefixesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$PrefixesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrefixesTable> {
  $$PrefixesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> exerciseVariantsRefs<T extends Object>(
      Expression<T> Function($$ExerciseVariantsTableAnnotationComposer a) f) {
    final $$ExerciseVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.prefixId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrefixesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrefixesTable,
    Prefixe,
    $$PrefixesTableFilterComposer,
    $$PrefixesTableOrderingComposer,
    $$PrefixesTableAnnotationComposer,
    $$PrefixesTableCreateCompanionBuilder,
    $$PrefixesTableUpdateCompanionBuilder,
    (Prefixe, $$PrefixesTableReferences),
    Prefixe,
    PrefetchHooks Function({bool exerciseVariantsRefs})> {
  $$PrefixesTableTableManager(_$AppDatabase db, $PrefixesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefixesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefixesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefixesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              PrefixesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              PrefixesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PrefixesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({exerciseVariantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseVariantsRefs) db.exerciseVariants
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseVariantsRefs)
                    await $_getPrefetchedData<Prefixe, $PrefixesTable,
                            ExerciseVariant>(
                        currentTable: table,
                        referencedTable: $$PrefixesTableReferences
                            ._exerciseVariantsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PrefixesTableReferences(db, table, p0)
                                .exerciseVariantsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.prefixId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PrefixesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrefixesTable,
    Prefixe,
    $$PrefixesTableFilterComposer,
    $$PrefixesTableOrderingComposer,
    $$PrefixesTableAnnotationComposer,
    $$PrefixesTableCreateCompanionBuilder,
    $$PrefixesTableUpdateCompanionBuilder,
    (Prefixe, $$PrefixesTableReferences),
    Prefixe,
    PrefetchHooks Function({bool exerciseVariantsRefs})>;
typedef $$SuffixesTableCreateCompanionBuilder = SuffixesCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$SuffixesTableUpdateCompanionBuilder = SuffixesCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$SuffixesTableReferences
    extends BaseReferences<_$AppDatabase, $SuffixesTable, Suffixe> {
  $$SuffixesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseVariantsTable, List<ExerciseVariant>>
      _exerciseVariantsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exerciseVariants,
              aliasName: $_aliasNameGenerator(
                  db.suffixes.id, db.exerciseVariants.suffixId));

  $$ExerciseVariantsTableProcessedTableManager get exerciseVariantsRefs {
    final manager =
        $$ExerciseVariantsTableTableManager($_db, $_db.exerciseVariants)
            .filter((f) => f.suffixId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_exerciseVariantsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SuffixesTableFilterComposer
    extends Composer<_$AppDatabase, $SuffixesTable> {
  $$SuffixesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> exerciseVariantsRefs(
      Expression<bool> Function($$ExerciseVariantsTableFilterComposer f) f) {
    final $$ExerciseVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.suffixId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SuffixesTableOrderingComposer
    extends Composer<_$AppDatabase, $SuffixesTable> {
  $$SuffixesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$SuffixesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuffixesTable> {
  $$SuffixesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> exerciseVariantsRefs<T extends Object>(
      Expression<T> Function($$ExerciseVariantsTableAnnotationComposer a) f) {
    final $$ExerciseVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.suffixId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SuffixesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SuffixesTable,
    Suffixe,
    $$SuffixesTableFilterComposer,
    $$SuffixesTableOrderingComposer,
    $$SuffixesTableAnnotationComposer,
    $$SuffixesTableCreateCompanionBuilder,
    $$SuffixesTableUpdateCompanionBuilder,
    (Suffixe, $$SuffixesTableReferences),
    Suffixe,
    PrefetchHooks Function({bool exerciseVariantsRefs})> {
  $$SuffixesTableTableManager(_$AppDatabase db, $SuffixesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuffixesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuffixesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuffixesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              SuffixesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              SuffixesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SuffixesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({exerciseVariantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseVariantsRefs) db.exerciseVariants
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseVariantsRefs)
                    await $_getPrefetchedData<Suffixe, $SuffixesTable,
                            ExerciseVariant>(
                        currentTable: table,
                        referencedTable: $$SuffixesTableReferences
                            ._exerciseVariantsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SuffixesTableReferences(db, table, p0)
                                .exerciseVariantsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.suffixId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SuffixesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SuffixesTable,
    Suffixe,
    $$SuffixesTableFilterComposer,
    $$SuffixesTableOrderingComposer,
    $$SuffixesTableAnnotationComposer,
    $$SuffixesTableCreateCompanionBuilder,
    $$SuffixesTableUpdateCompanionBuilder,
    (Suffixe, $$SuffixesTableReferences),
    Suffixe,
    PrefetchHooks Function({bool exerciseVariantsRefs})>;
typedef $$ExerciseVariantsTableCreateCompanionBuilder
    = ExerciseVariantsCompanion Function({
  Value<int> id,
  required int baseId,
  Value<int?> prefixId,
  Value<int?> suffixId,
});
typedef $$ExerciseVariantsTableUpdateCompanionBuilder
    = ExerciseVariantsCompanion Function({
  Value<int> id,
  Value<int> baseId,
  Value<int?> prefixId,
  Value<int?> suffixId,
});

final class $$ExerciseVariantsTableReferences extends BaseReferences<
    _$AppDatabase, $ExerciseVariantsTable, ExerciseVariant> {
  $$ExerciseVariantsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BaseExercisesTable _baseIdTable(_$AppDatabase db) =>
      db.baseExercises.createAlias($_aliasNameGenerator(
          db.exerciseVariants.baseId, db.baseExercises.id));

  $$BaseExercisesTableProcessedTableManager get baseId {
    final $_column = $_itemColumn<int>('base_id')!;

    final manager = $$BaseExercisesTableTableManager($_db, $_db.baseExercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PrefixesTable _prefixIdTable(_$AppDatabase db) =>
      db.prefixes.createAlias(
          $_aliasNameGenerator(db.exerciseVariants.prefixId, db.prefixes.id));

  $$PrefixesTableProcessedTableManager? get prefixId {
    final $_column = $_itemColumn<int>('prefix_id');
    if ($_column == null) return null;
    final manager = $$PrefixesTableTableManager($_db, $_db.prefixes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prefixIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SuffixesTable _suffixIdTable(_$AppDatabase db) =>
      db.suffixes.createAlias(
          $_aliasNameGenerator(db.exerciseVariants.suffixId, db.suffixes.id));

  $$SuffixesTableProcessedTableManager? get suffixId {
    final $_column = $_itemColumn<int>('suffix_id');
    if ($_column == null) return null;
    final manager = $$SuffixesTableTableManager($_db, $_db.suffixes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_suffixIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExerciseVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseVariantsTable> {
  $$ExerciseVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  $$BaseExercisesTableFilterComposer get baseId {
    final $$BaseExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableFilterComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrefixesTableFilterComposer get prefixId {
    final $$PrefixesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.prefixId,
        referencedTable: $db.prefixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrefixesTableFilterComposer(
              $db: $db,
              $table: $db.prefixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SuffixesTableFilterComposer get suffixId {
    final $$SuffixesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.suffixId,
        referencedTable: $db.suffixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuffixesTableFilterComposer(
              $db: $db,
              $table: $db.suffixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseVariantsTable> {
  $$ExerciseVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  $$BaseExercisesTableOrderingComposer get baseId {
    final $$BaseExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrefixesTableOrderingComposer get prefixId {
    final $$PrefixesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.prefixId,
        referencedTable: $db.prefixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrefixesTableOrderingComposer(
              $db: $db,
              $table: $db.prefixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SuffixesTableOrderingComposer get suffixId {
    final $$SuffixesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.suffixId,
        referencedTable: $db.suffixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuffixesTableOrderingComposer(
              $db: $db,
              $table: $db.suffixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseVariantsTable> {
  $$ExerciseVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$BaseExercisesTableAnnotationComposer get baseId {
    final $$BaseExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PrefixesTableAnnotationComposer get prefixId {
    final $$PrefixesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.prefixId,
        referencedTable: $db.prefixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrefixesTableAnnotationComposer(
              $db: $db,
              $table: $db.prefixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SuffixesTableAnnotationComposer get suffixId {
    final $$SuffixesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.suffixId,
        referencedTable: $db.suffixes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuffixesTableAnnotationComposer(
              $db: $db,
              $table: $db.suffixes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseVariantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseVariantsTable,
    ExerciseVariant,
    $$ExerciseVariantsTableFilterComposer,
    $$ExerciseVariantsTableOrderingComposer,
    $$ExerciseVariantsTableAnnotationComposer,
    $$ExerciseVariantsTableCreateCompanionBuilder,
    $$ExerciseVariantsTableUpdateCompanionBuilder,
    (ExerciseVariant, $$ExerciseVariantsTableReferences),
    ExerciseVariant,
    PrefetchHooks Function({bool baseId, bool prefixId, bool suffixId})> {
  $$ExerciseVariantsTableTableManager(
      _$AppDatabase db, $ExerciseVariantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> baseId = const Value.absent(),
            Value<int?> prefixId = const Value.absent(),
            Value<int?> suffixId = const Value.absent(),
          }) =>
              ExerciseVariantsCompanion(
            id: id,
            baseId: baseId,
            prefixId: prefixId,
            suffixId: suffixId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int baseId,
            Value<int?> prefixId = const Value.absent(),
            Value<int?> suffixId = const Value.absent(),
          }) =>
              ExerciseVariantsCompanion.insert(
            id: id,
            baseId: baseId,
            prefixId: prefixId,
            suffixId: suffixId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExerciseVariantsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {baseId = false, prefixId = false, suffixId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (baseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseId,
                    referencedTable:
                        $$ExerciseVariantsTableReferences._baseIdTable(db),
                    referencedColumn:
                        $$ExerciseVariantsTableReferences._baseIdTable(db).id,
                  ) as T;
                }
                if (prefixId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.prefixId,
                    referencedTable:
                        $$ExerciseVariantsTableReferences._prefixIdTable(db),
                    referencedColumn:
                        $$ExerciseVariantsTableReferences._prefixIdTable(db).id,
                  ) as T;
                }
                if (suffixId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.suffixId,
                    referencedTable:
                        $$ExerciseVariantsTableReferences._suffixIdTable(db),
                    referencedColumn:
                        $$ExerciseVariantsTableReferences._suffixIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExerciseVariantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExerciseVariantsTable,
    ExerciseVariant,
    $$ExerciseVariantsTableFilterComposer,
    $$ExerciseVariantsTableOrderingComposer,
    $$ExerciseVariantsTableAnnotationComposer,
    $$ExerciseVariantsTableCreateCompanionBuilder,
    $$ExerciseVariantsTableUpdateCompanionBuilder,
    (ExerciseVariant, $$ExerciseVariantsTableReferences),
    ExerciseVariant,
    PrefetchHooks Function({bool baseId, bool prefixId, bool suffixId})>;
typedef $$ProgressionEdgesTableCreateCompanionBuilder
    = ProgressionEdgesCompanion Function({
  Value<int> id,
  required int fromVariantId,
  required int toVariantId,
  required ProgressionType type,
});
typedef $$ProgressionEdgesTableUpdateCompanionBuilder
    = ProgressionEdgesCompanion Function({
  Value<int> id,
  Value<int> fromVariantId,
  Value<int> toVariantId,
  Value<ProgressionType> type,
});

final class $$ProgressionEdgesTableReferences extends BaseReferences<
    _$AppDatabase, $ProgressionEdgesTable, ProgressionEdge> {
  $$ProgressionEdgesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExerciseVariantsTable _fromVariantIdTable(_$AppDatabase db) =>
      db.exerciseVariants.createAlias($_aliasNameGenerator(
          db.progressionEdges.fromVariantId, db.exerciseVariants.id));

  $$ExerciseVariantsTableProcessedTableManager get fromVariantId {
    final $_column = $_itemColumn<int>('from_variant_id')!;

    final manager =
        $$ExerciseVariantsTableTableManager($_db, $_db.exerciseVariants)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromVariantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExerciseVariantsTable _toVariantIdTable(_$AppDatabase db) =>
      db.exerciseVariants.createAlias($_aliasNameGenerator(
          db.progressionEdges.toVariantId, db.exerciseVariants.id));

  $$ExerciseVariantsTableProcessedTableManager get toVariantId {
    final $_column = $_itemColumn<int>('to_variant_id')!;

    final manager =
        $$ExerciseVariantsTableTableManager($_db, $_db.exerciseVariants)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toVariantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProgressionEdgesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressionEdgesTable> {
  $$ProgressionEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ProgressionType, ProgressionType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ExerciseVariantsTableFilterComposer get fromVariantId {
    final $$ExerciseVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExerciseVariantsTableFilterComposer get toVariantId {
    final $$ExerciseVariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressionEdgesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressionEdgesTable> {
  $$ProgressionEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  $$ExerciseVariantsTableOrderingComposer get fromVariantId {
    final $$ExerciseVariantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableOrderingComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExerciseVariantsTableOrderingComposer get toVariantId {
    final $$ExerciseVariantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableOrderingComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressionEdgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressionEdgesTable> {
  $$ProgressionEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProgressionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$ExerciseVariantsTableAnnotationComposer get fromVariantId {
    final $$ExerciseVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExerciseVariantsTableAnnotationComposer get toVariantId {
    final $$ExerciseVariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toVariantId,
        referencedTable: $db.exerciseVariants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseVariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseVariants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressionEdgesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgressionEdgesTable,
    ProgressionEdge,
    $$ProgressionEdgesTableFilterComposer,
    $$ProgressionEdgesTableOrderingComposer,
    $$ProgressionEdgesTableAnnotationComposer,
    $$ProgressionEdgesTableCreateCompanionBuilder,
    $$ProgressionEdgesTableUpdateCompanionBuilder,
    (ProgressionEdge, $$ProgressionEdgesTableReferences),
    ProgressionEdge,
    PrefetchHooks Function({bool fromVariantId, bool toVariantId})> {
  $$ProgressionEdgesTableTableManager(
      _$AppDatabase db, $ProgressionEdgesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressionEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressionEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressionEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> fromVariantId = const Value.absent(),
            Value<int> toVariantId = const Value.absent(),
            Value<ProgressionType> type = const Value.absent(),
          }) =>
              ProgressionEdgesCompanion(
            id: id,
            fromVariantId: fromVariantId,
            toVariantId: toVariantId,
            type: type,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int fromVariantId,
            required int toVariantId,
            required ProgressionType type,
          }) =>
              ProgressionEdgesCompanion.insert(
            id: id,
            fromVariantId: fromVariantId,
            toVariantId: toVariantId,
            type: type,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProgressionEdgesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {fromVariantId = false, toVariantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fromVariantId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fromVariantId,
                    referencedTable: $$ProgressionEdgesTableReferences
                        ._fromVariantIdTable(db),
                    referencedColumn: $$ProgressionEdgesTableReferences
                        ._fromVariantIdTable(db)
                        .id,
                  ) as T;
                }
                if (toVariantId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toVariantId,
                    referencedTable:
                        $$ProgressionEdgesTableReferences._toVariantIdTable(db),
                    referencedColumn: $$ProgressionEdgesTableReferences
                        ._toVariantIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProgressionEdgesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgressionEdgesTable,
    ProgressionEdge,
    $$ProgressionEdgesTableFilterComposer,
    $$ProgressionEdgesTableOrderingComposer,
    $$ProgressionEdgesTableAnnotationComposer,
    $$ProgressionEdgesTableCreateCompanionBuilder,
    $$ProgressionEdgesTableUpdateCompanionBuilder,
    (ProgressionEdge, $$ProgressionEdgesTableReferences),
    ProgressionEdge,
    PrefetchHooks Function({bool fromVariantId, bool toVariantId})>;
typedef $$WorkoutLogsTableCreateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> id,
  required DateTime date,
  Value<int?> durationMinutes,
  Value<DateTime?> workoutStartTime,
  Value<int> accumulatedSeconds,
  Value<String?> notes,
});
typedef $$WorkoutLogsTableUpdateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int?> durationMinutes,
  Value<DateTime?> workoutStartTime,
  Value<int> accumulatedSeconds,
  Value<String?> notes,
});

final class $$WorkoutLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutLogsTable, WorkoutLog> {
  $$WorkoutLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
      _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.workoutSets,
          aliasName:
              $_aliasNameGenerator(db.workoutLogs.id, db.workoutSets.logId));

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.logId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get workoutStartTime => $composableBuilder(
      column: $table.workoutStartTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accumulatedSeconds => $composableBuilder(
      column: $table.accumulatedSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutSetsRefs(
      Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.logId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get workoutStartTime => $composableBuilder(
      column: $table.workoutStartTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accumulatedSeconds => $composableBuilder(
      column: $table.accumulatedSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get workoutStartTime => $composableBuilder(
      column: $table.workoutStartTime, builder: (column) => column);

  GeneratedColumn<int> get accumulatedSeconds => $composableBuilder(
      column: $table.accumulatedSeconds, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> workoutSetsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.logId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function({bool workoutSetsRefs})> {
  $$WorkoutLogsTableTableManager(_$AppDatabase db, $WorkoutLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<DateTime?> workoutStartTime = const Value.absent(),
            Value<int> accumulatedSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              WorkoutLogsCompanion(
            id: id,
            date: date,
            durationMinutes: durationMinutes,
            workoutStartTime: workoutStartTime,
            accumulatedSeconds: accumulatedSeconds,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<int?> durationMinutes = const Value.absent(),
            Value<DateTime?> workoutStartTime = const Value.absent(),
            Value<int> accumulatedSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              WorkoutLogsCompanion.insert(
            id: id,
            date: date,
            durationMinutes: durationMinutes,
            workoutStartTime: workoutStartTime,
            accumulatedSeconds: accumulatedSeconds,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutSetsRefs) db.workoutSets],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSetsRefs)
                    await $_getPrefetchedData<WorkoutLog, $WorkoutLogsTable,
                            WorkoutSet>(
                        currentTable: table,
                        referencedTable: $$WorkoutLogsTableReferences
                            ._workoutSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutLogsTableReferences(db, table, p0)
                                .workoutSetsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.logId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, $$WorkoutLogsTableReferences),
    WorkoutLog,
    PrefetchHooks Function({bool workoutSetsRefs})>;
typedef $$WorkoutSetsTableCreateCompanionBuilder = WorkoutSetsCompanion
    Function({
  Value<int> id,
  required int logId,
  required int baseExerciseId,
  required double weight,
  required double reps,
  Value<double?> rpe,
  Value<double?> rir,
  Value<int?> technique,
  Value<int?> failurePhase,
  Value<int?> restTimeSeconds,
  Value<String?> notes,
  Value<String?> trackName,
  Value<int?> hypeLevel,
  Value<bool> isPrSong,
  Value<bool> isPr,
  Value<bool> isCompleted,
  Value<int> orderIndex,
  Value<DateTime> timestamp,
  Value<String?> complexMetadata,
  Value<String?> priority,
  Value<String?> supersetGroupId,
  Value<String?> supersetName,
  Value<double?> assistanceValue,
  Value<String?> assistanceType,
});
typedef $$WorkoutSetsTableUpdateCompanionBuilder = WorkoutSetsCompanion
    Function({
  Value<int> id,
  Value<int> logId,
  Value<int> baseExerciseId,
  Value<double> weight,
  Value<double> reps,
  Value<double?> rpe,
  Value<double?> rir,
  Value<int?> technique,
  Value<int?> failurePhase,
  Value<int?> restTimeSeconds,
  Value<String?> notes,
  Value<String?> trackName,
  Value<int?> hypeLevel,
  Value<bool> isPrSong,
  Value<bool> isPr,
  Value<bool> isCompleted,
  Value<int> orderIndex,
  Value<DateTime> timestamp,
  Value<String?> complexMetadata,
  Value<String?> priority,
  Value<String?> supersetGroupId,
  Value<String?> supersetName,
  Value<double?> assistanceValue,
  Value<String?> assistanceType,
});

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutLogsTable _logIdTable(_$AppDatabase db) =>
      db.workoutLogs.createAlias(
          $_aliasNameGenerator(db.workoutSets.logId, db.workoutLogs.id));

  $$WorkoutLogsTableProcessedTableManager get logId {
    final $_column = $_itemColumn<int>('log_id')!;

    final manager = $$WorkoutLogsTableTableManager($_db, $_db.workoutLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_logIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BaseExercisesTable _baseExerciseIdTable(_$AppDatabase db) =>
      db.baseExercises.createAlias($_aliasNameGenerator(
          db.workoutSets.baseExerciseId, db.baseExercises.id));

  $$BaseExercisesTableProcessedTableManager get baseExerciseId {
    final $_column = $_itemColumn<int>('base_exercise_id')!;

    final manager = $$BaseExercisesTableTableManager($_db, $_db.baseExercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DiscomfortLogsTable, List<DiscomfortLog>>
      _discomfortLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.discomfortLogs,
              aliasName: $_aliasNameGenerator(
                  db.workoutSets.id, db.discomfortLogs.setId));

  $$DiscomfortLogsTableProcessedTableManager get discomfortLogsRefs {
    final manager = $$DiscomfortLogsTableTableManager($_db, $_db.discomfortLogs)
        .filter((f) => f.setId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_discomfortLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get technique => $composableBuilder(
      column: $table.technique, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get failurePhase => $composableBuilder(
      column: $table.failurePhase, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackName => $composableBuilder(
      column: $table.trackName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hypeLevel => $composableBuilder(
      column: $table.hypeLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrSong => $composableBuilder(
      column: $table.isPrSong, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPr => $composableBuilder(
      column: $table.isPr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetName => $composableBuilder(
      column: $table.supersetName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get assistanceValue => $composableBuilder(
      column: $table.assistanceValue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assistanceType => $composableBuilder(
      column: $table.assistanceType,
      builder: (column) => ColumnFilters(column));

  $$WorkoutLogsTableFilterComposer get logId {
    final $$WorkoutLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableFilterComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableFilterComposer get baseExerciseId {
    final $$BaseExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableFilterComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> discomfortLogsRefs(
      Expression<bool> Function($$DiscomfortLogsTableFilterComposer f) f) {
    final $$DiscomfortLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.discomfortLogs,
        getReferencedColumn: (t) => t.setId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogsTableFilterComposer(
              $db: $db,
              $table: $db.discomfortLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get technique => $composableBuilder(
      column: $table.technique, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failurePhase => $composableBuilder(
      column: $table.failurePhase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackName => $composableBuilder(
      column: $table.trackName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hypeLevel => $composableBuilder(
      column: $table.hypeLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrSong => $composableBuilder(
      column: $table.isPrSong, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPr => $composableBuilder(
      column: $table.isPr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetName => $composableBuilder(
      column: $table.supersetName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get assistanceValue => $composableBuilder(
      column: $table.assistanceValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assistanceType => $composableBuilder(
      column: $table.assistanceType,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutLogsTableOrderingComposer get logId {
    final $$WorkoutLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableOrderingComposer get baseExerciseId {
    final $$BaseExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<int> get technique =>
      $composableBuilder(column: $table.technique, builder: (column) => column);

  GeneratedColumn<int> get failurePhase => $composableBuilder(
      column: $table.failurePhase, builder: (column) => column);

  GeneratedColumn<int> get restTimeSeconds => $composableBuilder(
      column: $table.restTimeSeconds, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get trackName =>
      $composableBuilder(column: $table.trackName, builder: (column) => column);

  GeneratedColumn<int> get hypeLevel =>
      $composableBuilder(column: $table.hypeLevel, builder: (column) => column);

  GeneratedColumn<bool> get isPrSong =>
      $composableBuilder(column: $table.isPrSong, builder: (column) => column);

  GeneratedColumn<bool> get isPr =>
      $composableBuilder(column: $table.isPr, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get complexMetadata => $composableBuilder(
      column: $table.complexMetadata, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId, builder: (column) => column);

  GeneratedColumn<String> get supersetName => $composableBuilder(
      column: $table.supersetName, builder: (column) => column);

  GeneratedColumn<double> get assistanceValue => $composableBuilder(
      column: $table.assistanceValue, builder: (column) => column);

  GeneratedColumn<String> get assistanceType => $composableBuilder(
      column: $table.assistanceType, builder: (column) => column);

  $$WorkoutLogsTableAnnotationComposer get logId {
    final $$WorkoutLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.workoutLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableAnnotationComposer get baseExerciseId {
    final $$BaseExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> discomfortLogsRefs<T extends Object>(
      Expression<T> Function($$DiscomfortLogsTableAnnotationComposer a) f) {
    final $$DiscomfortLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.discomfortLogs,
        getReferencedColumn: (t) => t.setId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.discomfortLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSetsTable,
    WorkoutSet,
    $$WorkoutSetsTableFilterComposer,
    $$WorkoutSetsTableOrderingComposer,
    $$WorkoutSetsTableAnnotationComposer,
    $$WorkoutSetsTableCreateCompanionBuilder,
    $$WorkoutSetsTableUpdateCompanionBuilder,
    (WorkoutSet, $$WorkoutSetsTableReferences),
    WorkoutSet,
    PrefetchHooks Function(
        {bool logId, bool baseExerciseId, bool discomfortLogsRefs})> {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> logId = const Value.absent(),
            Value<int> baseExerciseId = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<double> reps = const Value.absent(),
            Value<double?> rpe = const Value.absent(),
            Value<double?> rir = const Value.absent(),
            Value<int?> technique = const Value.absent(),
            Value<int?> failurePhase = const Value.absent(),
            Value<int?> restTimeSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> trackName = const Value.absent(),
            Value<int?> hypeLevel = const Value.absent(),
            Value<bool> isPrSong = const Value.absent(),
            Value<bool> isPr = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String?> complexMetadata = const Value.absent(),
            Value<String?> priority = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<String?> supersetName = const Value.absent(),
            Value<double?> assistanceValue = const Value.absent(),
            Value<String?> assistanceType = const Value.absent(),
          }) =>
              WorkoutSetsCompanion(
            id: id,
            logId: logId,
            baseExerciseId: baseExerciseId,
            weight: weight,
            reps: reps,
            rpe: rpe,
            rir: rir,
            technique: technique,
            failurePhase: failurePhase,
            restTimeSeconds: restTimeSeconds,
            notes: notes,
            trackName: trackName,
            hypeLevel: hypeLevel,
            isPrSong: isPrSong,
            isPr: isPr,
            isCompleted: isCompleted,
            orderIndex: orderIndex,
            timestamp: timestamp,
            complexMetadata: complexMetadata,
            priority: priority,
            supersetGroupId: supersetGroupId,
            supersetName: supersetName,
            assistanceValue: assistanceValue,
            assistanceType: assistanceType,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int logId,
            required int baseExerciseId,
            required double weight,
            required double reps,
            Value<double?> rpe = const Value.absent(),
            Value<double?> rir = const Value.absent(),
            Value<int?> technique = const Value.absent(),
            Value<int?> failurePhase = const Value.absent(),
            Value<int?> restTimeSeconds = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> trackName = const Value.absent(),
            Value<int?> hypeLevel = const Value.absent(),
            Value<bool> isPrSong = const Value.absent(),
            Value<bool> isPr = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String?> complexMetadata = const Value.absent(),
            Value<String?> priority = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<String?> supersetName = const Value.absent(),
            Value<double?> assistanceValue = const Value.absent(),
            Value<String?> assistanceType = const Value.absent(),
          }) =>
              WorkoutSetsCompanion.insert(
            id: id,
            logId: logId,
            baseExerciseId: baseExerciseId,
            weight: weight,
            reps: reps,
            rpe: rpe,
            rir: rir,
            technique: technique,
            failurePhase: failurePhase,
            restTimeSeconds: restTimeSeconds,
            notes: notes,
            trackName: trackName,
            hypeLevel: hypeLevel,
            isPrSong: isPrSong,
            isPr: isPr,
            isCompleted: isCompleted,
            orderIndex: orderIndex,
            timestamp: timestamp,
            complexMetadata: complexMetadata,
            priority: priority,
            supersetGroupId: supersetGroupId,
            supersetName: supersetName,
            assistanceValue: assistanceValue,
            assistanceType: assistanceType,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {logId = false,
              baseExerciseId = false,
              discomfortLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (discomfortLogsRefs) db.discomfortLogs
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (logId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.logId,
                    referencedTable:
                        $$WorkoutSetsTableReferences._logIdTable(db),
                    referencedColumn:
                        $$WorkoutSetsTableReferences._logIdTable(db).id,
                  ) as T;
                }
                if (baseExerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseExerciseId,
                    referencedTable:
                        $$WorkoutSetsTableReferences._baseExerciseIdTable(db),
                    referencedColumn: $$WorkoutSetsTableReferences
                        ._baseExerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (discomfortLogsRefs)
                    await $_getPrefetchedData<WorkoutSet, $WorkoutSetsTable,
                            DiscomfortLog>(
                        currentTable: table,
                        referencedTable: $$WorkoutSetsTableReferences
                            ._discomfortLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSetsTableReferences(db, table, p0)
                                .discomfortLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.setId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutSetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSetsTable,
    WorkoutSet,
    $$WorkoutSetsTableFilterComposer,
    $$WorkoutSetsTableOrderingComposer,
    $$WorkoutSetsTableAnnotationComposer,
    $$WorkoutSetsTableCreateCompanionBuilder,
    $$WorkoutSetsTableUpdateCompanionBuilder,
    (WorkoutSet, $$WorkoutSetsTableReferences),
    WorkoutSet,
    PrefetchHooks Function(
        {bool logId, bool baseExerciseId, bool discomfortLogsRefs})>;
typedef $$DiscomfortTagsTableCreateCompanionBuilder = DiscomfortTagsCompanion
    Function({
  Value<int> id,
  required String name,
});
typedef $$DiscomfortTagsTableUpdateCompanionBuilder = DiscomfortTagsCompanion
    Function({
  Value<int> id,
  Value<String> name,
});

final class $$DiscomfortTagsTableReferences
    extends BaseReferences<_$AppDatabase, $DiscomfortTagsTable, DiscomfortTag> {
  $$DiscomfortTagsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiscomfortLogTagsTable, List<DiscomfortLogTag>>
      _discomfortLogTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.discomfortLogTags,
              aliasName: $_aliasNameGenerator(
                  db.discomfortTags.id, db.discomfortLogTags.tagId));

  $$DiscomfortLogTagsTableProcessedTableManager get discomfortLogTagsRefs {
    final manager =
        $$DiscomfortLogTagsTableTableManager($_db, $_db.discomfortLogTags)
            .filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_discomfortLogTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DiscomfortTagsTableFilterComposer
    extends Composer<_$AppDatabase, $DiscomfortTagsTable> {
  $$DiscomfortTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> discomfortLogTagsRefs(
      Expression<bool> Function($$DiscomfortLogTagsTableFilterComposer f) f) {
    final $$DiscomfortLogTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.discomfortLogTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogTagsTableFilterComposer(
              $db: $db,
              $table: $db.discomfortLogTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DiscomfortTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscomfortTagsTable> {
  $$DiscomfortTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$DiscomfortTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscomfortTagsTable> {
  $$DiscomfortTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> discomfortLogTagsRefs<T extends Object>(
      Expression<T> Function($$DiscomfortLogTagsTableAnnotationComposer a) f) {
    final $$DiscomfortLogTagsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.discomfortLogTags,
            getReferencedColumn: (t) => t.tagId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DiscomfortLogTagsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.discomfortLogTags,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$DiscomfortTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiscomfortTagsTable,
    DiscomfortTag,
    $$DiscomfortTagsTableFilterComposer,
    $$DiscomfortTagsTableOrderingComposer,
    $$DiscomfortTagsTableAnnotationComposer,
    $$DiscomfortTagsTableCreateCompanionBuilder,
    $$DiscomfortTagsTableUpdateCompanionBuilder,
    (DiscomfortTag, $$DiscomfortTagsTableReferences),
    DiscomfortTag,
    PrefetchHooks Function({bool discomfortLogTagsRefs})> {
  $$DiscomfortTagsTableTableManager(
      _$AppDatabase db, $DiscomfortTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscomfortTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscomfortTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscomfortTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              DiscomfortTagsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              DiscomfortTagsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DiscomfortTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({discomfortLogTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (discomfortLogTagsRefs) db.discomfortLogTags
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (discomfortLogTagsRefs)
                    await $_getPrefetchedData<DiscomfortTag,
                            $DiscomfortTagsTable, DiscomfortLogTag>(
                        currentTable: table,
                        referencedTable: $$DiscomfortTagsTableReferences
                            ._discomfortLogTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DiscomfortTagsTableReferences(db, table, p0)
                                .discomfortLogTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DiscomfortTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiscomfortTagsTable,
    DiscomfortTag,
    $$DiscomfortTagsTableFilterComposer,
    $$DiscomfortTagsTableOrderingComposer,
    $$DiscomfortTagsTableAnnotationComposer,
    $$DiscomfortTagsTableCreateCompanionBuilder,
    $$DiscomfortTagsTableUpdateCompanionBuilder,
    (DiscomfortTag, $$DiscomfortTagsTableReferences),
    DiscomfortTag,
    PrefetchHooks Function({bool discomfortLogTagsRefs})>;
typedef $$DiscomfortLogsTableCreateCompanionBuilder = DiscomfortLogsCompanion
    Function({
  Value<int> id,
  required int setId,
  required String description,
  Value<int?> intensity,
});
typedef $$DiscomfortLogsTableUpdateCompanionBuilder = DiscomfortLogsCompanion
    Function({
  Value<int> id,
  Value<int> setId,
  Value<String> description,
  Value<int?> intensity,
});

final class $$DiscomfortLogsTableReferences
    extends BaseReferences<_$AppDatabase, $DiscomfortLogsTable, DiscomfortLog> {
  $$DiscomfortLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSetsTable _setIdTable(_$AppDatabase db) =>
      db.workoutSets.createAlias(
          $_aliasNameGenerator(db.discomfortLogs.setId, db.workoutSets.id));

  $$WorkoutSetsTableProcessedTableManager get setId {
    final $_column = $_itemColumn<int>('set_id')!;

    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DiscomfortLogTagsTable, List<DiscomfortLogTag>>
      _discomfortLogTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.discomfortLogTags,
              aliasName: $_aliasNameGenerator(
                  db.discomfortLogs.id, db.discomfortLogTags.logId));

  $$DiscomfortLogTagsTableProcessedTableManager get discomfortLogTagsRefs {
    final manager =
        $$DiscomfortLogTagsTableTableManager($_db, $_db.discomfortLogTags)
            .filter((f) => f.logId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_discomfortLogTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DiscomfortLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DiscomfortLogsTable> {
  $$DiscomfortLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intensity => $composableBuilder(
      column: $table.intensity, builder: (column) => ColumnFilters(column));

  $$WorkoutSetsTableFilterComposer get setId {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.setId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> discomfortLogTagsRefs(
      Expression<bool> Function($$DiscomfortLogTagsTableFilterComposer f) f) {
    final $$DiscomfortLogTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.discomfortLogTags,
        getReferencedColumn: (t) => t.logId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogTagsTableFilterComposer(
              $db: $db,
              $table: $db.discomfortLogTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DiscomfortLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscomfortLogsTable> {
  $$DiscomfortLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intensity => $composableBuilder(
      column: $table.intensity, builder: (column) => ColumnOrderings(column));

  $$WorkoutSetsTableOrderingComposer get setId {
    final $$WorkoutSetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.setId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiscomfortLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscomfortLogsTable> {
  $$DiscomfortLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  $$WorkoutSetsTableAnnotationComposer get setId {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.setId,
        referencedTable: $db.workoutSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> discomfortLogTagsRefs<T extends Object>(
      Expression<T> Function($$DiscomfortLogTagsTableAnnotationComposer a) f) {
    final $$DiscomfortLogTagsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.discomfortLogTags,
            getReferencedColumn: (t) => t.logId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DiscomfortLogTagsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.discomfortLogTags,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$DiscomfortLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiscomfortLogsTable,
    DiscomfortLog,
    $$DiscomfortLogsTableFilterComposer,
    $$DiscomfortLogsTableOrderingComposer,
    $$DiscomfortLogsTableAnnotationComposer,
    $$DiscomfortLogsTableCreateCompanionBuilder,
    $$DiscomfortLogsTableUpdateCompanionBuilder,
    (DiscomfortLog, $$DiscomfortLogsTableReferences),
    DiscomfortLog,
    PrefetchHooks Function({bool setId, bool discomfortLogTagsRefs})> {
  $$DiscomfortLogsTableTableManager(
      _$AppDatabase db, $DiscomfortLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscomfortLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscomfortLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscomfortLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> setId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int?> intensity = const Value.absent(),
          }) =>
              DiscomfortLogsCompanion(
            id: id,
            setId: setId,
            description: description,
            intensity: intensity,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int setId,
            required String description,
            Value<int?> intensity = const Value.absent(),
          }) =>
              DiscomfortLogsCompanion.insert(
            id: id,
            setId: setId,
            description: description,
            intensity: intensity,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DiscomfortLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {setId = false, discomfortLogTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (discomfortLogTagsRefs) db.discomfortLogTags
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (setId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.setId,
                    referencedTable:
                        $$DiscomfortLogsTableReferences._setIdTable(db),
                    referencedColumn:
                        $$DiscomfortLogsTableReferences._setIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (discomfortLogTagsRefs)
                    await $_getPrefetchedData<DiscomfortLog,
                            $DiscomfortLogsTable, DiscomfortLogTag>(
                        currentTable: table,
                        referencedTable: $$DiscomfortLogsTableReferences
                            ._discomfortLogTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DiscomfortLogsTableReferences(db, table, p0)
                                .discomfortLogTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.logId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DiscomfortLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiscomfortLogsTable,
    DiscomfortLog,
    $$DiscomfortLogsTableFilterComposer,
    $$DiscomfortLogsTableOrderingComposer,
    $$DiscomfortLogsTableAnnotationComposer,
    $$DiscomfortLogsTableCreateCompanionBuilder,
    $$DiscomfortLogsTableUpdateCompanionBuilder,
    (DiscomfortLog, $$DiscomfortLogsTableReferences),
    DiscomfortLog,
    PrefetchHooks Function({bool setId, bool discomfortLogTagsRefs})>;
typedef $$DiscomfortLogTagsTableCreateCompanionBuilder
    = DiscomfortLogTagsCompanion Function({
  required int logId,
  required int tagId,
  Value<int> rowid,
});
typedef $$DiscomfortLogTagsTableUpdateCompanionBuilder
    = DiscomfortLogTagsCompanion Function({
  Value<int> logId,
  Value<int> tagId,
  Value<int> rowid,
});

final class $$DiscomfortLogTagsTableReferences extends BaseReferences<
    _$AppDatabase, $DiscomfortLogTagsTable, DiscomfortLogTag> {
  $$DiscomfortLogTagsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DiscomfortLogsTable _logIdTable(_$AppDatabase db) =>
      db.discomfortLogs.createAlias($_aliasNameGenerator(
          db.discomfortLogTags.logId, db.discomfortLogs.id));

  $$DiscomfortLogsTableProcessedTableManager get logId {
    final $_column = $_itemColumn<int>('log_id')!;

    final manager = $$DiscomfortLogsTableTableManager($_db, $_db.discomfortLogs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_logIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DiscomfortTagsTable _tagIdTable(_$AppDatabase db) =>
      db.discomfortTags.createAlias($_aliasNameGenerator(
          db.discomfortLogTags.tagId, db.discomfortTags.id));

  $$DiscomfortTagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$DiscomfortTagsTableTableManager($_db, $_db.discomfortTags)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DiscomfortLogTagsTableFilterComposer
    extends Composer<_$AppDatabase, $DiscomfortLogTagsTable> {
  $$DiscomfortLogTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DiscomfortLogsTableFilterComposer get logId {
    final $$DiscomfortLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.discomfortLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogsTableFilterComposer(
              $db: $db,
              $table: $db.discomfortLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DiscomfortTagsTableFilterComposer get tagId {
    final $$DiscomfortTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.discomfortTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortTagsTableFilterComposer(
              $db: $db,
              $table: $db.discomfortTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiscomfortLogTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscomfortLogTagsTable> {
  $$DiscomfortLogTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DiscomfortLogsTableOrderingComposer get logId {
    final $$DiscomfortLogsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.discomfortLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogsTableOrderingComposer(
              $db: $db,
              $table: $db.discomfortLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DiscomfortTagsTableOrderingComposer get tagId {
    final $$DiscomfortTagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.discomfortTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortTagsTableOrderingComposer(
              $db: $db,
              $table: $db.discomfortTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiscomfortLogTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscomfortLogTagsTable> {
  $$DiscomfortLogTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DiscomfortLogsTableAnnotationComposer get logId {
    final $$DiscomfortLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.logId,
        referencedTable: $db.discomfortLogs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.discomfortLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DiscomfortTagsTableAnnotationComposer get tagId {
    final $$DiscomfortTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.discomfortTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DiscomfortTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.discomfortTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DiscomfortLogTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiscomfortLogTagsTable,
    DiscomfortLogTag,
    $$DiscomfortLogTagsTableFilterComposer,
    $$DiscomfortLogTagsTableOrderingComposer,
    $$DiscomfortLogTagsTableAnnotationComposer,
    $$DiscomfortLogTagsTableCreateCompanionBuilder,
    $$DiscomfortLogTagsTableUpdateCompanionBuilder,
    (DiscomfortLogTag, $$DiscomfortLogTagsTableReferences),
    DiscomfortLogTag,
    PrefetchHooks Function({bool logId, bool tagId})> {
  $$DiscomfortLogTagsTableTableManager(
      _$AppDatabase db, $DiscomfortLogTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscomfortLogTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscomfortLogTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscomfortLogTagsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> logId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DiscomfortLogTagsCompanion(
            logId: logId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int logId,
            required int tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              DiscomfortLogTagsCompanion.insert(
            logId: logId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DiscomfortLogTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({logId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (logId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.logId,
                    referencedTable:
                        $$DiscomfortLogTagsTableReferences._logIdTable(db),
                    referencedColumn:
                        $$DiscomfortLogTagsTableReferences._logIdTable(db).id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable:
                        $$DiscomfortLogTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$DiscomfortLogTagsTableReferences._tagIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DiscomfortLogTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiscomfortLogTagsTable,
    DiscomfortLogTag,
    $$DiscomfortLogTagsTableFilterComposer,
    $$DiscomfortLogTagsTableOrderingComposer,
    $$DiscomfortLogTagsTableAnnotationComposer,
    $$DiscomfortLogTagsTableCreateCompanionBuilder,
    $$DiscomfortLogTagsTableUpdateCompanionBuilder,
    (DiscomfortLogTag, $$DiscomfortLogTagsTableReferences),
    DiscomfortLogTag,
    PrefetchHooks Function({bool logId, bool tagId})>;
typedef $$BlueprintsTableCreateCompanionBuilder = BlueprintsCompanion Function({
  Value<int> id,
  required String name,
  required String intention,
  Value<DateTime?> createdAt,
});
typedef $$BlueprintsTableUpdateCompanionBuilder = BlueprintsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> intention,
  Value<DateTime?> createdAt,
});

final class $$BlueprintsTableReferences
    extends BaseReferences<_$AppDatabase, $BlueprintsTable, Blueprint> {
  $$BlueprintsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BlueprintExercisesTable, List<BlueprintExercise>>
      _blueprintExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.blueprintExercises,
              aliasName: $_aliasNameGenerator(
                  db.blueprints.id, db.blueprintExercises.blueprintId));

  $$BlueprintExercisesTableProcessedTableManager get blueprintExercisesRefs {
    final manager = $$BlueprintExercisesTableTableManager(
            $_db, $_db.blueprintExercises)
        .filter((f) => f.blueprintId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_blueprintExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PlanDaysTable, List<PlanDay>> _planDaysRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.planDays,
          aliasName:
              $_aliasNameGenerator(db.blueprints.id, db.planDays.blueprintId));

  $$PlanDaysTableProcessedTableManager get planDaysRefs {
    final manager = $$PlanDaysTableTableManager($_db, $_db.planDays)
        .filter((f) => f.blueprintId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planDaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BlueprintsTableFilterComposer
    extends Composer<_$AppDatabase, $BlueprintsTable> {
  $$BlueprintsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> blueprintExercisesRefs(
      Expression<bool> Function($$BlueprintExercisesTableFilterComposer f) f) {
    final $$BlueprintExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.blueprintExercises,
        getReferencedColumn: (t) => t.blueprintId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintExercisesTableFilterComposer(
              $db: $db,
              $table: $db.blueprintExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> planDaysRefs(
      Expression<bool> Function($$PlanDaysTableFilterComposer f) f) {
    final $$PlanDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.blueprintId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableFilterComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlueprintsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlueprintsTable> {
  $$BlueprintsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BlueprintsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlueprintsTable> {
  $$BlueprintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> blueprintExercisesRefs<T extends Object>(
      Expression<T> Function($$BlueprintExercisesTableAnnotationComposer a) f) {
    final $$BlueprintExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.blueprintExercises,
            getReferencedColumn: (t) => t.blueprintId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$BlueprintExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.blueprintExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> planDaysRefs<T extends Object>(
      Expression<T> Function($$PlanDaysTableAnnotationComposer a) f) {
    final $$PlanDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.blueprintId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlueprintsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BlueprintsTable,
    Blueprint,
    $$BlueprintsTableFilterComposer,
    $$BlueprintsTableOrderingComposer,
    $$BlueprintsTableAnnotationComposer,
    $$BlueprintsTableCreateCompanionBuilder,
    $$BlueprintsTableUpdateCompanionBuilder,
    (Blueprint, $$BlueprintsTableReferences),
    Blueprint,
    PrefetchHooks Function({bool blueprintExercisesRefs, bool planDaysRefs})> {
  $$BlueprintsTableTableManager(_$AppDatabase db, $BlueprintsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlueprintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlueprintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlueprintsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> intention = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              BlueprintsCompanion(
            id: id,
            name: name,
            intention: intention,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String intention,
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              BlueprintsCompanion.insert(
            id: id,
            name: name,
            intention: intention,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BlueprintsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {blueprintExercisesRefs = false, planDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (blueprintExercisesRefs) db.blueprintExercises,
                if (planDaysRefs) db.planDays
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (blueprintExercisesRefs)
                    await $_getPrefetchedData<Blueprint, $BlueprintsTable,
                            BlueprintExercise>(
                        currentTable: table,
                        referencedTable: $$BlueprintsTableReferences
                            ._blueprintExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlueprintsTableReferences(db, table, p0)
                                .blueprintExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.blueprintId == item.id),
                        typedResults: items),
                  if (planDaysRefs)
                    await $_getPrefetchedData<Blueprint, $BlueprintsTable,
                            PlanDay>(
                        currentTable: table,
                        referencedTable:
                            $$BlueprintsTableReferences._planDaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlueprintsTableReferences(db, table, p0)
                                .planDaysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.blueprintId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BlueprintsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BlueprintsTable,
    Blueprint,
    $$BlueprintsTableFilterComposer,
    $$BlueprintsTableOrderingComposer,
    $$BlueprintsTableAnnotationComposer,
    $$BlueprintsTableCreateCompanionBuilder,
    $$BlueprintsTableUpdateCompanionBuilder,
    (Blueprint, $$BlueprintsTableReferences),
    Blueprint,
    PrefetchHooks Function({bool blueprintExercisesRefs, bool planDaysRefs})>;
typedef $$BlueprintExercisesTableCreateCompanionBuilder
    = BlueprintExercisesCompanion Function({
  Value<int> id,
  required int blueprintId,
  required int baseExerciseId,
  Value<String?> targetSetsReps,
  required int orderIndex,
  Value<String?> priority,
  Value<String?> supersetGroupId,
  Value<String?> supersetName,
});
typedef $$BlueprintExercisesTableUpdateCompanionBuilder
    = BlueprintExercisesCompanion Function({
  Value<int> id,
  Value<int> blueprintId,
  Value<int> baseExerciseId,
  Value<String?> targetSetsReps,
  Value<int> orderIndex,
  Value<String?> priority,
  Value<String?> supersetGroupId,
  Value<String?> supersetName,
});

final class $$BlueprintExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $BlueprintExercisesTable, BlueprintExercise> {
  $$BlueprintExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BlueprintsTable _blueprintIdTable(_$AppDatabase db) =>
      db.blueprints.createAlias($_aliasNameGenerator(
          db.blueprintExercises.blueprintId, db.blueprints.id));

  $$BlueprintsTableProcessedTableManager get blueprintId {
    final $_column = $_itemColumn<int>('blueprint_id')!;

    final manager = $$BlueprintsTableTableManager($_db, $_db.blueprints)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blueprintIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BaseExercisesTable _baseExerciseIdTable(_$AppDatabase db) =>
      db.baseExercises.createAlias($_aliasNameGenerator(
          db.blueprintExercises.baseExerciseId, db.baseExercises.id));

  $$BaseExercisesTableProcessedTableManager get baseExerciseId {
    final $_column = $_itemColumn<int>('base_exercise_id')!;

    final manager = $$BaseExercisesTableTableManager($_db, $_db.baseExercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BlueprintExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $BlueprintExercisesTable> {
  $$BlueprintExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetSetsReps => $composableBuilder(
      column: $table.targetSetsReps,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetName => $composableBuilder(
      column: $table.supersetName, builder: (column) => ColumnFilters(column));

  $$BlueprintsTableFilterComposer get blueprintId {
    final $$BlueprintsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableFilterComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableFilterComposer get baseExerciseId {
    final $$BaseExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableFilterComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BlueprintExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $BlueprintExercisesTable> {
  $$BlueprintExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetSetsReps => $composableBuilder(
      column: $table.targetSetsReps,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetName => $composableBuilder(
      column: $table.supersetName,
      builder: (column) => ColumnOrderings(column));

  $$BlueprintsTableOrderingComposer get blueprintId {
    final $$BlueprintsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableOrderingComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableOrderingComposer get baseExerciseId {
    final $$BaseExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BlueprintExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlueprintExercisesTable> {
  $$BlueprintExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetSetsReps => $composableBuilder(
      column: $table.targetSetsReps, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get supersetGroupId => $composableBuilder(
      column: $table.supersetGroupId, builder: (column) => column);

  GeneratedColumn<String> get supersetName => $composableBuilder(
      column: $table.supersetName, builder: (column) => column);

  $$BlueprintsTableAnnotationComposer get blueprintId {
    final $$BlueprintsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableAnnotationComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableAnnotationComposer get baseExerciseId {
    final $$BaseExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BlueprintExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BlueprintExercisesTable,
    BlueprintExercise,
    $$BlueprintExercisesTableFilterComposer,
    $$BlueprintExercisesTableOrderingComposer,
    $$BlueprintExercisesTableAnnotationComposer,
    $$BlueprintExercisesTableCreateCompanionBuilder,
    $$BlueprintExercisesTableUpdateCompanionBuilder,
    (BlueprintExercise, $$BlueprintExercisesTableReferences),
    BlueprintExercise,
    PrefetchHooks Function({bool blueprintId, bool baseExerciseId})> {
  $$BlueprintExercisesTableTableManager(
      _$AppDatabase db, $BlueprintExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlueprintExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlueprintExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlueprintExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> blueprintId = const Value.absent(),
            Value<int> baseExerciseId = const Value.absent(),
            Value<String?> targetSetsReps = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> priority = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<String?> supersetName = const Value.absent(),
          }) =>
              BlueprintExercisesCompanion(
            id: id,
            blueprintId: blueprintId,
            baseExerciseId: baseExerciseId,
            targetSetsReps: targetSetsReps,
            orderIndex: orderIndex,
            priority: priority,
            supersetGroupId: supersetGroupId,
            supersetName: supersetName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int blueprintId,
            required int baseExerciseId,
            Value<String?> targetSetsReps = const Value.absent(),
            required int orderIndex,
            Value<String?> priority = const Value.absent(),
            Value<String?> supersetGroupId = const Value.absent(),
            Value<String?> supersetName = const Value.absent(),
          }) =>
              BlueprintExercisesCompanion.insert(
            id: id,
            blueprintId: blueprintId,
            baseExerciseId: baseExerciseId,
            targetSetsReps: targetSetsReps,
            orderIndex: orderIndex,
            priority: priority,
            supersetGroupId: supersetGroupId,
            supersetName: supersetName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BlueprintExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {blueprintId = false, baseExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (blueprintId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.blueprintId,
                    referencedTable: $$BlueprintExercisesTableReferences
                        ._blueprintIdTable(db),
                    referencedColumn: $$BlueprintExercisesTableReferences
                        ._blueprintIdTable(db)
                        .id,
                  ) as T;
                }
                if (baseExerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseExerciseId,
                    referencedTable: $$BlueprintExercisesTableReferences
                        ._baseExerciseIdTable(db),
                    referencedColumn: $$BlueprintExercisesTableReferences
                        ._baseExerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BlueprintExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BlueprintExercisesTable,
    BlueprintExercise,
    $$BlueprintExercisesTableFilterComposer,
    $$BlueprintExercisesTableOrderingComposer,
    $$BlueprintExercisesTableAnnotationComposer,
    $$BlueprintExercisesTableCreateCompanionBuilder,
    $$BlueprintExercisesTableUpdateCompanionBuilder,
    (BlueprintExercise, $$BlueprintExercisesTableReferences),
    BlueprintExercise,
    PrefetchHooks Function({bool blueprintId, bool baseExerciseId})>;
typedef $$TrainingPlansTableCreateCompanionBuilder = TrainingPlansCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<bool> isPinned,
  Value<DateTime> createdAt,
});
typedef $$TrainingPlansTableUpdateCompanionBuilder = TrainingPlansCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<bool> isPinned,
  Value<DateTime> createdAt,
});

final class $$TrainingPlansTableReferences
    extends BaseReferences<_$AppDatabase, $TrainingPlansTable, TrainingPlan> {
  $$TrainingPlansTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanWeeksTable, List<PlanWeek>>
      _planWeeksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.planWeeks,
          aliasName:
              $_aliasNameGenerator(db.trainingPlans.id, db.planWeeks.planId));

  $$PlanWeeksTableProcessedTableManager get planWeeksRefs {
    final manager = $$PlanWeeksTableTableManager($_db, $_db.planWeeks)
        .filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planWeeksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TrainingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> planWeeksRefs(
      Expression<bool> Function($$PlanWeeksTableFilterComposer f) f) {
    final $$PlanWeeksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planWeeks,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanWeeksTableFilterComposer(
              $db: $db,
              $table: $db.planWeeks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TrainingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TrainingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> planWeeksRefs<T extends Object>(
      Expression<T> Function($$PlanWeeksTableAnnotationComposer a) f) {
    final $$PlanWeeksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planWeeks,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanWeeksTableAnnotationComposer(
              $db: $db,
              $table: $db.planWeeks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TrainingPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrainingPlansTable,
    TrainingPlan,
    $$TrainingPlansTableFilterComposer,
    $$TrainingPlansTableOrderingComposer,
    $$TrainingPlansTableAnnotationComposer,
    $$TrainingPlansTableCreateCompanionBuilder,
    $$TrainingPlansTableUpdateCompanionBuilder,
    (TrainingPlan, $$TrainingPlansTableReferences),
    TrainingPlan,
    PrefetchHooks Function({bool planWeeksRefs})> {
  $$TrainingPlansTableTableManager(_$AppDatabase db, $TrainingPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TrainingPlansCompanion(
            id: id,
            name: name,
            notes: notes,
            isActive: isActive,
            isPinned: isPinned,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TrainingPlansCompanion.insert(
            id: id,
            name: name,
            notes: notes,
            isActive: isActive,
            isPinned: isPinned,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrainingPlansTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({planWeeksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (planWeeksRefs) db.planWeeks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planWeeksRefs)
                    await $_getPrefetchedData<TrainingPlan, $TrainingPlansTable,
                            PlanWeek>(
                        currentTable: table,
                        referencedTable: $$TrainingPlansTableReferences
                            ._planWeeksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TrainingPlansTableReferences(db, table, p0)
                                .planWeeksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.planId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TrainingPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrainingPlansTable,
    TrainingPlan,
    $$TrainingPlansTableFilterComposer,
    $$TrainingPlansTableOrderingComposer,
    $$TrainingPlansTableAnnotationComposer,
    $$TrainingPlansTableCreateCompanionBuilder,
    $$TrainingPlansTableUpdateCompanionBuilder,
    (TrainingPlan, $$TrainingPlansTableReferences),
    TrainingPlan,
    PrefetchHooks Function({bool planWeeksRefs})>;
typedef $$PlanWeeksTableCreateCompanionBuilder = PlanWeeksCompanion Function({
  Value<int> id,
  required int planId,
  required int weekNumber,
  Value<String?> purpose,
});
typedef $$PlanWeeksTableUpdateCompanionBuilder = PlanWeeksCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<int> weekNumber,
  Value<String?> purpose,
});

final class $$PlanWeeksTableReferences
    extends BaseReferences<_$AppDatabase, $PlanWeeksTable, PlanWeek> {
  $$PlanWeeksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrainingPlansTable _planIdTable(_$AppDatabase db) =>
      db.trainingPlans.createAlias(
          $_aliasNameGenerator(db.planWeeks.planId, db.trainingPlans.id));

  $$TrainingPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$TrainingPlansTableTableManager($_db, $_db.trainingPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PlanDaysTable, List<PlanDay>> _planDaysRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.planDays,
          aliasName: $_aliasNameGenerator(db.planWeeks.id, db.planDays.weekId));

  $$PlanDaysTableProcessedTableManager get planDaysRefs {
    final manager = $$PlanDaysTableTableManager($_db, $_db.planDays)
        .filter((f) => f.weekId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planDaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlanWeeksTableFilterComposer
    extends Composer<_$AppDatabase, $PlanWeeksTable> {
  $$PlanWeeksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  $$TrainingPlansTableFilterComposer get planId {
    final $$TrainingPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableFilterComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> planDaysRefs(
      Expression<bool> Function($$PlanDaysTableFilterComposer f) f) {
    final $$PlanDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.weekId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableFilterComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanWeeksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanWeeksTable> {
  $$PlanWeeksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  $$TrainingPlansTableOrderingComposer get planId {
    final $$TrainingPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableOrderingComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanWeeksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanWeeksTable> {
  $$PlanWeeksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  $$TrainingPlansTableAnnotationComposer get planId {
    final $$TrainingPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> planDaysRefs<T extends Object>(
      Expression<T> Function($$PlanDaysTableAnnotationComposer a) f) {
    final $$PlanDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.weekId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanWeeksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlanWeeksTable,
    PlanWeek,
    $$PlanWeeksTableFilterComposer,
    $$PlanWeeksTableOrderingComposer,
    $$PlanWeeksTableAnnotationComposer,
    $$PlanWeeksTableCreateCompanionBuilder,
    $$PlanWeeksTableUpdateCompanionBuilder,
    (PlanWeek, $$PlanWeeksTableReferences),
    PlanWeek,
    PrefetchHooks Function({bool planId, bool planDaysRefs})> {
  $$PlanWeeksTableTableManager(_$AppDatabase db, $PlanWeeksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanWeeksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanWeeksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanWeeksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> planId = const Value.absent(),
            Value<int> weekNumber = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
          }) =>
              PlanWeeksCompanion(
            id: id,
            planId: planId,
            weekNumber: weekNumber,
            purpose: purpose,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int planId,
            required int weekNumber,
            Value<String?> purpose = const Value.absent(),
          }) =>
              PlanWeeksCompanion.insert(
            id: id,
            planId: planId,
            weekNumber: weekNumber,
            purpose: purpose,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlanWeeksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({planId = false, planDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (planDaysRefs) db.planDays],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (planId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.planId,
                    referencedTable:
                        $$PlanWeeksTableReferences._planIdTable(db),
                    referencedColumn:
                        $$PlanWeeksTableReferences._planIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planDaysRefs)
                    await $_getPrefetchedData<PlanWeek, $PlanWeeksTable,
                            PlanDay>(
                        currentTable: table,
                        referencedTable:
                            $$PlanWeeksTableReferences._planDaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlanWeeksTableReferences(db, table, p0)
                                .planDaysRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.weekId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlanWeeksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlanWeeksTable,
    PlanWeek,
    $$PlanWeeksTableFilterComposer,
    $$PlanWeeksTableOrderingComposer,
    $$PlanWeeksTableAnnotationComposer,
    $$PlanWeeksTableCreateCompanionBuilder,
    $$PlanWeeksTableUpdateCompanionBuilder,
    (PlanWeek, $$PlanWeeksTableReferences),
    PlanWeek,
    PrefetchHooks Function({bool planId, bool planDaysRefs})>;
typedef $$PlanDaysTableCreateCompanionBuilder = PlanDaysCompanion Function({
  Value<int> id,
  required int weekId,
  required int dayNumber,
  Value<int?> blueprintId,
  Value<String?> label,
});
typedef $$PlanDaysTableUpdateCompanionBuilder = PlanDaysCompanion Function({
  Value<int> id,
  Value<int> weekId,
  Value<int> dayNumber,
  Value<int?> blueprintId,
  Value<String?> label,
});

final class $$PlanDaysTableReferences
    extends BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDay> {
  $$PlanDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlanWeeksTable _weekIdTable(_$AppDatabase db) => db.planWeeks
      .createAlias($_aliasNameGenerator(db.planDays.weekId, db.planWeeks.id));

  $$PlanWeeksTableProcessedTableManager get weekId {
    final $_column = $_itemColumn<int>('week_id')!;

    final manager = $$PlanWeeksTableTableManager($_db, $_db.planWeeks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_weekIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BlueprintsTable _blueprintIdTable(_$AppDatabase db) =>
      db.blueprints.createAlias(
          $_aliasNameGenerator(db.planDays.blueprintId, db.blueprints.id));

  $$BlueprintsTableProcessedTableManager? get blueprintId {
    final $_column = $_itemColumn<int>('blueprint_id');
    if ($_column == null) return null;
    final manager = $$BlueprintsTableTableManager($_db, $_db.blueprints)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blueprintIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PlanDayBlocksTable, List<PlanDayBlock>>
      _planDayBlocksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.planDayBlocks,
              aliasName:
                  $_aliasNameGenerator(db.planDays.id, db.planDayBlocks.dayId));

  $$PlanDayBlocksTableProcessedTableManager get planDayBlocksRefs {
    final manager = $$PlanDayBlocksTableTableManager($_db, $_db.planDayBlocks)
        .filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planDayBlocksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlanDaysTableFilterComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  $$PlanWeeksTableFilterComposer get weekId {
    final $$PlanWeeksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.weekId,
        referencedTable: $db.planWeeks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanWeeksTableFilterComposer(
              $db: $db,
              $table: $db.planWeeks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlueprintsTableFilterComposer get blueprintId {
    final $$BlueprintsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableFilterComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> planDayBlocksRefs(
      Expression<bool> Function($$PlanDayBlocksTableFilterComposer f) f) {
    final $$PlanDayBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDayBlocks,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDayBlocksTableFilterComposer(
              $db: $db,
              $table: $db.planDayBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  $$PlanWeeksTableOrderingComposer get weekId {
    final $$PlanWeeksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.weekId,
        referencedTable: $db.planWeeks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanWeeksTableOrderingComposer(
              $db: $db,
              $table: $db.planWeeks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlueprintsTableOrderingComposer get blueprintId {
    final $$BlueprintsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableOrderingComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$PlanWeeksTableAnnotationComposer get weekId {
    final $$PlanWeeksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.weekId,
        referencedTable: $db.planWeeks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanWeeksTableAnnotationComposer(
              $db: $db,
              $table: $db.planWeeks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlueprintsTableAnnotationComposer get blueprintId {
    final $$BlueprintsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blueprintId,
        referencedTable: $db.blueprints,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlueprintsTableAnnotationComposer(
              $db: $db,
              $table: $db.blueprints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> planDayBlocksRefs<T extends Object>(
      Expression<T> Function($$PlanDayBlocksTableAnnotationComposer a) f) {
    final $$PlanDayBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDayBlocks,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDayBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.planDayBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanDaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlanDaysTable,
    PlanDay,
    $$PlanDaysTableFilterComposer,
    $$PlanDaysTableOrderingComposer,
    $$PlanDaysTableAnnotationComposer,
    $$PlanDaysTableCreateCompanionBuilder,
    $$PlanDaysTableUpdateCompanionBuilder,
    (PlanDay, $$PlanDaysTableReferences),
    PlanDay,
    PrefetchHooks Function(
        {bool weekId, bool blueprintId, bool planDayBlocksRefs})> {
  $$PlanDaysTableTableManager(_$AppDatabase db, $PlanDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> weekId = const Value.absent(),
            Value<int> dayNumber = const Value.absent(),
            Value<int?> blueprintId = const Value.absent(),
            Value<String?> label = const Value.absent(),
          }) =>
              PlanDaysCompanion(
            id: id,
            weekId: weekId,
            dayNumber: dayNumber,
            blueprintId: blueprintId,
            label: label,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int weekId,
            required int dayNumber,
            Value<int?> blueprintId = const Value.absent(),
            Value<String?> label = const Value.absent(),
          }) =>
              PlanDaysCompanion.insert(
            id: id,
            weekId: weekId,
            dayNumber: dayNumber,
            blueprintId: blueprintId,
            label: label,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PlanDaysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {weekId = false,
              blueprintId = false,
              planDayBlocksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planDayBlocksRefs) db.planDayBlocks
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (weekId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.weekId,
                    referencedTable: $$PlanDaysTableReferences._weekIdTable(db),
                    referencedColumn:
                        $$PlanDaysTableReferences._weekIdTable(db).id,
                  ) as T;
                }
                if (blueprintId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.blueprintId,
                    referencedTable:
                        $$PlanDaysTableReferences._blueprintIdTable(db),
                    referencedColumn:
                        $$PlanDaysTableReferences._blueprintIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planDayBlocksRefs)
                    await $_getPrefetchedData<PlanDay, $PlanDaysTable,
                            PlanDayBlock>(
                        currentTable: table,
                        referencedTable: $$PlanDaysTableReferences
                            ._planDayBlocksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlanDaysTableReferences(db, table, p0)
                                .planDayBlocksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.dayId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlanDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlanDaysTable,
    PlanDay,
    $$PlanDaysTableFilterComposer,
    $$PlanDaysTableOrderingComposer,
    $$PlanDaysTableAnnotationComposer,
    $$PlanDaysTableCreateCompanionBuilder,
    $$PlanDaysTableUpdateCompanionBuilder,
    (PlanDay, $$PlanDaysTableReferences),
    PlanDay,
    PrefetchHooks Function(
        {bool weekId, bool blueprintId, bool planDayBlocksRefs})>;
typedef $$WorkoutBlocksTableCreateCompanionBuilder = WorkoutBlocksCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> intention,
  Value<String?> description,
  Value<DateTime> createdAt,
});
typedef $$WorkoutBlocksTableUpdateCompanionBuilder = WorkoutBlocksCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> intention,
  Value<String?> description,
  Value<DateTime> createdAt,
});

final class $$WorkoutBlocksTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutBlocksTable, WorkoutBlock> {
  $$WorkoutBlocksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanDayBlocksTable, List<PlanDayBlock>>
      _planDayBlocksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.planDayBlocks,
              aliasName: $_aliasNameGenerator(
                  db.workoutBlocks.id, db.planDayBlocks.blockId));

  $$PlanDayBlocksTableProcessedTableManager get planDayBlocksRefs {
    final manager = $$PlanDayBlocksTableTableManager($_db, $_db.planDayBlocks)
        .filter((f) => f.blockId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planDayBlocksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutBlockKnsTable, List<WorkoutBlockKn>>
      _workoutBlockKnsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutBlockKns,
              aliasName: $_aliasNameGenerator(
                  db.workoutBlocks.id, db.workoutBlockKns.blockId));

  $$WorkoutBlockKnsTableProcessedTableManager get workoutBlockKnsRefs {
    final manager =
        $$WorkoutBlockKnsTableTableManager($_db, $_db.workoutBlockKns)
            .filter((f) => f.blockId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutBlockKnsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutBlocksTable> {
  $$WorkoutBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> planDayBlocksRefs(
      Expression<bool> Function($$PlanDayBlocksTableFilterComposer f) f) {
    final $$PlanDayBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDayBlocks,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDayBlocksTableFilterComposer(
              $db: $db,
              $table: $db.planDayBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutBlockKnsRefs(
      Expression<bool> Function($$WorkoutBlockKnsTableFilterComposer f) f) {
    final $$WorkoutBlockKnsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutBlocksTable> {
  $$WorkoutBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intention => $composableBuilder(
      column: $table.intention, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutBlocksTable> {
  $$WorkoutBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> planDayBlocksRefs<T extends Object>(
      Expression<T> Function($$PlanDayBlocksTableAnnotationComposer a) f) {
    final $$PlanDayBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planDayBlocks,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDayBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.planDayBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> workoutBlockKnsRefs<T extends Object>(
      Expression<T> Function($$WorkoutBlockKnsTableAnnotationComposer a) f) {
    final $$WorkoutBlockKnsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutBlocksTable,
    WorkoutBlock,
    $$WorkoutBlocksTableFilterComposer,
    $$WorkoutBlocksTableOrderingComposer,
    $$WorkoutBlocksTableAnnotationComposer,
    $$WorkoutBlocksTableCreateCompanionBuilder,
    $$WorkoutBlocksTableUpdateCompanionBuilder,
    (WorkoutBlock, $$WorkoutBlocksTableReferences),
    WorkoutBlock,
    PrefetchHooks Function(
        {bool planDayBlocksRefs, bool workoutBlockKnsRefs})> {
  $$WorkoutBlocksTableTableManager(_$AppDatabase db, $WorkoutBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> intention = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WorkoutBlocksCompanion(
            id: id,
            name: name,
            intention: intention,
            description: description,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> intention = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WorkoutBlocksCompanion.insert(
            id: id,
            name: name,
            intention: intention,
            description: description,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutBlocksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {planDayBlocksRefs = false, workoutBlockKnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planDayBlocksRefs) db.planDayBlocks,
                if (workoutBlockKnsRefs) db.workoutBlockKns
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planDayBlocksRefs)
                    await $_getPrefetchedData<WorkoutBlock, $WorkoutBlocksTable,
                            PlanDayBlock>(
                        currentTable: table,
                        referencedTable: $$WorkoutBlocksTableReferences
                            ._planDayBlocksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutBlocksTableReferences(db, table, p0)
                                .planDayBlocksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.blockId == item.id),
                        typedResults: items),
                  if (workoutBlockKnsRefs)
                    await $_getPrefetchedData<WorkoutBlock, $WorkoutBlocksTable, WorkoutBlockKn>(
                        currentTable: table,
                        referencedTable: $$WorkoutBlocksTableReferences
                            ._workoutBlockKnsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutBlocksTableReferences(db, table, p0)
                                .workoutBlockKnsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.blockId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutBlocksTable,
    WorkoutBlock,
    $$WorkoutBlocksTableFilterComposer,
    $$WorkoutBlocksTableOrderingComposer,
    $$WorkoutBlocksTableAnnotationComposer,
    $$WorkoutBlocksTableCreateCompanionBuilder,
    $$WorkoutBlocksTableUpdateCompanionBuilder,
    (WorkoutBlock, $$WorkoutBlocksTableReferences),
    WorkoutBlock,
    PrefetchHooks Function({bool planDayBlocksRefs, bool workoutBlockKnsRefs})>;
typedef $$PlanDayBlocksTableCreateCompanionBuilder = PlanDayBlocksCompanion
    Function({
  Value<int> id,
  required int dayId,
  required int blockId,
  Value<int> orderIndex,
  Value<String?> notes,
});
typedef $$PlanDayBlocksTableUpdateCompanionBuilder = PlanDayBlocksCompanion
    Function({
  Value<int> id,
  Value<int> dayId,
  Value<int> blockId,
  Value<int> orderIndex,
  Value<String?> notes,
});

final class $$PlanDayBlocksTableReferences
    extends BaseReferences<_$AppDatabase, $PlanDayBlocksTable, PlanDayBlock> {
  $$PlanDayBlocksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PlanDaysTable _dayIdTable(_$AppDatabase db) =>
      db.planDays.createAlias(
          $_aliasNameGenerator(db.planDayBlocks.dayId, db.planDays.id));

  $$PlanDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$PlanDaysTableTableManager($_db, $_db.planDays)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WorkoutBlocksTable _blockIdTable(_$AppDatabase db) =>
      db.workoutBlocks.createAlias(
          $_aliasNameGenerator(db.planDayBlocks.blockId, db.workoutBlocks.id));

  $$WorkoutBlocksTableProcessedTableManager get blockId {
    final $_column = $_itemColumn<int>('block_id')!;

    final manager = $$WorkoutBlocksTableTableManager($_db, $_db.workoutBlocks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlanDayBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $PlanDayBlocksTable> {
  $$PlanDayBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$PlanDaysTableFilterComposer get dayId {
    final $$PlanDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableFilterComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutBlocksTableFilterComposer get blockId {
    final $$WorkoutBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanDayBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanDayBlocksTable> {
  $$PlanDayBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$PlanDaysTableOrderingComposer get dayId {
    final $$PlanDaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableOrderingComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutBlocksTableOrderingComposer get blockId {
    final $$WorkoutBlocksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableOrderingComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanDayBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanDayBlocksTable> {
  $$PlanDayBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$PlanDaysTableAnnotationComposer get dayId {
    final $$PlanDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.planDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.planDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutBlocksTableAnnotationComposer get blockId {
    final $$WorkoutBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanDayBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlanDayBlocksTable,
    PlanDayBlock,
    $$PlanDayBlocksTableFilterComposer,
    $$PlanDayBlocksTableOrderingComposer,
    $$PlanDayBlocksTableAnnotationComposer,
    $$PlanDayBlocksTableCreateCompanionBuilder,
    $$PlanDayBlocksTableUpdateCompanionBuilder,
    (PlanDayBlock, $$PlanDayBlocksTableReferences),
    PlanDayBlock,
    PrefetchHooks Function({bool dayId, bool blockId})> {
  $$PlanDayBlocksTableTableManager(_$AppDatabase db, $PlanDayBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDayBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDayBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDayBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> dayId = const Value.absent(),
            Value<int> blockId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              PlanDayBlocksCompanion(
            id: id,
            dayId: dayId,
            blockId: blockId,
            orderIndex: orderIndex,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int dayId,
            required int blockId,
            Value<int> orderIndex = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              PlanDayBlocksCompanion.insert(
            id: id,
            dayId: dayId,
            blockId: blockId,
            orderIndex: orderIndex,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlanDayBlocksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayId = false, blockId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayId,
                    referencedTable:
                        $$PlanDayBlocksTableReferences._dayIdTable(db),
                    referencedColumn:
                        $$PlanDayBlocksTableReferences._dayIdTable(db).id,
                  ) as T;
                }
                if (blockId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.blockId,
                    referencedTable:
                        $$PlanDayBlocksTableReferences._blockIdTable(db),
                    referencedColumn:
                        $$PlanDayBlocksTableReferences._blockIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlanDayBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlanDayBlocksTable,
    PlanDayBlock,
    $$PlanDayBlocksTableFilterComposer,
    $$PlanDayBlocksTableOrderingComposer,
    $$PlanDayBlocksTableAnnotationComposer,
    $$PlanDayBlocksTableCreateCompanionBuilder,
    $$PlanDayBlocksTableUpdateCompanionBuilder,
    (PlanDayBlock, $$PlanDayBlocksTableReferences),
    PlanDayBlock,
    PrefetchHooks Function({bool dayId, bool blockId})>;
typedef $$AnthropometricLogsTableCreateCompanionBuilder
    = AnthropometricLogsCompanion Function({
  Value<int> id,
  required DateTime date,
  required String label,
  required double value,
  required String unit,
  Value<bool> isFlexed,
  Value<bool> isPumped,
  Value<DateTime> createdAt,
});
typedef $$AnthropometricLogsTableUpdateCompanionBuilder
    = AnthropometricLogsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> label,
  Value<double> value,
  Value<String> unit,
  Value<bool> isFlexed,
  Value<bool> isPumped,
  Value<DateTime> createdAt,
});

class $$AnthropometricLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AnthropometricLogsTable> {
  $$AnthropometricLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFlexed => $composableBuilder(
      column: $table.isFlexed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPumped => $composableBuilder(
      column: $table.isPumped, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AnthropometricLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnthropometricLogsTable> {
  $$AnthropometricLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFlexed => $composableBuilder(
      column: $table.isFlexed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPumped => $composableBuilder(
      column: $table.isPumped, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AnthropometricLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnthropometricLogsTable> {
  $$AnthropometricLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isFlexed =>
      $composableBuilder(column: $table.isFlexed, builder: (column) => column);

  GeneratedColumn<bool> get isPumped =>
      $composableBuilder(column: $table.isPumped, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnthropometricLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnthropometricLogsTable,
    AnthropometricLog,
    $$AnthropometricLogsTableFilterComposer,
    $$AnthropometricLogsTableOrderingComposer,
    $$AnthropometricLogsTableAnnotationComposer,
    $$AnthropometricLogsTableCreateCompanionBuilder,
    $$AnthropometricLogsTableUpdateCompanionBuilder,
    (
      AnthropometricLog,
      BaseReferences<_$AppDatabase, $AnthropometricLogsTable, AnthropometricLog>
    ),
    AnthropometricLog,
    PrefetchHooks Function()> {
  $$AnthropometricLogsTableTableManager(
      _$AppDatabase db, $AnthropometricLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnthropometricLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnthropometricLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnthropometricLogsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> isFlexed = const Value.absent(),
            Value<bool> isPumped = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AnthropometricLogsCompanion(
            id: id,
            date: date,
            label: label,
            value: value,
            unit: unit,
            isFlexed: isFlexed,
            isPumped: isPumped,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String label,
            required double value,
            required String unit,
            Value<bool> isFlexed = const Value.absent(),
            Value<bool> isPumped = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AnthropometricLogsCompanion.insert(
            id: id,
            date: date,
            label: label,
            value: value,
            unit: unit,
            isFlexed: isFlexed,
            isPumped: isPumped,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnthropometricLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnthropometricLogsTable,
    AnthropometricLog,
    $$AnthropometricLogsTableFilterComposer,
    $$AnthropometricLogsTableOrderingComposer,
    $$AnthropometricLogsTableAnnotationComposer,
    $$AnthropometricLogsTableCreateCompanionBuilder,
    $$AnthropometricLogsTableUpdateCompanionBuilder,
    (
      AnthropometricLog,
      BaseReferences<_$AppDatabase, $AnthropometricLogsTable, AnthropometricLog>
    ),
    AnthropometricLog,
    PrefetchHooks Function()>;
typedef $$ThemeSettingsTableCreateCompanionBuilder = ThemeSettingsCompanion
    Function({
  required String key,
  Value<String?> colorHex,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$ThemeSettingsTableUpdateCompanionBuilder = ThemeSettingsCompanion
    Function({
  Value<String> key,
  Value<String?> colorHex,
  Value<String?> value,
  Value<int> rowid,
});

class $$ThemeSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ThemeSettingsTable> {
  $$ThemeSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$ThemeSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThemeSettingsTable> {
  $$ThemeSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$ThemeSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThemeSettingsTable> {
  $$ThemeSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ThemeSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ThemeSettingsTable,
    ThemeSetting,
    $$ThemeSettingsTableFilterComposer,
    $$ThemeSettingsTableOrderingComposer,
    $$ThemeSettingsTableAnnotationComposer,
    $$ThemeSettingsTableCreateCompanionBuilder,
    $$ThemeSettingsTableUpdateCompanionBuilder,
    (
      ThemeSetting,
      BaseReferences<_$AppDatabase, $ThemeSettingsTable, ThemeSetting>
    ),
    ThemeSetting,
    PrefetchHooks Function()> {
  $$ThemeSettingsTableTableManager(_$AppDatabase db, $ThemeSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThemeSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThemeSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThemeSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThemeSettingsCompanion(
            key: key,
            colorHex: colorHex,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> colorHex = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThemeSettingsCompanion.insert(
            key: key,
            colorHex: colorHex,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ThemeSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ThemeSettingsTable,
    ThemeSetting,
    $$ThemeSettingsTableFilterComposer,
    $$ThemeSettingsTableOrderingComposer,
    $$ThemeSettingsTableAnnotationComposer,
    $$ThemeSettingsTableCreateCompanionBuilder,
    $$ThemeSettingsTableUpdateCompanionBuilder,
    (
      ThemeSetting,
      BaseReferences<_$AppDatabase, $ThemeSettingsTable, ThemeSetting>
    ),
    ThemeSetting,
    PrefetchHooks Function()>;
typedef $$WorkoutBlockKnsTableCreateCompanionBuilder = WorkoutBlockKnsCompanion
    Function({
  Value<int> id,
  required int blockId,
  required int baseExerciseId,
  Value<int> orderIndex,
  Value<String?> utilities,
  Value<String?> batchName,
  Value<String?> metadata,
});
typedef $$WorkoutBlockKnsTableUpdateCompanionBuilder = WorkoutBlockKnsCompanion
    Function({
  Value<int> id,
  Value<int> blockId,
  Value<int> baseExerciseId,
  Value<int> orderIndex,
  Value<String?> utilities,
  Value<String?> batchName,
  Value<String?> metadata,
});

final class $$WorkoutBlockKnsTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutBlockKnsTable, WorkoutBlockKn> {
  $$WorkoutBlockKnsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutBlocksTable _blockIdTable(_$AppDatabase db) =>
      db.workoutBlocks.createAlias($_aliasNameGenerator(
          db.workoutBlockKns.blockId, db.workoutBlocks.id));

  $$WorkoutBlocksTableProcessedTableManager get blockId {
    final $_column = $_itemColumn<int>('block_id')!;

    final manager = $$WorkoutBlocksTableTableManager($_db, $_db.workoutBlocks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BaseExercisesTable _baseExerciseIdTable(_$AppDatabase db) =>
      db.baseExercises.createAlias($_aliasNameGenerator(
          db.workoutBlockKns.baseExerciseId, db.baseExercises.id));

  $$BaseExercisesTableProcessedTableManager get baseExerciseId {
    final $_column = $_itemColumn<int>('base_exercise_id')!;

    final manager = $$BaseExercisesTableTableManager($_db, $_db.baseExercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WorkoutBlockSetsTable, List<WorkoutBlockSet>>
      _workoutBlockSetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutBlockSets,
              aliasName: $_aliasNameGenerator(
                  db.workoutBlockKns.id, db.workoutBlockSets.knsId));

  $$WorkoutBlockSetsTableProcessedTableManager get workoutBlockSetsRefs {
    final manager =
        $$WorkoutBlockSetsTableTableManager($_db, $_db.workoutBlockSets)
            .filter((f) => f.knsId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutBlockSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutBlockKnsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutBlockKnsTable> {
  $$WorkoutBlockKnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get utilities => $composableBuilder(
      column: $table.utilities, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchName => $composableBuilder(
      column: $table.batchName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  $$WorkoutBlocksTableFilterComposer get blockId {
    final $$WorkoutBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableFilterComposer get baseExerciseId {
    final $$BaseExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableFilterComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> workoutBlockSetsRefs(
      Expression<bool> Function($$WorkoutBlockSetsTableFilterComposer f) f) {
    final $$WorkoutBlockSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockSets,
        getReferencedColumn: (t) => t.knsId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockSetsTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlockSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutBlockKnsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutBlockKnsTable> {
  $$WorkoutBlockKnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get utilities => $composableBuilder(
      column: $table.utilities, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchName => $composableBuilder(
      column: $table.batchName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  $$WorkoutBlocksTableOrderingComposer get blockId {
    final $$WorkoutBlocksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableOrderingComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableOrderingComposer get baseExerciseId {
    final $$BaseExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutBlockKnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutBlockKnsTable> {
  $$WorkoutBlockKnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get utilities =>
      $composableBuilder(column: $table.utilities, builder: (column) => column);

  GeneratedColumn<String> get batchName =>
      $composableBuilder(column: $table.batchName, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$WorkoutBlocksTableAnnotationComposer get blockId {
    final $$WorkoutBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.workoutBlocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BaseExercisesTableAnnotationComposer get baseExerciseId {
    final $$BaseExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.baseExerciseId,
        referencedTable: $db.baseExercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BaseExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.baseExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> workoutBlockSetsRefs<T extends Object>(
      Expression<T> Function($$WorkoutBlockSetsTableAnnotationComposer a) f) {
    final $$WorkoutBlockSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutBlockSets,
        getReferencedColumn: (t) => t.knsId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlockSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutBlockKnsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutBlockKnsTable,
    WorkoutBlockKn,
    $$WorkoutBlockKnsTableFilterComposer,
    $$WorkoutBlockKnsTableOrderingComposer,
    $$WorkoutBlockKnsTableAnnotationComposer,
    $$WorkoutBlockKnsTableCreateCompanionBuilder,
    $$WorkoutBlockKnsTableUpdateCompanionBuilder,
    (WorkoutBlockKn, $$WorkoutBlockKnsTableReferences),
    WorkoutBlockKn,
    PrefetchHooks Function(
        {bool blockId, bool baseExerciseId, bool workoutBlockSetsRefs})> {
  $$WorkoutBlockKnsTableTableManager(
      _$AppDatabase db, $WorkoutBlockKnsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutBlockKnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutBlockKnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutBlockKnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> blockId = const Value.absent(),
            Value<int> baseExerciseId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> utilities = const Value.absent(),
            Value<String?> batchName = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              WorkoutBlockKnsCompanion(
            id: id,
            blockId: blockId,
            baseExerciseId: baseExerciseId,
            orderIndex: orderIndex,
            utilities: utilities,
            batchName: batchName,
            metadata: metadata,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int blockId,
            required int baseExerciseId,
            Value<int> orderIndex = const Value.absent(),
            Value<String?> utilities = const Value.absent(),
            Value<String?> batchName = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              WorkoutBlockKnsCompanion.insert(
            id: id,
            blockId: blockId,
            baseExerciseId: baseExerciseId,
            orderIndex: orderIndex,
            utilities: utilities,
            batchName: batchName,
            metadata: metadata,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutBlockKnsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {blockId = false,
              baseExerciseId = false,
              workoutBlockSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutBlockSetsRefs) db.workoutBlockSets
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (blockId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.blockId,
                    referencedTable:
                        $$WorkoutBlockKnsTableReferences._blockIdTable(db),
                    referencedColumn:
                        $$WorkoutBlockKnsTableReferences._blockIdTable(db).id,
                  ) as T;
                }
                if (baseExerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.baseExerciseId,
                    referencedTable: $$WorkoutBlockKnsTableReferences
                        ._baseExerciseIdTable(db),
                    referencedColumn: $$WorkoutBlockKnsTableReferences
                        ._baseExerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutBlockSetsRefs)
                    await $_getPrefetchedData<WorkoutBlockKn,
                            $WorkoutBlockKnsTable, WorkoutBlockSet>(
                        currentTable: table,
                        referencedTable: $$WorkoutBlockKnsTableReferences
                            ._workoutBlockSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutBlockKnsTableReferences(db, table, p0)
                                .workoutBlockSetsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.knsId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutBlockKnsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutBlockKnsTable,
    WorkoutBlockKn,
    $$WorkoutBlockKnsTableFilterComposer,
    $$WorkoutBlockKnsTableOrderingComposer,
    $$WorkoutBlockKnsTableAnnotationComposer,
    $$WorkoutBlockKnsTableCreateCompanionBuilder,
    $$WorkoutBlockKnsTableUpdateCompanionBuilder,
    (WorkoutBlockKn, $$WorkoutBlockKnsTableReferences),
    WorkoutBlockKn,
    PrefetchHooks Function(
        {bool blockId, bool baseExerciseId, bool workoutBlockSetsRefs})>;
typedef $$WorkoutBlockSetsTableCreateCompanionBuilder
    = WorkoutBlockSetsCompanion Function({
  Value<int> id,
  required int knsId,
  required int setNumber,
  Value<double?> repsMin,
  Value<double?> repsMax,
  Value<double?> pload,
  Value<double?> rpe,
  Value<double?> rir,
  Value<String?> setIntention,
  Value<String?> side,
  Value<String?> tags,
  Value<String?> metadata,
});
typedef $$WorkoutBlockSetsTableUpdateCompanionBuilder
    = WorkoutBlockSetsCompanion Function({
  Value<int> id,
  Value<int> knsId,
  Value<int> setNumber,
  Value<double?> repsMin,
  Value<double?> repsMax,
  Value<double?> pload,
  Value<double?> rpe,
  Value<double?> rir,
  Value<String?> setIntention,
  Value<String?> side,
  Value<String?> tags,
  Value<String?> metadata,
});

final class $$WorkoutBlockSetsTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutBlockSetsTable, WorkoutBlockSet> {
  $$WorkoutBlockSetsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutBlockKnsTable _knsIdTable(_$AppDatabase db) =>
      db.workoutBlockKns.createAlias($_aliasNameGenerator(
          db.workoutBlockSets.knsId, db.workoutBlockKns.id));

  $$WorkoutBlockKnsTableProcessedTableManager get knsId {
    final $_column = $_itemColumn<int>('kns_id')!;

    final manager =
        $$WorkoutBlockKnsTableTableManager($_db, $_db.workoutBlockKns)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_knsIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutBlockSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutBlockSetsTable> {
  $$WorkoutBlockSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setNumber => $composableBuilder(
      column: $table.setNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get repsMin => $composableBuilder(
      column: $table.repsMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get repsMax => $composableBuilder(
      column: $table.repsMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pload => $composableBuilder(
      column: $table.pload, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setIntention => $composableBuilder(
      column: $table.setIntention, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get side => $composableBuilder(
      column: $table.side, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  $$WorkoutBlockKnsTableFilterComposer get knsId {
    final $$WorkoutBlockKnsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.knsId,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableFilterComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutBlockSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutBlockSetsTable> {
  $$WorkoutBlockSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setNumber => $composableBuilder(
      column: $table.setNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get repsMin => $composableBuilder(
      column: $table.repsMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get repsMax => $composableBuilder(
      column: $table.repsMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pload => $composableBuilder(
      column: $table.pload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setIntention => $composableBuilder(
      column: $table.setIntention,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get side => $composableBuilder(
      column: $table.side, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  $$WorkoutBlockKnsTableOrderingComposer get knsId {
    final $$WorkoutBlockKnsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.knsId,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutBlockSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutBlockSetsTable> {
  $$WorkoutBlockSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<double> get repsMin =>
      $composableBuilder(column: $table.repsMin, builder: (column) => column);

  GeneratedColumn<double> get repsMax =>
      $composableBuilder(column: $table.repsMax, builder: (column) => column);

  GeneratedColumn<double> get pload =>
      $composableBuilder(column: $table.pload, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get setIntention => $composableBuilder(
      column: $table.setIntention, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$WorkoutBlockKnsTableAnnotationComposer get knsId {
    final $$WorkoutBlockKnsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.knsId,
        referencedTable: $db.workoutBlockKns,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutBlockKnsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutBlockKns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutBlockSetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutBlockSetsTable,
    WorkoutBlockSet,
    $$WorkoutBlockSetsTableFilterComposer,
    $$WorkoutBlockSetsTableOrderingComposer,
    $$WorkoutBlockSetsTableAnnotationComposer,
    $$WorkoutBlockSetsTableCreateCompanionBuilder,
    $$WorkoutBlockSetsTableUpdateCompanionBuilder,
    (WorkoutBlockSet, $$WorkoutBlockSetsTableReferences),
    WorkoutBlockSet,
    PrefetchHooks Function({bool knsId})> {
  $$WorkoutBlockSetsTableTableManager(
      _$AppDatabase db, $WorkoutBlockSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutBlockSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutBlockSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutBlockSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> knsId = const Value.absent(),
            Value<int> setNumber = const Value.absent(),
            Value<double?> repsMin = const Value.absent(),
            Value<double?> repsMax = const Value.absent(),
            Value<double?> pload = const Value.absent(),
            Value<double?> rpe = const Value.absent(),
            Value<double?> rir = const Value.absent(),
            Value<String?> setIntention = const Value.absent(),
            Value<String?> side = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              WorkoutBlockSetsCompanion(
            id: id,
            knsId: knsId,
            setNumber: setNumber,
            repsMin: repsMin,
            repsMax: repsMax,
            pload: pload,
            rpe: rpe,
            rir: rir,
            setIntention: setIntention,
            side: side,
            tags: tags,
            metadata: metadata,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int knsId,
            required int setNumber,
            Value<double?> repsMin = const Value.absent(),
            Value<double?> repsMax = const Value.absent(),
            Value<double?> pload = const Value.absent(),
            Value<double?> rpe = const Value.absent(),
            Value<double?> rir = const Value.absent(),
            Value<String?> setIntention = const Value.absent(),
            Value<String?> side = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              WorkoutBlockSetsCompanion.insert(
            id: id,
            knsId: knsId,
            setNumber: setNumber,
            repsMin: repsMin,
            repsMax: repsMax,
            pload: pload,
            rpe: rpe,
            rir: rir,
            setIntention: setIntention,
            side: side,
            tags: tags,
            metadata: metadata,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutBlockSetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({knsId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (knsId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.knsId,
                    referencedTable:
                        $$WorkoutBlockSetsTableReferences._knsIdTable(db),
                    referencedColumn:
                        $$WorkoutBlockSetsTableReferences._knsIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutBlockSetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutBlockSetsTable,
    WorkoutBlockSet,
    $$WorkoutBlockSetsTableFilterComposer,
    $$WorkoutBlockSetsTableOrderingComposer,
    $$WorkoutBlockSetsTableAnnotationComposer,
    $$WorkoutBlockSetsTableCreateCompanionBuilder,
    $$WorkoutBlockSetsTableUpdateCompanionBuilder,
    (WorkoutBlockSet, $$WorkoutBlockSetsTableReferences),
    WorkoutBlockSet,
    PrefetchHooks Function({bool knsId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BaseExercisesTableTableManager get baseExercises =>
      $$BaseExercisesTableTableManager(_db, _db.baseExercises);
  $$PrefixesTableTableManager get prefixes =>
      $$PrefixesTableTableManager(_db, _db.prefixes);
  $$SuffixesTableTableManager get suffixes =>
      $$SuffixesTableTableManager(_db, _db.suffixes);
  $$ExerciseVariantsTableTableManager get exerciseVariants =>
      $$ExerciseVariantsTableTableManager(_db, _db.exerciseVariants);
  $$ProgressionEdgesTableTableManager get progressionEdges =>
      $$ProgressionEdgesTableTableManager(_db, _db.progressionEdges);
  $$WorkoutLogsTableTableManager get workoutLogs =>
      $$WorkoutLogsTableTableManager(_db, _db.workoutLogs);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$DiscomfortTagsTableTableManager get discomfortTags =>
      $$DiscomfortTagsTableTableManager(_db, _db.discomfortTags);
  $$DiscomfortLogsTableTableManager get discomfortLogs =>
      $$DiscomfortLogsTableTableManager(_db, _db.discomfortLogs);
  $$DiscomfortLogTagsTableTableManager get discomfortLogTags =>
      $$DiscomfortLogTagsTableTableManager(_db, _db.discomfortLogTags);
  $$BlueprintsTableTableManager get blueprints =>
      $$BlueprintsTableTableManager(_db, _db.blueprints);
  $$BlueprintExercisesTableTableManager get blueprintExercises =>
      $$BlueprintExercisesTableTableManager(_db, _db.blueprintExercises);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db, _db.trainingPlans);
  $$PlanWeeksTableTableManager get planWeeks =>
      $$PlanWeeksTableTableManager(_db, _db.planWeeks);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db, _db.planDays);
  $$WorkoutBlocksTableTableManager get workoutBlocks =>
      $$WorkoutBlocksTableTableManager(_db, _db.workoutBlocks);
  $$PlanDayBlocksTableTableManager get planDayBlocks =>
      $$PlanDayBlocksTableTableManager(_db, _db.planDayBlocks);
  $$AnthropometricLogsTableTableManager get anthropometricLogs =>
      $$AnthropometricLogsTableTableManager(_db, _db.anthropometricLogs);
  $$ThemeSettingsTableTableManager get themeSettings =>
      $$ThemeSettingsTableTableManager(_db, _db.themeSettings);
  $$WorkoutBlockKnsTableTableManager get workoutBlockKns =>
      $$WorkoutBlockKnsTableTableManager(_db, _db.workoutBlockKns);
  $$WorkoutBlockSetsTableTableManager get workoutBlockSets =>
      $$WorkoutBlockSetsTableTableManager(_db, _db.workoutBlockSets);
}
