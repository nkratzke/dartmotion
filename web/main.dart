import 'dart:html';
import 'dart:async';
import 'dart:math';

import 'package:pwa/client.dart' as pwa;

import 'MotionView.dart';

void main() {

  new pwa.Client(); // This makes this game offline playable in your browser using service workers

  final qr = querySelector('#qr');       // Html element that shows the QR code of the URL.
  final start = querySelector('#start'); // Html element to start the game.
  final over = querySelector('#over');   // Html element to indicate the game over state.

  final view = new MotionView();         // View object, repsonsible to update game states
  var mobile = false;

  // Area and ball object
  Circle area = new Circle(view.center_x, view.center_y, view.size / 4, view);
  Circle ball = new Circle(view.center_x, view.center_y, view.size / 8, view);

  view.update(area, ball); // Initial update of the game state

  // Device orientation event handler.
  //
  window.onDeviceOrientation.listen((ev) {

    // No device orientation
    if (ev.alpha == null && ev.beta == null && ev.gamma == null) {
      qr.style.display = 'block'; // Show QR code
    }
    // Device orientation available
    else {
      qr.style.display = 'none'; // Hide QR code
      mobile = true;
      // Determine ball movement from orientation event
      //
      // beta: 30° no move, 10° full up, 50° full down
      // gamma: 0° no move, -20° full left, 20° full right
      //
      final dy = min(50, max(10, ev.beta)) - 30;
      final dx = min(20, max(-20, ev.gamma));
      ball.move(dx, dy);
    }
  });

  // (Re)start button handler
  //
  querySelector('body').onClick.listen((ev) {
    if (start.style.display == 'none') return;
    area.position(view.center_x, view.center_y);
    ball.position(view.center_x, view.center_y);
    ball.grow(-1000.0); // Shrink ball to target size

    start.style.display = 'none'; // Hide start and game over elements
    over.style.display = 'none';

    // Move area handler
    //
    final move = new Timer.periodic(new Duration(milliseconds: 500), (_) {
      final random = new Random();
      final steps = view.size / 30;
      final ax = random.nextDouble() * steps - steps / 2;
      final ay = random.nextDouble() * steps - steps / 2;
      area.move(ax, ay);
      if (!mobile) {
        ball.move((area.x - ball.x) / steps, (area.y - ball.y) / steps);
      }
    });

    // Update handler (at 30 hz)
    //
    final update = new Timer.periodic(new Duration(milliseconds: 30), (update) {
      if (!area.isInDanger(ball)) ball.grow(-1.0);
      if (area.isInDanger(ball)) ball.grow(-0.25);
      if (area.isOut(ball)) ball.grow(0.5);
      view.update(area, ball);

      // Game over detection
      //
      if (ball.radius > area.radius) {
        start.style.display = 'block'; // Show start and game over elements
        over.style.display = 'block';
        move.cancel();
        update.cancel();
      }
    });
  });
}