import 'dart:async';
import 'dart:math';
import 'package:num_remap/num_remap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class Game extends StatefulWidget {
  const Game({Key? key}) : super(key: key);

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  static const floorHeight = 200;
  late final AnimationController _jumpController = AnimationController(
    lowerBound: -1,
    upperBound: 1,
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  double birdY = 350;
  double startingJumpingHeight = 350;
  bool isGameStarted = false;
  bool isFalling = false;
  late Size screenSize;
  Timer? fallingTimer;
  int best = 100;

  void jump() {
    _jumpController.forward(from: -1);
    startingJumpingHeight = birdY;
    Timer.periodic(Duration(milliseconds: (1000 / 60).floor()), (timer) {
      setState(() {
        isFalling = false;
        double offset = _jumpController.value.remap(-1, 1, -pi / 2, pi / 2);
        offset = cos(offset);
        birdY = startingJumpingHeight + offset * -100;
        if (_jumpController.isCompleted) {
          timer.cancel();
          isFalling = true;
          fall();
        }
      });
    });
  }

  void fall() {
    double fallingSpeed = 3;
    fallingTimer?.cancel();
    fallingTimer =
        Timer.periodic(Duration(milliseconds: (1000 / 60).floor()), (timer) {
      setState(() {
        if (isFalling && isGameStarted) {
          const double acc = 0.35;
          fallingSpeed = acc * acc / 2 + fallingSpeed;
          birdY = fallingSpeed * fallingSpeed / 2 + birdY;
        } else {
          timer.cancel();
        }
        if (birdY > screenSize.height - floorHeight) {
          gameOver();
        }
      });
    });
  }

  void start(BuildContext context) {
    setState(() {
      isGameStarted = true;
    });

    jump();
    startMovingPipes();
    startPipeAdder();
    startCheckingPipesCollision();
    startScorer();
  }

  int score = 0;
  Timer? scorerTimer;

  void startScorer() {
    scorerTimer = Timer.periodic(
      Duration(milliseconds: (1000 / 60).floor()),
      (timer) {
        if (score < pipeRects.length && pipeRects[score].center.dx < 120) {
          setState(() {
            score++;
          });
        }
      },
    );
  }

  Timer? pipeAdderTimer;

  void startPipeAdder() {
    pipeAdderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      pipeRects.add(generatePipeRect());
    });
  }

  Timer? collisionTimer;

  void startCheckingPipesCollision() {
    collisionTimer = Timer.periodic(
      Duration(milliseconds: (1000 / 60).floor()),
      (timer) {
        Rect birdRect =
            Rect.fromCenter(center: Offset(120, birdY), width: 80, height: 80);

        for (var rect in pipeRects) {
          if (birdRect.overlaps(rect)) {
            gameOver();
          }
        }
      },
    );
  }

  bool isGameOver = false;

  void gameOver() {
    isGameOver = true;
    cancelTimers();

    SharedPreferences.getInstance().then((value) {
      int oldScore = value.getInt('best') ?? 0;
      if (score > oldScore) {
        value.setInt('best', score);
      }
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over', textScaleFactor: 2),
              Text('your score was: $score'),
            ],
          ),
        ),
      ),
    ).then((value) => restart());
  }

  void cancelTimers() {
    fallingTimer?.cancel();
    pipesTimer?.cancel();
    collisionTimer?.cancel();
    pipeAdderTimer?.cancel();
    scorerTimer?.cancel();
    _jumpController.stop();
  }

  void restart() {
    isGameOver = false;
    cancelTimers();
    setState(() {
      isGameStarted = false;
      birdY = 350;
      score = 0;
    });
    init();
  }

  bool isFirstStart = true;
  List<Rect> pipeRects = [];
  List<Positioned>? renderizedPipes;

  Rect generatePipeRect({isFirstPipe = false}) {
    bool orientation = Random().nextBool();

    final left = screenSize.width - 100 - Random().nextInt(50);
    final top = 120 + Random().nextDouble() * (screenSize.height - 200 - 240);

    orientation = orientation || isFirstPipe;

    return Rect.fromLTWH(
      isFirstPipe ? left : screenSize.width,
      orientation ? top : 0,
      70,
      orientation ? screenSize.height - top - 200 : top,
    );
  }

  void init() {
    screenSize = MediaQuery.of(context).size;
    pipeRects = [generatePipeRect(isFirstPipe: true)];

    renderizedPipes = pipeRects
        .map((rect) => Positioned.fromRect(
              rect: rect,
              child: Pipe(),
            ))
        .toList();
  }

  void chosePipes() {
    renderizedPipes = [];
    for (var rect in pipeRects) {
      final Rect screenRect =
          Rect.fromLTWH(0, 0, screenSize.width + 70, screenSize.height);
      if (rect.overlaps(screenRect)) {
        renderizedPipes?.add(
          Positioned.fromRect(
            rect: rect,
            child: Pipe(),
          ),
        );
      }
    }
  }

  Timer? pipesTimer;

  void startMovingPipes() {
    pipesTimer = Timer.periodic(
      Duration(milliseconds: (1000 / 60).floor()),
      (timer) {
        pipeRects =
            pipeRects.map((rect) => rect.shift(const Offset(-1.5, 0))).toList();

        chosePipes();
      },
    );
  }

  @override
  void dispose() {
    cancelTimers();
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstStart) {
      init();
      isFirstStart = false;
    }
    return GestureDetector(
      onTap: () => isGameStarted ? jump() : start(context),
      onLongPress: () => restart(),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.lightBlue.shade100,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: renderizedPipes! +
                        [
                          Positioned.fromRect(
                            rect: Rect.fromCenter(
                              center: Offset(120, birdY),
                              width: 80,
                              height: 80,
                            ),
                            child: const Bird(),
                          ),
                          Positioned(
                            child: Container(
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 200),
                              child: Text(
                                isGameOver
                                    ? ''
                                    : (isGameStarted
                                        ? '$score'
                                        : 'tap to start'),
                                textScaleFactor: 4,
                              ),
                            ),
                          ),
                          Positioned(
                            child: Container(
                              alignment: Alignment.center,
                              child: isGameStarted
                                  ? null
                                  : FutureBuilder(
                                      future: SharedPreferences.getInstance(),
                                      builder: (context,
                                          AsyncSnapshot<SharedPreferences>
                                              snap) {
                                        Widget scoreNum;
                                        print(snap);
                                        if (!snap.hasData) {
                                          scoreNum = const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else {
                                          scoreNum = Text(
                                            '${snap.data?.getInt('best') ?? 0}',
                                            textScaleFactor: 3,
                                          );
                                        }
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'best score: ',
                                              textScaleFactor: 3,
                                            ),
                                            scoreNum
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: constraints.maxHeight - 200,
                            height: 200,
                            width: constraints.maxWidth,
                            child: Container(
                              color: Colors.green.shade300,
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Bird extends StatelessWidget {
  const Bird({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
      ),
      width: 60,
      height: 60,
    );
  }
}

class Pipe extends StatelessWidget {
  const Pipe({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.green);
  }
}
