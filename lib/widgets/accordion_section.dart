import 'package:flutter/material.dart';

// ==========================================
// BAGIAN 1: WIDGET ACCORDION (MENU BUKA-TUTUP)
// ==========================================
class AccordionSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color? headerColor;
  final bool isInnerAccordion;

  const AccordionSection({
    super.key,
    required this.title,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    this.headerColor,
    this.isInnerAccordion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isInnerAccordion ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // HEADER (BISA DIKLIK)
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? (headerColor ?? const Color(0xFFE8EAF6))
                    : Colors.white,
                border: isExpanded
                    ? const Border(bottom: BorderSide(color: Colors.black12, width: 1))
                    : null,
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isExpanded ? const Color(0xFF3F51B5) : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isExpanded ? const Color(0xFF3F51B5) : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // ISI (ANIMASI BUKA/TUTUP)
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: EdgeInsets.all(isInnerAccordion ? 16.0 : 8.0),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}