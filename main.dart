import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';


Future<String> get _appDocPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
Future<File> get _UserCity async {
  final path = await _appDocPath;
  return File('$path/UserCity.txt');
}

Future<String> readUserCity() async{
  final file = await _UserCity;
  String UserCity = await file.readAsString();
  return UserCity;
}
Future<File> writeUserCity(String UserCity) async {
  final file = await _UserCity;
  return file.writeAsString(UserCity);
}


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentIndex = 0;
  final tabs=[
    Screen1(),
    screen2(),
  ];
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: '天氣app',
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('天氣APP'),
          ),
          backgroundColor: Colors.green,
        ),
        body: tabs[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home),label: '現在天氣'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud),label: '天氣預測'),
          ],
          onTap: onTabChanged,
        ),
      ),
    );
  }
  void onTabChanged(int value) {
    setState(() {
      currentIndex = value;
    });
  }
}

class WeatherStation {
  String stationName;
  GeoInfo geoInfo;
  WeatherElement weatherElement;

  WeatherStation({
    required this.stationName,
    required this.geoInfo,
    required this.weatherElement,
  });

  factory WeatherStation.fromJson(Map<String, dynamic> json) {
    return WeatherStation(
      stationName: json['StationName'],
      geoInfo: GeoInfo.fromJson(json['GeoInfo']),
      weatherElement: WeatherElement.fromJson(json['WeatherElement']),
    );
  }
}
class Screen1 extends StatefulWidget {
  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  late File UserCityFile;
  var selectedValue = TextEditingController();
  late String textValue = selectedValue.text;
  String key = 'CWA-15D3F278-DD19-4A8A-8749-96E501C29814';
  late String apiUrl; // 使用 'late' 來延遲初始化
  // 定義 API 的 URL
  WeatherStation? weatherStation;

  @override
  void initState() {
    super.initState();
    // 在初始化階段（Widget 第一次描繪時）觸發 API 請求

    _UserCity.then((file) => file.exists()).then((exists) async {
      if (exists){
        selectedValue.text = await readUserCity();
        print(selectedValue.text);
      }
      else{
        UserCityFile = await _UserCity;
        await UserCityFile.create(); // 確保 UserCityFile 被初始化
        await writeUserCity('臺北'); // 等待寫入完成
        selectedValue.text = '臺北'; // 更新選擇的值
        textValue = selectedValue.text;
        print(selectedValue.text);
      }

      // 在這裡觸發其他需要在 _UserCity 完成後執行的操作
      _fetchApiData(); // 這個操作應該也是在 _UserCity 完成後執行的
    });
  }



  void updateApiUrl() {
    apiUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-A0003-001?Authorization=$key&StationName=$textValue';
  }


