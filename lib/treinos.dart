import 'package:flutter/material.dart';
import 'package:eco/remo.dart';

class Treino extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treinos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20.0, 120.0, 20.0, 0.0),
        child: GridView.count(
          crossAxisCount: 2,
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => Remo()),
                // );
              },
              child: Image.asset('images/esteira.png'),
            ),
            GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => SecondPhotoPage()),
                // );
              },
              child: Image.asset('images/bicicleta.png'),
            ),
            GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ThirdPhotoPage()),
                // );
              },
              child: Image.asset('images/treino3.png'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RowingMachineScreen()),
                );
              },
              child: Image.asset('images/remo.png'),
            ),
          ],
        ),
      ),
    );
  }
}
