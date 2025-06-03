import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 40, // 水平间距
          runSpacing: 40, // 垂直间距
          alignment: WrapAlignment.start, // 子小部件对齐方式
          children: [
            Container(
              width: 500,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sensors, size: 40, color: Colors.white), // 图标
                    SizedBox(width: 10), // 图标与文本之间的间距
                    Text(
                      '数据采集',
                      style: TextStyle(
                        fontSize: 24, // 字体大小
                        fontWeight: FontWeight.bold, // 字体粗细
                        color: Colors.white, // 字体颜色
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 500,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 40, color: Colors.white), // 图标
                    SizedBox(width: 10), // 图标与文本之间的间距
                    Text(
                      '数据分析',
                      style: TextStyle(
                        fontSize: 24, // 字体大小
                        fontWeight: FontWeight.bold, // 字体粗细
                        color: Colors.white, // 字体颜色
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 500,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_sharp, size: 40, color: Colors.white), // 图标
                    SizedBox(width: 10), // 图标与文本之间的间距
                    Text(
                      '设备警报',
                      style: TextStyle(
                        fontSize: 24, // 字体大小
                        fontWeight: FontWeight.bold, // 字体粗细
                        color: Colors.white, // 字体颜色
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 500,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 40, color: Colors.white), // 图标
                    SizedBox(width: 10), // 图标与文本之间的间距
                    Text(
                      '系统设置',
                      style: TextStyle(
                        fontSize: 24, // 字体大小
                        fontWeight: FontWeight.bold, // 字体粗细
                        color: Colors.white, // 字体颜色
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
