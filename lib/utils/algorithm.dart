import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:fftea/fftea.dart';
import 'dart:typed_data';

class BearingFaultDiagnosis {
  final double samplingRate;
  final double rpm;
  final Map<String, dynamic> bearingParams;

  double fCage = 0;
  double fBall = 0;
  double fOuter = 0;
  double fInner = 0;
  double fShaft = 0;

  bool isFilter = false;

  BearingFaultDiagnosis(this.samplingRate, this.rpm, this.bearingParams) {
    calculateFaultFrequencies();
  }

  void calculateFaultFrequencies() {
    double d = bearingParams['diameter'];
    double D = bearingParams['pitch_diameter'];
    int n = bearingParams['number_of_balls'];
    double alpha = (bearingParams['contact_angle'] * pi / 180);

    fShaft = rpm / 60;
    fInner = (n / 2) * (1 + (d / D) * cos(alpha)) * fShaft;
    fOuter = (n / 2) * (1 - (d / D) * cos(alpha)) * fShaft;
    fBall =
        (D / d) * (1 - (d / D) * (d / D) * cos(alpha) * cos(alpha)) * fShaft;
    fCage = (1 / 2) * (1 - (d / D) * cos(alpha)) * fShaft;
  }

  List<List<double>> computeSpectrum(List<double> timeSignal) {
    // 输入验证
    if (timeSignal.isEmpty) {
      throw ArgumentError("输入信号必须是非空数组");
    }

    if (samplingRate <= 0) {
      throw ArgumentError("采样率(samplingRate)必须为正数");
    }

    // 转换为List并确保是一维的
    List<double> signalSamples = List.from(timeSignal);
    int sampleCount = signalSamples.length;

    if (sampleCount < 2) {
      throw ArgumentError("信号长度必须大于1");
    }

    // 应用汉宁窗
    List<double> window = List.generate(
      sampleCount,
      (i) => 0.5 * (1 - cos(2 * pi * i / (sampleCount - 1))),
    );
    List<double> windowedSignal = List.generate(
      sampleCount,
      (i) => signalSamples[i] * window[i],
    );

    // 去除直流分量
    double mean = windowedSignal.reduce((a, b) => a + b) / sampleCount;
    List<double> zeroMeanSignal = windowedSignal.map((x) => x - mean).toList();

    // 执行FFT并计算幅度谱
    final fft = FFT(sampleCount);
    final complexSpectrum = fft.realFft(zeroMeanSignal);
    List<double> amplitudeSpectrum = List.generate(sampleCount, (i) {
      return sqrt(pow(complexSpectrum[i].x, 2) + pow(complexSpectrum[i].y, 2));
    });

    // 归一化为单边谱
    for (int i = 1; i < amplitudeSpectrum.length ~/ 2; i++) {
      amplitudeSpectrum[i] =
          amplitudeSpectrum[i] / sampleCount * 2; // 补偿丢弃的负频率能量
    }
    amplitudeSpectrum = amplitudeSpectrum.sublist(
      0,
      sampleCount ~/ 2,
    ); // 取正频率部分

    // 生成频率轴
    List<double> frequencyAxis = List.generate(sampleCount ~/ 2, (i) {
      return i * (samplingRate / sampleCount);
    });

    return [frequencyAxis, amplitudeSpectrum];
  }

