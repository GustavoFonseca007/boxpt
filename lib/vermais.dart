import 'package:flutter/material.dart';

class VerMais extends StatelessWidget {
  const VerMais({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conquistas"),
      ),
      body: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Corredor",
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImageWithText(
                      'images/corredor.png', 'Nível 1\nCorra 1 km em 1 dia'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/corredor.png', 'Nível 2\nCorra 5 km em 1 dia'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/corredor.png', 'Nível 3\nCorra 10 km em 1 dia'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/corredor.png', 'Nível 4\nCorra 15 km em 1 dia'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/corredor.png', 'Nível 5\nCorra 20 km em 1 dia'),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Sempre a Remar!",
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImageWithText(
                      'images/remar.png', 'Nível 1\n5 Treinos no Remo'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/remar.png', 'Nível 2\n10 Treinos no Remo'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/remar.png', 'Nível 3\n15 Treinos no Remo'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/remar.png', 'Nível 4\n25 Treinos no Remo'),
                  SizedBox(width: 10),
                  _buildImageWithText(
                      'images/remar.png', 'Nível 5\n50 Treinos no Remo'),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Rei da Passadeira",
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImageWithText('images/corredor.png',
                      'Nível 1\n5 Treinos na Passadeira'),
                  SizedBox(width: 10),
                  _buildImageWithText('images/corredor.png',
                      'Nível 2\n10 Treinos na Passadeira'),
                  SizedBox(width: 10),
                  _buildImageWithText('images/corredor.png',
                      'Nível 3\n15 Treinos na Passadeira'),
                  SizedBox(width: 10),
                  _buildImageWithText('images/corredor.png',
                      'Nível 4\n25 Treinos na Passadeira'),
                  SizedBox(width: 10),
                  _buildImageWithText('images/corredor.png',
                      'Nível 5\n50 Treinos na Passadeira'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithText(String imagePath, String text) {
    return Container(
      width: 278,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20.0),
        color: null,
      ),
      child: Row(
        children: [
          SizedBox(width: 20),
          Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
          Spacer(),
          Image.asset(
            imagePath,
            width: 60,
            height: 60,
          ),
          SizedBox(width: 25),
        ],
      ),
    );
  }
}
