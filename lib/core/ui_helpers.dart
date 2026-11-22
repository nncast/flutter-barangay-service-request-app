import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Shared colors and formatting so every screen shows statuses the same way.

// Palette taken from the logo: burnt orange (BARANGAY) for actions, navy
// (SERVICE REQUEST) for dark surfaces, cream (outline) for highlights, and the
// logo's dark brown for text. Warm canvas, white cards, no pure black.
const Color kWhite = Color(0xFFFFFFFF);
const Color kInk = Color(0xFF46291D);
const Color kNavy = Color(0xFF2D4E8E);
const Color kCanvas = Color(0xFFF7F2EC);
const Color kOrange = Color(0xFFBE5633);
const Color kOrangeDark = Color(0xFFA4482A);
const Color kYellow = Color(0xFFFDE898);
const Color kYellowSoft = Color(0xFFFFF5D6);
const Color kGray = Color(0xFF6F625A);
const Color kLine = Color(0xFFEAE3DC);
const Color kSurface = Color(0xFFF5EFE9);
const Color kRed = Color(0xFFDC2626);
const Color kMuted = Color(0xFFA0958D);

/// Field outlines: at least 3:1 against white and the canvas (WCAG 1.4.11).
const Color kOutline = Color(0xFF8A7E76);

/// WCAG contrast ratio, from 1 to 21. Text needs 4.5 (AA), icons and outlines 3.
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance() + 0.05, y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}

/// Dark brown or white, whichever has the higher contrast on [color].
Color onColor(Color color) => contrastRatio(color, kInk) >= contrastRatio(color, kWhite) ? kInk : kWhite;

/// A soft tint for backgrounds, a dark shade of the same hue for text on it
/// (at least 4.5:1), and a stronger color for dots.
typedef Tone = ({Color bg, Color fg, Color dot});

const Tone kAmber = (bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E), dot: Color(0xFFF59E0B));
const Tone kBlue = (bg: Color(0xFFDFE6F3), fg: kNavy, dot: Color(0xFF4A6FB5));
const Tone kTeal = (bg: Color(0xFFCCFBF1), fg: Color(0xFF115E59), dot: Color(0xFF14B8A6));
const Tone kOrangeTone = (bg: Color(0xFFF9E2D6), fg: Color(0xFF8A3A1F), dot: kOrange);
const Tone kGreen = (bg: Color(0xFFDCFCE7), fg: Color(0xFF166534), dot: Color(0xFF22C55E));
const Tone kRedTone = (bg: Color(0xFFFEE2E2), fg: Color(0xFF991B1B), dot: Color(0xFFEF4444));
const Tone kViolet = (bg: Color(0xFFEDE9FE), fg: Color(0xFF5B21B6), dot: Color(0xFF8B5CF6));
const Tone kGrayTone = (bg: Color(0xFFEFE9E3), fg: Color(0xFF4F443D), dot: kMuted);

/// Tone for a color that comes from the API, such as a category's.
Tone toneOf(Color color) => (
      bg: Color.alphaBlend(color.withValues(alpha: 0.14), kWhite),
      fg: Color.lerp(color, kInk, 0.3)!,
      dot: color,
    );

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

/// Waiting is amber, being looked at blue, approved teal, in progress orange,
/// done green, rejected red, cancelled gray.
Tone statusTone(String? status) => switch (status) {
      'pending' => kAmber,
      'in_review' => kBlue,
      'approved' => kTeal,
      'processing' => kOrangeTone,
      'completed' => kGreen,
      'rejected' => kRedTone,
      _ => kGrayTone,
    };

/// Dot color for a status.
Color statusColor(String? status) => statusTone(status).dot;

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

Tone priorityTone(String priority) => switch (priority) {
      'high' => kOrangeTone,
      'urgent' => kRedTone,
      _ => kGrayTone,
    };

Tone roleTone(String role) => switch (role) {
      'admin' => kViolet,
      'staff' => kBlue,
      'resident' => kAmber,
      _ => kGrayTone,
    };

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