  List<List<double>> computeEnvelope(List<double> timeSignal) {
    if (timeSignal.isEmpty) {
      throw ArgumentError("输入信号必须是非空数组");
    }

    if (samplingRate <= 0) {
      throw ArgumentError("采样率(samplingRate)必须为正数");
    }

    int sampleCount = timeSignal.length;

    if (sampleCount < 2) {
      throw ArgumentError("信号长度必须大于1");
    }

    // 希尔伯特变换获取解析信号
    final fft = FFT(sampleCount);
    final complexSignal = fft.realFft(timeSignal);
    List<double> analyticSignal = List.generate(sampleCount, (i) {
      return i < sampleCount / 2 ? complexSignal[i].x : 0.0;
    });

    // 计算包络信号
    List<double> envelopeSignal = List.generate(sampleCount, (i) {
      return sqrt(pow(timeSignal[i], 2) + pow(analyticSignal[i], 2));
    });

    // 去除包络的直流分量
    double meanEnvelope = envelopeSignal.reduce((a, b) => a + b) / sampleCount;
    List<double> zeroMeanEnvelope = envelopeSignal
        .map((e) => e - meanEnvelope)
        .toList();

    // 计算包络谱
    final complexEnvelopeSpectrum = fft.realFft(zeroMeanEnvelope);
    List<double> envelopeSpectrum = List.generate(sampleCount ~/ 2, (i) {
      return sqrt(
            pow(complexEnvelopeSpectrum[i].x, 2) +
                pow(complexEnvelopeSpectrum[i].y, 2),
          ) /
          sampleCount *
          2;
    });

    // 生成频率轴
    List<double> frequencyAxis = List.generate(sampleCount ~/ 2, (i) {
      return i * (samplingRate / sampleCount);
    });

    return [frequencyAxis, envelopeSpectrum];
  }

  List<double> preprocessSignal(
    List<double> rawSignal, {
    double lowFreq = 20.0,
    double highFreq = 2000.0,
    double sampleRate = 44100.0,
  }) {
    // 1. 确保信号长度为2的幂（fftea要求）
    final n = rawSignal.length;
    final nextPowerOfTwo = 1 << (n.bitLength);
    final paddedSignal =
        (n & (n - 1)) == 0
              ? List<double>.from(rawSignal)
              : List<double>.from(rawSignal)
          ..addAll(List<double>.filled(nextPowerOfTwo - n, 0.0));

    // 2. 执行FFT
    final fft = FFT(paddedSignal.length);
    final spectrum = fft.realFft(paddedSignal);

    // 3. 计算频率分辨率
    final freqResolution = sampleRate / paddedSignal.length;

    // 4. 创建带通滤波器
    for (var i = 0; i < spectrum.length; i++) {
      final freq = i * freqResolution;
      if (freq > sampleRate / 2) continue; // 超过奈奎斯特频率

      // 计算当前频点是否在带通范围内
      final inPassBand = freq >= lowFreq && freq <= highFreq;
      final attenuation = inPassBand ? 1.0 : 0.01; // -40dB衰减

      // 应用滤波器
      spectrum[i] = Float64x2(
        spectrum[i].x * attenuation,
        spectrum[i].y * attenuation,
      );
    }

    // 5. 执行逆FFT
    final filteredSignal = fft.realInverseFft(spectrum);

    // 6. 返回原始长度信号（去掉填充的零）
    return filteredSignal.sublist(0, rawSignal.length);
  }

  Map<String, dynamic> extractFeatures(List<double> vibrationData) {
    // 输入验证
    if (vibrationData.isEmpty) {
      throw ArgumentError("振动数据不能为空");
    }

    // 时域特征
    double rms = sqrt(
      vibrationData.map((x) => x * x).reduce((a, b) => a + b) /
          vibrationData.length,
    );
    double peak = vibrationData
        .map((x) => x.abs())
        .reduce((a, b) => a > b ? a : b);
    double kurtosis = calculateKurtosis(vibrationData, rms);
    double skewness = calculateSkewness(vibrationData, rms);
    double crestFactor = peak / rms;

    Map<String, dynamic> timeFeatures = {
      'rms': rms,
      'peak': peak,
      'kurtosis': kurtosis,
      'skewness': skewness,
      'crest_factor': crestFactor,
    };

    // 频域特征
    var envelopeResult = computeEnvelope(vibrationData);
    var spectrumResult = computeSpectrum(vibrationData);

    return {
      'time': timeFeatures,
      'envelope_frequency': {
        'frequencies': envelopeResult[0],
        'amplitudes': envelopeResult[1],
      },
      'spectrum_frequency': {
        'frequencies': spectrumResult[0],
        'amplitudes': spectrumResult[1],
      },
    };
  }

