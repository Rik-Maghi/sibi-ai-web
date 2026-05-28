import 'package:tflite_flutter/tflite_flutter.dart';
import 'interpreter_service.dart';

class MobileInterpreterService implements InterpreterService {
  Interpreter? _interpreter;
  late final List<List<double>> _outputBuffer;
  static const int _numClasses = 29;

  MobileInterpreterService() {
    _outputBuffer = [List.filled(_numClasses, 0.0)];
  }

  @override
  bool get isReady => _interpreter != null;

  @override
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/sibi_model.tflite',
        options: options,
      );
    } catch (e) {
      // Failed to load native model
    }
  }

  @override
  List<double> run(List<double> input) {
    if (_interpreter == null) return _outputBuffer[0];
    try {
      _interpreter!.run([input], _outputBuffer);
      return _outputBuffer[0];
    } catch (e) {
      return _outputBuffer[0];
    }
  }

  @override
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}

InterpreterService getInterpreterService() => MobileInterpreterService();
