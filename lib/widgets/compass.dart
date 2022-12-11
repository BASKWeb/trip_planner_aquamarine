import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../platform/orientation.dart' as orientation;
import '../util/optional.dart';
import 'map.dart';

class Compass extends StatefulWidget {
  const Compass({super.key});

  @override
  State<Compass> createState() => CompassState();
}

class CompassState extends State<Compass> {
  late final Stream<Position> positionStream;
  late final Stream<orientation.WithGeomagneticCorrection<double>>
      orientationStream;

  @override
  void initState() {
    super.initState();

    positionStream = () async* {
      await Permission.locationWhenInUse.request().isGranted;
      yield* Geolocator.getPositionStream();
    }()
        .asBroadcastStream();

    orientation.updateInterval = const Duration(microseconds: 100000 ~/ 6);
    orientationStream = orientation.withGeomagneticCorrection(
      Rx.combineLatest2(
        orientation.bearing,
        positionStream,
        orientation.WithSpaceTime.fromPosition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black45,
            brightness: Brightness.dark,
            primary: Colors.black45,
          ),
          scaffoldBackgroundColor: Colors.black,
        ),
        child: Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder(
                  stream: positionStream,
                  builder: (context, positionSnapshot) =>
                      positionSnapshot.hasData
                          ? Text(
                              formatPosition(positionSnapshot.data!),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const LinearProgressIndicator(),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder(
                      stream: orientationStream,
                      builder: (context, orientationSnapshot) => CompassDisk(
                        magnetic: Optional(orientationSnapshot.data?.value)
                                .map(orientation.radians) ??
                            0,
                        geomagneticCorrection: Optional(
                              orientationSnapshot
                                  .data?.geomagneticCorrection?.dec,
                            ).map(orientation.radians) ??
                            0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class CompassDisk extends StatelessWidget {
  const CompassDisk({
    super.key,
    required this.magnetic,
    required this.geomagneticCorrection,
  });
  final double magnetic, geomagneticCorrection;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: Transform.rotate(
          angle: -magnetic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -geomagneticCorrection,
                child: const CompassRose(),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 7 / 72,
                  child: CustomPaint(painter: CompassArrow()),
                ),
              )
            ],
          ),
        ),
      );
}

class CompassRose extends StatelessWidget {
  const CompassRose({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const CircleBorder(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const referenceSize = 0x180;
          final sizeBasis = min(
            min(constraints.maxWidth, constraints.maxHeight),
            referenceSize,
          );
          final largeText = TextStyle(
            fontSize: sizeBasis * 72 / referenceSize,
            fontWeight: FontWeight.bold,
          );
          final smallText = TextStyle(
            fontSize: sizeBasis * 32 / referenceSize,
            fontWeight: FontWeight.bold,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              ...['N', 'E', 'S', 'W'].mapIndexed(
                (index, element) => Transform.rotate(
                  angle: index * pi / 2,
                  child: Text(
                    element,
                    textAlign: TextAlign.center,
                    style: largeText,
                  ),
                ),
              ),
              ...['NE', 'SE', 'SW', 'NW'].mapIndexed(
                (index, element) => Transform.rotate(
                  angle: (index + .5) * pi / 2,
                  child: Text(
                    element,
                    textAlign: TextAlign.center,
                    style: smallText,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class CompassArrow extends CustomPainter {
  const CompassArrow();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..addPolygon(
          [
            Offset(size.width / 2, 0),
            Offset(0, size.height / 2),
            Offset(size.width / 2, size.height / 2)
          ],
          true,
        ),
      Paint()..color = const Color(0xffc84031),
    );
    canvas.drawPath(
      Path()
        ..addPolygon(
          [
            Offset(size.width / 2, 0),
            Offset(size.width, size.height / 2),
            Offset(size.width / 2, size.height / 2)
          ],
          true,
        ),
      Paint()..color = const Color(0xffb73327),
    );
    canvas.drawPath(
      Path()
        ..addPolygon(
          [
            Offset(size.width / 2, size.height),
            Offset(0, size.height / 2),
            Offset(size.width / 2, size.height / 2)
          ],
          true,
        ),
      Paint()..color = const Color(0xffbdc0c5),
    );
    canvas.drawPath(
      Path()
        ..addPolygon(
          [
            Offset(size.width / 2, size.height),
            Offset(size.width, size.height / 2),
            Offset(size.width / 2, size.height / 2)
          ],
          true,
        ),
      Paint()..color = const Color(0xffd1d3d7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
