precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uBallPositions[24];
uniform bool uShotIsInProgress;

#define N_LIGHTS 8.0
#define N_SPHERES 8
#define N_BOXES 1

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_interior_intersect>



//---------------------------------------------------------------------------------------
float SceneIntersect()
//---------------------------------------------------------------------------------------
{
	float d = INFINITY;
	float t = INFINITY;
	vec3 n;
	int objectCount = 0;
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// white cueball / glass aiming ball
	d = SphereIntersect( 2.0, uBallPositions[0], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[0];
		hitEmission = vec3(0);
		//hitColor = uShotIsInProgress ? vec3(1) : vec3(2);
		hitColor = vec3(1);
		hitType = uShotIsInProgress ? COAT : REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// black ball
	d = SphereIntersect( 2.0, uBallPositions[1], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[1];
		hitEmission = vec3(0);
		hitColor = vec3(0.005);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// red balls

	d = SphereIntersect( 2.0, uBallPositions[2], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[2];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[3], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[3];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[4], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[4];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[5], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[5];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[6], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[6];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[7], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[7];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[8], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[8];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// yellow balls

	d = SphereIntersect( 2.0, uBallPositions[9], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[9];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[10], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[10];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[11], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[11];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[12], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[12];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[13], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[13];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[14], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[14];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( 2.0, uBallPositions[15], rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - uBallPositions[15];
		hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// pockets / lights
        
	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[3].position;
		hitEmission = spheres[3].emission;
		hitColor = spheres[3].color;
		hitType = spheres[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[4].radius, spheres[4].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[4].position;
		hitEmission = spheres[4].emission;
		hitColor = spheres[4].color;
		hitType = spheres[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[5].radius, spheres[5].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[5].position;
		hitEmission = spheres[5].emission;
		hitColor = spheres[5].color;
		hitType = spheres[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[6].radius, spheres[6].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[6].position;
		hitEmission = spheres[6].emission;
		hitColor = spheres[6].color;
		hitType = spheres[6].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[7].radius, spheres[7].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[7].position;
		hitEmission = spheres[7].emission;
		hitColor = spheres[7].color;
		hitType = spheres[7].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	
	return t;
	
} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance(out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Sphere lightChoice;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 dirToLight;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int intBest = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;


	for (int bounces = 0; bounces < 8; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;
		
		t = SceneIntersect();

		// //not used in this scene because we are inside a large box shape - no rays can escape
		if (t == INFINITY)
		{
			break;
		}


		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		
		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && isReflectionTime == FALSE)
			{
				pixelSharpness = 1.0;
				accumCol += mask * clamp(hitEmission, 0.0, 2.0);
			}
				
			else if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
				accumCol += mask * hitEmission;
			}
			else if (sampleLight == TRUE) 
			{
				accumCol += mask * clamp(hitEmission, 0.0, 8.0);
			} 

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				continue;
			}
				
			//reached a light, so we can exit
			break;
		}


		// if we get here and sampleLight is still true, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				continue;
			}

			break;
		}

		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= hitColor;
			
			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// loop through the 8 sphere lights and find the best one to sample
			for (int i = 0; i < N_SPHERES; i++)
			{
				intBest = rng() < dot(nl, normalize(spheres[i].position - x)) ? i : intBest;
			}
			lightChoice = spheres[intBest];

			dirToLight = randomDirectionInSpecularLobe(normalize(lightChoice.position - x), 0.15);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= N_LIGHTS;
			mask *= max(0.0, dot(nl, dirToLight)) * 0.005;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.3; // IOR of special Glass aiming cueball for this game

			// use 'nl' instead of 'n' in below function arguments for non-ray-bending clear materials
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// make glass aiming cueball brighter
			// if (diffuseCount == 0 && bounces == 1)
			// 	mask = uEPS_intersect == 1.0 ? vec3(6) : vec3(2); // make even brighter on mobile

			mask *= hitColor;
			mask *= Tr;

			// transmit ray through surface
			rayDirection = rayDirection; // this lets the viewing ray pass through without bending due to refraction
			rayOrigin = x - nl * uEPS_intersect;

			continue;
			
		} // end if (hitType == REFR)

		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.8; // IOR of very thick ClearCoat for pool balls
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (diffuseCount == 0 && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
			mask *= hitColor;
			
			bounceIsSpecular = FALSE;

			// loop through the 8 sphere lights and find the best one to sample
			for (int i = 0; i < N_SPHERES; i++)
			{
				intBest = rng() * 1.5 < dot(nl, normalize(spheres[i].position - x)) ? i : intBest;
			}
			lightChoice = spheres[intBest];

			dirToLight = randomDirectionInSpecularLobe(normalize(lightChoice.position - x), 0.2);
			
			mask *= N_LIGHTS;
			mask *= max(0.0, dot(nl, dirToLight)) * 0.03;//0.01;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == COAT)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z = vec3(0);
	vec3 L = vec3(1, 1, 1) * 10.0; // bright White light
	
        spheres[0] = Sphere(10.0, uBallPositions[16], L, z, LIGHT); // bottom left front spherical light
	spheres[1] = Sphere(10.0, uBallPositions[17], L, z, LIGHT); // bottom right front spherical light
	spheres[2] = Sphere(10.0, uBallPositions[18], L, z, LIGHT); // top left front spherical light
	spheres[3] = Sphere(10.0, uBallPositions[19], L, z, LIGHT); // top right front spherical light

	spheres[4] = Sphere(10.0, uBallPositions[20], L, z, LIGHT); // bottom left back spherical light
	spheres[5] = Sphere(10.0, uBallPositions[21], L, z, LIGHT); // bottom right back spherical light
	spheres[6] = Sphere(10.0, uBallPositions[22], L, z, LIGHT); // top left back spherical light
	spheres[7] = Sphere(10.0, uBallPositions[23], L, z, LIGHT); // top right back spherical light
	
	boxes[0] = Box(vec3(-50.5), vec3(50.5), z, vec3(0.0, 0.05, 0.99), DIFF); // Diffuse Box
}




// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


void main( void )
{
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	// the following is not needed - three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);
	// initialize rand() variables
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
	pixelOffset *= uCameraIsMoving ? 0.5 : 1.5; //1.5 needed to smooth out edges of pool balls
	
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;
	
	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	rayOrigin = cameraPosition + randomAperturePos;
	rayDirection = finalRayDir;

	SetupScene();
	
	// Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal, objectColor;
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;
	
	// perform path tracing and get resulting pixel color
	vec4 currentPixel = vec4( vec3(CalculateRadiance(objectNormal, objectColor, objectID, pixelSharpness)), 0.0 );

	// if difference between normals of neighboring pixels is less than the first edge0 threshold, the white edge line effect is considered off (0.0)
	float edge0 = 0.2; // edge0 is the minimum difference required between normals of neighboring pixels to start becoming a white edge line
	// any difference between normals of neighboring pixels that is between edge0 and edge1 smoothly ramps up the white edge line brightness (smoothstep 0.0-1.0)
	float edge1 = 0.6; // once the difference between normals of neighboring pixels is >= this edge1 threshold, the white edge line is considered fully bright (1.0)
	float difference_Nx = fwidth(objectNormal.x);
	float difference_Ny = fwidth(objectNormal.y);
	float difference_Nz = fwidth(objectNormal.z);
	float normalDifference = smoothstep(edge0, edge1, difference_Nx) + smoothstep(edge0, edge1, difference_Ny) + smoothstep(edge0, edge1, difference_Nz);

	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	// white-line debug visualization for normal difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(normalDifference);
	// white-line debug visualization for object difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(objectDifference);
	// white-line debug visualization for color difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(colorDifference);
	// white-line debug visualization for all 3 differences
	//currentPixel.rgb += (rng() * 1.5) * vec3( clamp(max(normalDifference, max(objectDifference, colorDifference)), 0.0, 1.0) );
 
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);


	if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)
		
		previousPixel.a = 0.0;
	}
	else 
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	currentPixel.a = pixelSharpness;

	// check for all edges that are not light sources
	if (pixelSharpness < 1.01 && (colorDifference >= 1.0 || normalDifference >= 1.0 || objectDifference >= 1.0)) // all other edges
		currentPixel.a = pixelSharpness = 1.0;

	// makes light source edges (shape boundaries) more stable
	// if (previousPixel.a == 1.01)
	// 	currentPixel.a = 1.01;

	// makes sharp edges more stable
	if (previousPixel.a == 1.0)
		currentPixel.a = 1.0;
		
	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.0 && rng() < 0.05)
		currentPixel.a = 0.0;
	

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
