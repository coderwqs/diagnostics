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

    // 计算频谱幅度
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
