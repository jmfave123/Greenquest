import 'package:get/get.dart';
import '../controllers/web_home_controller.dart';

class WebHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebHomeController>(() => WebHomeController());
  }
}
