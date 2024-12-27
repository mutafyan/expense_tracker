class Currency {
  Currency(this.symbol, this.name, this.iso);
  final String symbol;
  final String name;
  final String iso;

  String get displaySymbol => symbol;
  String get displayName => name;
  String get displayISO => iso;
}
