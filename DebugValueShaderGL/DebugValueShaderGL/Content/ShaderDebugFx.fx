//
// 2d Refraction related shaders.
//
//  ps_4_0_level_9_1
//
#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0
#define PS_SHADERMODEL ps_4_0
#endif

//-----------------------------------------------------------------------------
//
// Requisite variable and texture samplers
//
//-----------------------------------------------------------------------------

// This vector should be in motion in order to achieve the desired effect.
float2 DisplacementLookupScrollOffset;
float2 ForceDirectionNormal;
float2 ForceLocation;
float SampleWavelength;
float Frequency; //
float2 TextPosition;
//float ForceDistance;
//float AngularRangeDegrees;
//float CycleTime;
//float IntegerStep;
//float2 ViewportSize;
//float2 TextureSize;

Texture2D Texture : register(t0);
sampler TextureSampler : register(s0)
{
    Texture = (Texture);
};

Texture2D DisplacementTexture;
sampler2D DisplacementSampler = sampler_state
{
    magfilter = linear;
    minfilter = linear;
    AddressU = Wrap;
    AddressV = Wrap;
    Texture = <DisplacementTexture>;
};

//-----------------------------------------------------------------------------
//
// Requisite functions.
//
//-----------------------------------------------------------------------------


// function reflect map pixel grabber my version
float4 FuncRefractMapColor(float4 color, float2 texCoord)
{
    texCoord += (tex2D(DisplacementSampler, texCoord * SampleWavelength + DisplacementLookupScrollOffset).xy - float2(0.5f, 0.5f)) * Frequency;
    return tex2D(TextureSampler, texCoord) * color;
}

// function monochrome
float4 FuncMonoChrome(float4 col)
{
    col.rgb = (col.r + col.g + col.b) / 3.0f;
    return col;
}

// standard.
float GlMod(float x, float y)
{
    return x - y * trunc(x / y);
}
float DxMod(float x, float y)
{
    return x - y * floor(x / y);
}

float ToRadians(float degrees)
{
    return degrees * 0.01745329f;
}
float ToDegrees(float radians)
{
    return radians * 57.2957795;
}

float2 LeftCross2D(float2 a)
{
    return float2(-a.y, +a.x);
}

float2 LeftCross2D(float2 start, float2 end)
{
    float2 c = end - start;
    return float2(-c.y + start.x, +c.x + start.y);
}

//-----------------------------------------------------------------------------
//
// functions relating to drawing in the shader.
//
//-----------------------------------------------------------------------------

//  --- testing
int GetDecimalDigit(float value, float whichDigit)
{
    float val1 = floor(value);
    float place = pow(10.0f, whichDigit -1.0f);
    int decimalval = abs(( (int)val1 % (place * 10)) / place);
    //int asciicharval = decimalval + 48; // only need this for the switch(,,) if i want the full ascii character range.
    return decimalval;
}

//---  directly draw lines on the shader.
// boils it down basically to a boolean variable 1.0f is true 0.0f is false.
float4 DrawLine(float2 curpixel, float4 currentColor, float2 a, float2 b, float lineThickness, float4 linecolor)
{
    float2 p = curpixel;
    float t = lineThickness;
    float2 c = b - a;
    float2 n = normalize(float2(-c.y, +c.x)); // normalized cross ab
    float2 i = -(n * dot(n, p - a) * 2.0f); // inflected perp normal
    float dist2line = 1.0f - saturate((i.x * i.x + i.y * i.y) / (t * t)); // distance of point to line.
    float isinbounds = saturate(sign(dot(a - p, a - b) * dot(b - p, b - a) + 0.001f)); // + 0.0001f  determine point is within segment.
    float strength = dist2line * isinbounds;
    return lerp(currentColor, linecolor, strength);
}

//---  directly draw circles on the shader.
// boils it down basically to a boolean variable 1.0f is true 0.0f is false.
float4 DrawCircleAtRadius(float2 curpixel, float4 currentColor, float2 testpos, float radius, float lineSize, float4 linecolor)
{
    float strength = (1.0f - saturate(abs(distance(curpixel, testpos) - (radius - lineSize / 2)) / (lineSize / 2)));
    return lerp(currentColor, linecolor, strength);
}

