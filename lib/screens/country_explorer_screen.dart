import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dravik/models/country.dart';
import 'package:dravik/services/country_service.dart';
import 'package:dravik/screens/map_screen.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class CountryExplorerScreen extends StatefulWidget {
  final String? countryCode;

  const CountryExplorerScreen({super.key, this.countryCode});

  @override
  State<CountryExplorerScreen> createState() => _CountryExplorerScreenState();
}

class _CountryExplorerScreenState extends State<CountryExplorerScreen>
    with SingleTickerProviderStateMixin {
  final CountryService _countryService = CountryService();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();

  Country? _selectedCountry;
  List<Country> _allCountries = [];
  List<Country> _filteredCountries = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Currency converter
  final TextEditingController _amountController = TextEditingController();
  double _convertedAmount = 0;
  bool _toLocal = true; // USD to local or vice versa

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCountries();
    _initTts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoading = true);
    _allCountries = await _countryService.getAllCountries();
    _filteredCountries = _allCountries;

    if (widget.countryCode != null) {
      _selectedCountry =
          await _countryService.getCountryByCode(widget.countryCode!);
    } else if (_allCountries.isNotEmpty) {
      _selectedCountry = _allCountries.first;
    }

    setState(() => _isLoading = false);
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _allCountries;
      } else {
        _filteredCountries = _allCountries
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _speakPhrase(String text) async {
    await _tts.speak(text);
  }

  void _convertCurrency() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_selectedCountry == null) return;

    setState(() {
      if (_toLocal) {
        // USD to local
        _convertedAmount = amount * _selectedCountry!.exchangeRateToUSD;
      } else {
        // Local to USD
        _convertedAmount = amount / _selectedCountry!.exchangeRateToUSD;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Country Explorer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCountry != null
            ? '${_selectedCountry!.flagEmoji} ${_selectedCountry!.name}'
            : 'Country Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'View on Map',
            onPressed: _selectedCountry == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          initialQuery: _selectedCountry!.name,
                        ),
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Map (Offline)',
            onPressed: _selectedCountry == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          initialQuery: _selectedCountry!.name,
                          autoDownloadRegion: true,
                        ),
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showCountryPicker(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.translate), text: 'Phrasebook'),
            Tab(icon: Icon(Icons.attach_money), text: 'Currency'),
            Tab(icon: Icon(Icons.phone), text: 'Emergency'),
            Tab(icon: Icon(Icons.place), text: 'Highlights'),
          ],
        ),
      ),
      body: _selectedCountry == null
          ? const Center(child: Text('No country selected'))
          : Column(
              children: [
                const EditionBannerForScreen(
                  screen: EditionScreen.countryExplorer,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(isDark),
                      _buildPhrasebookTab(isDark),
                      _buildCurrencyTab(isDark),
                      _buildEmergencyTab(isDark),
                      _buildHighlightsTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Languages',
            _selectedCountry!.languages.join(', '),
            Icons.language,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Currency',
            '${_selectedCountry!.currency} (${_selectedCountry!.currencySymbol})',
            Icons.money,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Timezone',
            _selectedCountry!.timezone,
            Icons.access_time,
            isDark,
          ),
          const SizedBox(height: 20),
          Text(
            'Visa Requirements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedCountry!.visaRequirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        req,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Text(
            'Customs & Etiquette',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedCountry!.customs.map((custom) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading:
                      Text(custom.icon, style: const TextStyle(fontSize: 32)),
                  title: Text(custom.title),
                  subtitle: Text(custom.description),
                  dense: false,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPhrasebookTab(bool isDark) {
    final categories =
        _selectedCountry!.phrasebook.map((p) => p.category).toSet().toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final phrases = _selectedCountry!.phrasebook
            .where((p) => p.category == category)
            .toList();

        return ExpansionTile(
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: phrases
              .map((phrase) => ListTile(
                    title: Text(phrase.english),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          phrase.translation,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phrase.pronunciation,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _speakPhrase(phrase.english),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: phrase.translation));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCurrencyTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exchange Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 USD = ${_selectedCountry!.exchangeRateToUSD.toStringAsFixed(2)} ${_selectedCountry!.currencySymbol}',
                    style: const TextStyle(fontSize: 20, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Currency Converter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                      _toLocal ? Icons.check_circle : Icons.circle_outlined),
                  label: const Text('USD → Local'),
                  onPressed: () => setState(() => _toLocal = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _toLocal ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                      !_toLocal ? Icons.check_circle : Icons.circle_outlined),
                  label: const Text('Local → USD'),
                  onPressed: () => setState(() => _toLocal = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_toLocal ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: _convertCurrency,
              ),
            ),
            onChanged: (_) => _convertCurrency(),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Converted Amount',
                    style: TextStyle(
                      color: isDark ? Colors.black87 : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _convertedAmount.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    _toLocal ? _selectedCountry!.currencySymbol : 'USD',
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '⚠️ Tap to call emergency services',
          style: TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ..._selectedCountry!.emergencyContacts.map((contact) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getEmergencyColor(contact.type),
                  child: Icon(
                    _getEmergencyIcon(contact.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(contact.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(contact.number, style: const TextStyle(fontSize: 18)),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _makeCall(contact.number),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHighlightsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedCountry!.highlights.length,
      itemBuilder: (context, index) {
        final highlight = _selectedCountry!.highlights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (highlight.imageUrl.isNotEmpty)
                Image.network(
                  highlight.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 80),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(highlight.category),
                      backgroundColor: Colors.green.shade100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      highlight.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      highlight.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, bool isDark) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search countries',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterCountries,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  return ListTile(
                    leading: Text(country.flagEmoji,
                        style: const TextStyle(fontSize: 32)),
                    title: Text(country.name),
                    subtitle: Text(country.code),
                    onTap: () {
                      setState(() => _selectedCountry = country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmergencyColor(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Colors.blue;
      case 'medical':
        return Colors.red;
      case 'fire':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getEmergencyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.phone;
    }
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot dial $number')),
        );
      }
    }
  }
}
