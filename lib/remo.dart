// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:eco/devicepage.dart';
// import 'package:flutter_ftms/flutter_ftms.dart';

// class RemoPage extends StatefulWidget {
//   @override
//   _RemoPageState createState() => _RemoPageState();
// }

// class _RemoPageState extends State<RemoPage> {
//   final FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
//   final FlutterFtms flutterFtms = FlutterFtms.instance;
//   List<BluetoothDevice> devicesList = [];
//   bool isSearching = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Remo'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             GestureDetector(
//               child: Icon(Icons.bluetooth_searching, size: 100),
//               onTap: () async {
//                 setState(() {
//                   isSearching = true;
//                 });
//                 await searchBluetoothDevices();
//                 setState(() {
//                   isSearching = false;
//                 });
//                 showModalBottomSheet(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: <Widget>[
//                         Padding(
//                           padding: EdgeInsets.only(top: 20),
//                           child: Text(
//                             'Dispositivos encontrados:',
//                             style: TextStyle(
//                               fontSize: 20,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         Expanded(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: devicesList.length,
//                             itemBuilder:
//                                 (BuildContext context, int index) {
//                               BluetoothDevice device = devicesList[index];
//                               return ListTile(
//                                 title:
//                                     Text(device.name ?? 'Unknown Device'),
//                                 subtitle: Text(device.id.toString()),
//                                 onTap: () async {
//                                   await Navigator.of(context).push(
//                                     MaterialPageRoute(
//                                       builder: (BuildContext context) =>
//                                           DevicePage(device),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 20),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             isSearching ? CircularProgressIndicator() : Container(),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> searchBluetoothDevices() async {
//     devicesList.clear();
//     flutterBluePlus.startScan(timeout: Duration(seconds: 4));
//     flutterBluePlus.scanResults.listen((results) {
//       for (ScanResult result in results) {
//         BluetoothDevice device = result.device;
//         if (device.name.startsWith("DFIT")) {
//           devicesList.add(device);
//         }
//       }
//     });
//     await flutterBluePlus.stopScan();
//     for (BluetoothDevice device in devicesList) {
//       await flutterFtms.connect(device);
//       if (await flutterFtms.isFtmsDevice()) {
//         print('${device.name} is an FTMS device');
//       } else {
//         print('${device.name} is not an FTMS device');
//       }
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class RowingMachineScreen extends StatefulWidget {
  @override
  _RowingMachineScreenState createState() => _RowingMachineScreenState();
}

