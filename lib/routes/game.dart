import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../model/scorer.dart';
import '../widgets/background.dart';
import '../widgets/bird.dart';
import '../widgets/pipe.dart';

class Game extends StatefulWidget {
  const Game({Key? key}) : super(key: key);

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  static const double birdX = 120;
  static const Size birdHitboxSize = Size(30, 40);
  static const double pipeWidth = 60;
  static const double accY = 0.1;
  static const double startingVelY = 5;
  static const double velX = 100;
  static const double startingBirdY = 350;
  static const int ticksInASecond = 60;
  static const int pipeGenerationDelay = 3;

  final int ticksDelay = (1000 / ticksInASecond).floor();

  bool isGameStarted = false;
  double birdY = startingBirdY;
  double startJumpY = startingBirdY;
  Timer? gameTimer;
  double velY = startingVelY;
  int time = 0;
  int score = 0;
  List<Pipe> pipes = [];
  late StreamController<int> _bestScoreController;

  late Rect floorRect;
  late final int oldBestScore;

  void jump() {
    print('jump');
    time = 0;
    velY = startingVelY;
    startJumpY = birdY;
  }

  void start() {
    isGameStarted = true;
    gameTimer = Timer.periodic(
      Duration(milliseconds: ticksDelay),
      (timer) {
        setState(() {
          velY -= accY;
          birdY = startJumpY - velY * time;
          if (birdY < 0 || birdY > floorRect.top) {
            gameOver();
          }

          if (timer.tick % (ticksInASecond * pipeGenerationDelay) == 1) {
            final List<Pipe> newPipe = getPipe();
            pipes.addAll(newPipe);
          }

          for (int i = 0; i < pipes.length; i++) {
            final Pipe p = pipes[i];
            final Rect newRect = Rect.fromLTWH(
              p.rect.left - velX / ticksInASecond,
              p.rect.top,
              p.rect.width,
              p.rect.height,
            );
            pipes[i] = Pipe(newRect);

            final birdRect = Rect.fromCenter(
              center: Offset(birdX, birdY),
              width: birdHitboxSize.width,
              height: birdHitboxSize.height,
            );

            if (birdRect.overlaps(p.rect)) {
              gameOver();
            }
          }
          if (score * 2 < pipes.length && pipes[score * 2].rect.left < birdX) {
            print(score++);
            if (score > oldBestScore) {
              _bestScoreController.sink.add(score);
            }
          }

          time++;
        });
      },
    );
    print('start');
  }

  void reset() {
    setState(() {
      isGameStarted = false;
      score = 0;
      time = 0;
      birdY = startingBirdY;
      startJumpY = birdY;
      velY = startingVelY;
      pipes = [];
    });
  }

  List<Pipe> getPipe() {
    // TODO: Move these numbers somewhere else
    final double gap = Random().nextDouble() * (200 - 120) + 120;
    final double gapBottom =
        Random().nextDouble() * (floorRect.top - gap - 50 * 2) + 50;

    final Rect topPipeRect = Rect.fromLTRB(
      //Rect.fromLTWH(
      floorRect.right,
      0,
      floorRect.right + pipeWidth,
      floorRect.top - gapBottom - gap,
    );
    final Rect bottomPipeRect = Rect.fromLTRB(
      floorRect.right,
      floorRect.top - gapBottom,
      floorRect.right + pipeWidth,
      floorRect.top,
    );
    return [Pipe(topPipeRect), Pipe(bottomPipeRect)];
  }

  void gameOver() async {
    gameTimer?.cancel();
    Scorer.storeIfBest(score);
    await showDialog(
        context: context,
        builder: (contetx) => const Dialog(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Game Over'),
              ),
            ));
    reset();
  }

  @override
  void initState() {
    _bestScoreController = StreamController<int>();
    Scorer.getBestScore().then((value) {
      oldBestScore = value;
      _bestScoreController.sink.add(value);
    });
    super.initState();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _bestScoreController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = Align(
      alignment: Alignment.center,
      child: Text(
        '$score',
        textScaleFactor: 4,
      ),
    );

    const tapToPlayText = Align(
      alignment: Alignment.center,
      child: Text(
        'T A P  T O  P L A Y',
        textScaleFactor: 3,
      ),
    );

    final bestScoreText = StreamBuilder(
      stream: _bestScoreController.stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Center(
            child: RichText(
              textScaleFactor: 3,
              text: TextSpan(
                children: [
                  const TextSpan(text: 'best score: '),
                  TextSpan(text: '${snap.data}'),
                ],
              ),
            ),
          );
        }
      },
    );

    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Scorer.reset(),
      // ),
      body: GestureDetector(
        onPanDown: (_) => isGameStarted ? jump() : start(),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            floorRect = Rect.fromLTWH(
              0,
              constraints.maxHeight / 4 * 3,
              constraints.maxWidth,
              constraints.maxHeight / 4,
            );
            return Stack(
              children: [
                Background(floorRect),
                ...pipes,
                Bird(birdX, birdY),
                isGameStarted ? scoreText : tapToPlayText,
                Positioned.fromRect(
                  rect: floorRect,
                  child: bestScoreText,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
