import 'package:flutter/material.dart';
import 'package:infinite_scroll_tab_view/infinite_scroll_tab_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfiniteScrollTabView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfiniteScrollTabView Demo'),
      ),
      body: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({Key? key}) : super(key: key);

  @override
  __ContentState createState() => __ContentState();
}

class __ContentState extends State<_Content> {
  final contents = List.generate(9, (index) => index + 1)..shuffle();

  String _convertContent(int number) =>
      List.generate(number, (_) => '$number').join('');

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTabView(
      contentLength: contents.length,
      onTabTap: (index) {
        debugPrint('tapped $index');
      },
      tabBuilder: (index, isSelected) => Text(
        _convertContent(contents[index]),
        style: TextStyle(
          color: isSelected ? Colors.pink : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      separator: const BorderSide(color: Colors.black12, width: 2.0),
      onPageChanged: (index) => debugPrint('page changed to $index.'),
      indicatorColor: Colors.pink,
      pageBuilder: (context, index, _) {
        return SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(contents[index] / 10),
            ),
            child: Center(
              child: Text(
                _convertContent(contents[index]),
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                      color: contents[index] / 10 > 0.6
                          ? Colors.white
                          : Colors.black87,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
