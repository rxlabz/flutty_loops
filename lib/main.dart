import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/async.dart' as q;
import 'package:quiver/iterables.dart';

const ms = Duration(milliseconds: 1);
const gr = Color(0xaa404040);
const grd = Color(0xcc1a1a1a);
const yLow = Colors.yellow;
const bip = const MethodChannel('bz.rxla/tone');

snd(Iterable<int> ids) => bip.invokeMethod('play', ids.toList());

Paint pnt(Color c) => Paint()..color = c;

tpo(f) => 60 ~/ (f / 1000);

void main() => runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: SafeArea(
        child: Scaffold(
            backgroundColor: grd, body: SizedBox.expand(child: App())))));

class App extends StatefulWidget {
  @override
  Stt createState() => Stt();
}

class Stt extends State<App> {
  int id = -1, fq = 666;
  List<bool> ks = List.filled(8 * 6, false)..setRange(8, 9, [true]);
  StreamController<int> st = StreamController.broadcast();
  StreamSubscription sub;
  OverlayEntry ovrl;
  bool introOn = true;
  get _on => sub != null && !sub.isPaused;
  get rbx => context.findRenderObject() as RenderBox;
  get gl => rbx.globalToLocal;
  get mqh => rbx.size.height;
  up(f) => setState(f);
  gp(o) => o.globalPosition;

  @override
  initState() {
    super.initState();
    st.stream.listen((t) => up(() => fq = t));
    st.add(fq);
    go(fq);
  }

  go(int t) {
    sub?.cancel();
    sub = q.Metronome.periodic(ms * t).listen((d) {
      id = (id + 1) % 48;
      snd(enumerate(List.generate(6, (i) => ks[(id % 8) + (i * 8)]))
          .where((v) => v.value)
          .map((v) => v.index + 1));
      up(() {});
    });
  }

  togl() => _on ? sub.pause() : go(fq);
  nwfq(Offset o) => 250 + (gl(o).dy / mqh * 750);
  tap(int p) => up(() => ks[p] = !ks[p]);
  int posId(Offset p) =>
      (p.dx / (rbx.size.width / 8)).floor() + (p.dy / (mqh / 6)).floor() * 8;

  @override
  build(BuildContext _) => GestureDetector(
      onDoubleTap: togl,
      onVerticalDragStart: (o) => ovr(gl(gp(o))),
      onVerticalDragUpdate: (o) => st.add(nwfq(gp(o)).toInt()),
      onVerticalDragEnd: (o) {
        ovrl?.remove();
        up(() => go(fq));
      },
      onTapDown: (t) => tap(posId(gl(gp(t)))),
      child: Stack(children: [
        Sq(ks, id % 8, fq),
        InkWell(
          onTap: () => up(() => introOn = false),
          child: introOn
              ? Container(
                  color: grd,
                  constraints: BoxConstraints.expand(),
                  child: Center(
                      child: Text(
                          'FLUTTY LOOPS\n'
                          'PAUSE / RESUME : Double tap\n'
                          'Change the tempo : Slide up/down\n'
                          'Turn on speakers & Tap to start',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: yLow, fontSize: 20, height: 3))))
              : SizedBox(),
        )
      ]));

  ovr(Offset pos) {
    ovrl = OverlayEntry(builder: (_) => _bldOvrl(pos));
    Overlay.of(context).insert(ovrl);
  }

  _bldOvrl(Offset pos) => Positioned(
      left: pos.dx - 30,
      child: SafeArea(
        child: Container(
            width: 60,
            height: mqh,
            color: grd,
            child: StreamBuilder(
                stream: st.stream,
                builder: (_, s) =>
                    CustomPaint(painter: TPtr(tpo(s.data ?? fq))))),
      ));
}

class TPtr extends CustomPainter {
  final int t;
  TPtr(this.t);
  @override
  void paint(Canvas cv, Size sz) {
    var sh = sz.height;
    var h = sh * ((t - 60) / 180);
    cv.drawRect(
        Rect.fromPoints(Offset(sz.width, sh), Offset(0, sh - h)), pnt(yLow));
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
        Positioned(right: 10, top: 10, child: Text('${tpo(fq)}bpm'))
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
      final color = on ? Color(0xff103335) : grd;
      cnv.drawRRect(rr,
          (p.index % 8) == id ? pnt(rbw.withOpacity(on ? 1 : .2)) : pnt(color));
    });
  }

  @override
  bool shouldRepaint(Grd p) => p.ks != ks || id != p.id;
}
