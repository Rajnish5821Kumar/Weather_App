import 'package:flutter/material.dart';
import '../services/weather_services.dart';
import '../models/weather_model.dart';

class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

  @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    final WeatherService _weatherService = WeatherService();
    final TextEditingController _cityController = TextEditingController();

    bool _isLoading = false;
    Weather? _weather;
    String _cityName = 'London';

    void _getWeather() async {
      final query = _cityController.text.trim();
      if (query.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a city name')),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        final weather = await _weatherService.fetchWeather(query);
        if (mounted) {
          setState(() {
            _weather = weather;
            _cityName = query;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching weather data')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    @override
    void dispose() {
      _cityController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    final description = _weather?.description?.toLowerCase() ?? '';
    final Gradient backgroundGradient = description.contains('rain')
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey, Colors.blueGrey],
          )
        : description.contains('clear')
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orangeAccent, Colors.blueAccent],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey, Colors.lightBlueAccent],
              );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Weather App',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Search row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: TextField(
                            controller: _cityController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _getWeather(),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: 'Enter city name',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _getWeather,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Get Weather'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Weather display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _weather != null
                            ? _buildWeatherCard()
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final desc = _weather!.description.toLowerCase();
    IconData icon = Icons.help_outline;
    if (desc.contains('cloud')) icon = Icons.cloud;
    if (desc.contains('rain') || desc.contains('drizzle')) icon = Icons.grain;
    if (desc.contains('clear') || desc.contains('sun')) icon = Icons.wb_sunny;

    return Center(
      child: Card(
        color: Colors.white.withOpacity(0.14),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                _weather!.cityName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '${_weather!.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                _weather!.description,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 14),

              // Divider
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              // Bottom info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoColumn(Icons.opacity, '${_weather!.humidity}%','Humidity'),
                  _infoColumn(Icons.air, '${_weather!.windSpeed.toStringAsFixed(1)} m/s','Wind'),
                  _infoColumn(Icons.wb_sunny, _formatTime(_weather!.sunrise),'Sunrise'),
                  _infoColumn(Icons.nights_stay, _formatTime(_weather!.sunset),'Sunset'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatTime(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true).toLocal();
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}