# AntiGravity-Pool
The first real-time pathtraced game for desktop and mobile using WebGL. <br>
Click to Play --> https://erichlof.github.io/AntiGravity-Pool/AntiGravityPool.html
<br> <br>

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
