# AntiGravity-Pool
The first real-time pathtraced game for desktop and mobile using WebGL. <br>
Click to Play --> https://erichlof.github.io/AntiGravity-Pool/AntiGravityPool.html
<br> <br>

<h3> March 14, 2025 NOTE: Workaround for Black Screen Bug (Mobile devices only) in latest Chromium Browsers (mobile Chrome, Edge, Brave, Opera) </h3>

* In latest Chrome 134.0 (and all Chromium-based browsers), there is a major bug that occurs on touch devices (happens on my Android phone - iPhone and iPad not tested yet)
* At demo startup, when you touch your screen for the first time, the entire screen suddenly turns black. There is no recovering - the webpage must be reloaded to see anything again.
* THE WORKAROUND: After starting up the demo, do a 'pinch' gesture with 2 fingers.  You can tell if you did it because the camera (FOV) will zoom in or out.
* Once you have done this simple 2-finger pinch gesture, you can interact with the demo as normal - the screen will not turn black on you for the duration of the webpage.
* I have no idea why this is happening.  I hooked my phone up to my PC's Chrome dev tools, and there are no warnings or errors in my phone's browser console output when the black screen occurs.
* I don't know why a 2-finger pinch gesture gets around this issue and prevents the black screen from occuring.
* I have done my own debug output on the demo webpage (inside an HTML element), and from what I can see, all the recorded touch events (like touchstart, touchmove, etc.) and camera variables appear valid and are working like they always do.
* The WebGL context isn't being lost and the webpage is not crashing, because the demo keeps running and the cameraInfo element (that is in the lower left-hand corner) on all demos, still outputs correct data - it's like the app is still running, taking user input, and doing path tracing calculations, but all that is displayed to the user is a black screen.
* I may open up a new issue on the Chromium bug tracker, but I can't even tell what error is occuring.  Plus my use case (path tracing fullscreen quad shader on top of three.js) is pretty rare, so I don't know how fast the Chromium team would get around to it, if at all.
* In my experience, these bugs have a way of working themselves out when the next update of Chromium comes out (which shouldn't be too long from now).  I love targeting the web platform because it is the only platform where you can truly "write the code once, run everywhere" - but one of the downsides of coding for this platform are the occasional bugs that are introduced into the browser itself, even though nothing has changed in your own code.  Hopefully this will be resolved soon, either by a targeted bug fix, or by happy accident with the next release of Chromium.  <br> <br>
<h4>Desktop Controls</h4>

* Click anywhere to capture mouse
* move Mouse to aim cueball
* Mousewheel to dolly camera in or out
* SPACEBAR to enter shot mode.  Power will oscillate up and down
* SPACEBAR again to shoot!
* when shot has been made and balls are moving, WASD to fly around the scene
<br><br>

<h4>Mobile Controls</h4>

* Swipe to aim cueball
* Pinch to dolly camera in or out
* small up button above directional controls to enter shot mode.  Power will oscillate
* small up button again to shoot!
* when shot has been made and balls are moving, directional arrows to fly around the scene

<h2>TODO</h2>

* Squash sound fx bug due to the physics engine continually reporting collisions between balls and between balls and rails/walls. This results in sound fx playing repeatedly until the offending ball is pocketed. This bug is highly annoying so it gets the highest priority!
* Create simple banners to display game state (for example, "Player 1 Wins!")
* Create widgets to display current target-ball color (red, yellow, or black), as well as shot power meter<br>

<h2>ABOUT</h2>

* To my knowledge in 2019 this is the first real-time fully path traced game for all devices with a browser, including mobile. The technology behind this simple game is a combination of my three.js path tracing [project](https://github.com/erichlof/THREE.js-PathTracing-Renderer), physics simulation through [Oimo.js](https://github.com/lo-th/Oimo.js), and the WebAudio API for sound effects.  The goal of this project is enabling path traced real-time games for all players, regardless of their system specs and GPU power. <br>
