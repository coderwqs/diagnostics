import 'dart:math';
import 'dart:io';
import 'package:fftea/fftea.dart';
import 'dart:typed_data';

class BearingFaultDiagnosis {
  final double samplingRate;
  final double rpm;
  final Map<String, dynamic> bearingParams;

  double? fCage;
  double? fBall;
  double? fOuter;
  double? fInner;
  double? fShaft;

  BearingFaultDiagnosis(this.samplingRate, this.rpm, this.bearingParams) {
    calculateFaultFrequencies();
  }

  void calculateFaultFrequencies() {
    double d = bearingParams['diameter'];
    double D = bearingParams['pitch_diameter'];
    int n = bearingParams['number_of_balls'];
    double alpha = (bearingParams['contact_angle'] * pi / 180);

    fShaft = rpm / 60;
    fInner = (n / 2) * (1 + (d / D) * cos(alpha)) * fShaft!;
    fOuter = (n / 2) * (1 - (d / D) * cos(alpha)) * fShaft!;
    fBall =
        (D / d) * (1 - (d / D) * (d / D) * cos(alpha) * cos(alpha)) * fShaft!;
    fCage = (1 / 2) * (1 - (d / D) * cos(alpha)) * fShaft!;
  }

  List<double> computeSpectrum(List<double> timeSignal) {
    // 确保信号长度为2的幂，如果不是则自动填充零
    final n = timeSignal.length;
    final nextPowerOfTwo = 1 << (n.bitLength);

    // 如果需要填充零
    List<double> paddedSignal;
    if ((n & (n - 1)) != 0) {
      // 如果不是2的幂
      paddedSignal = List<double>.from(timeSignal)
        ..addAll(List<double>.filled(nextPowerOfTwo - n, 0.0));
    } else {
      paddedSignal = timeSignal;
    }

    // 创建FFT对象并执行变换
    final fft = FFT(paddedSignal.length);
    final complexSpectrum = fft.realFft(paddedSignal);

    // 计算幅度谱 (只需要前N/2+1个点，因为是对称的)
    final halfLength = paddedSignal.length ~/ 2 + 1;
    List<double> magnitudeSpectrum = List<double>.filled(halfLength, 0.0);

    // 处理 Float64x2List 数据
    for (var i = 0; i < halfLength; i++) {
      final complex = complexSpectrum[i];
      final real = complex.x; // 实部
      final imag = complex.y; // 虚部
      magnitudeSpectrum[i] = sqrt(real * real + imag * imag);
    }

    return magnitudeSpectrum;
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
    if (vibrationData.isEmpty) {
      throw ArgumentError('Input data must not be empty');
    }

    double rms = calculateRMS(vibrationData);
    double peak = calculatePeak(vibrationData);
    double kurtosis = calculateKurtosis(vibrationData, rms);
    double skewness = calculateSkewness(vibrationData, rms);

    return {
      'RMS': rms,
      'Peak': peak,
      'Kurtosis': kurtosis,
      'Skewness': skewness,
    };
  }

  double calculateRMS(List<double> data) {
    double sumOfSquares = data.map((x) => x * x).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / data.length);
  }

  double calculatePeak(List<double> data) {
    return data.map((x) => x.abs()).reduce((a, b) => a > b ? a : b);
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
    // 诊断故障的实现
    throw UnimplementedError('diagnoseFault not implemented');
  }

  Map<String, dynamic> analyzeVibrationData(List<double> rawSignal) {
    // 执行完整的振动数据分析流程
    List<double> processedData = preprocessSignal(rawSignal);
    Map<String, dynamic> features = extractFeatures(processedData);
    List<Map<String, dynamic>> faults = diagnoseFault(features);

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
    };
  }

  void ensureDirectoryExists(String folder) {
    Directory(folder).createSync(recursive: true);
  }
}

void main() {
  // 示例用法
  var bearingParams = {
    'diameter': 10.0,
    'pitch_diameter': 50.0,
    'number_of_balls': 8,
    'contact_angle': 15.0,
  };

  var diagnosis = BearingFaultDiagnosis(1000, 1200, bearingParams);
  print(diagnosis.fInner); // 输出内圈故障频率
}