  void _fetchApiData() {
    print('Fetching API data...');
    // 在這裡執行實際的 API 請求邏輯
    // 可能涉及到異步處理（例如使用 async/await）
    updateApiUrl();
    fetchData().then((data) {
      setState(() {
        weatherStation = data;
      });

      // 在這裡加入 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('資料已更新'),
          duration: Duration(seconds: 1), // 設定 SnackBar 顯示的時間
        ),
      );
    }).catchError((error) {
      print(error);
    });
  }
  Widget _buildWeatherImage(String weather) {
    String imagePath = '';

    switch (weather.toLowerCase()) {
      case '晴':
        imagePath = 'assets/sun.png'; // 假設你的圖片在 assets 資料夾下
        break;
      case '陰':
        imagePath = 'assets/cloudy.png';
        break;
      case '陰有雨':
        imagePath = 'assets/rainy.png';
        break;
    // 其他天氣狀況的處理...
      default:
        imagePath = 'assets/default.png'; // 預設圖片
    }

    return Image.asset(
      imagePath,
      width: 200.0,
      height: 200.0,
    );
  }

  Future<WeatherStation> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return WeatherStation.fromJson(data['records']['Station'][0]);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: weatherStation != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('選擇城市：',style: TextStyle(fontSize: 24.0)),
            DropdownButton<String>(
              value: textValue,
              onChanged: (String? newValue) {
                setState(() {
                  textValue = newValue!;
                  writeUserCity(textValue);
                  updateApiUrl(); // 在這裡更新 API URL
                  _fetchApiData(); // 重新抓取數據
                });
              },
              items: <String>[
                '臺北', '新北', '基隆', '新竹' , '宜蘭' , '臺中',
                '高雄', '臺南', '嘉義', '澎湖' , '花蓮' , '臺東'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,style: TextStyle(fontSize: 24.0),),
                );
              }).toList(),
            ),
            _buildWeatherImage(weatherStation!.weatherElement.weather),
            Text('城市： ${weatherStation!.geoInfo.countyName}', style: TextStyle(fontSize: 24.0)),
            Text('天氣情況： ${weatherStation!.weatherElement.weather}', style: TextStyle(fontSize: 24.0)),
            Text('目前溫度： ${weatherStation!.weatherElement.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('最高溫度： ${weatherStation!.weatherElement.dailyExtreme.dailyHigh.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('最低溫度： ${weatherStation!.weatherElement.dailyExtreme.dailyLow.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('資料時間： ${weatherStation!.weatherElement.datetime.substring(0,19).split("T")}', style: TextStyle(fontSize: 20.0)),
          ],
        )
            : CircularProgressIndicator(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 點擊按鈕時觸發更新資料的邏輯
          _fetchApiData();
        },
        tooltip: '更新資料',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class GeoInfo {
  String countyName;

  GeoInfo({
    required this.countyName,
  });

  factory GeoInfo.fromJson(Map<String, dynamic> json) {
    return GeoInfo(
      countyName: json['CountyName'],
    );
  }
}

class WeatherElement {
  String weather;
  DailyExtreme dailyExtreme;
  double airTemperature;
  String datetime;

  WeatherElement({
    required this.weather,
    required this.dailyExtreme,
    required this.airTemperature,
    required this.datetime,
  });

  factory WeatherElement.fromJson(Map<String, dynamic> json) {
    return WeatherElement(
      weather: json['Weather'],
      dailyExtreme: DailyExtreme.fromJson(json['DailyExtreme']),
      airTemperature: (json['AirTemperature'] != null)
          ? json['AirTemperature'].toDouble()
          : 0.0,
      datetime: (json['Max10MinAverage'] != null &&
          json['Max10MinAverage']['Occurred_at'] != null &&
          json['Max10MinAverage']['Occurred_at']['DateTime'] != null)
          ? json['Max10MinAverage']['Occurred_at']['DateTime']
          : '',
    );
  }

}

class DailyExtreme {
  TemperatureInfo dailyLow;
  TemperatureInfo dailyHigh;

  DailyExtreme({
    required this.dailyLow,
    required this.dailyHigh,
  });

  factory DailyExtreme.fromJson(Map<String, dynamic> json) {
    return DailyExtreme(
      dailyLow: TemperatureInfo.fromJson(json['DailyLow']['TemperatureInfo'] ?? {}),
      dailyHigh: TemperatureInfo.fromJson(json['DailyHigh']['TemperatureInfo'] ?? {}),
    );
  }
}


class TemperatureInfo {
  double airTemperature;

  TemperatureInfo({
    required this.airTemperature,
  });

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) {
    return TemperatureInfo(
      airTemperature: json['AirTemperature'] != null ? json['AirTemperature'].toDouble() : 0.0,
    );
  }
}


class screen2 extends StatefulWidget {
  const screen2({super.key});

  @override
  State<screen2> createState() => _screen2State();
}

class _screen2State extends State<screen2> {
  late File userCityFile;
  var selectedValue = TextEditingController();
  String textValue = ''; // 初始化 textValue 為空字符串
  String key = 'CWA-15D3F278-DD19-4A8A-8749-96E501C29814';
  String apiUrl = ''; // 使用 'late' 來延遲初始化
  Map<String, dynamic>? data; // 將 data 設置為可選的 Map<String, dynamic>

  @override
  void initState() {
    super.initState();

    settextvalue().then((_) {
      updateApiUrl();
      fetchDataAndUpdateData();
    });
  }

