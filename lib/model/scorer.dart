import 'package:shared_preferences/shared_preferences.dart';

class Scorer {
  static Future<int> getBestScore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best') ?? 0;
  }

  static void storeIfBest(int newBest) async {
    final int oldBest = await getBestScore();

    if (newBest > oldBest) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('best', newBest);
    }
  }

  static void reset() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('best', 0);
  }
}
