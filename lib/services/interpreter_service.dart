import 'interpreter_service_stub.dart'
    if (dart.library.io) 'interpreter_service_mobile.dart'
    if (dart.library.html) 'interpreter_service_web.dart';

abstract class InterpreterService {
  bool get isReady;
  Future<void> loadModel();
  List<double> run(List<double> input);
  void close();

  factory InterpreterService() => getInterpreterService();
}
