#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// These are points to sample relative to the starting point
float2 sobelSamplePoints2[9] = {
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1),
};




// Weights for the x component
float sobelXMatrix2[9] = {
    1, 0, -1,
    2, 0, -2,
    1, 0, -1
};

// Weights for the y component
 float sobelYMatrix2[9] = {
    1, 2, 1,
    0, 0, 0,
    -1, -2, -1
};


float3 GetTransformNormalViewOffset(float3 InputNormal, float3 AddVector) 
{
 
    return AddVector;
}


float3 GetConvertPositionNormal(float3 WorldNormal, float3 OffsetValue)
{
    float3 world = GetCameraRelativePositionWS(WorldNormal.xyz);
    float4 Clip = TransformWorldToHClip(world);
    float3 ConvertUV = Clip.xyz / Clip.w;
#if UNITY_UV_STARTS_AT_TOP
    ConvertUV.y = -ConvertUV.y;
#endif
    ConvertUV.xy = ConvertUV.xy * 0.5 + 0.5;
    float3 ConvertResult = ConvertUV;

    float3 AddVector = ConvertResult + (OffsetValue);

    world = ComputeWorldSpacePosition(AddVector.xyz.xy, AddVector.xyz.z, UNITY_MATRIX_I_VP);
    return  GetAbsolutePositionWS(world);
}






void LightColor_float(float4 shadowCoord ,out float3 LightColor)
{
#if SHADERGRAPH_PREVIEW
    LightColor = 1;
#else
#if SHADOWS_SCREEN

#else

#endif
    Light mainLight = GetMainLight(shadowCoord);
    LightColor = mainLight.color;
#endif
}
void LightColor_half(half4 shadowCoord, out half3 LightColor)
{
#if SHADERGRAPH_PREVIEW
    LightColor = 1;
#else
#if SHADOWS_SCREEN

#else

#endif
    Light mainLight = GetMainLight(shadowCoord);
    LightColor = mainLight.color;
#endif
}

void MainLightPosition_float(out float3 Position)
{
 
    
#if SHADERGRAPH_PREVIEW
    Position = float3(0, 0, 0);
 
#else
#if SHADOWS_SCREEN

#else

#endif
    float3 pos = half3(_MainLightPosition.xyz);
    Position = pos;
#endif
}
void MainLightPosition_half(out half3 Position)
{
 
#if SHADERGRAPH_PREVIEW
    Position = float3(0, 0, 0);

#else
#if SHADOWS_SCREEN

#else

#endif
    float3 pos = half3(_MainLightPosition.xyz);
    Position = pos;
#endif

}

void MainLightVector_float(out float3 LightVector) 
{
    float4 shadowCoord = float4(0, 0, 0, 0);
    LightVector = 0;

#if SHADERGRAPH_PREVIEW
    
 
#else
#if SHADOWS_SCREEN

#else

#endif
    Light mainLight = GetMainLight(shadowCoord);
    LightVector = mainLight.direction;
#endif

}

void MainLight_float(float3 WorldPos, float4 shadowCoord, out float3 Direction, out float3 Color, out float DistanceAtten, out float ShadowAtten)
{
#if SHADERGRAPH_PREVIEW
    Direction = float3(0.5, 0.5, 0);
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else
#if SHADOWS_SCREEN
 
#else
     
#endif
	Light mainLight = GetMainLight(shadowCoord);
	Direction = mainLight.direction;
	Color = mainLight.color;
	DistanceAtten = mainLight.distanceAttenuation;
	ShadowAtten = mainLight.shadowAttenuation;
#endif
}
void MainLight_half(float3 WorldPos, float4 shadowCoord, out half3 Direction, out half3 Color, out half DistanceAtten, out half ShadowAtten)
{
#if SHADERGRAPH_PREVIEW
    Direction = half3(0.5, 0.5, 0);
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else
#if SHADOWS_SCREEN
 
#else
 
#endif
	Light mainLight = GetMainLight(shadowCoord);
	Direction = mainLight.direction;
	Color = mainLight.color;
    DistanceAtten = mainLight.distanceAttenuation;
    ShadowAtten = mainLight.shadowAttenuation;
#endif
}

