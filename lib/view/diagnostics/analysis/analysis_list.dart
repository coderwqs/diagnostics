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

class TabItem {
  final String name;
  final IconData icon;

  const TabItem(this.name, this.icon);
}

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage>
    with SingleTickerProviderStateMixin {
  final HistoryService _historyService = HistoryService();
  final FeaturesService _featuresService = FeaturesService();
  final DeviceService _deviceService = DeviceService();
  final AlgorithmUtils _alg = AlgorithmUtils();

  List<Device> _devices = [];
  List<Feature> _features = [];

  Device? _selectedDevice;
  Feature? _selectedFeature;

  late ScrollController _scrollController;
  bool _isDeviceLoading = false;
  int _deviceCurrentPage = 0;
  final int _itemsPerPage = 5;

  late ScrollController _historyScrollController;
  bool _isFeatureLoading = false;
  int _featureCurrentPage = 0;
  final int _featureItemsPerPage = 10;

  late TabController _tabController;
  int _tabIndex = 0;
  final List<TabItem> algorithms = [
    TabItem("频谱分析", Icons.analytics),
    TabItem("包络分析", Icons.signal_wifi_4_bar),
    TabItem("小波分析", Icons.waves),
    TabItem("倒谱", Icons.graphic_eq),
    TabItem("阶次分析", Icons.filter_4),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _historyScrollController = ScrollController();
    _historyScrollController.addListener(_historyScrollListener);

    _tabController = TabController(length: algorithms.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
        });
      }
    });

    _loadMoreDevices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _historyScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<double> _calculateAlgorithm(int index, List<double> signal) {
    List<double> result = [];
    switch (index) {
      case 0:
        result = _alg.calculateSpectrum(signal);
        break;
      case 1:
        result = _alg.calculateEnvelope(signal);
        break;
      case 2:
        result = _alg.waveletTransform(signal);
        break;
      case 3:
        result = _alg.cepstrum(signal);
        break;
      case 4:
        result = _alg.calculateOrder(signal, 2);
        break;
    }

    return result;
  }

  void _onDeviceChanged(Device device) {
    setState(() {
      _features = [];
      _selectedFeature = null;
      _featureCurrentPage = 0;

      _selectedDevice = device;
    });

    _loadMoreFeatureData(device);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isDeviceLoading) {
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
    if (_isDeviceLoading) return;

    setState(() {
      _isDeviceLoading = true;
    });

    final devices = await _deviceService.getAllDevices(
      _deviceCurrentPage + 1,
      _itemsPerPage,
    );

    setState(() {
      _devices.addAll(devices);
      _deviceCurrentPage++;
      _isDeviceLoading = false;
    });

    if (_deviceCurrentPage == 1 && _selectedDevice == null) {
      setState(() {
        _selectedDevice = _devices.first;
      });
      _loadMoreFeatureData(_devices.first);
    }
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isDeviceLoading = true;
    });

    final d = await _deviceService.getAllDevices(0, _itemsPerPage);

    setState(() {
      _devices = d;
      _deviceCurrentPage = 0;
      _isDeviceLoading = false;
    });
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

    setState(() {
      _features.addAll(fs);
      _featureCurrentPage++;
      _isFeatureLoading = false;
    });

    if (_featureCurrentPage == 1 && _selectedFeature == null) {
      setState(() {
        _selectedFeature = _features.first;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaQueryWidth = MediaQuery.of(context).size.width;
    final mediaQueryHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('设备数据分析'), elevation: 0),
      body: Container(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLeftPanel(colorScheme, textTheme, mediaQueryWidth * 0.19),
            _buildRightPanel(
              colorScheme,
              textTheme,
              mediaQueryWidth * 0.8,
              mediaQueryHeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double width,
  ) {
    return Container(
      width: width,
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
          Expanded(child: _buildFeaturesList(colorScheme, textTheme)),
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
                itemCount: _devices.length + (_isDeviceLoading ? 1 : 0),
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
                      onTap: () => _onDeviceChanged(device),
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
                                  ? Colors.green
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
                                  ? Colors.green
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
                                color: Colors.green,
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

  Widget _buildFeaturesList(ColorScheme colorScheme, TextTheme textTheme) {
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

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedFeature = feature;
                            }),
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
                                        ? Colors.green
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
                                      DateFormat('yyyy/MM/dd HH:mm:ss').format(
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

  Widget _buildRightPanel(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double width,
    double height,
  ) {
    if (_selectedFeature == null) {
      return Center(
        child: Text(
          '暂无数据',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return FutureBuilder<ExtendedHistory?>(
      future: _historyService.getHistory(
        _selectedDevice!.id,
        _selectedFeature!.dataTime!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final history = snapshot.data!;
        final double samplingRate = history.samplingRate;
        final List<double> waveform = history.data;

        List<double> data = _calculateAlgorithm(_tabIndex, waveform);

        return Container(
          width: width,
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
          child: Column(
            children: [
              // Tab栏
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  tabs: List.generate(algorithms.length, (index) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(algorithms[index].icon, size: 16),
                          SizedBox(width: 4),
                          Text(algorithms[index].name),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              // Tab内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: algorithms
                        .map(
                          (TabItem tab) => _buildAlgorithmView(
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            waveformData: waveform,
                            spectrum: data,
                            samplingRate: samplingRate,
                            height: height,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlgorithmView({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required List<double> waveformData,
    required List<double> spectrum,
    required double samplingRate,
    required double height,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 波形图
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 280,
              maxHeight: height * 0.41,
            ),
            child: _buildChartCard(
              colorScheme: colorScheme,
              textTheme: textTheme,
              title: '时域波形',
              icon: Icons.show_chart,
              child: WaveformChart(
                samplingRate: samplingRate,
                waveform: waveformData,
                colorScheme: colorScheme,
                isShowDot: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 频谱图
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 280,
              maxHeight: height * 0.41,
            ),
            child: _buildChartCard(
              colorScheme: colorScheme,
              textTheme: textTheme,
              title: '频域频谱',
              icon: Icons.bar_chart,
              child: SpectrumChart(
                spectrum: spectrum,
                colorScheme: colorScheme,
                isShowDot: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getValueColor(double value) {
    if (value > 8) return Colors.red;
    if (value > 5) return Colors.orange;
    return Colors.green;
  }
}
