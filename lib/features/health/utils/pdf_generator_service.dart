import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';
import 'health_data_aggregator.dart';

class PdfGeneratorService {
  /// Gera o PDF com base nos dados e abre a preview nativa de partilha/impressão
  static Future<void> generateAndPreviewPdf({
    required List<HealthRecord> records,
    required String filter,
    required String userName,
    required String clinicalCondition,
  }) async {
    final pdf = pw.Document();

    // Tentar carregar fontes para suportar caracteres acentuados (PT-PT) e emoji se possível
    // O Printing suporta fallback fonts. Vamos usar as built-in ou carregar do assets se necessário
    // Por enquanto, as fontes standard do PDF funcionam para PT-PT (Helvetica).

    final now = DateTime.now();
    DateTime start;
    switch (filter) {
      case 'Hoje':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Últimos 7 dias':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        break;
      case 'Mês':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    final dateStr = '${DateFormat('dd MMM yyyy').format(start)} a ${DateFormat('dd MMM yyyy').format(now)}';
    final daysCount = filter == 'Hoje' ? 1 : now.difference(start).inDays;

    final bathroomCount = HealthDataAggregator.countBathroomTrips(records);
    final frequentSymptomData = HealthDataAggregator.getMostFrequentSymptom(records);
    final frequentSymptom = frequentSymptomData?.key ?? 'Nenhum';
    final symptomDistribution = HealthDataAggregator.getSymptomDistribution(records);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(userName, clinicalCondition, dateStr, daysCount),
            pw.SizedBox(height: 24),
            _buildSummary(bathroomCount, frequentSymptom, daysCount),
            pw.SizedBox(height: 24),
            if (symptomDistribution.isNotEmpty) _buildSymptomsTable(symptomDistribution, records),
            pw.SizedBox(height: 24),
            _buildTimeOfDayChart(records),
            pw.SizedBox(height: 24),
            _buildNotes(records),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10.0),
            child: pw.Text(
              'Gerado via VivaLivre App | Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
      ),
    );

    // Abre o ecrã nativo (iOS/Android/Web) com a pré-visualização e opções (Print, Share, Save)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Saude_VivaLivre_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildHeader(String userName, String clinicalCondition, String dateStr, int daysCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'RELATÓRIO CLÍNICO',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2563EB')),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Paciente: $userName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 4),
              pw.Text('Condição: $clinicalCondition', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text('Período: $dateStr ($daysCount dias)', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(int bathroomCount, String frequentSymptom, int daysCount) {
    final dailyAvg = daysCount > 0 ? (bathroomCount / daysCount).toStringAsFixed(1) : bathroomCount.toString();

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Idas ao Banheiro', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text(bathroomCount.toString(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Média: $dailyAvg por dia', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sintoma Frequente', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text(frequentSymptom, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('No período selecionado', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSymptomsTable(Map<String, double> symptomDistribution, List<HealthRecord> records) {
    // Calcular as ocorrências exatas para colocar na tabela
    final counts = <String, int>{};
    for (var r in records) {
      final parts = r.title.split(', ');
      for (var p in parts) {
        final symptom = p.trim();
        if (symptom.isEmpty || symptom.toLowerCase() == 'ida ao banheiro') continue;
        counts[symptom] = (counts[symptom] ?? 0) + 1;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Distribuição de Sintomas', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0')),
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Sintoma', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Ocorrências', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Frequência Relativa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            // Linhas
            ...symptomDistribution.entries.map((entry) {
              final count = counts[entry.key] ?? 0;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(count.toString())),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${entry.value.toStringAsFixed(1)}%')),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(List<HealthRecord> records) {
    // Para as notas, precisaríamos do campo `notes` do HealthEntry original.
    // Como o Dashboard usa HealthRecord que perdeu as notas, teremos de adicionar 'notes' ao HealthRecord.
    // Para simplificar, mostramos apenas a cronologia dos últimos eventos se não tiver notas.
    
    // Vamos mostrar um cronograma simples
    final timeline = records.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final limit = timeline.length > 20 ? 20 : timeline.length; // Mostrar máximo 20 eventos
    
    if (timeline.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Cronograma de Eventos (Últimos registos)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: timeline.take(limit).map((r) {
            final timeStr = DateFormat('dd/MM/yy HH:mm').format(r.timestamp);
            final typeStr = r.type == 'banheiro' ? '[Banheiro]' : '[Sintomas]';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 100, child: pw.Text(timeStr, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10))),
                  pw.Text(typeStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: r.type == 'banheiro' ? PdfColor.fromHex('#2563EB') : PdfColor.fromHex('#F59E0B'))),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(r.title, style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildTimeOfDayChart(List<HealthRecord> records) {
    int morning = 0;
    int afternoon = 0;
    int night = 0;

    for (var r in records) {
      final hour = r.timestamp.hour;
      if (hour >= 6 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 18) {
        afternoon++;
      } else {
        night++;
      }
    }

    final total = morning + afternoon + night;
    if (total == 0) return pw.SizedBox();

    final mPct = morning / total;
    final aPct = afternoon / total;
    final nPct = night / total;

    // A simple horizontal stacked bar
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Período Crítico do Dia', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Distribuição de todos os eventos (Idas ao banheiro + Sintomas)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Container(
          height: 24,
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: pw.Row(
              children: [
                if (morning > 0)
                  pw.Expanded(
                    flex: (mPct * 100).toInt(),
                    child: pw.Container(color: PdfColor.fromHex('#FCD34D')), // Amarelo
                  ),
                if (afternoon > 0)
                  pw.Expanded(
                    flex: (aPct * 100).toInt(),
                    child: pw.Container(color: PdfColor.fromHex('#F59E0B')), // Laranja
                  ),
                if (night > 0)
                  pw.Expanded(
                    flex: (nPct * 100).toInt(),
                    child: pw.Container(color: PdfColor.fromHex('#475569')), // Cinza Escuro
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _legendItem('Manhã (06h-12h)', '${(mPct * 100).toStringAsFixed(0)}%', PdfColor.fromHex('#FCD34D')),
            _legendItem('Tarde (12h-18h)', '${(aPct * 100).toStringAsFixed(0)}%', PdfColor.fromHex('#F59E0B')),
            _legendItem('Noite (18h-06h)', '${(nPct * 100).toStringAsFixed(0)}%', PdfColor.fromHex('#475569')),
          ],
        ),
      ],
    );
  }

  static pw.Widget _legendItem(String label, String pct, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 6),
        pw.Text('$label: $pct', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
