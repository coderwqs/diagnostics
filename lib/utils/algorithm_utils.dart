import 'dart:math';

class AlgorithmUtils {
  // 计算信号的 FFT
  List<Complex> fft(List<Complex> input) {
    int n = input.length;
    if (n <= 1) return input;

    List<Complex> even = fft(
      input
          .asMap()
          .entries
          .where((entry) => entry.key % 2 == 0)
          .map((entry) => entry.value)
          .toList(),
    );
    List<Complex> odd = fft(
      input
          .asMap()
          .entries
          .where((entry) => entry.key % 2 == 1)
          .map((entry) => entry.value)
          .toList(),
    );

    List<Complex> result = List.filled(n, Complex(0, 0));
    for (int k = 0; k < n ~/ 2; k++) {
      double t = -2 * pi * k / n;
      Complex exp = Complex(cos(t), sin(t)) * odd[k];
      result[k] = even[k] + exp;
      result[k + n ~/ 2] = even[k] - exp;
    }
    return result;
  }

  // 计算频谱
  List<double> calculateSpectrum(List<double> signal) {
    int n = signal.length;
    List<Complex> complexSignal = List.generate(
      n,
      (i) => Complex(signal[i], 0),
    );
    List<Complex> fftResult = fft(complexSignal);
    return fftResult.map((c) => c.modulus()).toList();
  }

  // 计算频谱包络
  List<double> calculateEnvelope(List<double> spectrum) {
    List<double> envelope = List.filled(spectrum.length, 0);
    int range = 10; // 调整范围以控制包络的平滑度
    for (int i = 0; i < spectrum.length; i++) {
      envelope[i] = _calculatePeak(spectrum, i, range);
    }
    return envelope;
  }

  // 计算包络的峰值
  double _calculatePeak(List<double> spectrum, int index, int range) {
    double peak = 0;
    for (
      int i = max(0, index - range);
      i <= min(spectrum.length - 1, index + range);
      i++
    ) {
      if (spectrum[i] > peak) {
        peak = spectrum[i];
      }
    }
    return peak;
  }

  // 小波变换 (简单的 Haar 小波)
  List<double> waveletTransform(List<double> signal) {
    int n = signal.length;
    List<double> result = List.filled(n, 0);
    for (int i = 0; i < n ~/ 2; i++) {
      result[i] = (signal[2 * i] + signal[2 * i + 1]) / sqrt(2);
      result[i + n ~/ 2] = (signal[2 * i] - signal[2 * i + 1]) / sqrt(2);
    }
    return result;
  }

  // 倒谱计算
  List<double> cepstrum(List<double> signal) {
    List<double> spectrum = calculateSpectrum(signal);
    List<double> logSpectrum = spectrum.map((s) => log(s)).toList();
    List<Complex> complexSignal = List.generate(
      logSpectrum.length,
      (i) => Complex(logSpectrum[i], 0),
    );
    List<Complex> fftResult = fft(complexSignal);
    return fftResult.map((c) => c.real).toList();
  }

  // 阶次计算
  List<double> calculateOrder(List<double> signal, int order) {
    List<double> result = List.filled(signal.length, 0);
    for (int i = 0; i < signal.length; i++) {
      result[i] = pow(signal[i], order).toDouble();
    }
    return result;
  }
}

class Complex {
  final double real;
  final double imaginary;

  Complex(this.real, this.imaginary);

  Complex operator +(Complex other) =>
      Complex(real + other.real, imaginary + other.imaginary);

  Complex operator -(Complex other) =>
      Complex(real - other.real, imaginary - other.imaginary);

  Complex operator *(Complex other) => Complex(
    real * other.real - imaginary * other.imaginary,
    real * other.imaginary + imaginary * other.real,
  );

  double modulus() => sqrt(real * real + imaginary * imaginary);
}
