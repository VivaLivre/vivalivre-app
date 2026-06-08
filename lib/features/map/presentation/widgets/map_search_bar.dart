import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:viva_livre_app/core/presentation/widgets/custom_text_field.dart';

const _kBlue = Color(0xFF2563EB);
const _kSlate = Color(0xFF94A3B8);
const _kSurface = Color(0xFFF1F5F9);

class MapSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final int openCount;
  final bool isLocating;
  final LatLng currentPosition;
  final VoidCallback onLocate;
  final Function(LatLng) onSuggestionSelected;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.openCount,
    required this.isLocating,
    required this.currentPosition,
    required this.onLocate,
    required this.onSuggestionSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _stripStreetPrefix(String query) {
    final pattern = RegExp(
      r'^(rua|r\.?|avenida|av\.?|ave\.?|travessa|tv\.?|trav\.?|alameda|al\.?|alam\.?|rodovia|rod\.?|praça|pça\.?|prc\.?|prac\.?|beco|bc\.?|estrada|est\.?|estr\.?|viaduto|vd\.?|viad\.?)\s+',
      caseSensitive: false,
    );
    return query.replaceFirst(pattern, '');
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isSearching = true);
    }

    try {
      final lat = widget.currentPosition.latitude;
      final lon = widget.currentPosition.longitude;
      
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&lat=$lat&lon=$lon');

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'VivaLivreApp/1.0 (suporte@vivalivre.com)'},
      );

      if (response.statusCode == 200 && mounted) {
        List<dynamic> data = json.decode(response.body);

        // Se a busca principal retornar vazia e a query contiver um prefixo de rua, tenta novamente sem o prefixo
        if (data.isEmpty) {
          final strippedQuery = _stripStreetPrefix(query.trim());
          if (strippedQuery != query.trim()) {
            final fallbackUri = Uri.parse(
                'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(strippedQuery)}&format=json&limit=5&lat=$lat&lon=$lon');
            final fallbackResponse = await http.get(
              fallbackUri,
              headers: {'User-Agent': 'VivaLivreApp/1.0 (suporte@vivalivre.com)'},
            );
            if (fallbackResponse.statusCode == 200 && mounted) {
              data = json.decode(fallbackResponse.body);
            }
          }
        }

        // Ordenar as sugestões pela distância até a localização atual do usuário
        if (data.isNotEmpty) {
          const distanceCalc = Distance();
          data.sort((a, b) {
            final latA = double.tryParse(a['lat']?.toString() ?? '') ?? 0.0;
            final lonA = double.tryParse(a['lon']?.toString() ?? '') ?? 0.0;
            final latB = double.tryParse(b['lat']?.toString() ?? '') ?? 0.0;
            final lonB = double.tryParse(b['lon']?.toString() ?? '') ?? 0.0;

            final distA = distanceCalc.as(
              LengthUnit.Meter,
              widget.currentPosition,
              LatLng(latA, lonA),
            );

            final distB = distanceCalc.as(
              LengthUnit.Meter,
              widget.currentPosition,
              LatLng(latB, lonB),
            );

            return distA.compareTo(distB);
          });
        }

        setState(() {
          _suggestions = data;
          _isSearching = false;
        });
      } else if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _fetchSuggestions(query);
    });
  }

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
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
                                controller: widget.searchController,
                                hintText: 'Buscar locais ou banheiros...',
                                textInputAction: TextInputAction.search,
                                onChanged: _onSearchChanged,
                                onFieldSubmitted: (val) {
                                  if (_suggestions.isNotEmpty) {
                                    final lat = double.parse(_suggestions[0]['lat'].toString());
                                    final lon = double.parse(_suggestions[0]['lon'].toString());
                                    widget.onSuggestionSelected(LatLng(lat, lon));
                                    setState(() { _suggestions = []; });
                                  }
                                },
                              ),
                            ),
                          ),
                          if (widget.searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                widget.searchController.clear();
                                _onSearchChanged('');
                                FocusScope.of(context).unfocus();
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
                  GestureDetector(
                    onTap: widget.onLocate,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.isLocating
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
              
              if (_isSearching || _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CustomLoadingIndicator(color: _kBlue, strokeWidth: 2),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: _kSlate),
                              title: Text(
                                suggestion['display_name'] ?? '',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                final lat = double.parse(suggestion['lat'].toString());
                                final lon = double.parse(suggestion['lon'].toString());
                                widget.onSuggestionSelected(LatLng(lat, lon));
                                setState(() {
                                  _suggestions = [];
                                  widget.searchController.text = suggestion['display_name'] ?? '';
                                });
                              },
                            );
                          },
                        ),
                ),
                
              if (!_isSearching && _suggestions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        'VivaLivre',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: _kSlate, fontSize: 13),
                      ),
                      Text(
                        '${widget.openCount} banheiros próximos',
                        style: const TextStyle(color: _kSlate, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
