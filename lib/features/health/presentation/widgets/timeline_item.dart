import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';
import 'package:viva_livre_app/core/widgets/confirm_delete_dialog.dart';
import 'entry_detail_dialog.dart';

class TimelineItem extends StatelessWidget {
  final HealthEntry entry;
  final bool isLast;

  const TimelineItem({required this.entry, required this.isLast});

  static Color _severityColor(String severity) {
    return switch (severity) {
      'Grave' => const Color(0xFFEF4444),
      'Observação' || 'Moderada' => const Color(0xFFF59E0B),
      _ => const Color(0xFF10B981),
    };
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // ── Ver Detalhes ──
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Ver Detalhes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Horário, sintomas e notas completas'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => EntryDetailDialog(entry: entry),
                  );
                },
              ),
              const Divider(height: 1),
              // ── Eliminar ──
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF2F2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: const Text(
                  'Eliminar Registo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: const Text('Esta acção não pode ser desfeita'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => const ConfirmDeleteDialog(
                      title: 'Eliminar registo?',
                      content: 'Este registo será removido permanentemente do seu histórico clínico.',
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    context.read<HealthBloc>().add(
                      DeleteHealthEntry(
                        docId: entry.id,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ), // fecha Container
      ), // fecha SafeArea
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(entry.timestamp);
    final isBathroom = entry.type == 'banheiro';
    final dotColor = _severityColor(entry.severity);
    final title = entry.symptoms.isNotEmpty
        ? entry.symptoms.join(', ')
        : 'Registo';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da hora
          SizedBox(
            width: 50,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Ponto + linha — cor pela severidade
          Column(
            children: [
              const SizedBox(height: 18),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.35),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.transparent),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    dotColor.withValues(alpha: 0.08),
                    Theme.of(context).cardColor,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dotColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isBathroom ? Icons.wc_rounded : Icons.healing_rounded,
                      color: dotColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.severity != 'Leve')
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry.severity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: dotColor,
                          ),
                        ),
                      ),
                    // ── 3 pontos ──
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Opções',
                      onPressed: () => _showMenu(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EntryDetailDialog — Detalhes completos de um registo clínico (Dialog)
// ═════════════════════════════════════════════════════════════════════════════
