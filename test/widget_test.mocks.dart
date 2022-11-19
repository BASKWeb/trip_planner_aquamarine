// Mocks generated by Mockito 5.3.2 from annotations
// in trip_planner_aquamarine/test/widget_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:typed_data' as _i6;

import 'package:joda/time.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:trip_planner_aquamarine/persistence/blob_cache.dart' as _i2;
import 'package:trip_planner_aquamarine/providers/trip_planner_client.dart'
    as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeBlobCache_0 extends _i1.SmartFake implements _i2.BlobCache {
  _FakeBlobCache_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeTripPlannerHttpClient_1 extends _i1.SmartFake
    implements _i3.TripPlannerHttpClient {
  _FakeTripPlannerHttpClient_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeTimeZone_2 extends _i1.SmartFake implements _i4.TimeZone {
  _FakeTimeZone_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [TripPlannerClient].
///
/// See the documentation for Mockito's code generation for more information.
class MockTripPlannerClient extends _i1.Mock implements _i3.TripPlannerClient {
  @override
  _i2.BlobCache get tideGraphCache => (super.noSuchMethod(
        Invocation.getter(#tideGraphCache),
        returnValue: _FakeBlobCache_0(
          this,
          Invocation.getter(#tideGraphCache),
        ),
        returnValueForMissingStub: _FakeBlobCache_0(
          this,
          Invocation.getter(#tideGraphCache),
        ),
      ) as _i2.BlobCache);
  @override
  _i3.TripPlannerHttpClient get httpClient => (super.noSuchMethod(
        Invocation.getter(#httpClient),
        returnValue: _FakeTripPlannerHttpClient_1(
          this,
          Invocation.getter(#httpClient),
        ),
        returnValueForMissingStub: _FakeTripPlannerHttpClient_1(
          this,
          Invocation.getter(#httpClient),
        ),
      ) as _i3.TripPlannerHttpClient);
  @override
  _i4.TimeZone get timeZone => (super.noSuchMethod(
        Invocation.getter(#timeZone),
        returnValue: _FakeTimeZone_2(
          this,
          Invocation.getter(#timeZone),
        ),
        returnValueForMissingStub: _FakeTimeZone_2(
          this,
          Invocation.getter(#timeZone),
        ),
      ) as _i4.TimeZone);
  @override
  void close() => super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i5.Future<Set<_i3.Station>> getDatapoints() => (super.noSuchMethod(
        Invocation.method(
          #getDatapoints,
          [],
        ),
        returnValue: _i5.Future<Set<_i3.Station>>.value(<_i3.Station>{}),
        returnValueForMissingStub:
            _i5.Future<Set<_i3.Station>>.value(<_i3.Station>{}),
      ) as _i5.Future<Set<_i3.Station>>);
  @override
  _i5.Stream<_i6.Uint8List> getTideGraph(
    _i3.Station? station,
    int? days,
    int? width,
    int? height,
    _i4.Date? begin,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTideGraph,
          [
            station,
            days,
            width,
            height,
            begin,
          ],
        ),
        returnValue: _i5.Stream<_i6.Uint8List>.empty(),
        returnValueForMissingStub: _i5.Stream<_i6.Uint8List>.empty(),
      ) as _i5.Stream<_i6.Uint8List>);
}