  double calculateKurtosis(List<double> data, double rms) {
    double mean = data.reduce((a, b) => a + b) / data.length;
    double fourthMoment =
        data.map((x) => pow(x - mean, 4)).reduce((a, b) => a + b) / data.length;
    double variance = rms * rms;
    return fourthMoment / (variance * variance) - 3; // 减去 3 使其中心化
  }

  double calculateSkewness(List<double> data, double rms) {
    double mean = data.reduce((a, b) => a + b) / data.length;
    double thirdMoment =
        data.map((x) => pow(x - mean, 3)).reduce((a, b) => a + b) / data.length;
    double variance = rms * rms;
    return thirdMoment / pow(variance, 1.5); // 计算偏度
  }

  List<Map<String, dynamic>> diagnoseFault(Map<String, dynamic> features) {
    List<Map<String, dynamic>> possibleFaults = [];

    // 故障特征频率
    Map<String, double> faultFreqs = {
      'inner_race': fInner,
      'outer_race': fOuter,
      'ball': fBall,
      'cage': fCage,
    };

    // 频域特征
    var envelopeFreqs = features['envelope_frequency']['frequencies'];
    var envelopeAmps = features['envelope_frequency']['amplitudes'];

    // 检测故障
    for (var entry in faultFreqs.entries) {
      String fault = entry.key;
      double freq = entry.value;

      // 计算感兴趣频谱范围的索引
      int leftIdx = _findClosestIndex(envelopeFreqs, freq * (1 - 0.05));
      int rightIdx = _findClosestIndex(envelopeFreqs, freq * (1 + 0.05));

      if (leftIdx >= rightIdx) continue;

      // 寻找峰值和平均值
      double peakMag = envelopeAmps.sublist(leftIdx, rightIdx).reduce(max);
      double meanMag = _mean(envelopeAmps.sublist(leftIdx - 3, rightIdx + 3));

      // 获取峰值对应的频率
      int faultFreqIndex = envelopeAmps.indexOf(peakMag);
      double faultFreq = envelopeFreqs[faultFreqIndex];

      // 判断故障条件
      if (peakMag / meanMag >= 5 && peakMag > 0.1) {
        possibleFaults.add({
          'fault_type': fault,
          'frequency': freq,
          'measured_frequency': faultFreq,
          'amplitude': peakMag,
          'harmonic_ratio': 0,
        });
      }
    }

    // 处理转子不平衡
    Map<String, double> rotorImbalance = {'rotor imbalance': fShaft};
    for (var entry in rotorImbalance.entries) {
      String fault = entry.key;
      double freq = entry.value;

      // 计算感兴趣频谱范围的索引
      int leftIdx = _findClosestIndex(envelopeFreqs, freq * (1 - 0.05));
      int rightIdx = _findClosestIndex(envelopeFreqs, freq * (1 + 0.05));

      if (leftIdx >= rightIdx) continue;

      // 寻找峰值和平均值
      double peakMag = envelopeAmps.sublist(leftIdx, rightIdx).reduce(max);
      double meanMag = _mean(envelopeAmps.sublist(leftIdx - 3, rightIdx + 3));

      // 获取对应的频率
      int faultFreqIndex = envelopeAmps.indexOf(peakMag);
      double faultFreq = envelopeFreqs[faultFreqIndex];

      // 判断故障条件
      if (_sumSquare(envelopeAmps.sublist(leftIdx, rightIdx)) /
                  _sumSquare(envelopeAmps) >=
              0.7 &&
          peakMag > 0.01) {
        possibleFaults.add({
          'fault_type': fault,
          'frequency': freq,
          'measured_frequency': faultFreq,
          'amplitude': peakMag,
          'harmonic_ratio': 0,
        });
      }
    }

    // 处理转子对中误差
    Map<String, double> rotorMisalignment = {'rotor misalignment': fShaft * 2};
    for (var entry in rotorMisalignment.entries) {
      String fault = entry.key;
      double freq = entry.value;

      // 计算感兴趣频谱范围的索引
      int leftIdx = _findClosestIndex(envelopeFreqs, freq * (1 - 0.05));
      int rightIdx = _findClosestIndex(envelopeFreqs, freq * (1 + 0.05));

      if (leftIdx >= rightIdx) continue;

      // 寻找2倍转频峰值和平均值
      double x2PeakMag = envelopeAmps.sublist(leftIdx, rightIdx).reduce(max);
      int faultFreqIndex = envelopeAmps.indexOf(x2PeakMag);
      double x2FaultFreq = envelopeFreqs[faultFreqIndex];

      double x1PeakMag = envelopeAmps
          .sublist(leftIdx ~/ 2, rightIdx ~/ 2)
          .reduce(max);

      if (x2PeakMag > x1PeakMag && x2PeakMag > 0.01) {
        possibleFaults.add({
          'fault_type': fault,
          'frequency': freq,
          'measured_frequency': x2FaultFreq,
          'amplitude': x2PeakMag,
          'harmonic_ratio': x2PeakMag / x1PeakMag,
        });
      }
    }

    // 根据时域特征增加诊断信息
    if (features['time']['kurtosis'].abs() > 1) {
      possibleFaults.add({
        'fault_type': 'severe_impact',
        'description': 'High kurtosis indicates severe impacts',
      });
    }

    if (features['time']['crest_factor'] > 5) {
      possibleFaults.add({
        'fault_type': 'spalling_or_pitting',
        'description': 'High crest factor indicates localized defects',
      });
    }

    return possibleFaults;
  }

