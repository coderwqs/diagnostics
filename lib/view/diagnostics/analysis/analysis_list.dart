import 'package:diagnosis/model/device.dart';
import 'package:diagnosis/model/features.dart';
import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/devices.dart';
import 'package:diagnosis/service/features.dart';
import 'package:diagnosis/service/history.dart';
import 'package:diagnosis/utils/algorithm_utils.dart';
import 'package:diagnosis/view/diagnostics/components/spectrum_chart.dart';
import 'package:diagnosis/view/diagnostics/components/waveform_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  final HistoryService _historyService = HistoryService();
  final FeaturesService _featuresService = FeaturesService();
  final DeviceService _deviceService = DeviceService();

  Device? _selectedDevice;
  List<Device> _devices = [];
  List<Feature> _features = [];
  List<double> _waveform = [];
  List<double> _spectrum = [];
  Feature? _selectedFeature;

  late ScrollController _scrollController;
  bool _isLoading = false;
  int _deviceCurrentPage = 0;
  final int _itemsPerPage = 5;

  late ScrollController _historyScrollController;
  bool _isFeatureLoading = false;
  int _featureCurrentPage = 0;
  final int _featureItemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _historyScrollController = ScrollController();
    _historyScrollController.addListener(_historyScrollListener);

    _loadMoreDevices();
  }

  void _addDevices(List<Device> devices) {
    setState(() {
      _devices.addAll(devices);
      _deviceCurrentPage++;
      _isLoading = false;

      _onDevicesChanged();
    });
  }

  void _updateSelectedDevice(Device device) {
    setState(() {
      _selectedDevice = device;
    });
    _onSelectedDeviceChanged();
  }

  void _onDevicesChanged() {
    if (_deviceCurrentPage == 1 &&
        _devices.isNotEmpty &&
        _selectedDevice == null) {
      _updateSelectedDevice(_devices.first);
      _loadMoreFeatureData(_devices.first);
    }
  }

  void _onSelectedDeviceChanged() {
    _features = [];
    _waveform = [];
    _spectrum = [];
    _selectedFeature = null;
    _featureCurrentPage = 0;

    _loadMoreFeatureData(_selectedDevice!);
  }

  void _addFeatures(List<Feature> features) {
    setState(() {
      _features.addAll(features);
      _featureCurrentPage++;
      _isFeatureLoading = false;
    });

    _onFeaturesChanged();
  }

  void _updateSelectedFeature(Feature feature) {
    setState(() {
      _selectedFeature = feature;
    });
    _onSelectedFeatureChanged();
  }

  void _onFeaturesChanged() {
    if (_featureCurrentPage == 1 && _selectedFeature == null && _features.isNotEmpty) {
      _updateSelectedFeature(_features.first);
    }
  }

  void _onSelectedFeatureChanged() {
    _waveform = [];
    _spectrum = [];
    _fetchDataDetails(_selectedFeature!, shouldRebuildHistory: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _loadMoreDevices();
    }
  }

  void _historyScrollListener() {
    if (_historyScrollController.position.pixels ==
            _historyScrollController.position.maxScrollExtent &&
        !_isFeatureLoading) {
      _loadMoreFeatureData(_selectedDevice!);
    }
  }

  Future<void> _loadMoreDevices() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final devices = await _deviceService.getAllDevices(
      _deviceCurrentPage + 1,
      _itemsPerPage,
    );

    _addDevices(devices);
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isLoading = true;
    });

    final d = await _deviceService.getAllDevices(0, _itemsPerPage);

    setState(() {
      _devices = d;
      _deviceCurrentPage = 0;
      _isLoading = false;
    });
  }

  Future<List<ExtendedHistory>> fetchHistoryData({
    int page = 1,
    int limit = 10,
  }) async {
    return _historyService.getAllHistories(page, limit);
  }

  Future<void> _loadMoreFeatureData(Device device) async {
    if (_isFeatureLoading || _selectedDevice == null) return;

    setState(() {
      _isFeatureLoading = true;
    });

    final fs = await _featuresService.getAllFeatures(
      page: _featureCurrentPage + 1,
      limit: _featureItemsPerPage,
      deviceId: device.id,
    );

    _addFeatures(fs);
  }

  Future<void> _refreshFeatures() async {
    setState(() {
      _isFeatureLoading = true;
    });

    final fs = await _featuresService.getAllFeatures(
      page: 1,
      limit: _featureItemsPerPage,
      deviceId: _selectedDevice?.id,
    );

    setState(() {
      _features = fs;
      _featureCurrentPage = 0;
      _isFeatureLoading = false;
    });
  }

  Future<void> _fetchDataDetails(
    Feature feature, {
    bool shouldRebuildHistory = true,
  }) async {
    if (!shouldRebuildHistory) {
      setState(() {
        _waveform = [];
        _spectrum = [];
      });
    } else {
      setState(() {
        _isLoading = true;
        _waveform = [];
        _spectrum = [];
      });
    }

    final history = await _historyService.getHistory(
      _selectedDevice!.id,
      _selectedFeature!.dataTime!,
    );

    if (history != null) {
      _waveform = history.data;

      AlgorithmUtils algorithm = AlgorithmUtils();
      _spectrum = algorithm.calculateSpectrum(history.data);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设备数据分析'), elevation: 0),
      body: Container(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeftPanel(colorScheme, textTheme),
            Expanded(child: _buildRightPanel(colorScheme, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildDeviceListSection(colorScheme, textTheme),
          const SizedBox(height: 8),
          Expanded(child: _buildDataHistorySection(colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.device_hub, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '设备列表',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          SizedBox(
            height: 220,
            child: RefreshIndicator(
              onRefresh: _refreshDevices,
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _devices.length + (_isLoading ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= _devices.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final device = _devices[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _updateSelectedDevice(device),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: device == _selectedDevice
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: device == _selectedDevice
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sensors,
                              color: device == _selectedDevice
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                device.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: device == _selectedDevice
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                ),
                              ),
                            ),
                            if (device == _selectedDevice)
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHistorySection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '数据记录',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '时间',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RMS值',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFeatures,
              child: _features.isEmpty && !_isFeatureLoading
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _historyScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _features.length + (_isFeatureLoading ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index >= _features.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        final feature = _features[index];
                        print("+++++++++++++++++++++++++++++++ ${feature.dataTime}");

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _updateSelectedFeature(feature),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedFeature?.id == feature.id
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      )
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: _selectedFeature == feature
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      DateFormat('HH:mm:ss').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                          feature.dataTime!,
                                        ),
                                      ),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      feature.rms.toStringAsFixed(2),
                                      textAlign: TextAlign.right,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: _getValueColor(feature.rms),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfoCard(colorScheme, textTheme),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _buildChartCard(
                colorScheme: colorScheme,
                textTheme: textTheme,
                title: '时域波形',
                icon: Icons.show_chart,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _buildWaveformChart(colorScheme, textTheme),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _buildChartCard(
                colorScheme: colorScheme,
                textTheme: textTheme,
                title: '频域频谱',
                icon: Icons.bar_chart,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _buildSpectrumChart(colorScheme, textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    if (_selectedDevice == null || _selectedFeature == null) {
      return const SizedBox();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDevice!.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最新记录: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_selectedFeature!.dataTime!))}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _selectedFeature!.rms.toStringAsFixed(2),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(_selectedFeature!.rms),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedFeature!.rms),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusLabel(_selectedFeature!.rms),
                    style: textTheme.labelSmall?.copyWith(
                      color: _getStatusTextColor(_selectedFeature!.rms),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformChart(ColorScheme colorScheme, TextTheme textTheme) {
    if (_selectedDevice == null || _selectedFeature == null) {
      return Center(
        child: Text(
          '无波形数据',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return WaveformChart(
      dataTime: _selectedFeature!.dataTime!,
      waveform: _waveform,
      colorScheme: colorScheme,
      isShowDot: false,
    );
  }

  Widget _buildSpectrumChart(ColorScheme colorScheme, TextTheme textTheme) {
    if (_selectedDevice == null || _selectedFeature == null) {
      return Center(
        child: Text(
          '无频谱数据',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return SpectrumChart(
      spectrum: _spectrum,
      colorScheme: colorScheme,
      isShowDot: false,
    );
  }

  String _getStatusLabel(double value) {
    if (value > 8) return '危险';
    if (value > 5) return '警告';
    return '正常';
  }

  Color _getStatusColor(double value) {
    if (value > 8) return Colors.red.withValues(alpha: 0.2);
    if (value > 5) return Colors.orange.withValues(alpha: 0.2);
    return Colors.green.withValues(alpha: 0.2);
  }

  Color _getStatusTextColor(double value) {
    if (value > 8) return Colors.red;
    if (value > 5) return Colors.orange;
    return Colors.green;
  }

  Color _getValueColor(double value) {
    if (value > 8) return Colors.red;
    if (value > 5) return Colors.orange;
    return Colors.green;
  }
}
