class MultipleBatch {
  var batches = Map<int, BatchTestResult>();

  MultipleBatch(this.batches);

  double get totalAvg => batches
    .values
    .map((e) => e.averageMs)
    .reduce((a, b) => a + b) / batches.length;
}

class BatchTestResult {
  List<TestResult> results;

  BatchTestResult(this.results);

  int get totalElements => results
    .where((element) => element != null && element.success)
    .length;

  Duration get totalTime => results
      .where((element) => element != null && element.success && element.duration != null)
      .map((e) => e.duration)
      .fold(Duration.zero, (e1, e2) => e1 + e2);

  Duration get min => results
    .where((element) => element != null)
    .map((e) => e.duration)
    .reduce((e1, e2) => e1 < e2 ? e1 : e2);  

  Duration get max => results
    .where((element) => element != null)
    .map((e) => e.duration)
    .reduce((e1, e2) => e1 > e2 ? e1 : e2);  

  double get averageMs => totalTime.inMilliseconds / totalElements;  

  int get nbErrors => results
    .where((element) => element != null && !element.success)
    .length;

  int get nbSuccess => results
    .where((element) => element != null && element.success)
    .length;  
}

class TestResult {
  DateTime startingTime;
  DateTime endingTime;
  int threadNumber;
  String threadName;
  String url;
  bool success;

  TestResult({this.threadName, this.threadNumber, this.startingTime, this.endingTime, this.url, this.success});

  Duration get duration => success 
    ? endingTime.difference(startingTime)
    : Duration.zero;
}