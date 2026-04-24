import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CartaoDIIPage extends StatefulWidget {
  const CartaoDIIPage({super.key});

  @override
  State<CartaoDIIPage> createState() => _CartaoDIIPageState();
}

class _CartaoDIIPageState extends State<CartaoDIIPage> {
  File? _laudoFile;
  bool _isPdf = false;
  bool _copied = false;

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Nome pendente';
  }

  // -- Upload do laudo --
  Future<void> _takeLaudoPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _laudoFile = File(picked.path);
        _isPdf = false;
      });
    }
  }

  Future<void> _pickLaudoFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _laudoFile = File(picked.path);
        _isPdf = false;
      });
    }
  }

  Future<void> _pickLaudoPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _laudoFile = File(result.files.single.path!);
        _isPdf = true;
      });
    }
  }

  // -- Abrir laudo em tela cheia --
  void _openLaudoFullScreen() {
    if (_laudoFile == null) return;

    if (_isPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visualizador de PDF em breve. Use "Compartilhar" para abrir.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LaudoFullScreenViewer(file: _laudoFile!),
      ),
    );
  }

  // -- Compartilhar o laudo --
  Future<void> _handleShare() async {
    if (_laudoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anexe o seu laudo primeiro.')),
      );
      return;
    }

    setState(() => _copied = true);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Laudo Medico - $_userName\nCartao DII Digital - VivaLivre',
        files: [XFile(_laudoFile!.path)],
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  // -- Gerar e compartilhar PDF com o laudo --
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Se o laudo for imagem, embute no PDF
    pw.Widget? laudoWidget;
    if (_laudoFile != null && !_isPdf) {
      final imageBytes = await _laudoFile!.readAsBytes();
      final image = pw.MemoryImage(imageBytes);
      laudoWidget = pw.Image(image, fit: pw.BoxFit.contain);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Cartao DII Digital - VivaLivre',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('Comprovante de Prioridade',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text('Titular: $_userName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Text('Laudo Medico:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              if (laudoWidget != null)
                pw.Expanded(child: laudoWidget)
              else
                pw.Text('Laudo nao disponivel em formato de imagem.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('Lei 15.138/2025 - Politica Nacional de Assistencia a DII',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laudo_DII_$_userName.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // -- Header --
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIVALIVRE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Meu Cartao DII',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  if (_laudoFile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text('Laudo anexado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // -- Conteudo --
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // -- Cartao de Identidade Visual --
                  _buildIdentityCard(),
                  const SizedBox(height: 24),

                  // -- Secao do Laudo --
                  _buildLaudoSection(),
                  const SizedBox(height: 24),

                  // -- Botoes de Acao --
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleShare,
                          icon: Icon(_copied ? Icons.check_rounded : Icons.share_rounded, size: 18),
                          label: Text(_copied ? 'Enviado!' : 'Compartilhar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _copied ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generatePdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('Baixar PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // -- Info Legal --
                  _buildLegalInfo(),
                  const SizedBox(height: 24),

                  // Seguranca
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dados protegidos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                              SizedBox(height: 2),
                              Text('Seu laudo fica apenas no seu dispositivo', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Cartao de identidade visual (nome + QR) --
  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF1E3A8A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CARTAO DE PRIORIDADE - DII',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nome do titular
          const Text('TITULAR', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(
            _userName,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),

          // Rodape legal
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: Color(0xFFFDE047), size: 12),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lei 15.138/2025 - Politica Nacional de Assistencia a DII',
                  style: TextStyle(color: Colors.white60, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- Secao do Laudo --
  Widget _buildLaudoSection() {
    if (_laudoFile == null) {
      // Sem laudo: mostrar opcoes de upload
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.description_outlined, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anexe o seu laudo medico',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'O laudo fica salvo apenas no seu celular e serve para comprovar a sua condicao.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takeLaudoPhoto,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Tirar Foto'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLaudoFromGallery,
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Galeria'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLaudoPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Com laudo: mostrar preview e botao de abrir
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Preview do laudo
          if (!_isPdf)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.file(
                _laudoFile!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 40, color: Color(0xFFEF4444)),
                    SizedBox(height: 8),
                    Text('Documento PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),

          // Botoes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Botao ABRIR LAUDO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openLaudoFullScreen,
                    icon: const Icon(Icons.open_in_full_rounded, size: 18),
                    label: const Text('Abrir Laudo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Botao trocar laudo
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _laudoFile = null),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Trocar Laudo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Info Legal --
  Widget _buildLegalInfo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seus direitos como portador de DII', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F2937))),
                    Text('Lei 15.138/2025 + legislacoes estaduais', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  'Lei 15.138/2025: Politica Nacional de Assistencia a DII',
                  'Diversos estados possuem leis de acesso prioritario a sanitarios',
                  'Em caso de recusa, registre Boletim de Ocorrencia',
                  'Apresente este cartao junto com laudo medico atualizado',
                ].map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Visualizador de laudo em tela cheia com zoom --
class _LaudoFullScreenViewer extends StatelessWidget {
  final File file;
  const _LaudoFullScreenViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Laudo Medico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
