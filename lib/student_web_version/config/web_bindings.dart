import 'package:get/get.dart';
import '../controllers/web_home_controller.dart';
import '../../../user/notification/announcement_controller.dart';
import '../../../user/submit/pit/pit_controller.dart';

class WebHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebHomeController>(() => WebHomeController());
    Get.lazyPut<UserAnnouncementController>(() => UserAnnouncementController());
    Get.lazyPut<PitController>(() => PitController());
  }
}
