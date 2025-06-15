// 공유 기능
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'timetable.dart';

class sharing{
  static Future<void> shareSchedule(Timetable schedule) async {
    try {
      String formattedStart = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.start_time));
      String formattedFinish = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(schedule.finish_time));

      final template = FeedTemplate(
        content: Content(
          title: schedule.name,
          description: '$formattedStart ~ $formattedFinish\n장소: ${schedule.place}',
          imageUrl: Uri.parse('https://via.placeholder.com/300x200.png?text=Schedule'),
          link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com'),
          ),
        ),
      );

      final isAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (isAvailable) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("카카오 공유 오류: $e");
    }
  }

  static Future<void> shareAllSchedules(List<Timetable> schedules) async {
    try {
      if (schedules.isEmpty) return;

      String combinedText = schedules.map((s) {
        String start = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(s.start_time));
        String end = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(s.finish_time));
        return "- ${s.name}\n  $start ~ $end\n  장소: ${s.place}";
      }).join("\n\n");

      final template = FeedTemplate(
        content: Content(
          title: '오늘의 전체 일정',
          description: combinedText,
          imageUrl: Uri.parse('https://via.placeholder.com/300x200.png?text=Schedules'),
          link: Link(
            webUrl: Uri.parse('https://developers.kakao.com'),
            mobileWebUrl: Uri.parse('https://developers.kakao.com'),
          ),
        ),
      );

      final isAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (isAvailable) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("전체 일정 카카오 공유 오류: $e");
    }
  }
}
