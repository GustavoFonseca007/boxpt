import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class GraficoRemo extends StatefulWidget {
  @override
  _GraficoRemoState createState() => _GraficoRemoState();
}

class _GraficoRemoState extends State<GraficoRemo> {
  List<double> dados = [0, 10, 20, 30, 25, 20, 15, 10, 5];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );

    double minY = -20;
    double maxY = 60;
    double minX = 0;
    double maxX = dados.length.toDouble();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    Color corFundo = Colors.white;
    Color corEixo = Colors.black;
    Color corLinha = Colors.blue;

    double espessuraLinha = 2.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico-Remo'),
        centerTitle: true,
      ),
      body: Container(
        color: corFundo,
        child: CustomPaint(
          size: Size(width, height),
          painter: GraficoPainter(
            dados: dados,
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            corEixo: corEixo,
            corLinha: corLinha,
            espessuraLinha: espessuraLinha,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

class GraficoPainter extends CustomPainter {
  List<double> dados;
  double minX;
  double maxX;
  double minY;
  double maxY;
  Color corEixo;
  Color corLinha;
  double espessuraLinha;

  GraficoPainter({
    required this.dados,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.corEixo,
    required this.corLinha,
    required this.espessuraLinha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width;
    double height = size.height;

    double graficoWidth = width - 100;
    double graficoHeight = height - 100;

    Paint eixoX = Paint()
      ..color = corEixo
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(50, graficoHeight + 50),
      Offset(graficoWidth + 50, graficoHeight + 50),
      eixoX,
    );

    Paint eixoY = Paint()
      ..color = corEixo
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(50, 50),
      Offset(50, graficoHeight + 50),
      eixoY,
    );

    Paint linhaGrafico = Paint()
      ..color = corLinha
      ..strokeWidth = espessuraLinha;
    Path path = Path();
    for (int i = 0; i < dados.length; i++) {
      double x = (i / (maxX - minX)) * graficoWidth + 50;
      double y = graficoHeight -
          ((dados[i] - minY) / (maxY - minY)) * graficoHeight +
          50;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linhaGrafico);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