//---  directly draw points on the shader.
// boils it down basically to a boolean variable 1.0f is true 0.0f is false.
float4 DrawPoint(float2 curpixel, float4 currentColor, float2 testpos, float range, float4 linecolor)
{
    float2 dif = curpixel - testpos;
    float strength = 1.0f - saturate((dif.x * dif.x + dif.y * dif.y) / (range * range));
    return lerp(currentColor, linecolor, strength * strength);
}

// helper function for the primary number draw function.
float4 FuncDrawDigitAtPosition(float charValueToDisplay, float2 curpixel, float4 currentColor, float2 drawToPosition, float lineThickness, float4 lineColor)
{
    float x = 8.0f;
    float y = 8.0f;
    // if using a regular effect this is right side up.
    //float2 TL = float2(x * 0.0f, y * 0.0f)+ drawToPosition;
    //float2 TM = float2(x * 1.0f, y * 0.0f)+ drawToPosition;
    //float2 TR = float2(x * 2.0f, y * 0.0f)+ drawToPosition;
    //float2 ML = float2(x * 0.0f, y * 1.0f)+ drawToPosition;
    //float2 MM = float2(x * 1.0f, y * 1.0f)+ drawToPosition;
    //float2 MR = float2(x * 2.0f, y * 1.0f)+ drawToPosition;
    //float2 BL = float2(x * 0.0f, y * 2.0f)+ drawToPosition;
    //float2 BM = float2(x * 1.0f, y * 2.0f)+ drawToPosition;
    //float2 BR = float2(x * 2.0f, y * 2.0f)+ drawToPosition;
    // reversed for spritebatches Y flip.
    float2 BL = float2(x * 0.0f, y * 0.0f) + drawToPosition;
    float2 BM = float2(x * 1.0f, y * 0.0f) + drawToPosition;
    float2 BR = float2(x * 2.0f, y * 0.0f) + drawToPosition;
    float2 ML = float2(x * 0.0f, y * 1.0f) + drawToPosition;
    float2 MM = float2(x * 1.0f, y * 1.0f) + drawToPosition;
    float2 MR = float2(x * 2.0f, y * 1.0f) + drawToPosition;
    float2 TL = float2(x * 0.0f, y * 2.0f) + drawToPosition;
    float2 TM = float2(x * 1.0f, y * 2.0f) + drawToPosition;
    float2 TR = float2(x * 2.0f, y * 2.0f) + drawToPosition;
    //
    switch (charValueToDisplay)
    {
        case 0: // draw a 0 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BR, BL, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BL, TL, lineThickness, lineColor);
            }
            break;
        case 1: // draw a 1 character
            {
                currentColor = DrawLine(curpixel, currentColor, TM, BM, lineThickness, lineColor);
            }
            break;
        case 2: // draw a 2 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, MR, ML, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, BL, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BL, BR, lineThickness, lineColor);
            }
            break;
        case 3: // draw a 3 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BL, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, MR, MM, lineThickness, lineColor);
            }
            break;
        case 4: // draw a 4 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, ML, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BR, lineThickness, lineColor);

            }
            break;
        case 5: // draw a 5 character
            {
                currentColor = DrawLine(curpixel, currentColor, TR, TL, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TL, ML, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, MR, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BR, BL, lineThickness, lineColor);
            }
            break;
        case 6: // draw a 6 character   ToDo just make a exact circle for the bottom of the six
            {
                currentColor = DrawLine(curpixel, currentColor, TR, ML, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, BL, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BL, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BR, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, MR, ML, lineThickness, lineColor);
            }
            break;
        case 7: // draw a 7 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BL, lineThickness, lineColor);
            }
            break;
        case 8: // draw a 8 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, BL, BR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TL, BL, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BR, lineThickness, lineColor);
            }
            break;
        case 9: // draw a 9 character
            {
                currentColor = DrawLine(curpixel, currentColor, TL, TR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, ML, MR, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TL, ML, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, TR, BR, lineThickness, lineColor);
            }
            break;
        default: 
            {
                currentColor = DrawPoint(curpixel, currentColor, drawToPosition + MM, 3.0f, float4(0.0f, 0.0f, 0.0f, 1.0f));
            }
            break;
    }
    return currentColor;
}

