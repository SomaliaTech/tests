int calculateReadingTime(String context) {
  final wordsPerMinute = 200;
  final wordsRegex = RegExp(r'\w+');
  final int wordCount = wordsRegex.allMatches(context).length;
  return (wordCount / wordsPerMinute).ceil();
}
