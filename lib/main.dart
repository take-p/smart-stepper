// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ThreeDimension accelerometer = ThreeDimension(0, 0, 0);
  final ThreeDimension userAccelerometer = ThreeDimension(0, 0, 0);
  final ThreeDimension gyroscope = ThreeDimension(0, 0, 0);
  final ThreeDimension magnetometer = ThreeDimension(0, 0, 0);

  Queue<ThreeDimension> accelerometerHistory = Queue();

  // 閾値
  double threshold1 = -2.0;
  double threshold2 = -4.0;

  bool isDown = false;
  int count = 0;

  Duration exerciseTime = const Duration(seconds: 0);// 経過時間
  Duration targetTime = const Duration(minutes: 30); // 目標時間
  String _time = ""; // 表示される文字列
  bool isStop = false; // タイマーストップフラグ

  bool isAlarmOn = false; // アラームフラグ

  final _streamSubscriptions = <StreamSubscription<dynamic>>[]; // 定期実行

  static final _audioPlayer = AudioPlayer();

  static const dataN = 50;// グラフの幅

  @override
  Widget build(BuildContext context) {
    if (accelerometer.y > threshold1 && !isDown) {
      setState(() {
        isDown = true;
        count++;
      });
    }
    if (accelerometer.y < threshold2 && isDown) {
      setState(() {
        isDown = false;
        count++;
      });
    }
    if (!isStop && _time == targetTime.toString().split(".")[0]) {
      setState(() {
        isStop = true;
        _audioPlayer.play(AssetSource("audios/chime.mp3"));
      });
    }

    setState(() => _time = exerciseTime.toString().split(".")[0]); // 経過時間

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Example'),
      ),
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0, maxX: dataN.toDouble(), minY: -15, maxY: 15,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: threshold1, color: Colors.blue.shade100),
                    HorizontalLine(y: threshold2, color: Colors.blue.shade100),
                  ]
                ),
                lineBarsData: [
                  LineChartBarData(
                    color: Colors.red,
                    dotData: FlDotData(
                      show: false,
                    ),
                    spots: [
                      ...[
                        for (int i = 0;i < accelerometerHistory.length; i++)
                          FlSpot(i.toDouble(), accelerometerHistory.elementAt(i).x)
                      ]
                    ],
                  ),
                  LineChartBarData(
                    color: Colors.green,
                    dotData: FlDotData(
                      show: false,
                    ),
                    spots: [
                      ...[
                        for (int i = 0;i < accelerometerHistory.length; i++)
                          FlSpot(i.toDouble(), accelerometerHistory.elementAt(i).y)
                      ]
                    ],
                  ),
                  LineChartBarData(
                    color: Colors.blue,
                    dotData: FlDotData(
                      show: false,
                    ),
                    spots: [
                      ...[
                        for (int i = 0;i < accelerometerHistory.length; i++)
                          FlSpot(i.toDouble(), accelerometerHistory.elementAt(i).z)
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          /*Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('加速度: ${accelerometer.getXYZ(1)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('加速度（重力の影響を引く）: ${userAccelerometer.getXYZ(1)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('ジャイロ: ${gyroscope.getXYZ(1)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('地磁気: ${magnetometer.getXYZ(1)}'),
              ],
            ),
          ),*/
          Text("現在値: ${accelerometer.y.toStringAsFixed(1)}, 閾値(上限): $threshold1, 閾値(下限): $threshold2", style: TextStyle(fontSize: 16),),
          Text("状態: ${isDown ? "🔻" : "🔺︎"}, 歩数: $count", style: const TextStyle(fontSize: 32),),
          Text("経過時間: $_time", style: const TextStyle(fontSize: 32),),
          Text("目標時間: ${targetTime.toString().split(".")[0]}", style: TextStyle(fontSize: 32),),
          //Text("現在時刻: ${DateFormat('H:mm').format(DateTime.now())}", style: TextStyle(fontSize: 25),),
          //Text("アラーム: ${DateFormat('H:mm').format(DateTime(2020, 1, 1, 12, 34))}", style: TextStyle(fontSize: 25),),
          /*Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
              ),
              child: DecimalNumberPicker(
                itemCount: 1, minValue: -10, maxValue: 10, value: threshold1, haptics: true,
                onChanged: (value) {
                  setState(() {
                    threshold1 = value;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1)
              ),
              child: DecimalNumberPicker(
                itemCount: 1, minValue: -10, maxValue: 10, value: threshold2, haptics: true,
                onChanged: (value) {
                  setState(() {
                    threshold2 = value;
                  });
                },
              ),
            ),
          ),*/
          ElevatedButton(
            onPressed: () {
              if (isStop) {
                isStop = false;
                /*for (StreamSubscription ss in _streamSubscriptions) {
                  ss.resume();
                }*/
              } else {
                isStop = true;
                /*for (StreamSubscription ss in _streamSubscriptions) {
                  ss.pause();
                }*/
              }
            },
            child: Text(isStop ? "再開" : "一時停止"),
          ),
          ElevatedButton(
            onPressed: () {
              setState((){
                count = 0;
                exerciseTime = const Duration(seconds: 0);
                isStop = true;
                _audioPlayer.stop();
                _audioPlayer.seek(const Duration(seconds: 0));
              });
            },
            child: Text("リセット"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("キャリブレーション"),
          ),
          /*Expanded(
            child: Row(
              children: [
                /*CupertinoPicker(
                  itemExtent: 30,
                  onSelectedItemChanged: (x) {},
                  children: [
                    for(int i = 0; i < 60; i++)
                      Text("$i")
                  ],
                ),*/
                CupertinoPicker(
                  itemExtent: 30,
                  onSelectedItemChanged: (x) {},
                  children: [
                    for(int i = 0; i < 60; i++)
                      Text("$i")
                  ],
                ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }

  // 終了???
  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  // タイマー処理
  void _onTimer(Timer timer) {
    if (!isStop) {
      exerciseTime += const Duration(seconds: 1);
      //var now = DateTime.now();
      //var formatter = DateFormat('HH:mm:ss');
      //var formattedTime = formatter.format(now);
    }
  }

  // 初期化
  // 定期的にセンサーの値を取得する処理を実行
  @override
  void initState() {
    super.initState();

    // タイマー
    Timer.periodic(
      const Duration(seconds: 1), // 1秒ごとに
      _onTimer, // この処理を実行
    );

    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            accelerometer.setXYZ(event.x, event.y, event.z);
            accelerometerHistory.addFirst(accelerometer.copyWith());
            if (accelerometerHistory.length > dataN) {
              accelerometerHistory.removeLast();
            }
          });
        },
      ),
    );
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            userAccelerometer.setXYZ(event.x, event.y, event.z);
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            gyroscope.setXYZ(event.x, event.y, event.z);
          });
        },
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            magnetometer.setXYZ(event.x, event.y, event.z);
          });
        },
      ),
    );
  }
}

class ThreeDimension {
  double x, y, z;
  ThreeDimension(this.x, this.y, this.z);

  void setXYZ(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  List<String> getXYZ(int k) {
    return [x.toStringAsFixed(k), y.toStringAsFixed(k), z.toStringAsFixed(k)];
  }

  ThreeDimension copyWith() {
    return ThreeDimension(x, y, z);
  }
}