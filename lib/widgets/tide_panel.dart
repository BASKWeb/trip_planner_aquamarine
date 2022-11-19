import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joda/time.dart';
import 'package:logging/logging.dart';

import '../providers/trip_planner_client.dart';

class GridSwatch {
  const GridSwatch({
    required this.hourly,
    required this.noon,
    required this.midnight,
  });
  GridSwatch.fromSeed(Color seed)
      : this(
          hourly: Color.lerp(seed, null, .5)!,
          noon: Color.lerp(seed, null, .25)!,
          midnight: Color.lerp(seed, Colors.black, .5)!,
        );

  final Color hourly, noon, midnight;
}

class OverlaySwatch {
  const OverlaySwatch({required this.text, required this.grid});
  OverlaySwatch.fromSeed(Color seed)
      : this(text: seed, grid: GridSwatch.fromSeed(seed));

  final Color text;
  final GridSwatch grid;
}

class TidePanel extends StatefulWidget {
  TidePanel({
    super.key,
    required this.client,
    required this.station,
    required this.t,
    this.graphWidth = 455,
    this.graphHeight = 231,
    OverlaySwatch? overlaySwatch,
    this.onTimeChanged,
  }) : overlaySwatch =
            overlaySwatch ?? OverlaySwatch.fromSeed(const Color(0xff999900));

  final TripPlannerClient client;
  final Station station;
  final Instant t;
  final double graphWidth, graphHeight;
  final OverlaySwatch overlaySwatch;
  final void Function(Instant t)? onTimeChanged;

  @override
  State<StatefulWidget> createState() => TidePanelState();
}

/// Represents a consistent time window configuration that is valid for the
/// graph.
class GraphTimeWindow {
  static DateTime _quantizeT0(DateTime t0, int days) {
    t0 = t0.withTimeAtStartOfDay();

    // tides.php; For a single-day graph at the fall-back transition, xtide
    // draws starting from 1 AM PDT.
    if (days == 1 && t0.isDst && !(t0 + const Period(days: 1)).isDst) {
      t0 += const Duration(hours: 1);
    }

    return t0;
  }

  GraphTimeWindow._(this.t0, this.t, this.days) {
    assert(t0 <= t && t <= t0 + timespan);
  }

  /// A graph time window where [t] falls on the leading day. [mayMove]
  /// determines whether we will adjust [t] if it falls outside the normal
  /// window due to DST quirks or instead change the window.
  factory GraphTimeWindow.leftAligned(DateTime t, int days, bool mayMove) {
    var t0 = _quantizeT0(t, days);

    if (t < t0) {
      // This can only happen if we're [12AM-1AM) on the fall-back transition in
      // a 1-day window, and we can only show this time on a multi-day window.
      if (mayMove) {
        t += const Duration(hours: 1);
      } else {
        days = 2;
        t0 = _quantizeT0(t, days);
      }
    }

    return GraphTimeWindow._(t0, t, days);
  }

  /// A graph time window where [t] falls on the trailing day. [mayMove]
  /// determines whether we will adjust [t] if it falls outside the normal
  /// window due to DST quirks or instead change the window.
  factory GraphTimeWindow.rightAligned(DateTime t, int days, bool mayMove) {
    var t0 = _quantizeT0(
      t - Period(days: t.time == Time.zero ? days : days - 1),
      days,
    );

    if (t < t0) {
      // This can only happen if we're (12AM-1AM) on the fall-back transition in
      // a 1-day window, and we can only show this time on a multi-day window.
      if (mayMove) {
        t += const Duration(hours: 1);
      } else {
        days = 2;
        t0 = _quantizeT0(t - const Period(days: 1), days);
      }
    } else if (t0 + Period(days: days) < t) {
      // This is the trailing end of a multi-day fall-back window.
      if (mayMove) {
        t -= const Duration(hours: 1);
      } else {
        t0 = _quantizeT0(t0 - const Period(days: 1), days);
      }
    }

    return GraphTimeWindow._(t0, t, days);
  }

  /// [t0] is set from the year, month, and day, and location of the given time,
  /// and is adjusted so that the window includes [t].
  ///
  /// The adjustment is chosen to minimize the number of changes while
  /// "scrolling", so `t < t0` will adjust to a right-aligned window and
  /// `t > t0 + timespan` will adjust to a left-aligned window.
  ///
  /// If [mayMove] is true, [t] may be adjusted instead to minimize the window
  /// adjustment in DST edge cases.
  factory GraphTimeWindow(DateTime t0, Instant t, int days, bool mayMove) {
    t0 = _quantizeT0(t0, days);

    if (t < t0) {
      return GraphTimeWindow.rightAligned(
        DateTime(t, t0.timeZone),
        days,
        mayMove,
      );
    } else if (t0 + Period(days: days) < t) {
      return GraphTimeWindow.leftAligned(
        DateTime(t, t0.timeZone),
        days,
        mayMove,
      );
    } else {
      return GraphTimeWindow._(t0, t, days);
    }
  }

