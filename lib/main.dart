import 'package:flutter/material.dart';
import 'package:flutter_carousel/flutter_carousel.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({ Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
// mock 轮播列表
  List<Widget> carouselList = [
    Container(
        color: Colors.deepOrange, child: Center(child: Text('111'))
    ),
    Container(
        color: Colors.amberAccent, child: Center(child: Text('222'))
    ),
    Container(
        color: Colors.pink, child: Center(child: Text('333'))
    ),
    Container(
        color: Colors.blue, child: Center(child: Text('444'))
    )
  ];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('轮播图'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 200.0,
                child: PageView.builder(itemBuilder: (context, index) {
                  return carouselList[index % carouselList.length];
                },),
              ),

              SizedBox(
                height: 200.0,
                child: Swiper(
                  indicatorAlignment: AlignmentDirectional.bottomEnd,
                  speed: 400,
                  controller: SwiperController(initialPage: 1),
                  // viewportFraction: .95,
                  indicator: CircleSwiperIndicator(),
                  onChanged: (index) => debugPrint('$index'),
                  children: carouselList
                      .map((e) => Padding(
                      child: e,
                      padding: const EdgeInsets.symmetric(horizontal: 1)))
                      .toList(),
                ),
              ),
              AspectRatio(
                aspectRatio: 16.0 / 9.0,
                child: Swiper(
                  indicatorAlignment: AlignmentDirectional.bottomCenter,
                  circular: true,
                  indicator: RectangleSwiperIndicator(),
                  children: carouselList,
                ),
              ),
              AspectRatio(
                aspectRatio: 16.0 / 9.0,
                child: Swiper.builder(
                  indicatorAlignment: AlignmentDirectional.topStart,
                  direction: Axis.vertical,
                  circular: true,
                  childCount: carouselList.length,
                  indicator: NumberSwiperIndicator(),
                  itemBuilder: (context, index) => carouselList[index],
                ),
              ),
            ]
                .map((e) => Padding(
                child: e, padding: const EdgeInsets.symmetric(vertical: 10)))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class NumberSwiperIndicator extends SwiperIndicator {
  @override
  Widget build(BuildContext context, int index, int itemCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin: const EdgeInsets.only(top: 10.0, right: 5.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: Text(
        "${++index}/$itemCount",
        style: const TextStyle(color: Colors.white70, fontSize: 11.0),
      ),
    );
  }
}