void MainLightSoftShadow_float(float3 WorldPos ,float3 Normal ,float Softness, int Sampling , out float ShadowAtten)
{
    float3 SamplePoints3[11] = {
    float3(-1, 1, 1), float3(0, 1 ,0), float3(1, 1 ,-1),
    float3(-1, 0, 0), float3(0, 0 ,0), float3(1, 0 ,0),
    float3(-1, -1, 1), float3(0, -1 , 0), float3(1, -1 ,-1),
    float3(-1, -1 ,-1),float3(1, 1 ,1)
    };


    float Per = Softness / Sampling;
    ShadowAtten = 0;
    Normal = float3(1, 1, 1);
#if SHADERGRAPH_PREVIEW


#else
#if SHADOWS_SCREEN

    float4 clipPos = TransformWorldToHClip(WorldPos);
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else

    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);

#endif
    Light mainLight;
    //x_shift
    for (int i = 0; i < Sampling; ++i)
    {
        for (int ii = 0; ii < 11; ++ii)
        {
            shadowCoord = TransformWorldToShadowCoord(WorldPos + (SamplePoints3[ii] * Per * 0.01) * i);
            //shadowCoord = TransformWorldToShadowCoord( GetConvertPositionNormal(WorldPos, (SamplePoints3[ii] * Per * 0.01) * i) );
            mainLight = GetMainLight(shadowCoord);
            ShadowAtten += (mainLight.shadowAttenuation);
        }
    }
 
    ShadowAtten /= Sampling * 11;

#endif
}
float Remap(float In, float2 InMinMax, float2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}
void AdditionalLightsSoftShadow_Rev2_float(float3 WorldPos, float Softness, float DecayDistance ,int Sampling, out float ShadowAttenResult, out float distanceAtten)
{
    float3 SamplePoints3[11] = {
       float3(-1, 1, 1), float3(0, 1 ,0), float3(1, 1 ,-1),
       float3(-1, 0, 0), float3(0, 0 ,0), float3(1, 0 ,0),
       float3(-1, -1, 1), float3(0, -1 , 0), float3(1, -1 ,-1),
       float3(-1, -1 ,-1),float3(1, 1 ,1)
    };
    float2 In = float2(0, 1);
    float2 Out = float2(1, 0);

    float4 ShadowMask;
    float4 lightPositionWS = float4(0.0, 0.0, 0.0, 0.0);
    float Per = 0;
    float ShadowAtten = 0;
    ShadowAttenResult = 0;

#if SHADERGRAPH_PREVIEW
    ShadowAtten = 0;
    ShadowAttenResult = 0;
    distanceAtten = 0;

#else
#if SHADOWS_SCREEN
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        lightPositionWS = _AdditionalLightsPosition[i];
        ShadowAtten = 0;
        //float Dist = (1.0 / DecayDistance) * clamp( distance(lightPositionWS, WorldPos)  , 0.01 , DecayDistance);
        //Dist = Remap(Dist, In, Out);
        

        for (int ii = 0; ii < Sampling; ++ii)
        {
            for (int i3 = 0; i3 < 11; ++i3)
            {
                Per = Softness  / Sampling;
                light = GetAdditionalLight(i, WorldPos + ((SamplePoints3[i3] * Per * 0.01) * ii), ShadowMask);
                ShadowAtten += (light.shadowAttenuation);
            }
        }
        ShadowAtten /= Sampling * 11;
        ShadowAttenResult += lerp(0, clamp(ShadowAtten, 0, 1), light.distanceAttenuation);
        distanceAtten += light.distanceAttenuation;
    }
#endif
}


void AdditionalLightsDot_float(float3 WorldPosition, float3 Normal, float3 MultplyVector, float FlatBlend , out float Result)
{
    float3 diffuseColor = 0;

#if SHADERGRAPH_PREVIEW

#else
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();

    for (int i = 0; i < pixelLightCount; ++i)
    {
        light = GetAdditionalLight(i, WorldPosition);
        float dotResult = clamp(dot(Normal, MultplyVector * light.direction), 0, 1);
        float diff_nor = lerp(0, dotResult, light.distanceAttenuation);
        float3 ColorResult = clamp(lerp(0, light.color, light.distanceAttenuation), 0, 1);
        diffuseColor += lerp(diff_nor, ColorResult, FlatBlend);
    }
#endif
    Result = diffuseColor;
} 

