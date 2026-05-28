import 'interpreter_service.dart';

class WebInterpreterService implements InterpreterService {
  bool _isReady = false;

  @override
  bool get isReady => _isReady;

  @override
  Future<void> loadModel() async {
    // Simulator loading delay to make it realistic
    await Future.delayed(const Duration(milliseconds: 500));
    _isReady = true;
  }

  @override
  List<double> run(List<double> input) {
    // Web mock doesn't need to run actual neural network tensors
    return List.filled(29, 0.0);
  }

  @override
  void close() {
    // No-op on web
  }
}

InterpreterService getInterpreterService() => WebInterpreterService();
