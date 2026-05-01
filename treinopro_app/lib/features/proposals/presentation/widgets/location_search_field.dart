import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/training_location.dart';

/// Campo de busca de locais com sugestões
class LocationSearchField extends StatefulWidget {
  final String? initialValue;
  final List<TrainingLocation> suggestions;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TrainingLocation> onLocationSelected;
  final String placeholder;

  const LocationSearchField({
    super.key,
    this.initialValue,
    required this.suggestions,
    this.isLoading = false,
    required this.onSearchChanged,
    required this.onLocationSelected,
    this.placeholder = 'Pesquise academia ou local que deseja',
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && widget.suggestions.isNotEmpty;
    });
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged(value);
    setState(() {
      _showSuggestions = value.isNotEmpty || _focusNode.hasFocus;
    });
  }

  void _onLocationSelected(TrainingLocation location) {
    _controller.text = location.name;
    widget.onLocationSelected(location);
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de busca
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.secondaryDark, width: 1),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: AppTextStyles.small.copyWith(color: AppColors.secondaryDark),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 22,
              ),
              suffixIcon: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      color: AppColors.secondaryDark,
                      size: 24,
                    ),
            ),
          ),
        ),

        // Lista de sugestões
        if (_showSuggestions && widget.suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            // Altura calculada para mostrar exatamente 3 itens
            // Título (16 + 16 + 8 + 12) = 52px
            // 3 itens × 72px (altura de cada item) = 216px
            // Total: 268px
            height: 268,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título das sugestões
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _controller.text.isEmpty
                        ? 'Locais mais escolhidos'
                        : 'Locais disponíveis',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryDark.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Lista scrollável de locais (altura restante)
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.suggestions.length,
                    itemBuilder: (context, index) {
                      final location = widget.suggestions[index];
                      return _SuggestionItem(
                        location: location,
                        onTap: () => _onLocationSelected(location),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Item individual da lista de sugestões
class _SuggestionItem extends StatelessWidget {
  final TrainingLocation location;
  final VoidCallback onTap;

  const _SuggestionItem({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone do local
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Informações do local
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.address,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryDark.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Ícone de seleção
            const Icon(
              Icons.chevron_right,
              color: AppColors.secondaryDark,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
