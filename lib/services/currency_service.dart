import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class CurrencyService {
  final String soapEndpoint = "http://api.cba.am/exchangerates.asmx";

  // Currencies to fetch
  final List<String> requiredCurrencies = ['USD', 'EUR', 'RUB', 'AMD'];

  Future<Map<String, double>> fetchCurrencyRates() async {
    const requestBody = '''
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ExchangeRatesLatest xmlns="http://www.cba.am/" />
  </soap12:Body>
</soap12:Envelope>
''';

    try {
      final response = await http.post(
        Uri.parse(soapEndpoint),
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
        },
        body: requestBody,
      );
      if (response.statusCode == 200) {
        final xmlResponse = XmlDocument.parse(response.body);
        return _filterRates(xmlResponse);
      } else {
        throw Exception('Failed to fetch rates: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Filter rates for required currencies and map them
  Map<String, double> _filterRates(XmlDocument xmlResponse) {
    final rates = <String, double>{};

    final rateElements = xmlResponse.findAllElements('ExchangeRate',
        namespace: 'http://www.cba.am/');
    for (var element in rateElements) {
      final currencyCode =
          element.getElement('ISO', namespace: 'http://www.cba.am/')?.innerText;
      final rate = element
          .getElement('Rate', namespace: 'http://www.cba.am/')
          ?.innerText;

      if (currencyCode != null &&
          rate != null &&
          requiredCurrencies.contains(currencyCode)) {
        rates[currencyCode] = double.parse(rate);
      }
    }
    return rates;
  }
}