/// Parses "#RRGGBB"; anything else gives [fallback].
Color colorFromHex(String? hex, {Color fallback = kOrange}) {
  final value = (hex ?? '').replaceFirst('#', '');
  final parsed = value.length == 6 ? int.tryParse(value, radix: 16) : null;
  return parsed == null ? fallback : Color(0xFF000000 | parsed);
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

/// Small pill label in a soft tint, e.g. a status, priority or role.
class Tag extends StatelessWidget {
  final String label;
  final Tone tone;
  final double fontSize;

  const Tag({super.key, required this.label, required this.tone, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: tone.fg),
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
  Widget build(BuildContext context) => Tag(label: statusLabel(status), tone: statusTone(status), fontSize: fontSize);
}

/// Initials in a filled circle.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color color;
  final Color? textColor;

  const InitialsAvatar({super.key, required this.initials, this.radius = 24, this.color = kYellow, this.textColor});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w800, color: textColor ?? onColor(color)),
      ),
    );
  }
}

/// Icon in a filled circle, used for info rows and list items.
class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color? iconColor;

  const IconBox(this.icon, {super.key, this.size = 36, this.color = kSurface, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: iconColor ?? onColor(color)),
    );
  }
}

/// Round filled icon button, e.g. the orange "+" or the white bell.
class RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  const RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = kOrange,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onColor(color),
        fixedSize: Size.square(size),
      ),
    );
  }
}

/// Section heading on a page, with an optional "View all".
class SectionTitle extends StatelessWidget {
  final String text;
  final VoidCallback? onViewAll;

  const SectionTitle(this.text, {super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kInk, letterSpacing: -0.5),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(foregroundColor: kGray),
            child: const Text('View all'),
          ),
      ],
    );
  }
}

/// Avatar, today's date and an optional bell, above a big two-tone greeting:
/// "Good evening, Maria / Here's your request update."
class Greeting extends StatelessWidget {
  final String name;
  final String initials;
  final String lead;
  final String accent;
  final VoidCallback? onBell;
  final int unread;

  const Greeting({
    super.key,
    required this.name,
    required this.initials,
    required this.lead,
    required this.accent,
    this.onBell,
    this.unread = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final partOfDay = now.hour < 12 ? 'morning' : (now.hour < 18 ? 'afternoon' : 'evening');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsAvatar(initials: initials, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGray),
              ),
            ),
            if (onBell != null)
              Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: RoundButton(
                  icon: Icons.notifications_none,
                  tooltip: 'Alerts',
                  onPressed: onBell,
                  color: kWhite,
                  size: 48,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Good $partOfDay, ${name.trim().split(' ').first}\n'),
              TextSpan(text: lead, style: const TextStyle(color: kGray)),
              TextSpan(text: accent, style: const TextStyle(color: kOrangeDark)),
            ],
          ),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: kInk,
            height: 1.12,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

/// Burnt-orange summary card: a small tag, a big white title, and a white pill
/// row with a one-line summary and a navy action button.
class HeroCard extends StatelessWidget {
  final String tag;
  final IconData icon;
  final String title;
  final String summary;
  final String actionLabel;
  final VoidCallback onAction;

  const HeroCard({
    super.key,
    required this.tag,
    required this.icon,
    required this.title,
    required this.summary,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const ShapeDecoration(color: kYellowSoft, shape: StadiumBorder()),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              const Spacer(),
              ExcludeSemantics(child: Icon(icon, size: 44, color: kWhite)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kWhite,
              height: 1.08,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const ShapeDecoration(color: kWhite, shape: StadiumBorder()),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
                  ),
                ),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNavy,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef NavItem = ({IconData icon, String label, int badge});

/// Floating navy pill navigation; the selected item sits in a white pill.
/// [action] (e.g. a round "+" button) goes to its right.
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavItem> items;
  final Widget? action;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(5),
                decoration: const ShapeDecoration(color: kNavy, shape: StadiumBorder()),
                child: Row(
                  children: [
                    for (final (i, item) in items.indexed)
                      Expanded(
                        child: _NavButton(item: item, selected: i == selectedIndex, onTap: () => onSelected(i)),
                      ),
                  ],
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 10), action!],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? kNavy : kWhite.withValues(alpha: 0.75);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? kWhite : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                child: Icon(item.icon, size: 22, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
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
        Center(child: IconBox(icon, size: 64, color: kWhite)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk),
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
