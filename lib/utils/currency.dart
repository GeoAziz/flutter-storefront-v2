String currencySymbol(String? currency) {
  final c = (currency ?? 'USD').toUpperCase();
  switch (c) {
    case 'USD':
      return r'$';
    case 'KES':
      return 'KSh';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'NGN':
      return '₦';
    case 'ZAR':
      return 'R';
    default:
      return '$c ';
  }
}

String formatPrice(num price, {String? currency}) {
  final sym = currencySymbol(currency);
  // Use fixed 2-decimal places for consistency.
  final formatted = (price is int) ? price.toString() : price.toStringAsFixed(2);
  // For symbol like 'KSh' we include a space.
  if (sym.trim().length > 1 && !sym.startsWith(r'$')) {
    return '$sym$formatted';
  }
  return '$sym$formatted';
}
