enum SubscriptionFrequency { weekly, monthly }

class SubscriptionModel {
  final String id;
  final String hotelId;
  final String hotelName;
  final SubscriptionFrequency frequency;
  final List<int> selectedDays; // 1 = Monday .. 7 = Sunday; empty = all days
  final String timeSlot; // e.g. "08:00 - 10:00"

  const SubscriptionModel({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    required this.frequency,
    required this.selectedDays,
    required this.timeSlot,
  });

  String get frequencyLabel =>
      frequency == SubscriptionFrequency.weekly ? 'Weekly' : 'Monthly';

  String get daysLabel {
    if (frequency == SubscriptionFrequency.monthly && selectedDays.isEmpty) {
      return 'Once per month';
    }
    if (selectedDays.isEmpty) return 'Every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return selectedDays.map((d) => names[d - 1]).join(', ');
  }
}
