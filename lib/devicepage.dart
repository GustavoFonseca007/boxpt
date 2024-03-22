// import 'package:charts_flutter_new/flutter.dart' as charts;
// import 'package:flutter/material.dart';

// class RowingDataChart extends StatelessWidget {
//   final List<charts.Series> seriesList;

//   RowingDataChart(this.seriesList);

//   @override
//   Widget build(BuildContext context) {
//     return new charts.LineChart(seriesList);
//   }
// }

// // Exemplo de como formatar os dados da máquina de remo para uso com o gráfico
// List<charts.Series<RowingData, int>> formatRowingDataForChart(
//     List<RowingData> data) {
//   return [
//     new charts.Series<RowingData, int>(
//       id: 'RowingData',
//       colorFn: (RowingData data, _) => charts.MaterialPalette.blue.shadeDefault,
//       domainFn: (RowingData data, _) => data.time,
//       measureFn: (RowingData data, _) => data.value,
//       data: data,
//     )
//   ];
// }

// class RowingData {
//   final int time;
//   final int value;

//   RowingData(this.time, this.value);
// }

// class MyChartPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // Dados de exemplo
//     final data = [
//       RowingData(0, 5),
//       RowingData(1, 25),
//       RowingData(2, 100),
//       RowingData(3, 75),
//     ];

//     // Formatar os dados para uso com o gráfico
//     final seriesList = formatRowingDataForChart(data);

//     // Criar uma instância de RowingDataChart com os dados formatados
//     final chart = RowingDataChart(seriesList);

//     return Scaffold(
//       body: Center(
//         child: chart,
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// class DevicePage extends StatefulWidget {
//   @override
//   _DevicePageState createState() => _DevicePageState();
// }

// class _DevicePageState extends State<DevicePage> {
//   final flutterReactiveBle = FlutterReactiveBle();
//   final deviceId = "F5:C0:00:0C:57:AB";
//   final serviceUuid = "00001826-0000-1000-8000-00805f9b34fb";
//   final uuids = [
//     "00002a99-0000-1000-8000-00805f9b34fb",
//     "00002a9a-0000-1000-8000-00805f9b34fb",
//     "00002a9f-0000-1000-8000-00805f9b34fb",
//     "0000ffe9-0000-1000-8000-00805f9b34fb",
//     "0000ffe0-0000-1000-8000-00805f9b34fb",
//     "0000f202-0000-1000-8000-00805f9b34fb",
//     "00002a00-0000-1000-8000-00805f9b34fb",
//     "00002a01-0000-1000-8000-00805f9b34fb",
//     "00002a29-0000-1000-8000-00805f9b34fb",
//     "00002a24-0000-1000-8000-00805f9b34fb",
//     "00002a25-0000-1000-8000-00805f9b34fb",
//     "00002a27-0000-1000-8000-00805f9b34fb",
//     "00002a26-0000-1000-8000-00805f9b34fb",
//     "00002a28-0000-1000-8000-00805f9b34fb",
//     "00002a23-0000-1000-8000-00805f9b34fb",
//     "00002a2a-0000-1000-8000-00805f9b34fb",
//     "49535343-026e-3a9b-954c-97daef17e26e",
//     "49535343-aca3-481c-91ec-d85e28a60318",
//     "49535343-1e4d-4bd9-ba61-23c647249616",
//     "49535343-8841-43f4-a8d4-ecbe34729bb3",
//     "49535343-4c8a-39b3-2f49-511cff073b7e",
//     "00002acc-0000-1000-8000-00805f9b34fb",
//     "00002acd-0000-1000-8000-00805f9b34fb",
//     "00002ace-0000-1000-8000-00805f9b34fb",
//     "00002acf-0000-1000-8000-00805f9b34fb",
//     "00002ad0-0000-1000-8000-00805f9b34fb",
//     "00002ad1-0000-1000-8000-00805f9b34fb",
//     "00002ad2-0000-1000-8000-00805f9b34fb",
//     "00002ad3-0000-1000-8000-00805f9b34fb",
//     "00002ad4-0000-1000-8000-00805f9b34fb",
//     "00002ad5-0000-1000-8000-00805f9b34fb",
//     "00002ad6-0000-1000-8000-00805f9b34fb",
//     "00002ad8-0000-1000-8000-00805f9b34fb",
//     "00002ad7-0000-1000-8000-00805f9b34fb",
//     "00002ad9-0000-1000-8000-00805f9b34fb",
//     "00002ada-0000-1000-8000-00805f9b34fb",
//     "d18d2c10-c44c-11e8-a355-529269fb1459",
//     "00002a8a-0000-1000-8000-00805f9b34fb",
//     "00002a90-0000-1000-8000-00805f9b34fb",
//     "00002a87-0000-1000-8000-00805f9b34fb",
//     "00002a80-0000-1000-8000-00805f9b34fb",
//     "00002a85-0000-1000-8000-00805f9b34fb",
//     "00002a8c-0000-1000-8000-00805f9b34fb",
//     "00002a98-0000-1000-8000-00805f9b34fb",
//     "00002a8e-0000-1000-8000-00805f9b34fb",
//     "00002a8d-0000-1000-8000-00805f9b34fb",
//     "00002a92-0000-1000-8000-00805f9b34fb",
//     "00002a91-0000-1000-8000-00805f9b34fb",
//     "00002a7f-0000-1000-8000-00805f9b34fb",
//     "00002a83-0000-1000-8000-00805f9b34fb",
//     "00002a93-0000-1000-8000-00805f9b34fb",
//     "00002a86-0000-1000-8000-00805f9b34fb",
//     "00002a97-0000-1000-8000-00805f9b34fb",
//     "00002a8f-0000-1000-8000-00805f9b34fb",
//     "00002a88-0000-1000-8000-00805f9b34fb",
//     "00002a89-0000-1000-8000-00805f9b34fb",
//     "00002a7e-0000-1000-8000-00805f9b34fb",
//     "0000ffb1-0000-1000-8000-00805f9b34fb"
//   ];