  final DateTime t0;
  final Instant t;
  final int days;
  Duration get timespan => Duration(days: days);
  DateTime lerp(double f) => t0 + timespan * f;

  /// Creates a copy with the given overrides, potentially adjusting the window
  /// to contain [t]. If [mayMove] is true, [t] itself may be adjusted as well.
  GraphTimeWindow copyWith({
    DateTime? t0,
    Instant? t,
    int? days,
    required bool mayMove,
  }) =>
      GraphTimeWindow(t0 ?? this.t0, t ?? this.t, days ?? this.days, mayMove);

  /// Shifts a [GraphTimeWindow] by the given [Period]. If [t] falls on a DST
  /// edge case, it is adjusted. Furthermore, if [days] = 1,
  /// [Resolvers.fallBackLater] is used since xtide ends up shifting the graph
  /// start by an hour anyway; combined with the [t] adjustment for [12AM-1AM),
  /// this creates a continuous mapping.
  GraphTimeWindow operator +(Period period) {
    return copyWith(
      t0: t0.add(period, fallBack: Resolvers.fallBackLater),
      t: DateTime(t, t0.timeZone)
          .add(period, fallBack: Resolvers.fallBackLater),
      mayMove: true,
    );
  }
}

class TidePanelState extends State<TidePanel> {
  late GraphTimeWindow timeWindow = GraphTimeWindow.leftAligned(
    DateTime(widget.t, widget.client.timeZone),
    1,
    false,
  );

