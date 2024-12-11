class Currency {
  Currency(this.symbol, this.name);
  final String symbol;
  final String name;

  String get displaySymbol => symbol;
  String get displayName => name;
}
