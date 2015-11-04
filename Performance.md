So far, this is just a draft. I've spent some time writing a test suite in Javascript which will be used when benchmarking performance as well as API correctness. What I've noted so far is:

  * In Google Chrome, a WebSocket connection takes approximately 20 ms to 30 ms. This is when using the WebSocket implementation that Chrome supports natively.
  * When switching to the Flash version that will be used for backwards-compatibility, time spent for just connecting and getting a handshake is more than 500 ms(!)
  * Shooting off a great bunch of commands in sequence increases respons time for each call. This seems to be a problem only present in Chrome (at least not in Safari) so memory leakage is a candidate here.

Todo:

  * Write Python tests that don't rely on Javascript garbage collection
  * Profile server and measure time for requests
  * Investigate how threading can decrease response time