/* leap-kick: connect to leapd as a LeapC client until tracking frames
 * arrive, then disconnect.
 *
 * leapd lights the controller's IR LEDs as soon as it opens the device, but
 * on shutdown it only switches them off if the cameras streamed during its
 * run, and streaming only starts once a client connects. Stopping a service
 * that never had a client leaves the LEDs on (even with the device
 * runtime-suspended or USB-reset). leap-off runs this first.
 *
 * Exit status: 0 = got frames, 1 = couldn't connect, 2 = no frames in ~5 s. */
#include <stdio.h>
#include <LeapC.h>

int main(void) {
  LEAP_CONNECTION conn;
  if (LeapCreateConnection(NULL, &conn) != eLeapRS_Success) return 1;
  if (LeapOpenConnection(conn) != eLeapRS_Success) return 1;

  int frames = 0;
  for (int i = 0; i < 50 && frames < 10; i++) { /* 100 ms polls, <= ~5 s */
    LEAP_CONNECTION_MESSAGE msg;
    if (LeapPollConnection(conn, 100, &msg) == eLeapRS_Success &&
        msg.type == eLeapEventType_Tracking)
      frames++;
  }

  LeapCloseConnection(conn);
  LeapDestroyConnection(conn);
  printf("%d tracking frames\n", frames);
  return frames ? 0 : 2;
}
