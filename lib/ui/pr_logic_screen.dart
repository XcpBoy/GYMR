import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'styles.dart';
import 'main_scaffold.dart';
import '../localization/strings.dart';

class PRLogicScreen extends ConsumerWidget {
  const PRLogicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? 'en';
    return MainScaffold(
      title: 'PR.LOGIC_PROTOCOL',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, lang),
            const SizedBox(height: 24),
            _buildFormulaCard(
              context,
              'ESTIMATED_1RM (EPLEY)',
              'w * (1 + (r / 30))',
              tr(lang, 'The core metric for theoretical peak performance. Normalizes different rep ranges to a single intensity value.'),
              LabColors.workoutRed,
            ),
            const SizedBox(height: 16),
            _buildFormulaCard(
              context,
              'EFFICIENCY_COEFFICIENT',
              'e1RM / (rest_factor + 1.0)',
              tr(lang, 'Measures performance relative to rest intervals. Higher density workouts yield higher efficiency.'),
              LabColors.primary,
            ),
            const SizedBox(height: 16),
            _buildFormulaCard(
              context,
              'RECOVERY_ADJUSTED_e1RM',
              'e1RM * (1.1 - (0.1 * RPE))',
              tr(lang, 'Adjusts potential based on perceived exertion. A lower RPE for the same load indicates higher systemic recovery.'),
              LabColors.accent,
            ),
            const SizedBox(height: 16),
            _buildFormulaCard(
              context,
              'TECHNICAL_e1RM',
              'e1RM * technique_score',
              tr(lang, 'Multiplies theoretical peak by form quality (0.5x to 1.5x). Prioritizes execution over raw weight.'),
              LabColors.inventoryOrange,
            ),
            const SizedBox(height: 32),
            Text(
              'TROPHY_ACTIVATION_CRITERIA',
              style: LabStyles.mono(context, fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildCriteriaItem(context, 'LOAD_PR', tr(lang, 'Current Load > Historical Max Load')),
            _buildCriteriaItem(context, 'REPS_PR', tr(lang, 'Reps > Historical Max Reps for the specific Load')),
            _buildCriteriaItem(context, 'STRENGTH_PR', tr(lang, 'Current e1RM > Historical Max e1RM')),
            _buildCriteriaItem(context, 'DENSITY_PR', tr(lang, 'Current Efficiency > Historical Max Efficiency')),
            _buildCriteriaItem(context, 'RECOVERY_PR', tr(lang, 'Current Recovery-Adj > Historical Max Recovery-Adj')),
            const SizedBox(height: 40),
            _buildSystemNote(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LabColors.surfaceContainerLow,
        border: Border.all(color: LabColors.primary.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: LabColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'SYSTEM_LOGIC_OVERRIDE',
                style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr(lang, 'The Rainbow Trophy activates when ANY quality surpasses historical data. The Red Trophy (SMART PR) only activates for the absolute best theoretical performance of the session.'),
            style: LabStyles.mono(context, fontSize: 9, color: Colors.grey[400]!),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard(BuildContext context, String title, String formula, String desc, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LabStyles.mono(context, fontSize: 8, color: color)),
          const SizedBox(height: 8),
          Text(
            formula,
            style: LabStyles.headline(context, color: Colors.white).copyWith(fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: LabStyles.mono(context, fontSize: 9, color: Colors.grey[500]!),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(BuildContext context, String label, String criteria) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>', style: LabStyles.mono(context, color: LabColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LabStyles.mono(context, fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                Text(criteria, style: LabStyles.mono(context, fontSize: 8, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemNote(BuildContext context) {
    return Center(
      child: Text(
        'V13_PERFORMANCE_ALGORITHM_STABLE',
        style: LabStyles.mono(context, fontSize: 8, color: Colors.grey[800]!),
      ),
    );
  }
}