void AdditionalLightsSoftShadow_float(float3 WorldPos, float Softness, int Sampling, out float ShadowAttenResult, out float distanceAtten)
{
    float3 SamplePoints3[11] = {
       float3(-1, 1, 1), float3(0, 1 ,0), float3(1, 1 ,-1),
       float3(-1, 0, 0), float3(0, 0 ,0), float3(1, 0 ,0),
       float3(-1, -1, 1), float3(0, -1 , 0), float3(1, -1 ,-1),
       float3(-1, -1 ,-1),float3(1, 1 ,1)
    };
    float4 ShadowMask;
    float4 lightPositionWS = float4(0.0, 0.0, 0.0, 0.0);
    float Per = 0;
    float ShadowAtten = 0;
    ShadowAttenResult = 0;

#if SHADERGRAPH_PREVIEW
    ShadowAtten = 0;
    ShadowAttenResult = 0;
    distanceAtten = 0;

#else
#if SHADOWS_SCREEN
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        lightPositionWS = _AdditionalLightsPosition[i];
        ShadowAtten = 0;
        for (int ii = 0; ii < Sampling; ++ii)
        {
            for (int i3 = 0; i3 < 11; ++i3)
            {
                float Dist =  clamp(distance(lightPositionWS, WorldPos), 0, 1) ;
                Per = (Softness * Dist) / Sampling;
                light = GetAdditionalLight(i, (WorldPos + (SamplePoints3[i3] * Per * 0.01) * ii), ShadowMask);
                ShadowAtten += (light.shadowAttenuation);
            }
        }
        ShadowAtten /= Sampling * 11;
        ShadowAttenResult += lerp( 0, clamp(ShadowAtten , 0 , 1) , light.distanceAttenuation);
        distanceAtten += light.distanceAttenuation;
    }
#endif
}
void AdditionalLightsPosition_float(float3 WorldPosition, float3 Normal , float3 TestVec , out float3 Diffuse)
{
    float4 lightPositionWS = float4(0.0, 0.0, 0.0, 0.0);
    float3 diffuseColor = 0;

#if SHADERGRAPH_PREVIEW

#else
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();

    for (int i = 0; i < pixelLightCount; ++i)
    {
        light = GetAdditionalLight(i, WorldPosition);
        lightPositionWS = _AdditionalLightsPosition[i];
        
        float3 vec = normalize(lightPositionWS - WorldPosition);
        float dotResult = clamp( dot(Normal, light.direction) , 0, 1);
        if (dotResult > 0) 
        {
            dotResult = 1;
        }
        float result = lerp(0 , dotResult, light.distanceAttenuation);
        diffuseColor += result;
    }
#endif
    Diffuse = diffuseColor;
}

void AdditionalLightsVector_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView , float FlatBlend , out float Attenuation, out float3 Diffuse, out float3 Specular)
{
    Attenuation = 0;
    float4 lightPositionWS = float4(0.0, 0.0, 0.0, 0.0);

    float3 diffuseColor = 0;
    float3 specularColor = 0;
    float3 black = 0;
 
    
#if SHADERGRAPH_PREVIEW

#else
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);

    for (int i = 0; i < pixelLightCount; ++i)
    {
       light = GetAdditionalLight(i, WorldPosition);
       lightPositionWS = _AdditionalLightsPosition[i];
       float shading = dot(WorldNormal, light.direction);
       float Atten = lerp(0,  shading , light.distanceAttenuation);
       float Result = lerp(Atten, light.distanceAttenuation, FlatBlend);
       Attenuation += clamp(Result, 0, 1);
       
   
       float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
       float3 diff_nor = LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
       float3 ColorResult = clamp( lerp(0, light.color, light.distanceAttenuation) , 0 ,1 );
       //float3 NormalResult = lerp(WorldNormal, light.direction, FlatBlend);

       diffuseColor += lerp(diff_nor, ColorResult , FlatBlend);
       specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness);
    }

#endif

    Diffuse = diffuseColor;
    Specular = specularColor;
}
void AdditionalLightsVector_half(half3 SpecColor, half Smoothness, half3 WorldPosition, half3 WorldNormal, half3 WorldView, half FlatBlend, out half Attenuation, out half3 Diffuse, out half3 Specular)
{
    Attenuation = 0;
    half4 lightPositionWS = half4(0.0, 0.0, 0.0, 0.0);

    half3 diffuseColor = 0;
    half3 specularColor = 0;
    half3 black = 0;


#if SHADERGRAPH_PREVIEW

#else
    Light light;
    int pixelLightCount = GetAdditionalLightsCount();
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);

    for (int i = 0; i < pixelLightCount; ++i)
    {
        light = GetAdditionalLight(i, WorldPosition);
        lightPositionWS = _AdditionalLightsPosition[i];
        half shading = dot(WorldNormal, light.direction);
        half Atten = lerp(0, shading, light.distanceAttenuation);
        half Result = lerp(Atten, light.distanceAttenuation, FlatBlend);
        Attenuation += clamp(Result, 0, 1);


        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        half3 diff_nor = LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
        half3 ColorResult = clamp(lerp(0, light.color, light.distanceAttenuation), 0, 1);
        //float3 NormalResult = lerp(WorldNormal, light.direction, FlatBlend);

        diffuseColor += lerp(diff_nor, ColorResult, FlatBlend);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness);
    }

