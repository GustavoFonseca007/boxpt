import 'package:flutter/material.dart';
import 'package:eco/graficoremo.dart';

class HorizontalRemo extends StatefulWidget {
  @override
  _HorizontalRemoState createState() => _HorizontalRemoState();
}

class _HorizontalRemoState extends State<HorizontalRemo>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation =
        Tween<double>(begin: 0, end: 0.75).animate(_animationController!);
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remo'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RotationTransition(
              turns: _animation!,
              child: Image.asset(
                'images/rotaçao.png',
                width: 200,
              ),
            ),
          ),
          SizedBox(height: 150),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              minimumSize: Size(280, 50),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GraficoRemo()),
              );
            },
            child: Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
