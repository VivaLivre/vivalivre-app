import 'package:flutter/material.dart';

class AddBathroomPage extends StatefulWidget {
  const AddBathroomPage({super.key});

  @override
  State<AddBathroomPage> createState() => _AddBathroomPageState();
}

class _AddBathroomPageState extends State<AddBathroomPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  bool _accessible = false;
  bool _changingTable = false;
  bool _free = true;
  
  int _cleanliness = 0;
  int _accessibility = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Navigate back to map
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Banheiro enviado para aprovação!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827), size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Adicionar Banheiro',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Mini Map
                  Container(
                    height: 160,
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Grid Pattern (Simulated)
                        Positioned.fill(
                          child: CustomPaint(painter: _GridPainter()),
                        ),
                        // Map Pin
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2), width: 4),
                                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.3), shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                            ),
                            child: const Text(
                              '📍 Localização selecionada',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Input
                        const Text('Nome do Local', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Ex: Shopping, Restaurante, Posto...',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Photo Button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid), // In Flutter, dashed is usually done via package or custom painter. We use solid for now.
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt_rounded, color: Color(0xFF9CA3AF), size: 20),
                                SizedBox(width: 8),
                                Text('Adicionar Fotos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Toggles
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _ToggleRow(label: '♿ Acessível para PCD', value: _accessible, onChanged: (v) => setState(() => _accessible = v)),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              _ToggleRow(label: '🍼 Possui Trocador', value: _changingTable, onChanged: (v) => setState(() => _changingTable = v)),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              _ToggleRow(label: '🆓 Gratuito', value: _free, onChanged: (v) => setState(() => _free = v)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Star Ratings
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StarRating(label: '🧹 Limpeza', value: _cleanliness, onChanged: (v) => setState(() => _cleanliness = v)),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 16),
                              _StarRating(label: '♿ Acessibilidade', value: _accessibility, onChanged: (v) => setState(() => _accessibility = v)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Comment
                        RichText(
                          text: const TextSpan(
                            text: 'Comentário ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                            children: [TextSpan(text: '(opcional)', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal))],
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Dicas, observações sobre o local...',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Submit
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text('Enviar para Aprovação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF111827))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2563EB),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: star <= value ? const Color(0xFFFBBF24) : const Color(0xFFD1D5DB),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final boldPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.2)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), boldPaint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), boldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
