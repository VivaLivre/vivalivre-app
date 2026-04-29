import 'package:flutter/material.dart';

import 'package:viva_livre_app/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';

const _kBlue = Color(0xFF2563EB);
const _kSlate = Color(0xFF94A3B8);
const _kSurface = Color(0xFFF1F5F9);

class MapSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final int openCount;
  final bool isLocating;
  final VoidCallback onLocate;
  final ValueChanged<String> onSearch;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.openCount,
    required this.isLocating,
    required this.onLocate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Campo de busca
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kSurface),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded, color: _kSlate, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: const InputDecorationTheme(
                                  hintStyle: TextStyle(color: _kSlate, fontSize: 15),
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              child: CustomTextField(
                                controller: searchController,
                                hintText: 'Buscar banheiros...',
                                textInputAction: TextInputAction.search,
                                onFieldSubmitted: onSearch,
                              ),
                            ),
                          ),
                          if (searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                searchController.clear();
                                onSearch('');
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Icon(Icons.close_rounded, color: _kSlate, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botão "Localizar com GPS real"
                  GestureDetector(
                    onTap: onLocate,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kSurface),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CustomLoadingIndicator(
                                strokeWidth: 2,
                                color: _kBlue,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: _kBlue,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Brand chip
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wc, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VivaLivre',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    ' · ',
                    style: TextStyle(color: _kSlate, fontSize: 13),
                  ),
                  Text(
                    '$openCount banheiros próximos',
                    style: const TextStyle(color: _kSlate, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