//---  directly draw a shader float value as characters on the shader.
// boils it down basically to a boolean variable 1.0f is true 0.0f is false.
float4 FuncDrawValue(float valueToDisplay, float2 curpixel, float4 currentColor, float2 drawToPosition, float lineThickness, float4 lineColor)
{
    float distbetweenchars = 22.0f;
    float x = 8.0f;
    float y = 8.0f;
    float signDraw = saturate(sign(valueToDisplay) + 1.0f);
    switch (signDraw)
    {
        case 0: // draw a 0 character
            {
                currentColor = DrawLine(curpixel, currentColor, float2(x * 0.0f, y * 1.0f) + drawToPosition, float2(x * 2.0f, y * 1.0f) + drawToPosition, lineThickness, lineColor);
            }
            break;
        default:
            {
                currentColor = DrawLine(curpixel, currentColor, float2(x * 0.0f, y * 1.0f) + drawToPosition, float2(x * 2.0f, y * 1.0f) + drawToPosition, lineThickness, lineColor);
                currentColor = DrawLine(curpixel, currentColor, float2(x * 1.0f, y * 2.0f) + drawToPosition, float2(x * 1.0f, y * 0.0f) + drawToPosition, lineThickness, lineColor);
            }
            break;
    }
    // character or digit draw positions.
    float shiftedValue = trunc(abs(valueToDisplay *= 1000.0f));

    // drawing location offsets.
    float2 digit1DrawLocation = drawToPosition + float2(distbetweenchars * 7.2f, 0.0f);
    float2 digit2DrawLocation = drawToPosition + float2(distbetweenchars * 6.2f, 0.0f);
    float2 digit3DrawLocation = drawToPosition + float2(distbetweenchars * 5.2f, 0.0f);
    float2 decimalPointDrawLocation = drawToPosition + float2(distbetweenchars * 4.95f, y * 0.0f);
    float2 digit4DrawLocation = drawToPosition + float2(distbetweenchars * 4.0f, 0.0f);
    float2 digit5DrawLocation = drawToPosition + float2(distbetweenchars * 3.0f, 0.0f);
    float2 digit6DrawLocation = drawToPosition + float2(distbetweenchars * 2.0f, 0.0f);
    float2 digit7DrawLocation = drawToPosition + float2(distbetweenchars * 1.0f, 0.0f);
    
    // get digit from value.
    int switchVal1 = GetDecimalDigit(shiftedValue, 1);
    int switchVal2 = GetDecimalDigit(shiftedValue, 2);
    int switchVal3 = GetDecimalDigit(shiftedValue, 3);
    // the decimal point goes here.
    int switchVal4 = GetDecimalDigit(shiftedValue, 4);
    int switchVal5 = GetDecimalDigit(shiftedValue, 5);
    int switchVal6 = GetDecimalDigit(shiftedValue, 6);
    int switchVal7 = GetDecimalDigit(shiftedValue, 7);
    // draw digit at position.
    currentColor = FuncDrawDigitAtPosition(switchVal1, curpixel, currentColor, digit1DrawLocation, lineThickness, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal2, curpixel, currentColor, digit2DrawLocation, lineThickness, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal3, curpixel, currentColor, digit3DrawLocation, lineThickness, lineColor);
    currentColor = DrawPoint(curpixel, currentColor, decimalPointDrawLocation, 4.0f, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal4, curpixel, currentColor, digit4DrawLocation, lineThickness, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal5, curpixel, currentColor, digit5DrawLocation, lineThickness, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal6, curpixel, currentColor, digit6DrawLocation, lineThickness, lineColor);
    currentColor = FuncDrawDigitAtPosition(switchVal7, curpixel, currentColor, digit7DrawLocation, lineThickness, lineColor);
    return currentColor;
}



