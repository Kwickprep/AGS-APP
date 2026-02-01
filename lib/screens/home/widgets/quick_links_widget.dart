import 'package:flutter/material.dart';

class QuickLinksWidget extends StatelessWidget {
  const QuickLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final links = [
      _QuickLink('Messages', Icons.chat_outlined, const Color(0xFF25D366), '/messages'),
      _QuickLink('Products', Icons.search_outlined, const Color(0xFF3B82F6), '/products'),
      _QuickLink('Activity', Icons.add_circle_outline, const Color(0xFF6366F1), '/activities/create'),
      _QuickLink('Inquiry', Icons.note_add_outlined, const Color(0xFFF59E0B), '/inquiries/create'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: links.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final link = links[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(link.route),
              child: Container(
                width: 76,
                decoration: BoxDecoration(
                  color: link.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: link.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(link.icon, size: 26, color: link.color),
                    const SizedBox(height: 6),
                    Text(
                      link.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: link.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickLink {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  _QuickLink(this.label, this.icon, this.color, this.route);
}