//   List<QualifiedCharacteristic> characteristics = [];
//   Map<Uuid, List<int>> characteristicValues = {};
//   List<int> eventValue = [];

//   @override
//   void initState() {
//     super.initState();
//     characteristics = uuids
//         .map((uuid) => QualifiedCharacteristic(
//               deviceId: deviceId,
//               serviceId: Uuid.parse(serviceUuid),
//               characteristicId: Uuid.parse(uuid),
//             ))
//         .toList();
//     print("Características a serem lidas: $characteristics");

//     for (final characteristic in characteristics) {
//       flutterReactiveBle
//           .subscribeToCharacteristic(characteristic)
//           .listen((event) {
//         setState(() {
//           characteristicValues[characteristic.characteristicId] = event;
//           eventValue = event;
//         });
//         print(
//             "Valor lido da característica ${characteristic.characteristicId}: $event");
//       });
//     }

//     readCharacteristics();
//   }

//   Future<void> readCharacteristics() async {
//     for (final uuid in uuids) {
//       final characteristic = QualifiedCharacteristic(
//         deviceId: deviceId,
//         serviceId: Uuid.parse(serviceUuid),
//         characteristicId: Uuid.parse(uuid),
//       );

//       final value = await flutterReactiveBle.readCharacteristic(characteristic);
//       print("Valor lido da característica $uuid: $value");
//     }
//   }

//   @override
//   @override
// Widget build(BuildContext context) {
//   // Acesse os valores das características relevantes
//   final speedValue = characteristicValues[
//       Uuid.parse("00002a99-0000-1000-8000-00805f9b34fb")];
//   final distanceValue = characteristicValues[
//       Uuid.parse("00002a9f-0000-1000-8000-00805f9b34fb")];
//   final elapsedTimeValue = characteristicValues[
//       Uuid.parse("00002a28-0000-1000-8000-00805f9b34fb")];

//   return Scaffold(
//     appBar: AppBar(
//       title: Text("Conexão com a máquina FTMS"),
//     ),
//     body: SingleChildScrollView(
//       child: Column(
//         children: [
//           // Exiba os valores das características relevantes na tela
//           ListTile(
//             title: Text('Velocidade média'),
//             subtitle: speedValue != null
//                 ? Text(speedValue.toString())
//                 : Text('Nenhum valor lido'),
//           ),
//           ListTile(
//             title: Text('Distância total'),
//             subtitle: distanceValue != null
//                 ? Text(distanceValue.toString())
//                 : Text('Nenhum valor lido'),
//           ),
//           ListTile(
//             title: Text('Tempo decorrido'),
//             subtitle: elapsedTimeValue != null
//                 ? Text(elapsedTimeValue.toString())
//                 : Text('Nenhum valor lido'),
//           ),
//         ],
//       ),
//     ),
//   );
// }}