  int _findClosestIndex(List<double> frequencies, double target) {
    return frequencies.indexOf(
      frequencies.reduce(
        (a, b) => (a - target).abs() < (b - target).abs() ? a : b,
      ),
    );
  }

  double _mean(List<double> data) {
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _sumSquare(List<double> data) {
    return data.map((x) => x * x).reduce((a, b) => a + b);
  }

  Map<String, dynamic> analyzeVibrationData(List<double> rawSignal) {
    // 输入验证
    if (rawSignal.isEmpty) {
      throw ArgumentError("输入信号必须是非空数组");
    }

    List<double> signalSamples = List.from(rawSignal);
    if (signalSamples.length < 2) {
      throw ArgumentError("信号长度必须大于1");
    }

    // 预处理信号
    List<double> processedData = isFilter
        ? preprocessSignal(signalSamples)
        : signalSamples;

    // 提取特征
    Map<String, dynamic> features = extractFeatures(processedData);

    // 故障诊断
    List<Map<String, dynamic>> faults = diagnoseFault(features);

    // 返回结果字典
    return {
      'processed_data': processedData,
      'features': features,
      'faults': faults,
      'characteristic_frequencies': {
        'inner_race': fInner,
        'outer_race': fOuter,
        'ball': fBall,
        'cage': fCage,
      },
      'metadata': {
        'sampling_rate': samplingRate,
        'analysis_time': DateTime.now().toIso8601String(),
        'processing_steps': [
          isFilter ? 'preprocessing' : null,
          'feature_extraction',
          'fault_diagnosis',
        ].whereType<String>().toList(),
      },
    };
  }

  void ensureDirectoryExists(String folder) {
    Directory(folder).createSync(recursive: true);
  }
}

void main() async {
  var bearingParams = {
    'diameter': 7.94,
    'pitch_diameter': 39.04,
    'number_of_balls': 9,
    'contact_angle': 0,
  };

  var diagnosis = BearingFaultDiagnosis(48000, 1797, bearingParams);

  print("Calculated Fault Frequencies:");
  print("Inner Race: ${diagnosis.fInner.toStringAsFixed(2)} Hz");
  print("Outer Race: ${diagnosis.fOuter.toStringAsFixed(2)} Hz");
  print("Ball: ${diagnosis.fBall.toStringAsFixed(2)} Hz");
  print("Cage: ${diagnosis.fCage.toStringAsFixed(2)} Hz");


  final file = File('/home/coderwqs/workspace/flutter/diagnostics/lib/utils/109.json');
  String contents = await file.readAsString();

  // 解析 JSON 数据
  List<double> rawSignal = List<double>.from(json.decode(contents));
  print("++++++++++++++++++++++++++++++++ ${rawSignal.length}");

  // List<double> rawSignal = [];
  var result = diagnosis.analyzeVibrationData(rawSignal);

}
