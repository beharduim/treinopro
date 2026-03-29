import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class BottomNavigationItem {
  final String? icon; // path to svg asset
  final IconData? iconData; // optional material icon
  final String label;
  final VoidCallback onTap;

  const BottomNavigationItem({
    this.icon,
    this.iconData,
    required this.label,
    required this.onTap,
  });
}

class CustomBottomNavigationBar extends StatelessWidget {
  final List<BottomNavigationItem> items;
  final int currentIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(
          top: BorderSide(color: Color(0xFFA6A6A6), width: 0.24),
          left: BorderSide(color: Color(0xFFA6A6A6), width: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, -1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              MainAxisAlignment.center, // Centraliza verticalmente
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
              ), // Ainda mais próximo do topo
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: item.onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: item.iconData != null
                                  ? Icon(
                                      item.iconData,
                                      size: 24,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF2D3748),
                                    )
                                  : SvgPicture.asset(
                                      item.icon!,
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        isActive
                                            ? Colors.white
                                            : const Color(0xFF2D3748),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : const Color(0xFF2D3748),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
