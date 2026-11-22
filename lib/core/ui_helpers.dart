import 'package:flutter/material.dart';

// Shared colors and formatting so every screen shows statuses the same way.

// Flat palette: black and white, orange for actions, yellow for highlights.
const Color kWhite = Color(0xFFFFFFFF);
const Color kBlack = Color(0xFF111111);
const Color kOrange = Color(0xFFF97316);
const Color kYellow = Color(0xFFFFC72C);
const Color kYellowSoft = Color(0xFFFFF4CC);
const Color kGray = Color(0xFF6B6B6B);
const Color kLine = Color(0xFFE6E6E6);
const Color kSurface = Color(0xFFF5F5F5);
const Color kRed = Color(0xFFDC2626);
const Color kMuted = Color(0xFF9E9E9E);

/// Black or white, whichever has the higher contrast on [color]. Above a
/// luminance of 0.179 black wins (Flutter's brightness estimate would put
/// white on the orange, at 2.8:1).
Color onColor(Color color) => color.computeLuminance() > 0.179 ? kBlack : kWhite;

/// Request statuses in workflow order. `cancelled` is set by residents only.
const List<String> kRequestStatuses = [
  'pending',
  'in_review',
  'approved',
  'processing',
  'completed',
  'rejected',
  'cancelled',
];

/// Statuses staff can set from the app.
const List<String> kStaffSettableStatuses = [
  'pending',
  'in_review',
  'approved',
  'processing',
  'completed',
  'rejected',
];

String statusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'in_review':
      return 'In Review';
    case 'approved':
      return 'Approved';
    case 'processing':
      return 'Processing';
    case 'completed':
      return 'Completed';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
      return 'Cancelled';
    case null:
    case '':
      return 'Unknown';
    default:
      return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }
}

/// Yellow → orange → black as a request moves along; red and gray when it stops.
Color statusColor(String? status) {
  switch (status) {
    case 'pending':
      return kYellow;
    case 'in_review':
      return const Color(0xFFFFA41B);
    case 'approved':
      return kOrange;
    case 'processing':
      return const Color(0xFFC2410C);
    case 'completed':
      return kBlack;
    case 'rejected':
      return kRed;
    default:
      return kMuted;
  }
}

IconData statusIcon(String? status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_empty;
    case 'in_review':
      return Icons.manage_search;
    case 'approved':
      return Icons.thumb_up_alt_outlined;
    case 'processing':
      return Icons.autorenew;
    case 'completed':
      return Icons.check_circle_outline;
    case 'rejected':
      return Icons.block;
    case 'cancelled':
      return Icons.cancel_outlined;
    default:
      return Icons.assignment;
  }
}

String priorityLabel(String priority) =>
    priority.isEmpty ? 'Normal' : priority[0].toUpperCase() + priority.substring(1);

Color priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return kOrange;
    case 'urgent':
      return kRed;
    default:
      return kLine;
  }
}

/// Maps the icon names stored on categories (Heroicons-style) to Material icons.
IconData categoryIcon(String? name) {
  switch (name) {
    case 'document_text':
      return Icons.description_outlined;
    case 'shield_check':
      return Icons.verified_user_outlined;
    case 'briefcase':
      return Icons.business_center_outlined;
    case 'exclamation_circle':
      return Icons.report_problem_outlined;
    case 'document_report':
      return Icons.assignment_late_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'heart':
      return Icons.volunteer_activism_outlined;
    case 'dots_horizontal':
      return Icons.more_horiz;
    default:
      return Icons.category_outlined;
  }
}

DateTime? _parseLocal(String value) => DateTime.tryParse(value)?.toLocal();

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// e.g. "Oct 4, 2026 · 2:05 PM", in the device's time zone.
String formatDateTime(String value) {
  final dt = _parseLocal(value);
  if (dt == null) return value;
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour < 12 ? 'AM' : 'PM';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$minute $suffix';
}

/// e.g. "Just now", "5m ago", "3h ago", "2d ago", then a date.
String formatRelative(String value) {
  final dt = _parseLocal(value);
  if (dt == null) return value;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Small filled label, e.g. a status or a priority.
class Tag extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const Tag({super.key, required this.label, required this.color, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: onColor(color)),
      ),
    );
  }
}

/// Request status label used everywhere.
class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusChip({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) =>
      Tag(label: statusLabel(status), color: statusColor(status), fontSize: fontSize);
}

/// Initials in a filled circle.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color color;

  const InitialsAvatar({super.key, required this.initials, this.radius = 24, this.color = kYellow});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w800, color: onColor(color)),
      ),
    );
  }
}

/// Icon in a filled circle, used for info rows and list items.
class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const IconBox(this.icon, {super.key, this.size = 36, this.color = kSurface});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: onColor(color)),
    );
  }
}

/// Section heading on a page.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kBlack, letterSpacing: -0.6),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Big "Hello, Maria!" heading with the user's initials, atop both dashboards.
class Greeting extends StatelessWidget {
  final String name;
  final String initials;

  const Greeting({super.key, required this.name, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Hello,\n${name.trim().split(' ').first}!',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: kBlack,
              height: 1.05,
              letterSpacing: -1.2,
            ),
          ),
        ),
        InitialsAvatar(initials: initials, radius: 26),
      ],
    );
  }
}

/// Round orange arrow button.
class ArrowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const ArrowButton({super.key, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.arrow_forward),
      style: IconButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: kBlack,
        fixedSize: const Size(52, 52),
      ),
    );
  }
}

/// Black card with a row of counts, a big title and an arrow; the whole card is tappable.
class HeroCard extends StatelessWidget {
  final List<(String, int)> stats;
  final String title;
  final VoidCallback onTap;

  const HeroCard({super.key, required this.stats, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBlack,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (final (i, (label, value)) in stats.indexed) ...[
                      if (i > 0) VerticalDivider(width: 24, color: kWhite.withValues(alpha: 0.2)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: kWhite.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$value',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: kYellow),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                        height: 1.05,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ArrowButton(onPressed: onTap, tooltip: title.replaceAll('\n', ' ')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation with a hairline on top instead of a shadow.
class FlatNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<Widget> destinations;

  const FlatNavBar({super.key, required this.selectedIndex, required this.onSelected, required this.destinations});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: kLine))),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: destinations,
      ),
    );
  }
}

/// Centered icon and message for empty or failed lists. Scrollable, so
/// pull-to-refresh still works.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.message, this.hint, this.action});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Center(child: IconBox(icon, size: 64)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBlack),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, textAlign: TextAlign.center, style: const TextStyle(color: kGray)),
        ],
        if (action != null) Center(child: action),
      ],
    );
  }
}

/// Small color dot next to a status name.
class Dot extends StatelessWidget {
  final Color color;
  final double size;

  const Dot(this.color, {super.key, this.size = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
