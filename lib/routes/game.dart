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
  static const Size birdSpriteSize = Size(80, 80);
  static const Size birdHitboxSize = Size(30, 40);
  static const double birdX = 120;
  static const double pipeWidth = 60;
  static const double pipeMinHeight = 50;
  static const double pipeGapMinHeight = 150;
  static const double pipeGapMaxHeight = 400;
  static const double pipeStartingVelX = 200;
  static const double birdAccY = 0.2;
  static const double birdStartingVelY = 8;
  static const double birdStartingY = 350;
  static const int ticksInASecond = 60;
  static const int pipeMinGenerationDelay = 1;
  static const int pipeMaxGenerationDelay = 3;

  final int ticksDelay = (1000 / ticksInASecond).floor();

  bool isGameStarted = false;
  double birdY = birdStartingY;
  double birdVelY = birdStartingVelY;
  double birdStartingJumpY = birdStartingY;
  double pipeVelX = pipeStartingVelX;
  Timer? gameTimer;
  int time = 0;
  int score = 0;
  List<Pipe> pipes = [];

  late StreamController<int> _bestScoreController;
  late Rect floorRect;
  late final int oldBestScore;

  void jump() {
    time = 0;
    birdVelY = birdStartingVelY;
    birdStartingJumpY = birdY;
  }

  void start() {
    isGameStarted = true;
    gameTimer = Timer.periodic(
      // TODO: Could change this into a ticker
      Duration(milliseconds: ticksDelay),
      (timer) {
        setState(() {
          birdVelY -= birdAccY;
          birdY = birdStartingJumpY - birdVelY * time;

          checkVerticalBounds();

          addPipeOnDelay(timer.tick);

          for (int i = 0; i < pipes.length; i++) {
            updatePipeXAt(i);
            checkPipeCollisionAt(i);
          }

          updateScore();

          pipeVelX = pipeStartingVelX + timer.tick / (ticksInASecond);
          time++;
        });
      },
    );
  }

  void updatePipeXAt(int i) {
    final Pipe pipe = pipes[i];
    final Rect newPipeRect = Rect.fromLTWH(
      pipe.rect.left - pipeVelX / ticksInASecond,
      pipe.rect.top,
      pipe.rect.width,
      pipe.rect.height,
    );
    pipes[i] = Pipe(newPipeRect);
  }

  void updateScore() {
    if (score * 2 < pipes.length && pipes[score * 2].rect.left < birdX) {
      score++;
      if (score > oldBestScore) {
        _bestScoreController.sink.add(score);
      }
    }
  }

  void checkPipeCollisionAt(int i) {
    final pipe = pipes[i];
    final birdRect = Rect.fromCenter(
      center: Offset(birdX, birdY),
      width: birdHitboxSize.width,
      height: birdHitboxSize.height,
    );

    if (birdRect.overlaps(pipe.rect)) {
      gameOver();
    }
  }

  void checkVerticalBounds() {
    if (birdY < 0 || birdY > floorRect.top) {
      gameOver();
    }
  }

  void addPipeOnDelay(int ticksSinceLastPipe) {
    final int delay =
        Random().nextInt(pipeMaxGenerationDelay - pipeMinGenerationDelay) +
            pipeMinGenerationDelay;

    if (ticksSinceLastPipe % (ticksInASecond * delay) == 1) {
      final List<Pipe> newPipe = getNewPipe();
      pipes.addAll(newPipe);
    }
  }

  void reset() {
    setState(() {
      isGameStarted = false;
      score = 0;
      time = 0;
      birdY = birdStartingY;
      birdStartingJumpY = birdY;
      birdVelY = birdStartingVelY;
      pipes = [];
    });
  }

  List<Pipe> getNewPipe() {
    final double gap =
        Random().nextDouble() * (pipeGapMaxHeight - pipeGapMinHeight) +
            pipeGapMinHeight;
    final double gapBottom =
        Random().nextDouble() * (floorRect.top - gap - pipeMinHeight * 2) +
            pipeMinHeight;

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

    const dialog = Dialog(
      backgroundColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsetsDirectional.all(16),
        child: Text(
          'Game Over',
          textScaleFactor: 2,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    await showDialog(context: context, builder: (contetx) => dialog);
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
                Bird(Rect.fromCenter(
                  center: Offset(birdX, birdY),
                  width: birdSpriteSize.width,
                  height: birdSpriteSize.height,
                )),
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
