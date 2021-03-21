import 'dart:async';
import 'package:http/http.dart' as http;

import 'dart:math';

import 'package:perfcli/test_model.dart';

typedef OnEachRes = Function(TestResult res);

typedef OnEachBatchRes = Function(BatchTestResult res);

typedef OnEachBatchStart = Function(int batchNumber);

Future<BatchTestResult> stressTestUrlResponseTime(
      int numberOfThread, 
      String urlPath, 
      int nbRepeat,
      {OnEachBatchStart onEachStart, String token, bool randomDelayed = false}) async {
  var batches = <TestResult>[];
  var futures = <Future>[];
  for(var index = 0; index<nbRepeat; index++) {
    await Future.delayed(Duration(seconds: 1));
    if(onEachStart != null) {
      onEachStart(index);
    }
    var request = List.generate(numberOfThread, 
      (index) => sendRequest(
        index, urlPath, 
        token: token, 
        randomDelayed: randomDelayed
      ).then((test) {
        batches.add(test);
      })
    );
    futures.addAll(request);
  }
  await Future.wait(futures);
  return BatchTestResult(batches);
}

Future<BatchTestResult> testUrlResponseTime(
      int numberOfThread, 
      String urlPath, 
      {OnEachRes onEachRes, String token, bool randomDelayed = false}) async {
  var testResultList = await Future.wait<TestResult>(
    List.generate(numberOfThread, 
      (index) => sendRequest(
        index, urlPath, 
        token: token, 
        randomDelayed: randomDelayed
      )
      .then((res) async {
        if(onEachRes != null) {
          onEachRes(res);
        }
        return res;
      })
    )
  );
  return BatchTestResult(testResultList);
}

Future<TestResult> sendRequest(
      int threadNumber, 
      String urlPath, 
      {
        String token, 
        bool randomDelayed = false
      }) async {
  if(randomDelayed) {
    var rdm = Random().nextInt(1000);
    await Future.delayed(Duration(milliseconds: rdm));
  }                              
  var startTime = DateTime.now();
  var url = Uri.parse(urlPath);
  http.Response response;
  try {
    response = await http.get(
      url, 
      headers: {
        'Authorization': 'Bearer $token'
      }
    );
  } finally {
    var endTime = DateTime.now();
    return TestResult(
      threadName: '',
      threadNumber: threadNumber,
      startingTime: startTime,
      endingTime: endTime,
      url: urlPath,
      success: response.statusCode >= 200 && response.statusCode < 300
    );
  }
}