  Future<void> settextvalue() async {
    await _UserCity.then((file) => file.exists()).then((exists) async {
      String? value;
      if (exists) {
        value = await readUserCity();
      } else {
        userCityFile = await _UserCity;
        await userCityFile.create();
        await writeUserCity('臺北');
        value = '臺北';
      }

      setState(() {
        if (value != null) {
          selectedValue.text = value!;
          textValue = selectedValue.text;
          if (textValue == '臺北' || textValue == '新北' || textValue == '高雄' ||
              textValue == '新竹' || textValue == '臺中' || textValue == '臺南' ||
              textValue == '基隆') {
            textValue += '市';
          } else {
            textValue += '縣';
          }
          // 確保在 textValue 被設置後再更新 apiUrl
          updateApiUrl();
        }
      });
    });
  }

  Future<void> fetchDataAndUpdateData() async {
    try {
      Map<String, dynamic> result = await fetchData();
      if (result.isNotEmpty) { // 確保 result 不為空才進行更新
        setState(() {
          data = result;
        });
      }
    } catch (error) {
      print(error);
    }
  }


  void updateApiUrl() {
    apiUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=$key&locationName=$textValue';
  }

  Future<Map<String, dynamic>> fetchData() async {
    Map<String, dynamic> result = {};
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        var location = data['records']['location'][0];
        String locationName = location['locationName'];
        List<dynamic> weatherElements = location['weatherElement'];

        Map<String, Map<String, dynamic>> extractedData = {};

        // 遍歷每個天氣元素
        for (var weatherElement in weatherElements) {
          String elementName = weatherElement['elementName'];
          List<dynamic> timeData = weatherElement['time'];

          // 提取所有時間點的資訊
          for (var time in timeData) {
            String startTime = time['startTime'];
            String endTime = time['endTime'];
            Map<String, dynamic> parameter = time['parameter'];

            if (!extractedData.containsKey(startTime)) {
              extractedData[startTime] = {
                'startTime': startTime,
                'endTime': endTime,
                'Wx': '',
                'MaxT': '',
                'MinT': '',
                'CI': '',
                'PoP': ''
              };
            }

            switch (elementName) {
              case 'Wx':
                extractedData[startTime]!['Wx'] = parameter['parameterName'] ?? '';
                break;
              case 'MaxT':
                extractedData[startTime]!['MaxT'] = parameter['parameterName'] ?? '';
                break;
              case 'MinT':
                extractedData[startTime]!['MinT'] = parameter['parameterName'] ?? '';
                break;
              case 'CI':
                extractedData[startTime]!['CI'] = parameter['parameterName'] ?? '';
                break;
              case 'PoP':
                extractedData[startTime]!['PoP'] = parameter['parameterName'] ?? '';
                break;
            }
          }
        }

        result = {
          'locationName': locationName,
          'weatherInfo': extractedData.values.toList()
        };
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    print('Data: $data'); // 檢查資料是否為 null
    if (data != null) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('地點：${data!['locationName']}', style: TextStyle(fontSize:24)),
                SizedBox(height: 10),
                Text('預測36小時天氣資訊：', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                // 遍歷 data 中的所有天氣資訊項目
                for (var weatherInfo in data!['weatherInfo'])
                  WeatherTimeWidget(
                    startTime: weatherInfo['startTime'],
                    endTime: weatherInfo['endTime'],
                    weatherInfo: weatherInfo,
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      print('Data is null, triggering API fetch...');
      // 在資料還未加載完成時，顯示加載指示器
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // 顯示加載指示器
        ),
      );
    }
  }
}

class WeatherTimeWidget extends StatelessWidget {
  final String startTime;
  final String endTime;
  final Map<String, dynamic> weatherInfo;

  const WeatherTimeWidget({
    required this.startTime,
    required this.endTime,
    required this.weatherInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('時間：$startTime~${endTime.substring(11)}', style: TextStyle(fontSize: 20)),
        Text('天氣現象：${weatherInfo['Wx']}', style: TextStyle(fontSize: 20)),
        Text('最高溫度：${weatherInfo['MaxT']}', style: TextStyle(fontSize: 20)),
        Text('最低溫度：${weatherInfo['MinT']}', style: TextStyle(fontSize: 20)),
        Text('舒適度：${weatherInfo['CI']}', style: TextStyle(fontSize: 20)),
        Text('降雨機率：${weatherInfo['PoP']}%', style: TextStyle(fontSize: 20)),
        SizedBox(height: 10),
      ],
    );
  }
}