#endif

    Diffuse = diffuseColor;
    Specular = specularColor;
}

void GetVertexLighting_float(float3 positionWS, half3 normalWS ,float AttenBias , out float OutColor)
{
    OutColor = float3(0.0, 0.0, 0.0);

#if SHADERGRAPH_PREVIEW
 
#else
#if SHADOWS_SCREEN

#else

#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
    half3 lightColor = float3(1, 1,1);
    OutColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END

       
#endif
        OutColor += AttenBias;
#endif
   
}

void GetVertexLighting_half(float3 positionWS, half3 normalWS, float AttenBias, out float OutColor)
{
    OutColor = float3(0.0, 0.0, 0.0);

#if SHADERGRAPH_PREVIEW

#else
#if SHADOWS_SCREEN

#else

#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
    half3 lightColor = float3(1, 1, 1);;
    OutColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END

       
#endif
         OutColor += AttenBias;
#endif

}



void DirectSpecular_float(float3 Specular, float Smoothness, float3 Direction, float3 Color, float3 WorldNormal, float3 WorldView, out float3 Out)
{
#if SHADERGRAPH_PREVIEW
    Out = 0;
#else
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    Out = LightingSpecular(Color, Direction, WorldNormal, WorldView, float4(Specular, 0), Smoothness);
#endif
}

void DirectSpecular_half(half3 Specular, half Smoothness, half3 Direction, half3 Color, half3 WorldNormal, half3 WorldView, out half3 Out)
{
#if SHADERGRAPH_PREVIEW
    Out = 0;
#else
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    Out = LightingSpecular(Color, Direction, WorldNormal, WorldView,half4(Specular, 0), Smoothness);
#endif
}

void AdditionalLights_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView, out float3 Diffuse, out float3 Specular)
{
    float3 diffuseColor = 0;
    float3 specularColor = 0;

#ifndef SHADERGRAPH_PREVIEW
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness);
    }
#endif

    Diffuse = diffuseColor;
    Specular = specularColor;
}

void AdditionalLights_half(half3 SpecColor, half Smoothness, half3 WorldPosition, half3 WorldNormal, half3 WorldView, out half3 Diffuse, out half3 Specular)
{
    half3 diffuseColor = 0;
    half3 specularColor = 0;

#ifndef SHADERGRAPH_PREVIEW
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, half4(SpecColor, 0), Smoothness);
    }
#endif

    Diffuse = diffuseColor;
    Specular = specularColor;
}

#endif

void AdditionalLights_Atten_float(float3 WorldPos, half4 ShadowMask, out float shadowAtten ,out float distanceAtten )
{
    float3 diffuseColor = 0;
    float3 specularColor = 0;
    half Smoothness = 0;

#if SHADERGRAPH_PREVIEW
    shadowAtten = 0;
    distanceAtten = 0;
         
#else
#if SHADOWS_SCREEN
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif
    Smoothness = exp2(10 * Smoothness + 1);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPos , ShadowMask);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);

        shadowAtten += light.shadowAttenuation;
        distanceAtten += light.distanceAttenuation;
    }
    

#endif
}

void AdditionalLights_Atten_half(float3 WorldPos, half4 ShadowMask , out half shadowAtten, out half distanceAtten)
{
    float3 diffuseColor = 0;
    float3 specularColor = 0;
    half Smoothness = 0;

#if SHADERGRAPH_PREVIEW
    shadowAtten = 0;
    distanceAtten = 0;
#else
#if SHADOWS_SCREEN
    float4 shadowCoord = ComputeScreenPos(clipPos);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif
    Smoothness = exp2(10 * Smoothness + 1);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPos , ShadowMask);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);

        shadowAtten += light.shadowAttenuation;
        distanceAtten += light.distanceAttenuation;
    }
#endif
}

 



void ShadowCoord_float(float3 WorldPos, out float4 shadowCoord)
{

#if SHADERGRAPH_PREVIEW

        shadowCoord = float4(0, 0, 0, 0);
#else
#if SHADOWS_SCREEN
        float4 clipPos = TransformWorldToHClip(WorldPos);
        shadowCoord = ComputeScreenPos(clipPos);
#else
        shadowCoord= TransformWorldToShadowCoord(WorldPos);
#endif
        //shadowCoord = shadowCoord;

#endif
 }
