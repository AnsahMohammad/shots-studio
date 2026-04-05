class SplashTextItem {
  final String text;
  final String analyticsKey;

  const SplashTextItem({required this.text, required this.analyticsKey});
}

class SplashTexts {
  static const List<SplashTextItem> items = [
    SplashTextItem(text: 'Amaze Amaze 👎', analyticsKey: 'amaze_amaze'),
    SplashTextItem(text: 'You are Awesome!!', analyticsKey: 'you_are_awesome'),
    SplashTextItem(text: 'Do a barrel roll', analyticsKey: 'barrel_roll'),
    SplashTextItem(text: 'As seen on TV!', analyticsKey: 'as_seen_on_tv'),
    SplashTextItem(text: '0% Sugar!', analyticsKey: 'zero_sugar'),
    SplashTextItem(text: 'Also try Minecraft!', analyticsKey: 'try_minecraft'),
    SplashTextItem(text: 'Follow the train, CJ!', analyticsKey: 'gta_sa'),
    SplashTextItem(text: 'beep boop beep', analyticsKey: 'beep'),
    SplashTextItem(text: 'Chicken jockey', analyticsKey: 'cj'),
    SplashTextItem(text: 'To infinity and beyond!', analyticsKey: 'toystory'),
    SplashTextItem(text: 'Winter is Coming', analyticsKey: 'got'),
    SplashTextItem(text: 'Legend.. wait for it ..DARY!', analyticsKey: 'himym'),
    SplashTextItem(text: 'On your left', analyticsKey: 'avengers'),
    SplashTextItem(text: 'suit up', analyticsKey: 'barney'),
    SplashTextItem(text: 'i am groot', analyticsKey: 'gotg'),
  ];
}
