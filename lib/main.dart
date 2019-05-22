import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/async.dart' as q;
import 'package:quiver/iterables.dart';

/// a millisecond
const ms = Duration(milliseconds: 1);

// grey color
const grey = Color(0xaa404040);

// dark grey color
const darkGrey = Color(0xcc1a1a1a);

// yellow color
const yellow = Colors.yellow;

/// sound MethodChannel : permet d'envoyer les "instructions de génération sonore"
/// à la platform ( ios ou android )
const soundChannel = const MethodChannel('bz.rxla/tone');

/// envoie une liste d'instruction
playSounds(Iterable<int> ids) =>
    soundChannel.invokeMethod('play', ids.toList());

/// génére un painter coloré
Paint paintWith(Color c) => Paint()..color = c;

/// calcul le tempo correspondant à un interval en mms
tempoFor(int interval) => 60 ~/ (interval / 1000);

void main() => runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: SafeArea(
        child: Scaffold(
            backgroundColor: darkGrey, body: SizedBox.expand(child: App())))));

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  /// index de la colonne active
  int currentColumnIndex = -1;

  /// interval de déplacement de "la tête de lecture"
  int interval = 666;

  /// tableau des cases, une case rempli au départ pour l'exemple
  List<bool> cells = List.filled(8 * 6, false)..setRange(8, 9, [true]);

  /// ? streamer principal
  StreamController<int> streamer = StreamController.broadcast();

  /// souscription au strem
  StreamSubscription streamSubscription;

  /// ? overlay d'affichage des instructions et du tempo
  OverlayEntry overlay;

  /// flag d'affichage des instructions au lancement
  bool showInstruction = true;

  /// en cours de lecture ?
  get _isRunning => streamSubscription != null && !streamSubscription.isPaused;

  /// renderObject de l'app
  get rbx => context.findRenderObject() as RenderBox;

  /// methode de "conversion position"
  get ToLocalPosition => rbx.globalToLocal;

  /// hauteur du context
  get contextHeight => rbx.size.height;

  /// applique un changement d'état FIXME rm
  updateState(f) => setState(f);

  gp(o) => o.globalPosition;

  @override
  initState() {
    super.initState();

    streamer.stream.listen((t) => updateState(() => interval = t));
    streamer.add(interval);
    startAt(interval);
  }

  /// lance la lecture à partir de l'index transmis
  startAt(int t) {
    streamSubscription?.cancel();
    streamSubscription = q.Metronome.periodic(ms * t).listen((d) {
      currentColumnIndex = (currentColumnIndex + 1) % 48;
      playSounds(enumerate(List.generate(
              6, (i) => cells[(currentColumnIndex % 8) + (i * 8)]))
          .where((v) => v.value)
          .map((v) => v.index + 1));
      updateState(() {});
    });
  }

  /// pause le timer
  playPause() => _isRunning ? streamSubscription.pause() : startAt(interval);

  /// calcul le tempo à partir de la position finale du slider
  onNewInterval(Offset tempoSliderLastPosition) =>
      250 + (ToLocalPosition(tempoSliderLastPosition).dy / contextHeight * 750);

  ///
  onCellTap(int cellIndex) =>
      updateState(() => cells[cellIndex] = !cells[cellIndex]);

  /// correspondance entre la position du touch et la cellule du tableau
  int positionToCellIndex(Offset p) =>
      (p.dx / (rbx.size.width / 8)).floor() +
      (p.dy / (contextHeight / 6)).floor() * 8;

  @override
  build(BuildContext _) => GestureDetector(
      onDoubleTap: playPause,
      onVerticalDragStart: (o) => showTempoOverlay(ToLocalPosition(gp(o))),
      onVerticalDragUpdate: (o) => streamer.add(onNewInterval(gp(o)).toInt()),
      onVerticalDragEnd: (o) {
        overlay?.remove();
        updateState(() => startAt(interval));
      },
      onTapDown: (t) => onCellTap(positionToCellIndex(ToLocalPosition(gp(t)))),
      child: Stack(children: [
        Sq(cells, currentColumnIndex % 8, interval),
        InkWell(
          onTap: () => updateState(() => showInstruction = false),
          child: showInstruction
              ? Container(
                  color: darkGrey,
                  constraints: BoxConstraints.expand(),
                  child: Center(
                      child: Text(
                          'FLUTTY LOOPS\n'
                          'PAUSE / RESUME : Double tap\n'
                          'Change the tempo : Slide up/down\n'
                          'Turn on speakers & Tap to start',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: yellow, fontSize: 20, height: 3))))
              : SizedBox(),
        )
      ]));

  /// affiche
  showTempoOverlay(Offset pos) {
    overlay = OverlayEntry(builder: (_) => _buildTempoOverlay(pos));
    Overlay.of(context).insert(overlay);
  }

  _buildTempoOverlay(Offset pos) => Positioned(
      left: pos.dx - 30,
      child: SafeArea(
        child: Container(
            width: 60,
            height: contextHeight,
            color: darkGrey,
            child: StreamBuilder(
                stream: streamer.stream,
                builder: (_, s) =>
                    CustomPaint(painter: TPtr(tempoFor(s.data ?? interval))))),
      ));
}

class TPtr extends CustomPainter {
  final int t;
  TPtr(this.t);
  @override
  void paint(Canvas cv, Size sz) {
    var sh = sz.height;
    var h = sh * ((t - 60) / 180);
    cv.drawRect(Rect.fromPoints(Offset(sz.width, sh), Offset(0, sh - h)),
        paintWith(yellow));
  }

  @override
  bool shouldRepaint(TPtr old) => old.t != t;
}

class Sq extends StatelessWidget {
  final List<bool> ks;
  final int id, fq;
  const Sq(this.ks, this.id, this.fq);

  @override
  Widget build(BuildContext _) => Stack(children: [
        Positioned.fill(child: CustomPaint(painter: Grd(List.from(ks), id))),
        Positioned(right: 10, top: 10, child: Text('${tempoFor(fq)}bpm'))
      ]);
}

class Grd extends CustomPainter {
  final List<bool> ks;
  final int id;
  Grd(this.ks, this.id);

  @override
  void paint(Canvas cnv, Size sz) {
    final rbw = HSLColor.fromAHSL(1, 360 * id / 8, 1, .5).toColor();
    final btW = sz.width / 8;
    final btH = sz.height / 6;
    enumerate(List.generate(
        8 * 6, (i) => Offset(i % 8 * btW, (i / 8).floor() * btH))).forEach((p) {
      final r = Rect.fromPoints(p.value, p.value + Offset(btW - 4, btH - 4));
      final rr = RRect.fromRectAndRadius(r, Radius.circular(8));
      final on = ks[p.index];
      final color = on ? Color(0xff103335) : darkGrey;
      cnv.drawRRect(
          rr,
          (p.index % 8) == id
              ? paintWith(rbw.withOpacity(on ? 1 : .2))
              : paintWith(color));
    });
  }

  @override
  bool shouldRepaint(Grd p) => p.ks != ks || id != p.id;
}