  @override
  void didUpdateWidget(TidePanel oldWidget) {
    timeWindow = timeWindow.copyWith(t: widget.t, mayMove: false);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: visual feedback of current selections (today/weekend/days)
    // TODO: date picker
    return SizedBox(
      width: widget.graphWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: FittedBox(
              child: Text(
                '${widget.station.type == 'tide' ? 'Tide Height' : 'Currents'}: ${widget.station.shortTitle}',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          FittedBox(
            child: TideGraph(
              client: widget.client,
              station: widget.station,
              timeWindow: timeWindow,
              width: widget.graphWidth,
              height: widget.graphHeight,
              overlaySwatch: widget.overlaySwatch,
              onTimeChanged: widget.onTimeChanged,
            ),
          ),
          FittedBox(
            child: TimeControls(
              timeZone: widget.client.timeZone,
              timeWindow: timeWindow,
              onWindowChanged: (timeWindow) {
                setState(() => this.timeWindow = timeWindow);
                widget.onTimeChanged?.call(timeWindow.t);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TideGraph extends StatefulWidget {
  static const dayLabels = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  const TideGraph({
    super.key,
    required this.client,
    required this.station,
    required this.timeWindow,
    required this.width,
    required this.height,
    required this.overlaySwatch,
    this.onTimeChanged,
  });

  final TripPlannerClient client;
  final Station station;
  final GraphTimeWindow timeWindow;
  final double width, height;
  int get imageWidth => width.round();
  int get imageHeight => height.round() + 81;
  final OverlaySwatch overlaySwatch;
  final void Function(DateTime t)? onTimeChanged;

  @override
  State<StatefulWidget> createState() => TideGraphState();

  Stream<Uint8List> getTideGraph() => client.getTideGraph(
        station,
        timeWindow.days,
        imageWidth,
        imageHeight,
        timeWindow.t0,
      );

  bool isGraphDirty(TideGraph oldWidget) =>
      client != oldWidget.client ||
      station != oldWidget.station ||
      timeWindow.days != oldWidget.timeWindow.days ||
      imageWidth != oldWidget.imageWidth ||
      imageHeight != oldWidget.imageHeight ||
      timeWindow.t0 != oldWidget.timeWindow.t0;
}

class TideGraphState extends State<TideGraph> {
  static final log = Logger('TideGraphState');

  late Stream<Uint8List> graphImages = widget.getTideGraph();

  @override
  void didUpdateWidget(covariant TideGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isGraphDirty(oldWidget)) {
      graphImages = widget.getTideGraph();
    }
  }

  @override
  Widget build(BuildContext context) {
    int gridDivisions = widget.timeWindow.days == 7 ? 14 : 24;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(color: widget.overlaySwatch.text),
        child: Stack(
          children: [
            Positioned(
              top: -37,
              child: StreamBuilder(
                stream: graphImages,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.requireData,
                      width: widget.imageWidth.toDouble(),
                      height: widget.imageHeight.toDouble(),
                      gaplessPlayback: true,
                    );
                  } else {
                    if (snapshot.hasError) {
                      log.warning(
                        'Failed to fetch tide graph.',
                        snapshot.error,
                        snapshot.stackTrace,
                      );
                    }
                    return const Text('...');
                  }
                },
              ),
            ),
            for (int t = 1; t < gridDivisions; ++t)
              Positioned(
                left: t * widget.width / gridDivisions,
                top: 0,
                bottom: 0,
                child: _HourGrid(
                  widget.timeWindow.lerp(t / gridDivisions),
                  swatch: widget.overlaySwatch.grid,
                ),
              ),
            for (int d = 0; d < widget.timeWindow.days; ++d)
              Positioned(
                left: d * widget.width / widget.timeWindow.days,
                width: widget.width / widget.timeWindow.days,
                bottom: 0,
                child: Text(
                  TideGraph.dayLabels[widget.timeWindow
                      .lerp((d + .5) / widget.timeWindow.days)
                      .weekday],
                  textAlign: TextAlign.center,
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _HourGrid extends StatelessWidget {
  const _HourGrid(this.t, {required this.swatch});

  final Time t;
  int get hour => t.hour;
  String get label => hour == 0
      ? 'm'
      : hour == 12
          ? 'n'
          : (hour % 12).toString();

  final GridSwatch swatch;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 0,
        child: Stack(
          children: [
            OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.topCenter,
              child: Text(label),
            ),
            VerticalDivider(
              color: hour == 0
                  ? swatch.midnight
                  : hour == 12
                      ? swatch.noon
                      : swatch.hourly,
            ),
          ],
        ),
      );
}

class TimeControls extends StatelessWidget {
  const TimeControls({
    super.key,
    required this.timeZone,
    required this.timeWindow,
    this.onWindowChanged,
  });

  final TimeZone timeZone;
  final GraphTimeWindow timeWindow;
  final void Function(GraphTimeWindow window)? onWindowChanged;

  void Function()? _changeTime(int days) => onWindowChanged == null
      ? null
      : () => onWindowChanged!(timeWindow + Period(days: days));

  void Function()? _changeDays(int days) => onWindowChanged == null
      ? null
      : () => onWindowChanged!(
            timeWindow.copyWith(days: days, mayMove: true),
          );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        dividerTheme:
            theme.dividerTheme.copyWith(indent: 8, endIndent: 8, space: 8),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: Size.zero),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            IconButton(
              onPressed: _changeTime(-1),
              icon: const Icon(Icons.keyboard_arrow_left),
            ),
            const Text('Day'),
            IconButton(
              onPressed: _changeTime(1),
              icon: const Icon(Icons.keyboard_arrow_right),
            ),
            const VerticalDivider(),
            IconButton(
              onPressed: _changeTime(-7),
              icon: const Icon(Icons.keyboard_double_arrow_left),
            ),
            const Text('Week'),
            IconButton(
              onPressed: _changeTime(7),
              icon: const Icon(Icons.keyboard_double_arrow_right),
            ),
            const VerticalDivider(),
            TextButton(
              onPressed: onWindowChanged == null
                  ? null
                  : () {
                      onWindowChanged!(
                        GraphTimeWindow.leftAligned(
                          DateTime.now(timeZone),
                          1,
                          true,
                        ),
                      );
                    },
              child: const Text('Today'),
            ),
            const VerticalDivider(),
            TextButton(
              onPressed: onWindowChanged == null
                  ? null
                  : () {
                      onWindowChanged!(
                        GraphTimeWindow.leftAligned(
                          DateTime.resolve(
                            DateTime.now(timeZone)
                                    .date
                                    .nextWeekday(core.DateTime.saturday) &
                                // This construct does get simpler if we don't
                                // try to preserve the selected time.
                                DateTime(timeWindow.t, timeZone).time,
                            timeZone,
                          ),
                          2,
                          true,
                        ),
                      );
                      // Even if it's Sunday, go to next Saturday.
                    },
              child: const Text('Weekend'),
            ),
            const VerticalDivider(),
            for (final days in const [1, 2, 4, 7])
              TextButton(
                onPressed: _changeDays(days),
                child: Text(days.toString()),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('days'),
            ),
          ],
        ),
      ),
    );
  }
}