class _RowingMachineScreenState extends State<RowingMachineScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? selectedDevice;
  Stream<List<int>>? dataStream;
  String strokeRate = 'N/A';
  String strokeCount = 'N/A';
  String averageStrokeRate = 'N/A';
  String totalDistance = 'N/A';
  String instantaneousPace = 'N/A';
  String averagePace = 'N/A';
  String instantaneousPower = 'N/A';
  String averagePower = 'N/A';
  String resistanceLevel = 'N/A';
  String totalEnergy = 'N/A';
  String energyPerHour = 'N/A';

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
      if (scanResult.device.name == 'DFIT-D-R-00734') {
        selectedDevice = scanResult.device;
        connectToDevice();
      }
    });
  }

  void connectToDevice() async {
    if (selectedDevice != null) {
      await selectedDevice!.connect();
      discoverServices();
    }
  }

  void discoverServices() async {
    if (selectedDevice != null) {
      List<BluetoothService> services =
          await selectedDevice!.discoverServices();
      services.forEach((service) {
        if (service.uuid.toString() == '00001826-0000-1000-8000-00805f9b34fb') {
          BluetoothCharacteristic characteristic = service.characteristics
              .firstWhere((c) =>
                  c.uuid.toString() == '00002a5d-0000-1000-8000-00805f9b34fb');
          characteristic.setNotifyValue(true);
          dataStream = characteristic.value;
          processData();
        }
      });
    }
  }

  void processData() {
    if (dataStream != null) {
      dataStream!.listen((data) {
        String receivedData = String.fromCharCodes(data);
        List<String> dataFields = receivedData.split(',');

        if (dataFields.length >= 10) {
          strokeRate = dataFields[0];
          strokeCount = dataFields[1];
          averageStrokeRate = dataFields[2];
          totalDistance = dataFields[3];
          instantaneousPace = dataFields[4];
          averagePace = dataFields[5];
          instantaneousPower = dataFields[6];
          averagePower = dataFields[7];
          resistanceLevel = dataFields[8];
          totalEnergy = dataFields[9];
          energyPerHour = dataFields[10];

          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rowing Machine'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Stroke Rate: $strokeRate'),
            Text('Stroke Count: $strokeCount'),
            Text('Average Stroke Rate: $averageStrokeRate'),
            Text('Total Distance: $totalDistance'),
            Text('Instantaneous Pace: $instantaneousPace'),
            Text('Average Pace: $averagePace'),
            Text('Instantaneous Power: $instantaneousPower'),
            Text('Average Power: $averagePower'),
            Text('Resistance Level: $resistanceLevel'),
            Text('Total Energy: $totalEnergy'),
            Text('Energy per Hour: $energyPerHour'),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter_blue/flutter_blue.dart';
// import 'package:eco/devicepage.dart';

// class RemoPage extends StatefulWidget {
//   @override
//   _RemoPageState createState() => _RemoPageState();
// }

// class _RemoPageState extends State<RemoPage> {
//   final FlutterBlue flutterBluePlus = FlutterBlue.instance;
//   List<BluetoothDevice> devicesList = [];
//   bool isSearching = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Remo'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             GestureDetector(
//               child: Icon(Icons.bluetooth_searching, size: 100),
//               onTap: () async {
//                 setState(() {
//                   isSearching = true;
//                 });
//                 await searchBluetoothDevices();
//                 setState(() {
//                   isSearching = false;
//                 });
//                 showModalBottomSheet(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: <Widget>[
//                         Padding(
//                           padding: EdgeInsets.only(top: 20),
//                           child: Text(
//                             'Dispositivos encontrados:',
//                             style: TextStyle(
//                               fontSize: 20,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         Expanded(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: devicesList.length,
//                             itemBuilder: (BuildContext context, int index) {
//                               BluetoothDevice device = devicesList[index];
//                               return ListTile(
//                                 title: Text(device.name ?? 'Unknown Device'),
//                                 subtitle: Text(device.id.toString()),
//                               );
//                             },
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 20),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//               onTapDown: (TapDownDetails details) async {
//                 if (devicesList.isNotEmpty) {
//                   int index = details.localPosition.dy ~/ 70;
//                   if (index < devicesList.length) {
//                     BluetoothDevice device = devicesList[index];
//                     await Navigator.of(context).push(MaterialPageRoute(
//                       builder: (BuildContext context) =>
//                           DevicePage(),
//                     ));
//                   }
//                 }
//               },
//             ),
//             SizedBox(height: 20),
//             isSearching ? CircularProgressIndicator() : Container(),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> searchBluetoothDevices() async {
//     devicesList.clear();
//     flutterBluePlus.startScan(timeout: Duration(seconds: 4));
//     flutterBluePlus.scanResults.listen((results) {
//       for (ScanResult result in results) {
//         BluetoothDevice device = result.device;
//         if (device.name.startsWith("DFIT")) {
//           devicesList.add(device);
//         }
//       }
//     });
//     await flutterBluePlus.stopScan();
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_ftms/flutter_ftms.dart';

// class FtmsExample extends StatefulWidget {
//   @override
//   _FtmsExampleState createState() => _FtmsExampleState();
// }

// class _FtmsExampleState extends State<FtmsExample> {
//   final FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
//   List<BluetoothDevice> devicesList = [];
//   bool isSearching = false;
//   String deviceData = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('FTMS Example'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             GestureDetector(
//               child: Icon(Icons.bluetooth_searching, size: 100),
//               onTap: () async {
//                 setState(() {
//                   isSearching = true;
//                 });
//                 await searchBluetoothDevices();
//                 setState(() {
//                   isSearching = false;
//                 });
//                 showModalBottomSheet(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: <Widget>[
//                         Padding(
//                           padding: EdgeInsets.only(top: 20),
//                           child: Text(
//                             'Dispositivos encontrados:',
//                             style: TextStyle(
//                               fontSize: 20,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         Expanded(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: devicesList.length,
//                             itemBuilder: (BuildContext context, int index) {
//                               BluetoothDevice device = devicesList[index];
//                               return ListTile(
//                                 title: Text(device.name ?? 'Unknown Device'),
//                                 subtitle: Text(device.id.toString()),
//                                 onTap: () async {
//                                   await connectToDevice(device);
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(bottom: 20),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             Text(deviceData),
//             SizedBox(height: 20),
//             isSearching ? CircularProgressIndicator() : Container(),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> searchBluetoothDevices() async {
//     devicesList.clear();
//     flutterBluePlus.startScan(timeout: Duration(seconds: 4));
//     flutterBluePlus.scanResults.listen((results) {
//       for (ScanResult result in results) {
//         BluetoothDevice device = result.device;
//         if (device.name.startsWith("DFIT")) {
//           devicesList.add(device);
//         }
//       }
//     });
//     await flutterBluePlus.stopScan();
//     for (BluetoothDevice device in devicesList) {
//       await FTMS.connectToFTMSDevice(device);
//       if (await FTMS.isBluetoothDeviceFTMSDevice(device)) {
//         print('${device.name} is an FTMS device');
//       } else {
//         print('${device.name} is not an FTMS device');
//       }
//     }
//   }

//   Future<void> connectToDevice(BluetoothDevice device) async {
//     await FTMS.connectToFTMSDevice(device);
//     bool isFTMSDevice = await FTMS.isBluetoothDeviceFTMSDevice(device);
//     if (isFTMSDevice) {
//       print('${device.name} is an FTMS device');
//       DeviceDataType? dataType = await FTMS.getDeviceDataType(device);
//       if (dataType != null) {
//         String deviceTypeString = FTMS.convertDeviceDataTypeToString(dataType);
//         print('Device type: $deviceTypeString');
//       }
//       await FTMS.useDeviceDataCharacteristic(device, (DeviceData data) {
//         // handle new data
//         setState(() {
//           deviceData = data.toString();
//         });
//       });
//       MachineFeature? feature =
//           await FTMS.readMachineFeatureCharacteristic(device);
//       if (feature != null) {
//         // handle feature object
//         print('Received machine feature from device');
//       }
//       await FTMS.useMachineStatusCharacteristic(device, (MachineStatus status) {
//         // handle new machine status
//         print('Received new machine status from device');
//       });
//     } else {
//       print('${device.name} is not an FTMS device');
//     }
//   }
// }
