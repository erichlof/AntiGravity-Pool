precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tPathTracedImageTexture;
uniform float uSampleCounter;
uniform float uOneOverSampleCounter;
uniform float uPixelEdgeSharpness;
uniform float uEdgeSharpenSpeed;
//uniform float uFilterDecaySpeed;
uniform bool uCameraIsMoving;
uniform bool uSceneIsDynamic;
uniform bool uUseToneMapping;


void main()
{
	// First, start with a large blur kernel, which will be used on all diffuse
	// surfaces.  It will blur out the noise, giving a smoother, more uniform color.
	// Starting at the current pixel (centerPixel), the algorithm performs an outward search/walk
	// moving to the immediate neighbor pixels around the center pixel, and then out farther to 
	// more distant neighbors.  If the outward walk doesn't encounter any 'edge' pixels, it will continue
	// until it reaches the maximum extents of the large kernel (a little less than 7x7 pixels, minus the 4
	// corners to give a more rounded kernel filter shape). However, while walking/searching outward from
	// the center pixel, if the walk encounters an 'edge' boundary pixel, it will not blend (average in) with 
	// that pixel, and will stop the search/walk from going any further in that direction. This keeps the edge 
	// boundary pixels non-blurred, and these edges remain sharp in the final image.

	vec4 m37[37];

	vec2 glFragCoord_xy = gl_FragCoord.xy;

	
	m37[ 0] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1, 3)), 0);
	m37[ 1] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0, 3)), 0);
	m37[ 2] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1, 3)), 0);
	m37[ 3] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-2, 2)), 0);
	m37[ 4] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1, 2)), 0);
	m37[ 5] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0, 2)), 0);
	m37[ 6] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1, 2)), 0);
	m37[ 7] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 2, 2)), 0);
	m37[ 8] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-3, 1)), 0);
	m37[ 9] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-2, 1)), 0);
	m37[10] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1, 1)), 0);
	m37[11] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0, 1)), 0);
	m37[12] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1, 1)), 0);
	m37[13] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 2, 1)), 0);
	m37[14] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 3, 1)), 0);
	m37[15] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-3, 0)), 0);
	m37[16] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-2, 0)), 0);
	m37[17] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1, 0)), 0);
	m37[18] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0, 0)), 0); // center pixel
	m37[19] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1, 0)), 0);
	m37[20] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 2, 0)), 0);
	m37[21] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 3, 0)), 0);
	m37[22] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-3,-1)), 0);
	m37[23] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-2,-1)), 0);
	m37[24] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1,-1)), 0);
	m37[25] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0,-1)), 0);
	m37[26] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1,-1)), 0);
	m37[27] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 2,-1)), 0);
	m37[28] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 3,-1)), 0);
	m37[29] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-2,-2)), 0);
	m37[30] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1,-2)), 0);
	m37[31] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0,-2)), 0);
	m37[32] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1,-2)), 0);
	m37[33] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 2,-2)), 0);
	m37[34] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2(-1,-3)), 0);
	m37[35] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 0,-3)), 0);
	m37[36] = texelFetch(tPathTracedImageTexture, ivec2(glFragCoord_xy + vec2( 1,-3)), 0);

	
	vec4 centerPixel = m37[18];
	vec3 filteredPixelColor, edgePixelColor;
	float threshold = 1.0;
	int count = 1;

	// start with center pixel rgb color
	filteredPixelColor = centerPixel.rgb;

	// search above
	if (m37[11].a < threshold)
	{
		filteredPixelColor += m37[11].rgb;
		count++; 
		if (m37[5].a < threshold)
		{
			filteredPixelColor += m37[5].rgb;
			count++;
			if (m37[1].a < threshold)
			{
				filteredPixelColor += m37[1].rgb;
				count++;
				if (m37[0].a < threshold)
				{
					filteredPixelColor += m37[0].rgb;
					count++; 
				}
				if (m37[2].a < threshold)
				{
					filteredPixelColor += m37[2].rgb;
					count++; 
				}
			}
		}		
	}

	

	// search left
	if (m37[17].a < threshold)
	{
		filteredPixelColor += m37[17].rgb;
		count++; 
		if (m37[16].a < threshold)
		{
			filteredPixelColor += m37[16].rgb;
			count++;
			if (m37[15].a < threshold)
			{
				filteredPixelColor += m37[15].rgb;
				count++;
				if (m37[8].a < threshold)
				{
					filteredPixelColor += m37[8].rgb;
					count++; 
				}
				if (m37[22].a < threshold)
				{
					filteredPixelColor += m37[22].rgb;
					count++; 
				}
			}
		}	
	}

	// search right
	if (m37[19].a < threshold)
	{
		filteredPixelColor += m37[19].rgb;
		count++; 
		if (m37[20].a < threshold)
		{
			filteredPixelColor += m37[20].rgb;
			count++;
			if (m37[21].a < threshold)
			{
				filteredPixelColor += m37[21].rgb;
				count++;
				if (m37[14].a < threshold)
				{
					filteredPixelColor += m37[14].rgb;
					count++; 
				}
				if (m37[28].a < threshold)
				{
					filteredPixelColor += m37[28].rgb;
					count++; 
				}
			}
		}		
	}

	// search below
	if (m37[25].a < threshold)
	{
		filteredPixelColor += m37[25].rgb;
		count++; 
		if (m37[31].a < threshold)
		{
			filteredPixelColor += m37[31].rgb;
			count++;
			if (m37[35].a < threshold)
			{
				filteredPixelColor += m37[35].rgb;
				count++;
				if (m37[34].a < threshold)
				{
					filteredPixelColor += m37[34].rgb;
					count++; 
				}
				if (m37[36].a < threshold)
				{
					filteredPixelColor += m37[36].rgb;
					count++; 
				}
			}
		}		
	}

	// search upper-left diagonal
	if (m37[10].a < threshold)
	{
		filteredPixelColor += m37[10].rgb;
		count++; 
		if (m37[3].a < threshold)
		{
			filteredPixelColor += m37[3].rgb;
			count++;
		}		
		if (m37[4].a < threshold)
		{
			filteredPixelColor += m37[4].rgb;
			count++; 
		}
		if (m37[9].a < threshold)
		{
			filteredPixelColor += m37[9].rgb;
			count++; 
		}		
	}

	// search upper-right diagonal
	if (m37[12].a < threshold)
	{
		filteredPixelColor += m37[12].rgb;
		count++; 
		if (m37[6].a < threshold)
		{
			filteredPixelColor += m37[6].rgb;
			count++;
		}		
		if (m37[7].a < threshold)
		{
			filteredPixelColor += m37[7].rgb;
			count++; 
		}
		if (m37[13].a < threshold)
		{
			filteredPixelColor += m37[13].rgb;
			count++; 
		}		
	}

	// search lower-left diagonal
	if (m37[24].a < threshold)
	{
		filteredPixelColor += m37[24].rgb;
		count++; 
		if (m37[23].a < threshold)
		{
			filteredPixelColor += m37[23].rgb;
			count++;
		}		
		if (m37[29].a < threshold)
		{
			filteredPixelColor += m37[29].rgb;
			count++; 
		}
		if (m37[30].a < threshold)
		{
			filteredPixelColor += m37[30].rgb;
			count++; 
		}		
	}

	// search lower-right diagonal
	if (m37[26].a < threshold)
	{
		filteredPixelColor += m37[26].rgb;
		count++; 
		if (m37[27].a < threshold)
		{
			filteredPixelColor += m37[27].rgb;
			count++;
		}		
		if (m37[32].a < threshold)
		{
			filteredPixelColor += m37[32].rgb;
			count++; 
		}
		if (m37[33].a < threshold)
		{
			filteredPixelColor += m37[33].rgb;
			count++; 
		}		
	}
	
	

	// divide by total count to get the average
	filteredPixelColor *= (1.0 / float(count));



	// next, use a smaller blur kernel (3x3), to help blend the noisy, sharp edge pixels
	// 3x3 kernel
	vec3 m9[9];
	m9[0] = m37[10].rgb;
	m9[1] = m37[11].rgb;
	m9[2] = m37[12].rgb;

	m9[3] = m37[17].rgb;
	m9[4] = m37[18].rgb; // center pixel
	m9[5] = m37[19].rgb;

	m9[6] = m37[24].rgb;
	m9[7] = m37[25].rgb;
	m9[8] = m37[26].rgb;

	edgePixelColor = m9[0] + m9[1] + m9[2] + 
			 m9[3] + m9[4] + m9[5] + 
			 m9[6] + m9[7] + m9[8]; // produces white outlines along edges

	edgePixelColor *= 0.1111111111; // same as dividing by 9 pixels (1 / 9), to get the average

	

	if (centerPixel.a == 1.0) // is this an edge pixel?  centerPixel.a == 1.0
	{
		if (uSceneIsDynamic)
			filteredPixelColor = mix(edgePixelColor, centerPixel.rgb, 0.5);//uPixelEdgeSharpness);
		else // static scene
			filteredPixelColor = mix(edgePixelColor, centerPixel.rgb, clamp(uSampleCounter * uEdgeSharpenSpeed, 0.0, 1.0));	
	}

	// centerPixel.a == 1.01 means this pixel is a light source, and light sources must be sharpest
	if (centerPixel.a == 1.01) 
		filteredPixelColor = centerPixel.rgb; // no blending, maximum sharpness
	
	
	// final filteredPixelColor processing ////////////////////////////////////

	// average accumulation buffer
	filteredPixelColor *= uOneOverSampleCounter;

	// apply tone mapping (brings pixel into 0.0-1.0 rgb color range)
	filteredPixelColor = uUseToneMapping ? ReinhardToneMapping(filteredPixelColor) : filteredPixelColor;

	// lastly, apply gamma correction (gives more intensity/brightness range where it's needed)
	pc_fragColor = vec4(sqrt(filteredPixelColor), 1.0);
}