//-----------------------------------------------------------------------------
//
// Requisite Shaders.
//
//-----------------------------------------------------------------------------


////__________________________________________________
//// (Tech) PsShaderDebugDraw  
//// Outputs lines points hollow circles and numerical values as text.
//__________________________________________________
float4 PsShaderDebugDraw(float4 position : SV_Position, float4 color : COLOR0, float2 texCoord : TEXCOORD0) : COLOR0
{
	//  points distances and variable positions.
    float4 currentColor = tex2D(TextureSampler, texCoord) * color * float4(0.99f, 0.79f, 0.79f, 1.00f);
    float2 curpixel = position;
    float2 p = position; // current pixel position.
    float2 a = float2(200.0f, 400.0f);
    float2 b = float2(300.0f, 400.0f);
    float2 c = ForceLocation; // for now this is were the mouse is.
    float2 d = LeftCross2D(a, c);
    float2 m = ((c - b) * 0.5f + b);

    float lineSize = 3.0f;
    float pointSize = 20.0f;
    float4 lineColor = float4(0.99f, 0.79f, 0.79f, 1.0f); // default is whitish red;
    float4 lineColorRed = float4(0.99f, 0.00f, 0.00f, 1.0f);
    float4 lineColorGreen = float4(0.00f, 0.99f, 0.00f, 1.0f);
    float4 lineColorBlue = float4(0.00f, 0.00f, 0.99f, 1.0f);
    float4 lineColorWhite = float4(0.99f, 0.99f, 0.99f, 1.0f);
    float4 lineColorBlack = float4(0.00f, 0.00f, 0.00f, 1.0f);
    float4 lineColorAqua = float4(0.00f, 0.99f, 0.99f, 1.0f);
    float4 lineColorYellow = float4(0.99f, 0.99f, 0.00f, 1.0f);

    // display circular radius about midpoint m.
    currentColor = DrawCircleAtRadius(p, currentColor, m, length(c - b) * 0.5f, 3.0f, lineColorYellow);

    // draw the lines.
    currentColor = DrawLine(position.xy, currentColor, b, a, lineSize, lineColorRed);
    currentColor = DrawLine(position.xy, currentColor, c, b, lineSize, lineColorGreen);
    currentColor = DrawLine(position.xy, currentColor, a, c, lineSize, lineColorBlue);
    currentColor = DrawLine(position.xy, currentColor, d, a, 2.0f, lineColorAqua);

    //// draw the points a b c d.
    currentColor = DrawPoint(p, currentColor, a, pointSize, lineColorRed);
    currentColor = DrawPoint(p, currentColor, b, pointSize, lineColorGreen);
    currentColor = DrawPoint(p, currentColor, c, pointSize, lineColorBlue);
    currentColor = DrawPoint(p, currentColor, d, pointSize, lineColorAqua);


    // Display the mouse x value.
    float valuetotest = ForceLocation.x; 
    currentColor = FuncDrawValue(valuetotest, curpixel, currentColor, TextPosition, lineSize, lineColorWhite);
    
    // Display the mouse y value.
    float valuetotest2 = ForceLocation.y;
    currentColor = FuncDrawValue(valuetotest2, curpixel, currentColor, TextPosition + float2(250.0f, -2.0f), lineSize, lineColorWhite);

    // since sprite batch flips the y value in the shader the y goes from bottom to top for positive values.
   
    return currentColor;
}

//__________________________________________________
// (Tech)  refraction map shader mine
//__________________________________________________

float4 PsRefractionMap(float4 position : SV_Position, float4 color : COLOR0, float2 texCoord : TEXCOORD0) : COLOR0
{
    float4 col = FuncRefractMapColor(color, texCoord.rg);
    return col;
}


//-----------------------------------------------------------------------------
//
// Requisite Techniques.
//
//-----------------------------------------------------------------------------

technique ShaderDebugDraw
{
    pass Pass0
    {
        PixelShader = compile PS_SHADERMODEL
			PsShaderDebugDraw();
    }
}

technique RefractionMap
{
    pass Pass0
    {
        PixelShader = compile PS_SHADERMODEL
        PsRefractionMap();
    }
}

