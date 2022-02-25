// game-specific variables go here
var initialCameraZ;
var cameraZOffset = 0;
var poolTableWalls = [];
var ballObjects = [];
var ballPositions = [];
var pocketSounds = [];
var railWallSounds = [];
var ballClickSounds = [];
var cueStickSound = null;
var chalkSound = null;
var rackSound = null;
var sphereSize = 2;
var pocketSize = 10;
var pocketPosX = 52;
var pocketPosY = 52;
var pocketPosZ = 52;
var sphereDensity = 1.0;
var light0, light1;
var aimOrigin = new THREE.Vector3();
var aimVector = new THREE.Vector3();
var frictionVector = new THREE.Vector3();
var sml = 2.2;
var lrg = sml * 2;
var rnd0, rnd1, rnd2;
var range = 0.5;
var x, y, z;
var shotIsInProgress = false;
var allBallsHaveStopped = true;
var playerIsAiming = true;
var launchGhostAimingBall = false;
var canLaunchGhostAimingBall = false;
var playerOneTurn = true;
var playerTwoTurn = false;
var willBePlayerOneTurn = false;
var willBePlayerTwoTurn = false;
var playerOneColor = 'undecided';
var playerTwoColor = 'undecided';
var redBallsRemaining = 7;
var yellowBallsRemaining = 7;
var playerOneCanShootBlackBall = false;
var playerTwoCanShootBlackBall = false;
var spotCueBall = false;
var spotBlackBall = false;
var playerOneWins = false;
var playerTwoWins = false;
var shouldStartNewGame = false;
var isBreakShot = true;
var canPlayBallSounds = false;
var isShooting = false;
var canPressSpacebar = false;
var minShotPower = 0.2;
var shotPower = minShotPower;
var shotFlip = 1;

// oimo physics variables
var world = null;
var rigidBodies = [];

// WebAudio variables
var audioLoader;
var listener;


// overwrite onMouseWheel function
function onMouseWheel(event)
{
	event.stopPropagation();

	if (event.deltaY > 0) 
		dollyCameraOut = true;

	else if (event.deltaY < 0) 
		dollyCameraIn = true;
}


// called automatically from within initTHREEjs() function
function initSceneData() 
{        
	// game-specific three.js variables / Oimo.js physics setup goes here
	sceneIsDynamic = true;
	cameraFlightSpeed = 30;
	
	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.8 : 1.0;

	EPS_intersect = 0.001;

	// we will use our own custom input handling for this game
	useGenericInput = false;
	
	// set camera's field of view
	worldCamera.fov = mouseControl ? 40 : 30;
	
	initialCameraZ = 0; // close to cueball is better

	for (let i = 0; i < 24; i++)
	{
		ballObjects[i] = new THREE.Object3D();
		ballPositions[i] = new THREE.Vector3();
	}

	world = new OIMO.World({timestep: 1/60, worldscale: 1} );
	world.gravity = new OIMO.Vec3(0, 0, 0);

	audioLoader = new THREE.AudioLoader();
	listener = new THREE.AudioListener();
	//cameraControlsObject.add( listener );
	worldCamera.add( listener );

	
	audioLoader.load( 'sounds/pocket.mp3', function ( buffer )
	{
		for ( let i = 16; i < 24; i ++ ) 
		{
			pocketSounds[i] = new THREE.PositionalAudio( listener );
			pocketSounds[i].setBuffer( buffer );
			pocketSounds[i].setVolume(2);
			ballObjects[i].add( pocketSounds[i] );
		}
	} );

	audioLoader.load( 'sounds/rail.mp3', function ( buffer )
	{
		for ( let i = 0; i < 16; i ++ ) 
		{
			railWallSounds[i] = new THREE.PositionalAudio( listener );
			railWallSounds[i].setBuffer( buffer );
			railWallSounds[i].setVolume(0.3);
			ballObjects[i].add( railWallSounds[i] );
		}
	} );

	audioLoader.load( 'sounds/click2.mp3', function ( buffer )
	{
		for ( let i = 0; i < 16; i ++ ) 
		{
			ballClickSounds[i] = new THREE.PositionalAudio( listener );
			ballClickSounds[i].setBuffer( buffer );
			ballObjects[i].add( ballClickSounds[i] );
		}
	} );

	audioLoader.load( 'sounds/cuestick.mp3', function ( buffer )
	{
		cueStickSound = new THREE.PositionalAudio( listener );
		cueStickSound.setBuffer( buffer );
		cueStickSound.setVolume(0.2);
		worldCamera.add(cueStickSound);
	} );

	audioLoader.load( 'sounds/chalk.mp3', function ( buffer )
	{
		chalkSound = new THREE.PositionalAudio( listener );
		chalkSound.setBuffer( buffer );
		chalkSound.setVolume(0.05);
		worldCamera.add(chalkSound);
	} );

	audioLoader.load( 'sounds/rack.mp3', function ( buffer )
	{
		rackSound = new THREE.PositionalAudio( listener );
		rackSound.setBuffer( buffer );
		rackSound.setVolume(0.2);
		worldCamera.add(rackSound);
	} );
	
	
	startNewGame();

} // end function initSceneData()



	


// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
	// app/game-specific uniforms go here
	pathTracingUniforms.uShotIsInProgress = { type: "b1", value: false };
	pathTracingUniforms.uBallPositions = { type: "v3v", value: ballPositions };

	pathTracingDefines = 
	{
		//NUMBER_OF_TRIANGLES: total_number_of_triangles
	};

	// load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
	fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) 
	{
		pathTracingVertexShader = shaderText;

		createPathTracingMaterial();
	});

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() 
{
	fileLoader.load('shaders/AntiGravityPool_Fragment.glsl', function (shaderText) 
	{        
		pathTracingFragmentShader = shaderText;

		pathTracingMaterial = new THREE.ShaderMaterial({
			uniforms: pathTracingUniforms,
			defines: pathTracingDefines,
			vertexShader: pathTracingVertexShader,
			fragmentShader: pathTracingFragmentShader,
			depthTest: false,
			depthWrite: false
		});

		pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
		pathTracingScene.add(pathTracingMesh);

		// the following keeps the large scene ShaderMaterial quad right in front 
		//   of the camera at all times. This is necessary because without it, the scene 
		//   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
		worldCamera.add(pathTracingMesh);    
	});

} // end function createPathTracingMaterial()



function startNewGame() 
{
	
	// reset all flags and variables
	isBreakShot = true;
	canPlayBallSounds = false;
	isShooting = false;
	shotPower = minShotPower;
	shotFlip = 1;
	shotIsInProgress = false;
	playerIsAiming = true;
	cameraRotationSpeed = mouseControl ? 0.5 : 0.35;
	launchGhostAimingBall = true;
	playerOneTurn = true;
	playerTwoTurn = false;
	willBePlayerOneTurn = false;
	willBePlayerTwoTurn = false;
	playerOneColor = 'undecided';
	playerTwoColor = 'undecided';
	redBallsRemaining = 7;
	yellowBallsRemaining = 7;
	spotCueBall = false;
	spotBlackBall = false;
	playerOneCanShootBlackBall = false;
	playerTwoCanShootBlackBall = false;
	playerOneWins = false;
	playerTwoWins = false;
	shouldStartNewGame = false;
	rigidBodies = [];

	world.clear();

	poolTableWalls[0] = world.add({size:[100, 10, 100], pos:[0,-55,0], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	poolTableWalls[1] = world.add({size:[100, 10, 100], pos:[0, 55,0], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	poolTableWalls[2] = world.add({size:[10, 100, 100], pos:[-55,0,0], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	poolTableWalls[3] = world.add({size:[10, 100, 100], pos:[ 55,0,0], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	poolTableWalls[4] = world.add({size:[100, 100, 10], pos:[0,0,-55], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	poolTableWalls[5] = world.add({size:[100, 100, 10], pos:[0,0, 55], world:world, density: 1.0, friction: 0.0, restitution: 0.1});
	
	// add static balls for aiming purposes

	// cueball
	x = 0; y = 0; z = 40;
	aimOrigin.set(x, y, z);
	rigidBodies[0] = world.add({type:'sphere', name:'cueball', size:[sphereSize], pos:[x, y, z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	
	// camera
	cameraControlsObject.position.copy(rigidBodies[0].position);
	worldCamera.position.set(0, 0, initialCameraZ);

	// blackball
	x = 0; y = 0; z = 0;
	rigidBodies[1] = world.add({type:'sphere', name:'blackball', size:[sphereSize], pos:[x, y, z], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	
	// red balls
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[2] = world.add({type:'sphere', name:'redball2', size:[sphereSize], pos:[-sml + rnd0,sml + rnd1,sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[3] = world.add({type:'sphere', name:'redball3', size:[sphereSize], pos:[sml + rnd0,sml + rnd1,-sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[4] = world.add({type:'sphere', name:'redball4', size:[sphereSize], pos:[-sml + rnd0,-sml + rnd1,-sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[5] = world.add({type:'sphere', name:'redball5', size:[sphereSize], pos:[sml + rnd0,-sml + rnd1,sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[6] = world.add({type:'sphere', name:'redball6', size:[sphereSize], pos:[0 + rnd0,lrg + rnd1,0 + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[7] = world.add({type:'sphere', name:'redball7', size:[sphereSize], pos:[lrg + rnd0,0 + rnd1,0 + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[8] = world.add({type:'sphere', name:'redball8', size:[sphereSize], pos:[0 + rnd0,0 + rnd1,-lrg + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	
	
	// yellow balls
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[9] = world.add({type:'sphere', name:'yellowball9', size:[sphereSize], pos:[sml + rnd0,sml + rnd1,sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[10] = world.add({type:'sphere', name:'yellowball10', size:[sphereSize], pos:[-sml + rnd0,sml + rnd1,-sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[11] = world.add({type:'sphere', name:'yellowball11', size:[sphereSize], pos:[sml + rnd0,-sml + rnd1,-sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[12] = world.add({type:'sphere', name:'yellowball12', size:[sphereSize], pos:[-sml + rnd0,-sml + rnd1,sml + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[13] = world.add({type:'sphere', name:'yellowball13', size:[sphereSize], pos:[0 + rnd0,-lrg + rnd1,0 + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[14] = world.add({type:'sphere', name:'yellowball14', size:[sphereSize], pos:[-lrg + rnd0,0 + rnd1,0 + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rnd0 = THREE.Math.randFloat(-range, range); rnd1 = THREE.Math.randFloat(-range, range); rnd2 = THREE.Math.randFloat(-range, range);
	rigidBodies[15] = world.add({type:'sphere', name:'yellowball15', size:[sphereSize], pos:[0 + rnd0,0 + rnd1,lrg + rnd2], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	

	// pockets
	rigidBodies[16] = world.add({type:'sphere', name:'pocket0', size:[pocketSize], pos:[-pocketPosX, -pocketPosY, pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[17] = world.add({type:'sphere', name:'pocket1', size:[pocketSize], pos:[pocketPosX, -pocketPosY, pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[18] = world.add({type:'sphere', name:'pocket2', size:[pocketSize], pos:[-pocketPosX, pocketPosY, pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[19] = world.add({type:'sphere', name:'pocket3', size:[pocketSize], pos:[pocketPosX, pocketPosY, pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[20] = world.add({type:'sphere', name:'pocket4', size:[pocketSize], pos:[-pocketPosX, -pocketPosY, -pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[21] = world.add({type:'sphere', name:'pocket5', size:[pocketSize], pos:[pocketPosX, -pocketPosY, -pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[22] = world.add({type:'sphere', name:'pocket6', size:[pocketSize], pos:[-pocketPosX, pocketPosY, -pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	rigidBodies[23] = world.add({type:'sphere', name:'pocket7', size:[pocketSize], pos:[pocketPosX, pocketPosY, -pocketPosZ], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
	
	if (rackSound)
	{
		if (!rackSound.isPlaying)
			rackSound.play();
	}
} // end function startNewGame()



function updateOimoPhysics() 
{

	// step physics simulation forward
	world.step();

	if (playerIsAiming) 
	{
		// if player has moved the line of aim and comes to rest, send out another
		 // ghost aiming cueball to aid in lining up the shot 
		if (launchGhostAimingBall) 
		{
			launchGhostAimingBall = false;
			rigidBodies[0].position.copy(aimOrigin);
			rigidBodies[0].linearVelocity.set(0, 0, 0);
			rigidBodies[0].angularVelocity.set(0, 0, 0);
			aimVector.copy(cameraDirectionVector).multiplyScalar(1000);
			rigidBodies[0].applyImpulse(rigidBodies[0].position, aimVector);
		}
	}

	// check for balls being pocketed
	if (!playerIsAiming && shotIsInProgress) 
	{
		// pocket sound
		for (let i = 0; i < 16; i++) 
		{
			for (let j = 16; j < 24; j++) 
			{
				if (rigidBodies[i] != null && world.getContact(rigidBodies[i], rigidBodies[j])) 
				{
					if (!pocketSounds[j].isPlaying)
						pocketSounds[j].play();
					
					doGameStateLogic(i);
					//console.log("ball " + i + " was pocketed");	
				}
			}	
		}

		// rail/wall impact sound
		for (let i = 0; i < 16; i++) 
		{
			for (let j = 0; j < 6; j++) 
			{
				if (rigidBodies[i] != null && world.getContact(rigidBodies[i], poolTableWalls[j])) 
				{
					if (!railWallSounds[i].isPlaying)
						railWallSounds[i].play();	
				}
			}	
		}

		if (!canPlayBallSounds)
		{
			for (let i = 1; i < 24; i++) 
			{
				if (rigidBodies[0] != null && rigidBodies[i] != null &&
					world.getContact(rigidBodies[0], rigidBodies[i])) 
				{
					canPlayBallSounds = true; 	
				}
			}
			// for (let j = 0; j < 6; j++) 
			// {
			//         if (rigidBodies[0] != null && world.getContact(rigidBodies[0], poolTableWalls[j])) 
			//         {
			//                 canPlayBallSounds = true;	
			//         }
			// }
		}
		

		if (canPlayBallSounds)
		{
			// balls impact clacking sound
			for (let i = 0; i < 16; i++) 
			{
				for (let j = 0; j < 16; j++) 
				{
					if (i==j) continue;
					if (rigidBodies[i] != null && rigidBodies[j] != null &&
						world.getContact(rigidBodies[i], rigidBodies[j])) 
					{
						if (!ballClickSounds[i].isPlaying)
							ballClickSounds[i].play();
						//if (!ballClickSounds[j].isPlaying)
						  //      ballClickSounds[j].play();	
					}
				}	
			}
		}
		
	}

	// if shot has been taken and balls are moving, keep checking for all balls to come to rest
	if (!playerIsAiming && shotIsInProgress) 
	{
		allBallsHaveStopped = true; // try to set allBallsHaveStopped flag to true

		for (let i = 0; i < 16; i++) 
		{
			if (rigidBodies[i] == null)
				continue;
			
			if ( rigidBodies[i].sleeping == false ) 
			{
				allBallsHaveStopped = false; // balls are still moving
				frictionVector.copy(rigidBodies[i].linearVelocity).negate().normalize().multiplyScalar(1.25);
				rigidBodies[i].applyImpulse(rigidBodies[i].position, frictionVector);
			}	
		}
	}

	// if all balls have just come to rest (allBallsHaveStopped is true), switch to aiming mode
	if (!playerIsAiming && shotIsInProgress && allBallsHaveStopped) 
	{
		if (shouldStartNewGame) 
		{
			startNewGame();
			return;
		}

		shotPower = minShotPower;
		shotFlip = 1;
		shotIsInProgress = false;
		isBreakShot = false;
		playerIsAiming = true;
		cameraRotationSpeed = mouseControl ? 0.5 : 0.35;
		launchGhostAimingBall = true;

		// no balls were pocketed, switch turns
		if (!willBePlayerOneTurn && !willBePlayerTwoTurn) 
		{
			if (!chalkSound.isPlaying)
				chalkSound.play();
			
			
			if (playerOneTurn) 
			{
				playerOneTurn = false;
				playerTwoTurn = true;
			}
			else if (playerTwoTurn) 
			{
				playerTwoTurn = false;
				playerOneTurn = true;
			}
		} 
		else // ball or balls were pocketed
		{ 
			if (willBePlayerOneTurn) 
			{
				if (!playerOneTurn)
				{
					if (!chalkSound.isPlaying)
						chalkSound.play();
				}
				
				playerOneTurn = true;
				playerTwoTurn = false;
				willBePlayerOneTurn = false; // reset
			}
			else if (willBePlayerTwoTurn) 
			{
				if (!playerTwoTurn)
				{
					if (!chalkSound.isPlaying)
						chalkSound.play();
				}
				
				playerTwoTurn = true;
				playerOneTurn = false;
				willBePlayerTwoTurn = false; // reset
			}
		}

		// remove dynamic balls that were used for shot making and
		// add static balls for aiming purposes

		// cueball
		if (spotCueBall) 
		{
			if (!chalkSound.isPlaying)
				chalkSound.play();
			
			x = 0; y = 0; z = 40;
			aimOrigin.set(x, y, z);
			spotCueBall = false;
		}
		else 
		{
			// record current position before deleting
			aimOrigin.copy(rigidBodies[0].position);
			x = rigidBodies[0].position.x;
			y = rigidBodies[0].position.y;
			z = rigidBodies[0].position.z;
			
			rigidBodies[0].remove();
			rigidBodies[0] = null;
		}
		
		rigidBodies[0] = world.add({type:'sphere', size:[sphereSize], pos:[x,y,z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
		
		cameraControlsObject.position.copy(rigidBodies[0].position);
		worldCamera.position.set(0, 0, initialCameraZ);

		// blackball
		if (spotBlackBall) 
		{
			x = 0; y = 0; z = 0;
			spotBlackBall = false;
		}
		else 
		{
			// record current position before deleting
			x = rigidBodies[1].position.x;
			y = rigidBodies[1].position.y;
			z = rigidBodies[1].position.z;
			rigidBodies[1].remove();
			rigidBodies[1] = null;
		}
		rigidBodies[1] = world.add({type:'sphere', size:[sphereSize], pos:[x,y,z], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
		

		// red and yellow object balls
		for (let i = 2; i < 16; i++) 
		{
			if (rigidBodies[i] == null)
				continue;
			// record current position before deleting
			x = rigidBodies[i].position.x;
			y = rigidBodies[i].position.y;
			z = rigidBodies[i].position.z;

			rigidBodies[i].remove();
			rigidBodies[i] = null;
			rigidBodies[i] = world.add({type:'sphere', size:[sphereSize], pos:[x,y,z], move:false, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
		}

	} // end if (shotIsInProgress && allBallsHaveStopped)


	
	

	

	
} // end function updateOimoPhysics()



function doGameStateLogic(ballPocketed) 
{
	if (ballPocketed == 0)  // cueball was pocketed
	{
		if (playerOneTurn) 
		{
			willBePlayerOneTurn = false;
			willBePlayerTwoTurn = true;
		}
		else 
		{
			willBePlayerTwoTurn = false;
			willBePlayerOneTurn = true;
		}

		spotCueBall = true;
		//console.log("spotCueBall = true");
	}
	else if (ballPocketed == 1) // blackball was pocketed
	{ 
		if (playerOneTurn) 
		{
			if (playerOneCanShootBlackBall) 
			{
				playerOneWins = true;
				shouldStartNewGame = true;
				//console.log("player One wins!");
			}
			else 
			{
				spotBlackBall = true;
				//console.log("spotBlackBall = true");
				willBePlayerOneTurn = false;
				willBePlayerTwoTurn = true;
			}
		}
		else if (playerTwoTurn) 
		{
			if (playerTwoCanShootBlackBall) 
			{
				playerTwoWins = true;
				shouldStartNewGame = true;
				//console.log("player Two wins!");
			}
			else 
			{
				spotBlackBall = true;
				//console.log("spotBlackBall = true");
				willBePlayerTwoTurn = false;
				willBePlayerOneTurn = true;
			}
		}
		
	}
	else if (ballPocketed > 1) // yellow or red object ball was pocketed
	{ 
		if (rigidBodies[ballPocketed].name == ('redball' + ballPocketed)) 
		{
			redBallsRemaining -= 1;
			if (redBallsRemaining == 0) 
			{
				if (playerOneColor == 'red') 
					playerOneCanShootBlackBall = true;
				
				if (playerTwoColor == 'red') 
					playerTwoCanShootBlackBall = true;
			}
			if (playerOneTurn) 
			{
				if (playerOneColor == 'red') 
				{
					willBePlayerOneTurn = true;
					willBePlayerTwoTurn = false;
				}
				if (playerOneColor == 'yellow' && !isBreakShot) 
				{
					willBePlayerOneTurn = false;
					willBePlayerTwoTurn = true;
				}
				if (playerOneColor == 'undecided') 
				{
					playerOneColor = 'red';
					playerTwoColor = 'yellow';
					willBePlayerOneTurn = true;
					willBePlayerTwoTurn = false;
				}
			}
			else if (playerTwoTurn) 
			{
				if (playerTwoColor == 'red') 
				{
					willBePlayerTwoTurn = true;
					willBePlayerOneTurn = false;
				}
				if (playerTwoColor == 'yellow' && !isBreakShot) 
				{
					willBePlayerTwoTurn = false;
					willBePlayerOneTurn = true;
				}
				if (playerTwoColor == 'undecided') 
				{
					playerTwoColor = 'red';
					playerOneColor = 'yellow';
					willBePlayerTwoTurn = true;
					willBePlayerOneTurn = false;
				}
			}
		}
		else if (rigidBodies[ballPocketed].name == ('yellowball' + ballPocketed)) 
		{
			yellowBallsRemaining -= 1;
			if (yellowBallsRemaining == 0) 
			{
				if (playerOneColor == 'yellow') 
					playerOneCanShootBlackBall = true;
				
				if (playerTwoColor == 'yellow') 
					playerTwoCanShootBlackBall = true;  
			}
			if (playerOneTurn) 
			{
				if (playerOneColor == 'yellow') 
				{
					willBePlayerOneTurn = true;
					willBePlayerTwoTurn = false;
				}
				if (playerOneColor == 'red' && !isBreakShot) 
				{
					willBePlayerOneTurn = false;
					willBePlayerTwoTurn = true;
				}
				if (playerOneColor == 'undecided') 
				{
					playerOneColor = 'yellow';
					playerTwoColor = 'red';
					willBePlayerOneTurn = true;
					willBePlayerTwoTurn = false;
				}
			}
			else if (playerTwoTurn) 
			{
				if (playerTwoColor == 'yellow') 
				{
					willBePlayerTwoTurn = true;
					willBePlayerOneTurn = false;
				}
				if (playerTwoColor == 'red' && !isBreakShot) 
				{
					willBePlayerTwoTurn = false;
					willBePlayerOneTurn = true;
				}
				if (playerTwoColor == 'undecided') 
				{
					playerTwoColor = 'yellow';
					playerOneColor = 'red';
					willBePlayerTwoTurn = true;
					willBePlayerOneTurn = false;
				}
			}
		}
	}

	// remove pocketed ball from physics bodies list and turn off rendering
	rigidBodies[ballPocketed].remove();
	rigidBodies[ballPocketed] = null;

} // end function doGameStateLogic(ballPocketed)




// called automatically from within the animate() function
function updateVariablesAndUniforms() 
{
	
	if (playerIsAiming) 
	{
		if ( dollyCameraIn ) 
		{
			cameraZOffset -= 1;
			if (cameraZOffset < -initialCameraZ)
				cameraZOffset = -initialCameraZ;
			worldCamera.position.set(0, 0, initialCameraZ + cameraZOffset);
			cameraIsMoving = true;
			dollyCameraIn = false;
		}
		if ( dollyCameraOut ) 
		{
			cameraZOffset += 1;
			if (cameraZOffset > 200)
				cameraZOffset = 200;
			worldCamera.position.set(0, 0, initialCameraZ + cameraZOffset);
			cameraIsMoving = true;
			dollyCameraOut = false;
		}
	}

	if (!keyPressed('space') && !button5Pressed && !shotIsInProgress) 
	{
		canPressSpacebar = true;
	}
	if ((keyPressed('space') || button5Pressed) && canPressSpacebar)
	{ 
		canPressSpacebar = false;

		if (!isShooting) 
		{
			isShooting = true;
		}
		else if (isShooting) 
		{
			if (!cueStickSound.isPlaying)
				cueStickSound.play();
			
			
			isShooting = false;
			playerIsAiming = false;
			cameraRotationSpeed = 1;
			shotIsInProgress = true;
			cameraZOffset = 0;

			// remove static balls that were used for aiming and
			// add dynamic balls for shot making physics simulation

			// white cueball
			// record current position before deleting
			x = aimOrigin.x;
			y = aimOrigin.y;
			z = aimOrigin.z;
			rigidBodies[0].remove();
			rigidBodies[0] = null;
			rigidBodies[0] = world.add({type:'sphere', name:'cueball', size:[sphereSize], pos:[x,y,z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
			aimVector.copy(cameraDirectionVector).multiplyScalar(shotPower * 5000);
			rigidBodies[0].applyImpulse(rigidBodies[0].position, aimVector);

			cameraControlsObject.position.set(worldCamera.matrixWorld.elements[12],
							worldCamera.matrixWorld.elements[13],
							worldCamera.matrixWorld.elements[14]);
			worldCamera.position.set(0, 0, 0);
			

			// black ball
			// record current position before deleting
			x = rigidBodies[1].position.x;
			y = rigidBodies[1].position.y;
			z = rigidBodies[1].position.z;
			rigidBodies[1].remove();
			rigidBodies[1] = null;
			rigidBodies[1] = world.add({type:'sphere', name:'blackball', size:[sphereSize], pos:[x,y,z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
		
			// red balls
			for (let i = 2; i < 9; i++) 
			{
				if (rigidBodies[i] == null)
					continue;
				// record current position before deleting
				x = rigidBodies[i].position.x;
				y = rigidBodies[i].position.y;
				z = rigidBodies[i].position.z;

				rigidBodies[i].remove();
				rigidBodies[i] = null;
				rigidBodies[i] = world.add({type:'sphere', name:'redball' + i, size:[sphereSize], pos:[x,y,z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
			}

			// yellow balls
			for (let i = 9; i < 16; i++) 
			{
				if (rigidBodies[i] == null)
					continue;
				// record current position before deleting
				x = rigidBodies[i].position.x;
				y = rigidBodies[i].position.y;
				z = rigidBodies[i].position.z;

				rigidBodies[i].remove();
				rigidBodies[i] = null;
				rigidBodies[i] = world.add({type:'sphere', name:'yellowball' + i, size:[sphereSize], pos:[x,y,z], move:true, world:world, density: sphereDensity, friction: 0.0, restitution: 0.9});
			}

		} // end else if (isShooting)
		
	} // end if ((keyPressed('space') || button5Pressed) && canPressSpacebar)
	

	if (shotIsInProgress) 
	{
		// allow flying camera
		if ((keyPressed('w') || button3Pressed) && !(keyPressed('s') || button4Pressed))
		{
			cameraControlsObject.position.add(cameraDirectionVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
		if ((keyPressed('s') || button4Pressed) && !(keyPressed('w') || button3Pressed))
		{
			cameraControlsObject.position.sub(cameraDirectionVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
		if ((keyPressed('a') || button1Pressed) && !(keyPressed('d') || button2Pressed))
		{
			cameraControlsObject.position.sub(cameraRightVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
		if ((keyPressed('d') || button2Pressed) && !(keyPressed('a') || button1Pressed))
		{
			cameraControlsObject.position.add(cameraRightVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
		if (keyPressed('q') && !keyPressed('z'))
		{
			cameraControlsObject.position.add(cameraUpVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
		if (keyPressed('z') && !keyPressed('q'))
		{
			cameraControlsObject.position.sub(cameraUpVector.multiplyScalar(cameraFlightSpeed * frameTime));
			cameraIsMoving = true;
		}
	} // end if (shotIsInProgress)

	
	if (isShooting) 
	{
		shotPower += shotFlip * 0.5 * frameTime;
		if (shotPower > 1.0) 
		{
			shotPower = 1.0;
			shotFlip = -1;
		}
		if (shotPower < minShotPower) 
		{
			shotPower = minShotPower;
			shotFlip = 1;
		}
	}

	world.timeStep = Math.min(frameTime, 0.03333); // if frameTime takes too long, default to 1/30 sec update
	updateOimoPhysics();

	// update pathtraced sphere ballObjects to match their physics proxy bodies
	for (let i = 0; i < 24; i++) 
	{
		if (rigidBodies[i] == null)
		{
			ballObjects[i].position.set(10000,10000,10000);
			ballObjects[i].updateMatrixWorld(true);
			ballPositions[i].copy(ballObjects[i].position);
			continue;
		}
			
		ballObjects[i].position.copy(rigidBodies[i].getPosition());
		ballObjects[i].updateMatrixWorld(true);
		//ballRotations[i].copy(rigidBodies[i].getQuaternion());

		ballPositions[i].copy(ballObjects[i].position);
	}

	
	if ( !cameraIsMoving ) {
		if (playerIsAiming && canLaunchGhostAimingBall) 
		{
			launchGhostAimingBall = true;
			canLaunchGhostAimingBall = false;
		}
	}

	if (cameraIsMoving) {
		canLaunchGhostAimingBall = true;
		launchGhostAimingBall = false;
	}

	
	pathTracingUniforms.uShotIsInProgress.value = shotIsInProgress;
	

	// INFO
	if (playerOneTurn) 
	{
		if (playerOneWins)
			cameraInfoElement.innerHTML = "player 1 WINS!";
		else if (playerOneCanShootBlackBall)
			cameraInfoElement.innerHTML = "player 1's turn | color: BLACK!";
		else
			cameraInfoElement.innerHTML = "player 1's turn | color: " + playerOneColor;
	}
		
	if (playerTwoTurn) 
	{
		if (playerTwoWins)
			cameraInfoElement.innerHTML = "player 2 WINS!";
		else if (playerTwoCanShootBlackBall)
			cameraInfoElement.innerHTML = "player 2's turn | color: BLACK!";
		else
			cameraInfoElement.innerHTML = "player 2's turn | color: " + playerTwoColor;
	}
		
	if (isShooting) 
	{
		cameraInfoElement.innerHTML = "shotPower: " + shotPower.toFixed(1);
	}

} // end function updateVariablesAndUniforms()


// begin Web Audio user-interaction requirement for MacOS & iOS
const startButton = document.getElementById('startButton');
startButton.addEventListener('click', beginInit);

function beginInit()
{
	const overlay = document.getElementById('overlay');
	overlay.remove();
	init(); // init app and start animating
}
// end Web Audio user-interaction requirement for MacOS & iOS
