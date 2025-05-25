import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CurrencyConverterApp());
}

class CurrencyConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C3E),
          labelStyle: const TextStyle(color: Colors.tealAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D1FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.cyanAccent,
            elevation: 12,
          ),
        ),
      ),
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  String? fromCurrency = 'USD';
  String? toCurrency = 'PKR';
  double? convertedAmount;
  bool isLoading = false;
  String? errorMessage;

  Map<String, String> currencyNames = {};
  List<String> currencyCodes = [];

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
    _fromController.text = fromCurrency!;
    _toController.text = toCurrency!;
  }

  Future<void> fetchCurrencies() async {
    final url = Uri.parse(
      'https://v6.exchangerate-api.com/v6/083cfa4f21dfbfe9ffc31bb7/codes',
    );
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['result'] == 'success') {
        final codes = data['supported_codes'] as List;
        setState(() {
          currencyNames = {for (var code in codes) code[0]: code[1]};
          currencyCodes = currencyNames.keys.toList();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load currency list.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching currencies: $e';
      });
    }
  }

  String getFlag(String currencyCode) {
    final currencyToCountry = {
      'USD': 'US',
      'PKR': 'PK',
      'EUR': 'EU',
      'GBP': 'GB',
      'INR': 'IN',
      'JPY': 'JP',
      'AUD': 'AU',
      'CAD': 'CA',
      'CNY': 'CN',
      'SAR': 'SA',
      'AED': 'AE',
    };
    String countryCode =
        currencyToCountry[currencyCode] ?? currencyCode.substring(0, 2);
    return countryCode.toUpperCase().replaceAllMapped(
      RegExp(r'.'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  Future<void> convertCurrency() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      setState(() {
        errorMessage = "Please enter a valid amount.";
        convertedAmount = null;
      });
      return;
    }

    if (!currencyCodes.contains(fromCurrency) ||
        !currencyCodes.contains(toCurrency)) {
      setState(() {
        errorMessage = "Invalid currency selected.";
        convertedAmount = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      convertedAmount = null;
    });

    final url = Uri.parse(
      'https://v6.exchangerate-api.com/v6/083cfa4f21dfbfe9ffc31bb7/pair/$fromCurrency/$toCurrency',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['result'] == 'success') {
        final rate = data['conversion_rate'];
        setState(() {
          convertedAmount = double.parse(amountText) * rate;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch exchange rate.';
          convertedAmount = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        convertedAmount = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget currencyField({
    required TextEditingController controller,
    required String label,
    required void Function(String) onSelected,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return currencyCodes.where((String code) {
          return code.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ) ||
              currencyNames[code]!.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        });
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        controller.text = textEditingController.text;
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(
              Icons.monetization_on,
              color: Colors.tealAccent,
            ),
          ),
        );
      },
      onSelected: (String selection) {
        controller.text = selection;
        onSelected(selection);
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final String option = options.elementAt(index);
                return ListTile(
                  leading: Text(getFlag(option)),
                  title: Text('$option - ${currencyNames[option]}'),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            '💱 Currency Converter',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            currencyCodes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      currencyField(
                        controller: _fromController,
                        label: 'From Currency',
                        onSelected:
                            (value) => setState(() {
                              fromCurrency = value;
                            }),
                      ),
                      const SizedBox(height: 16),
                      currencyField(
                        controller: _toController,
                        label: 'To Currency',
                        onSelected:
                            (value) => setState(() {
                              toCurrency = value;
                            }),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: convertCurrency,
                        child: const Text(' Convert Now'),
                      ),
                      const SizedBox(height: 24),
                      if (!isKeyboardVisible)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C3E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.tealAccent,
                              width: 1.5,
                            ),
                          ),
                          child:
                              isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : errorMessage != null
                                  ? Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                  : convertedAmount != null
                                  ? Text(
                                    '$convertedAmount $toCurrency',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                  : const Text(
                                    'Conversion result will appear here',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
