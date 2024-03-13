// Made with Amplify Shader Editor v1.9.3.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "HSS08/FX/Screen Flip (Passthrough)"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[IntRange]_FlipCount("Flip Count", Range( 1 , 3)) = 1
		_SideA("Side A", 2D) = "white" {}
		_SideB("Side B", 2D) = "white" {}
		[Toggle]_GlobalControl("Global Control", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 2
		[KeywordEnum(UV,WorldGrid,WorldGrid2,ObjectGrid)] _UVMode("UV Mode", Float) = 0
		_GridSize("Grid Size", Vector) = (8,8,0,0)
		[Toggle]_DebugOut("Debug Out", Float) = 0
		_Transition("Transition", Range( 0 , 1)) = 0
		_FlipFuzz("Flip Fuzz", Range( 0 , 0.5)) = 0.1


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		_MetaDepthOcclusionBias("Occlusion Depth Bias", Float) = 0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Unlit" }

		Cull [_Cull]
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
		#include "Packages/com.meta.xr.depthapi.urp/Shaders/EnvironmentOcclusionURP.hlsl" // Meta Quest 3 Depth Occlusion

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_SRP_VERSION 140009


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			// Meta Quest 3 Depth Occlusion
			#pragma multi_compile _ HARD_OCCLUSION SOFT_OCCLUSION
			#if !defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				#define ASE_NEEDS_FRAG_WORLD_POSITION
			#endif
			// End MQ3DO

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
			#pragma multi_compile __ _KVRL_PASSTHROUGH_ON
			#pragma shader_feature_local _UVMODE_UV _UVMODE_WORLDGRID _UVMODE_WORLDGRID2 _UVMODE_OBJECTGRID


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float2 _GridSize;
			float _Cull;
			float _GlobalControl;
			float _FlipFuzz;
			float _Transition;
			float _FlipCount;
			float _DebugOut;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
				float _MetaDepthOcclusionBias;
			CBUFFER_END

			sampler2D _SideA;
			float4 KVRL_TransitionSphere;
			float KVRL_PanelTransition;
			sampler2D _SideB;


			float3 Selector( float TestA, float TestB, float TestC, float3 OutA, float3 OutB, float3 OutC )
			{
				float m = min(min(TestA, TestB), TestC);
				if (TestA == m) {
				return OutA;
				}
				if (TestB == m) {
				return OutB;
				}
				return OutC;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord6.xy = v.ase_texcoord.xy;
				o.ase_texcoord7 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 _Vector3 = float2(1,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				float3 worldToObjDir128 = mul( GetWorldToObjectMatrix(), float4( float3(1,0,0), 0 ) ).xyz;
				float3 normalizeResult172 = normalize( worldToObjDir128 );
				float TestA236 = abs( normalizeResult172.y );
				float3 worldToObjDir166 = mul( GetWorldToObjectMatrix(), float4( float3(0,1,0), 0 ) ).xyz;
				float3 normalizeResult173 = normalize( worldToObjDir166 );
				float TestB236 = abs( normalizeResult173.y );
				float3 worldToObjDir167 = mul( GetWorldToObjectMatrix(), float4( float3(0,0,1), 0 ) ).xyz;
				float3 normalizeResult174 = normalize( worldToObjDir167 );
				float TestC236 = abs( normalizeResult174.y );
				float3 OutA236 = worldToObjDir128;
				float3 OutB236 = worldToObjDir166;
				float3 OutC236 = worldToObjDir167;
				float3 localSelector236 = Selector( TestA236 , TestB236 , TestC236 , OutA236 , OutB236 , OutC236 );
				float3 break253 = ( cross( ( ase_parentObjectScale * localSelector236 ) , ( float3(0,1,0) * ase_parentObjectScale ) ) / ase_parentObjectScale );
				float2 appendResult254 = (float2(break253.x , break253.z));
				float2 selectTileAxis188 = appendResult254;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 break327 = abs( ase_worldNormal );
				float TestA316 = break327.x;
				float TestB316 = break327.y;
				float TestC316 = break327.z;
				float3 _Vector8 = float3(1,0,0);
				float3 OutA316 = _Vector8;
				float3 _Vector9 = float3(0,1,0);
				float3 OutB316 = _Vector9;
				float3 _Vector7 = float3(0,0,1);
				float3 OutC316 = _Vector7;
				float3 localSelector316 = Selector( TestA316 , TestB316 , TestC316 , OutA316 , OutB316 , OutC316 );
				float3 temp_output_331_0 = cross( localSelector316 , ase_worldNormal );
				float3 normalizeResult352 = normalize( temp_output_331_0 );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float temp_output_387_0 = ( dotResult335 * dotResult336 );
				float temp_output_359_0 = sign( temp_output_387_0 );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , temp_output_359_0 ));
				float2 appendResult338 = (float2(lerpResult393 , dotResult336));
				float2 normalizeResult361 = normalize( appendResult338 );
				float2 refactorAxis339 = normalizeResult361;
				#if defined(_UVMODE_UV)
				float2 staticSwitch157 = _Vector3;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch157 = selectTileAxis188;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch157 = refactorAxis339;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch157 = _Vector3;
				#else
				float2 staticSwitch157 = _Vector3;
				#endif
				float2 temp_output_29_0_g30 = staticSwitch157;
				float2 normalizeResult30_g30 = normalize( temp_output_29_0_g30 );
				float2 texCoord11 = IN.ase_texcoord6.xy * float2( 1,1 ) + float2( 0,0 );
				float3 appendResult434 = (float3(IN.ase_texcoord7.xyz.x , 0.0 , IN.ase_texcoord7.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = appendResult434;
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float2 appendResult134 = (float2(IN.ase_texcoord7.xyz.x , IN.ase_texcoord7.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( (inputCoord26).xz ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float3 temp_output_10_0_g44 = inputCoord26;
				float2 appendResult12_g44 = (float2(temp_output_10_0_g44.xy));
				float2 gridSize2D22_g44 = _GridSize;
				float2 temp_output_7_0_g44 = ( ( 1.0 / gridSize2D22_g44 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g44 * gridSize2D22_g44 ) ) / gridSize2D22_g44 ) + temp_output_7_0_g44 );
				float cellSize3D25_g44 = ( 1.0 / _GridSize.x );
				float3 temp_output_16_0_g44 = floor( ( temp_output_10_0_g44 / cellSize3D25_g44 ) );
				float temp_output_17_0_g44 = ( cellSize3D25_g44 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g44 * cellSize3D25_g44 ) + temp_output_17_0_g44 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float2 appendResult135 = (float2(worldToObj126.x , worldToObj126.z));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = (cellCenter3D117).xz;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g30 = staticSwitch121;
				float2 temp_output_5_0_g30 = ( staticSwitch136.xy - center77_g30 );
				float dotResult31_g30 = dot( normalizeResult30_g30 , temp_output_5_0_g30 );
				float temp_output_1_0_g31 = 0.0;
				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float fuzzy149 = _FlipFuzz;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( lerpResult293 + fuzzy149 ) , rawTransitionVal310);
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				#if defined(_UVMODE_UV)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch416 = objToWorld417;
				#else
				float3 staticSwitch416 = cellCenter3D117;
				#endif
				float3 transitionCellCenter418 = staticSwitch416;
				float3 appendResult291 = (float3(KVRL_TransitionSphere.xyz));
				float3 lerpResult294 = lerp( float3(0,1,-2.7) , appendResult291 , useGlobals292);
				float smoothstepResult148 = smoothstep( ( lerpResult146 + fuzzy149 ) , ( lerpResult146 - fuzzy149 ) , ( fuzzy149 + distance( transitionCellCenter418 , lerpResult294 ) ));
				float transitionValue59 = smoothstepResult148;
				float temp_output_4_0_g30 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float cosFactor57_g30 = temp_output_4_0_g30;
				float2 cellRadius2D34 = temp_output_7_0_g44;
				float cellRadius3D118 = abs( temp_output_17_0_g44 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float2 appendResult142 = (float2(ase_parentObjectScale.x , ase_parentObjectScale.z));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				float2 appendResult364 = (float2(ase_parentObjectScale.z , ase_parentObjectScale.x));
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = ( appendResult140 / appendResult364 );
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g30 = staticSwitch122;
				float dotResult36_g30 = dot( temp_output_29_0_g30 , cellRadius59_g30 );
				float flipRadius55_g30 = abs( dotResult36_g30 );
				float temp_output_53_0_g30 = ( ( dotResult31_g30 - temp_output_1_0_g31 ) / ( ( cosFactor57_g30 * flipRadius55_g30 ) - temp_output_1_0_g31 ) );
				float2 temp_output_62_0_g30 = ( ( temp_output_53_0_g30 * flipRadius55_g30 ) * normalizeResult30_g30 );
				float side73_g30 = saturate( step( temp_output_4_0_g30 , 0.0 ) );
				float2 lerpResult75_g30 = lerp( temp_output_62_0_g30 , -temp_output_62_0_g30 , side73_g30);
				float2 deltaUV39_g30 = temp_output_5_0_g30;
				float2 flipDelta64_g30 = ( dotResult31_g30 * normalizeResult30_g30 );
				float2 nonFlipUV67_g30 = ( deltaUV39_g30 - flipDelta64_g30 );
				float2 outputCoord41 = ( lerpResult75_g30 + nonFlipUV67_g30 + center77_g30 );
				float2 temp_output_1_0_g33 = outputCoord41;
				float sideIndex87 = side73_g30;
				float4 lerpResult5_g33 = lerp( tex2D( _SideA, temp_output_1_0_g33 ) , tex2D( _SideB, temp_output_1_0_g33 ) , sideIndex87);
				float outputMask42 = step( abs( temp_output_53_0_g30 ) , 1.0 );
				float testOutg220 = frac( cellCenter3D117 ).y;
				float4 temp_cast_8 = (testOutg220).xxxx;
				float4 lerpResult223 = lerp( ( lerpResult5_g33 * outputMask42 ) , temp_cast_8 , _DebugOut);
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch303 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch303 = staticSwitch299;
				#endif
				clip( staticSwitch303 - 0.5);
				#ifdef _KVRL_PASSTHROUGH_ON
				float4 staticSwitch301 = lerpResult223;
				#else
				float4 staticSwitch301 = lerpResult223;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = staticSwitch301.rgb;
				float Alpha = staticSwitch299;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float occlusionBias = _MetaDepthOcclusionBias; 

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
				
				// Meta Quest 3 Depth Occlusion
				half4 finalFrag = half4(Color, Alpha);


				META_DEPTH_OCCLUDE_OUTPUT_PREMULTIPLY_WORLDPOS(IN.positionWS, finalFrag, occlusionBias);
				return finalFrag;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile __ _KVRL_PASSTHROUGH_ON
			#pragma shader_feature_local _UVMODE_UV _UVMODE_WORLDGRID _UVMODE_WORLDGRID2 _UVMODE_OBJECTGRID


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float2 _GridSize;
			float _Cull;
			float _GlobalControl;
			float _FlipFuzz;
			float _Transition;
			float _FlipCount;
			float _DebugOut;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 KVRL_TransitionSphere;
			float KVRL_PanelTransition;


			float3 Selector( float TestA, float TestB, float TestC, float3 OutA, float3 OutB, float3 OutC )
			{
				float m = min(min(TestA, TestB), TestC);
				if (TestA == m) {
				return OutA;
				}
				if (TestB == m) {
				return OutB;
				}
				return OutC;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float fuzzy149 = _FlipFuzz;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( lerpResult293 + fuzzy149 ) , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float3 appendResult434 = (float3(IN.ase_texcoord3.xyz.x , 0.0 , IN.ase_texcoord3.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = appendResult434;
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g44 = inputCoord26;
				float cellSize3D25_g44 = ( 1.0 / _GridSize.x );
				float3 temp_output_16_0_g44 = floor( ( temp_output_10_0_g44 / cellSize3D25_g44 ) );
				float temp_output_17_0_g44 = ( cellSize3D25_g44 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g44 * cellSize3D25_g44 ) + temp_output_17_0_g44 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				#if defined(_UVMODE_UV)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch416 = objToWorld417;
				#else
				float3 staticSwitch416 = cellCenter3D117;
				#endif
				float3 transitionCellCenter418 = staticSwitch416;
				float3 appendResult291 = (float3(KVRL_TransitionSphere.xyz));
				float3 lerpResult294 = lerp( float3(0,1,-2.7) , appendResult291 , useGlobals292);
				float smoothstepResult148 = smoothstep( ( lerpResult146 + fuzzy149 ) , ( lerpResult146 - fuzzy149 ) , ( fuzzy149 + distance( transitionCellCenter418 , lerpResult294 ) ));
				float transitionValue59 = smoothstepResult148;
				float temp_output_4_0_g30 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g30 = saturate( step( temp_output_4_0_g30 , 0.0 ) );
				float sideIndex87 = side73_g30;
				float2 _Vector3 = float2(1,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				float3 worldToObjDir128 = mul( GetWorldToObjectMatrix(), float4( float3(1,0,0), 0 ) ).xyz;
				float3 normalizeResult172 = normalize( worldToObjDir128 );
				float TestA236 = abs( normalizeResult172.y );
				float3 worldToObjDir166 = mul( GetWorldToObjectMatrix(), float4( float3(0,1,0), 0 ) ).xyz;
				float3 normalizeResult173 = normalize( worldToObjDir166 );
				float TestB236 = abs( normalizeResult173.y );
				float3 worldToObjDir167 = mul( GetWorldToObjectMatrix(), float4( float3(0,0,1), 0 ) ).xyz;
				float3 normalizeResult174 = normalize( worldToObjDir167 );
				float TestC236 = abs( normalizeResult174.y );
				float3 OutA236 = worldToObjDir128;
				float3 OutB236 = worldToObjDir166;
				float3 OutC236 = worldToObjDir167;
				float3 localSelector236 = Selector( TestA236 , TestB236 , TestC236 , OutA236 , OutB236 , OutC236 );
				float3 break253 = ( cross( ( ase_parentObjectScale * localSelector236 ) , ( float3(0,1,0) * ase_parentObjectScale ) ) / ase_parentObjectScale );
				float2 appendResult254 = (float2(break253.x , break253.z));
				float2 selectTileAxis188 = appendResult254;
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 break327 = abs( ase_worldNormal );
				float TestA316 = break327.x;
				float TestB316 = break327.y;
				float TestC316 = break327.z;
				float3 _Vector8 = float3(1,0,0);
				float3 OutA316 = _Vector8;
				float3 _Vector9 = float3(0,1,0);
				float3 OutB316 = _Vector9;
				float3 _Vector7 = float3(0,0,1);
				float3 OutC316 = _Vector7;
				float3 localSelector316 = Selector( TestA316 , TestB316 , TestC316 , OutA316 , OutB316 , OutC316 );
				float3 temp_output_331_0 = cross( localSelector316 , ase_worldNormal );
				float3 normalizeResult352 = normalize( temp_output_331_0 );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float temp_output_387_0 = ( dotResult335 * dotResult336 );
				float temp_output_359_0 = sign( temp_output_387_0 );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , temp_output_359_0 ));
				float2 appendResult338 = (float2(lerpResult393 , dotResult336));
				float2 normalizeResult361 = normalize( appendResult338 );
				float2 refactorAxis339 = normalizeResult361;
				#if defined(_UVMODE_UV)
				float2 staticSwitch157 = _Vector3;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch157 = selectTileAxis188;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch157 = refactorAxis339;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch157 = _Vector3;
				#else
				float2 staticSwitch157 = _Vector3;
				#endif
				float2 temp_output_29_0_g30 = staticSwitch157;
				float2 normalizeResult30_g30 = normalize( temp_output_29_0_g30 );
				float2 appendResult134 = (float2(IN.ase_texcoord3.xyz.x , IN.ase_texcoord3.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( (inputCoord26).xz ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g44 = (float2(temp_output_10_0_g44.xy));
				float2 gridSize2D22_g44 = _GridSize;
				float2 temp_output_7_0_g44 = ( ( 1.0 / gridSize2D22_g44 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g44 * gridSize2D22_g44 ) ) / gridSize2D22_g44 ) + temp_output_7_0_g44 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float2 appendResult135 = (float2(worldToObj126.x , worldToObj126.z));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = (cellCenter3D117).xz;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g30 = staticSwitch121;
				float2 temp_output_5_0_g30 = ( staticSwitch136.xy - center77_g30 );
				float dotResult31_g30 = dot( normalizeResult30_g30 , temp_output_5_0_g30 );
				float temp_output_1_0_g31 = 0.0;
				float cosFactor57_g30 = temp_output_4_0_g30;
				float2 cellRadius2D34 = temp_output_7_0_g44;
				float cellRadius3D118 = abs( temp_output_17_0_g44 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float2 appendResult142 = (float2(ase_parentObjectScale.x , ase_parentObjectScale.z));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				float2 appendResult364 = (float2(ase_parentObjectScale.z , ase_parentObjectScale.x));
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = ( appendResult140 / appendResult364 );
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g30 = staticSwitch122;
				float dotResult36_g30 = dot( temp_output_29_0_g30 , cellRadius59_g30 );
				float flipRadius55_g30 = abs( dotResult36_g30 );
				float temp_output_53_0_g30 = ( ( dotResult31_g30 - temp_output_1_0_g31 ) / ( ( cosFactor57_g30 * flipRadius55_g30 ) - temp_output_1_0_g31 ) );
				float outputMask42 = step( abs( temp_output_53_0_g30 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				

				float Alpha = staticSwitch299;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile __ _KVRL_PASSTHROUGH_ON
			#pragma shader_feature_local _UVMODE_UV _UVMODE_WORLDGRID _UVMODE_WORLDGRID2 _UVMODE_OBJECTGRID


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float2 _GridSize;
			float _Cull;
			float _GlobalControl;
			float _FlipFuzz;
			float _Transition;
			float _FlipCount;
			float _DebugOut;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 KVRL_TransitionSphere;
			float KVRL_PanelTransition;


			float3 Selector( float TestA, float TestB, float TestC, float3 OutA, float3 OutB, float3 OutC )
			{
				float m = min(min(TestA, TestB), TestC);
				if (TestA == m) {
				return OutA;
				}
				if (TestB == m) {
				return OutB;
				}
				return OutC;
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord1.xyz = ase_worldPos;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float fuzzy149 = _FlipFuzz;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( lerpResult293 + fuzzy149 ) , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 appendResult434 = (float3(IN.ase_texcoord2.xyz.x , 0.0 , IN.ase_texcoord2.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = appendResult434;
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g44 = inputCoord26;
				float cellSize3D25_g44 = ( 1.0 / _GridSize.x );
				float3 temp_output_16_0_g44 = floor( ( temp_output_10_0_g44 / cellSize3D25_g44 ) );
				float temp_output_17_0_g44 = ( cellSize3D25_g44 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g44 * cellSize3D25_g44 ) + temp_output_17_0_g44 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				#if defined(_UVMODE_UV)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch416 = objToWorld417;
				#else
				float3 staticSwitch416 = cellCenter3D117;
				#endif
				float3 transitionCellCenter418 = staticSwitch416;
				float3 appendResult291 = (float3(KVRL_TransitionSphere.xyz));
				float3 lerpResult294 = lerp( float3(0,1,-2.7) , appendResult291 , useGlobals292);
				float smoothstepResult148 = smoothstep( ( lerpResult146 + fuzzy149 ) , ( lerpResult146 - fuzzy149 ) , ( fuzzy149 + distance( transitionCellCenter418 , lerpResult294 ) ));
				float transitionValue59 = smoothstepResult148;
				float temp_output_4_0_g30 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g30 = saturate( step( temp_output_4_0_g30 , 0.0 ) );
				float sideIndex87 = side73_g30;
				float2 _Vector3 = float2(1,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				float3 worldToObjDir128 = mul( GetWorldToObjectMatrix(), float4( float3(1,0,0), 0 ) ).xyz;
				float3 normalizeResult172 = normalize( worldToObjDir128 );
				float TestA236 = abs( normalizeResult172.y );
				float3 worldToObjDir166 = mul( GetWorldToObjectMatrix(), float4( float3(0,1,0), 0 ) ).xyz;
				float3 normalizeResult173 = normalize( worldToObjDir166 );
				float TestB236 = abs( normalizeResult173.y );
				float3 worldToObjDir167 = mul( GetWorldToObjectMatrix(), float4( float3(0,0,1), 0 ) ).xyz;
				float3 normalizeResult174 = normalize( worldToObjDir167 );
				float TestC236 = abs( normalizeResult174.y );
				float3 OutA236 = worldToObjDir128;
				float3 OutB236 = worldToObjDir166;
				float3 OutC236 = worldToObjDir167;
				float3 localSelector236 = Selector( TestA236 , TestB236 , TestC236 , OutA236 , OutB236 , OutC236 );
				float3 break253 = ( cross( ( ase_parentObjectScale * localSelector236 ) , ( float3(0,1,0) * ase_parentObjectScale ) ) / ase_parentObjectScale );
				float2 appendResult254 = (float2(break253.x , break253.z));
				float2 selectTileAxis188 = appendResult254;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 break327 = abs( ase_worldNormal );
				float TestA316 = break327.x;
				float TestB316 = break327.y;
				float TestC316 = break327.z;
				float3 _Vector8 = float3(1,0,0);
				float3 OutA316 = _Vector8;
				float3 _Vector9 = float3(0,1,0);
				float3 OutB316 = _Vector9;
				float3 _Vector7 = float3(0,0,1);
				float3 OutC316 = _Vector7;
				float3 localSelector316 = Selector( TestA316 , TestB316 , TestC316 , OutA316 , OutB316 , OutC316 );
				float3 temp_output_331_0 = cross( localSelector316 , ase_worldNormal );
				float3 normalizeResult352 = normalize( temp_output_331_0 );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float temp_output_387_0 = ( dotResult335 * dotResult336 );
				float temp_output_359_0 = sign( temp_output_387_0 );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , temp_output_359_0 ));
				float2 appendResult338 = (float2(lerpResult393 , dotResult336));
				float2 normalizeResult361 = normalize( appendResult338 );
				float2 refactorAxis339 = normalizeResult361;
				#if defined(_UVMODE_UV)
				float2 staticSwitch157 = _Vector3;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch157 = selectTileAxis188;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch157 = refactorAxis339;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch157 = _Vector3;
				#else
				float2 staticSwitch157 = _Vector3;
				#endif
				float2 temp_output_29_0_g30 = staticSwitch157;
				float2 normalizeResult30_g30 = normalize( temp_output_29_0_g30 );
				float2 appendResult134 = (float2(IN.ase_texcoord2.xyz.x , IN.ase_texcoord2.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( (inputCoord26).xz ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g44 = (float2(temp_output_10_0_g44.xy));
				float2 gridSize2D22_g44 = _GridSize;
				float2 temp_output_7_0_g44 = ( ( 1.0 / gridSize2D22_g44 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g44 * gridSize2D22_g44 ) ) / gridSize2D22_g44 ) + temp_output_7_0_g44 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float2 appendResult135 = (float2(worldToObj126.x , worldToObj126.z));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = (cellCenter3D117).xz;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g30 = staticSwitch121;
				float2 temp_output_5_0_g30 = ( staticSwitch136.xy - center77_g30 );
				float dotResult31_g30 = dot( normalizeResult30_g30 , temp_output_5_0_g30 );
				float temp_output_1_0_g31 = 0.0;
				float cosFactor57_g30 = temp_output_4_0_g30;
				float2 cellRadius2D34 = temp_output_7_0_g44;
				float cellRadius3D118 = abs( temp_output_17_0_g44 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float2 appendResult142 = (float2(ase_parentObjectScale.x , ase_parentObjectScale.z));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				float2 appendResult364 = (float2(ase_parentObjectScale.z , ase_parentObjectScale.x));
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = ( appendResult140 / appendResult364 );
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g30 = staticSwitch122;
				float dotResult36_g30 = dot( temp_output_29_0_g30 , cellRadius59_g30 );
				float flipRadius55_g30 = abs( dotResult36_g30 );
				float temp_output_53_0_g30 = ( ( dotResult31_g30 - temp_output_1_0_g31 ) / ( ( cosFactor57_g30 * flipRadius55_g30 ) - temp_output_1_0_g31 ) );
				float outputMask42 = step( abs( temp_output_53_0_g30 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				

				surfaceDescription.Alpha = staticSwitch299;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile __ _KVRL_PASSTHROUGH_ON
			#pragma shader_feature_local _UVMODE_UV _UVMODE_WORLDGRID _UVMODE_WORLDGRID2 _UVMODE_OBJECTGRID


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float2 _GridSize;
			float _Cull;
			float _GlobalControl;
			float _FlipFuzz;
			float _Transition;
			float _FlipCount;
			float _DebugOut;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 KVRL_TransitionSphere;
			float KVRL_PanelTransition;


			float3 Selector( float TestA, float TestB, float TestC, float3 OutA, float3 OutB, float3 OutC )
			{
				float m = min(min(TestA, TestB), TestC);
				if (TestA == m) {
				return OutA;
				}
				if (TestB == m) {
				return OutB;
				}
				return OutC;
			}
			

			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord1.xyz = ase_worldPos;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float fuzzy149 = _FlipFuzz;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( lerpResult293 + fuzzy149 ) , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 appendResult434 = (float3(IN.ase_texcoord2.xyz.x , 0.0 , IN.ase_texcoord2.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = appendResult434;
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g44 = inputCoord26;
				float cellSize3D25_g44 = ( 1.0 / _GridSize.x );
				float3 temp_output_16_0_g44 = floor( ( temp_output_10_0_g44 / cellSize3D25_g44 ) );
				float temp_output_17_0_g44 = ( cellSize3D25_g44 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g44 * cellSize3D25_g44 ) + temp_output_17_0_g44 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				#if defined(_UVMODE_UV)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch416 = objToWorld417;
				#else
				float3 staticSwitch416 = cellCenter3D117;
				#endif
				float3 transitionCellCenter418 = staticSwitch416;
				float3 appendResult291 = (float3(KVRL_TransitionSphere.xyz));
				float3 lerpResult294 = lerp( float3(0,1,-2.7) , appendResult291 , useGlobals292);
				float smoothstepResult148 = smoothstep( ( lerpResult146 + fuzzy149 ) , ( lerpResult146 - fuzzy149 ) , ( fuzzy149 + distance( transitionCellCenter418 , lerpResult294 ) ));
				float transitionValue59 = smoothstepResult148;
				float temp_output_4_0_g30 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g30 = saturate( step( temp_output_4_0_g30 , 0.0 ) );
				float sideIndex87 = side73_g30;
				float2 _Vector3 = float2(1,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				float3 worldToObjDir128 = mul( GetWorldToObjectMatrix(), float4( float3(1,0,0), 0 ) ).xyz;
				float3 normalizeResult172 = normalize( worldToObjDir128 );
				float TestA236 = abs( normalizeResult172.y );
				float3 worldToObjDir166 = mul( GetWorldToObjectMatrix(), float4( float3(0,1,0), 0 ) ).xyz;
				float3 normalizeResult173 = normalize( worldToObjDir166 );
				float TestB236 = abs( normalizeResult173.y );
				float3 worldToObjDir167 = mul( GetWorldToObjectMatrix(), float4( float3(0,0,1), 0 ) ).xyz;
				float3 normalizeResult174 = normalize( worldToObjDir167 );
				float TestC236 = abs( normalizeResult174.y );
				float3 OutA236 = worldToObjDir128;
				float3 OutB236 = worldToObjDir166;
				float3 OutC236 = worldToObjDir167;
				float3 localSelector236 = Selector( TestA236 , TestB236 , TestC236 , OutA236 , OutB236 , OutC236 );
				float3 break253 = ( cross( ( ase_parentObjectScale * localSelector236 ) , ( float3(0,1,0) * ase_parentObjectScale ) ) / ase_parentObjectScale );
				float2 appendResult254 = (float2(break253.x , break253.z));
				float2 selectTileAxis188 = appendResult254;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 break327 = abs( ase_worldNormal );
				float TestA316 = break327.x;
				float TestB316 = break327.y;
				float TestC316 = break327.z;
				float3 _Vector8 = float3(1,0,0);
				float3 OutA316 = _Vector8;
				float3 _Vector9 = float3(0,1,0);
				float3 OutB316 = _Vector9;
				float3 _Vector7 = float3(0,0,1);
				float3 OutC316 = _Vector7;
				float3 localSelector316 = Selector( TestA316 , TestB316 , TestC316 , OutA316 , OutB316 , OutC316 );
				float3 temp_output_331_0 = cross( localSelector316 , ase_worldNormal );
				float3 normalizeResult352 = normalize( temp_output_331_0 );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float temp_output_387_0 = ( dotResult335 * dotResult336 );
				float temp_output_359_0 = sign( temp_output_387_0 );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , temp_output_359_0 ));
				float2 appendResult338 = (float2(lerpResult393 , dotResult336));
				float2 normalizeResult361 = normalize( appendResult338 );
				float2 refactorAxis339 = normalizeResult361;
				#if defined(_UVMODE_UV)
				float2 staticSwitch157 = _Vector3;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch157 = selectTileAxis188;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch157 = refactorAxis339;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch157 = _Vector3;
				#else
				float2 staticSwitch157 = _Vector3;
				#endif
				float2 temp_output_29_0_g30 = staticSwitch157;
				float2 normalizeResult30_g30 = normalize( temp_output_29_0_g30 );
				float2 appendResult134 = (float2(IN.ase_texcoord2.xyz.x , IN.ase_texcoord2.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( (inputCoord26).xz ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g44 = (float2(temp_output_10_0_g44.xy));
				float2 gridSize2D22_g44 = _GridSize;
				float2 temp_output_7_0_g44 = ( ( 1.0 / gridSize2D22_g44 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g44 * gridSize2D22_g44 ) ) / gridSize2D22_g44 ) + temp_output_7_0_g44 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float2 appendResult135 = (float2(worldToObj126.x , worldToObj126.z));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = (cellCenter3D117).xz;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g30 = staticSwitch121;
				float2 temp_output_5_0_g30 = ( staticSwitch136.xy - center77_g30 );
				float dotResult31_g30 = dot( normalizeResult30_g30 , temp_output_5_0_g30 );
				float temp_output_1_0_g31 = 0.0;
				float cosFactor57_g30 = temp_output_4_0_g30;
				float2 cellRadius2D34 = temp_output_7_0_g44;
				float cellRadius3D118 = abs( temp_output_17_0_g44 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float2 appendResult142 = (float2(ase_parentObjectScale.x , ase_parentObjectScale.z));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				float2 appendResult364 = (float2(ase_parentObjectScale.z , ase_parentObjectScale.x));
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = ( appendResult140 / appendResult364 );
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g30 = staticSwitch122;
				float dotResult36_g30 = dot( temp_output_29_0_g30 , cellRadius59_g30 );
				float flipRadius55_g30 = abs( dotResult36_g30 );
				float temp_output_53_0_g30 = ( ( dotResult31_g30 - temp_output_1_0_g31 ) / ( ( cosFactor57_g30 * flipRadius55_g30 ) - temp_output_1_0_g31 ) );
				float outputMask42 = step( abs( temp_output_53_0_g30 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				

				surfaceDescription.Alpha = staticSwitch299;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile __ _KVRL_PASSTHROUGH_ON
			#pragma shader_feature_local _UVMODE_UV _UVMODE_WORLDGRID _UVMODE_WORLDGRID2 _UVMODE_OBJECTGRID


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float2 _GridSize;
			float _Cull;
			float _GlobalControl;
			float _FlipFuzz;
			float _Transition;
			float _FlipCount;
			float _DebugOut;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 KVRL_TransitionSphere;
			float KVRL_PanelTransition;


			float3 Selector( float TestA, float TestB, float TestC, float3 OutA, float3 OutB, float3 OutC )
			{
				float m = min(min(TestA, TestB), TestC);
				if (TestA == m) {
				return OutA;
				}
				if (TestB == m) {
				return OutB;
				}
				return OutC;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.positionOS).xyz );
				o.ase_texcoord2.xyz = ase_worldPos;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

				o.positionCS = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float fuzzy149 = _FlipFuzz;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( lerpResult293 + fuzzy149 ) , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord2.xyz;
				float3 appendResult434 = (float3(IN.ase_texcoord3.xyz.x , 0.0 , IN.ase_texcoord3.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = appendResult434;
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g44 = inputCoord26;
				float cellSize3D25_g44 = ( 1.0 / _GridSize.x );
				float3 temp_output_16_0_g44 = floor( ( temp_output_10_0_g44 / cellSize3D25_g44 ) );
				float temp_output_17_0_g44 = ( cellSize3D25_g44 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g44 * cellSize3D25_g44 ) + temp_output_17_0_g44 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				#if defined(_UVMODE_UV)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch416 = cellCenter3D117;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch416 = objToWorld417;
				#else
				float3 staticSwitch416 = cellCenter3D117;
				#endif
				float3 transitionCellCenter418 = staticSwitch416;
				float3 appendResult291 = (float3(KVRL_TransitionSphere.xyz));
				float3 lerpResult294 = lerp( float3(0,1,-2.7) , appendResult291 , useGlobals292);
				float smoothstepResult148 = smoothstep( ( lerpResult146 + fuzzy149 ) , ( lerpResult146 - fuzzy149 ) , ( fuzzy149 + distance( transitionCellCenter418 , lerpResult294 ) ));
				float transitionValue59 = smoothstepResult148;
				float temp_output_4_0_g30 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g30 = saturate( step( temp_output_4_0_g30 , 0.0 ) );
				float sideIndex87 = side73_g30;
				float2 _Vector3 = float2(1,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				float3 worldToObjDir128 = mul( GetWorldToObjectMatrix(), float4( float3(1,0,0), 0 ) ).xyz;
				float3 normalizeResult172 = normalize( worldToObjDir128 );
				float TestA236 = abs( normalizeResult172.y );
				float3 worldToObjDir166 = mul( GetWorldToObjectMatrix(), float4( float3(0,1,0), 0 ) ).xyz;
				float3 normalizeResult173 = normalize( worldToObjDir166 );
				float TestB236 = abs( normalizeResult173.y );
				float3 worldToObjDir167 = mul( GetWorldToObjectMatrix(), float4( float3(0,0,1), 0 ) ).xyz;
				float3 normalizeResult174 = normalize( worldToObjDir167 );
				float TestC236 = abs( normalizeResult174.y );
				float3 OutA236 = worldToObjDir128;
				float3 OutB236 = worldToObjDir166;
				float3 OutC236 = worldToObjDir167;
				float3 localSelector236 = Selector( TestA236 , TestB236 , TestC236 , OutA236 , OutB236 , OutC236 );
				float3 break253 = ( cross( ( ase_parentObjectScale * localSelector236 ) , ( float3(0,1,0) * ase_parentObjectScale ) ) / ase_parentObjectScale );
				float2 appendResult254 = (float2(break253.x , break253.z));
				float2 selectTileAxis188 = appendResult254;
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 break327 = abs( IN.normalWS );
				float TestA316 = break327.x;
				float TestB316 = break327.y;
				float TestC316 = break327.z;
				float3 _Vector8 = float3(1,0,0);
				float3 OutA316 = _Vector8;
				float3 _Vector9 = float3(0,1,0);
				float3 OutB316 = _Vector9;
				float3 _Vector7 = float3(0,0,1);
				float3 OutC316 = _Vector7;
				float3 localSelector316 = Selector( TestA316 , TestB316 , TestC316 , OutA316 , OutB316 , OutC316 );
				float3 temp_output_331_0 = cross( localSelector316 , IN.normalWS );
				float3 normalizeResult352 = normalize( temp_output_331_0 );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float temp_output_387_0 = ( dotResult335 * dotResult336 );
				float temp_output_359_0 = sign( temp_output_387_0 );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , temp_output_359_0 ));
				float2 appendResult338 = (float2(lerpResult393 , dotResult336));
				float2 normalizeResult361 = normalize( appendResult338 );
				float2 refactorAxis339 = normalizeResult361;
				#if defined(_UVMODE_UV)
				float2 staticSwitch157 = _Vector3;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch157 = selectTileAxis188;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch157 = refactorAxis339;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch157 = _Vector3;
				#else
				float2 staticSwitch157 = _Vector3;
				#endif
				float2 temp_output_29_0_g30 = staticSwitch157;
				float2 normalizeResult30_g30 = normalize( temp_output_29_0_g30 );
				float2 appendResult134 = (float2(IN.ase_texcoord3.xyz.x , IN.ase_texcoord3.xyz.z));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( (inputCoord26).xz ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g44 = (float2(temp_output_10_0_g44.xy));
				float2 gridSize2D22_g44 = _GridSize;
				float2 temp_output_7_0_g44 = ( ( 1.0 / gridSize2D22_g44 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g44 * gridSize2D22_g44 ) ) / gridSize2D22_g44 ) + temp_output_7_0_g44 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float2 appendResult135 = (float2(worldToObj126.x , worldToObj126.z));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = (cellCenter3D117).xz;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g30 = staticSwitch121;
				float2 temp_output_5_0_g30 = ( staticSwitch136.xy - center77_g30 );
				float dotResult31_g30 = dot( normalizeResult30_g30 , temp_output_5_0_g30 );
				float temp_output_1_0_g31 = 0.0;
				float cosFactor57_g30 = temp_output_4_0_g30;
				float2 cellRadius2D34 = temp_output_7_0_g44;
				float cellRadius3D118 = abs( temp_output_17_0_g44 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float2 appendResult142 = (float2(ase_parentObjectScale.x , ase_parentObjectScale.z));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				float2 appendResult364 = (float2(ase_parentObjectScale.z , ase_parentObjectScale.x));
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = ( appendResult140 / appendResult364 );
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g30 = staticSwitch122;
				float dotResult36_g30 = dot( temp_output_29_0_g30 , cellRadius59_g30 );
				float flipRadius55_g30 = abs( dotResult36_g30 );
				float temp_output_53_0_g30 = ( ( dotResult31_g30 - temp_output_1_0_g31 ) / ( ( cosFactor57_g30 * flipRadius55_g30 ) - temp_output_1_0_g31 ) );
				float outputMask42 = step( abs( temp_output_53_0_g30 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				

				surfaceDescription.Alpha = staticSwitch299;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19302
Node;AmplifyShaderEditor.CommentaryNode;305;-2068.813,-1030.851;Inherit;False;1946.993;694.3204;Create Grid out of input coordinates, output grid centers and cell sizes;14;119;120;34;25;118;117;26;125;11;409;410;420;423;434;UV Grid;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;320;-6166.855,-136.1776;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;120;-2039.721,-699.6614;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;313;-5626.014,-1224.522;Inherit;False;2782.714;796.3502;To align flip axist to closest World Space axis;26;165;163;164;167;166;128;172;173;174;178;179;180;219;218;217;236;249;247;248;250;251;252;253;254;188;239;Flip Axis;1,1,1,1;0;0
Node;AmplifyShaderEditor.AbsOpNode;324;-5544.352,-143.306;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1527.868,-970.9323;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;125;-1490.312,-851.8826;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;434;-1625.274,-706.8828;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;317;-6145.236,369.8335;Inherit;False;Constant;_Vector7;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;318;-6157,54.18637;Inherit;False;Constant;_Vector8;Vector 4;8;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;319;-6148.236,215.8333;Inherit;False;Constant;_Vector9;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;165;-5564.251,-613.1718;Inherit;False;Constant;_Vector6;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;163;-5576.014,-928.8188;Inherit;False;Constant;_Vector4;Vector 4;8;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;164;-5567.251,-767.1718;Inherit;False;Constant;_Vector5;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;327;-5407.352,-138.306;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.StaticSwitch;119;-1242.517,-824.0913;Inherit;False;Property;_UVMode;UV Mode;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;4;UV;WorldGrid;WorldGrid2;ObjectGrid;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;167;-5369.251,-613.1718;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;166;-5368.251,-766.1718;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;128;-5360.166,-920.5337;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;332;-5215.448,391.0483;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;316;-5218.146,2.29301;Inherit;False;float m = min(min(TestA, TestB), TestC)@$if (TestA == m) {$return OutA@$}$if (TestB == m) {$return OutB@$}$return OutC@;3;Create;6;True;TestA;FLOAT;0;In;;Inherit;False;True;TestB;FLOAT;0;In;;Inherit;False;True;TestC;FLOAT;0;In;;Inherit;False;True;OutA;FLOAT3;0,0,0;In;;Inherit;False;True;OutB;FLOAT3;0,0,0;In;;Inherit;False;True;OutC;FLOAT3;0,0,0;In;;Inherit;False;Selector;False;False;0;;False;6;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-967.9767,-816.4578;Inherit;False;inputCoord;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;172;-5087.924,-922.0229;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;173;-5086.924,-766.0228;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;174;-5088.924,-610.0228;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;331;-4993.795,298.8884;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;435;-701.1661,-818.1656;Inherit;False;UV Grid;8;;44;00fc8464f2b1b2f4182579db99f68779;0;1;10;FLOAT3;0,0,0;False;4;FLOAT2;0;FLOAT3;13;FLOAT2;11;FLOAT;28
Node;AmplifyShaderEditor.BreakToComponentsNode;178;-4914.736,-920.9029;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;179;-4913.736,-765.903;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;180;-4917.736,-607.903;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.VertexTangentNode;333;-4964.405,117.4828;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexBinormalNode;334;-4961.463,445.6952;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;352;-4784.885,305.9114;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;314;-4497.629,2614.453;Inherit;False;2137.327;1031.889;Handle logic to transform uniform transition value into something more dynamic;24;294;145;155;59;148;151;150;146;311;144;153;293;291;143;152;290;295;147;416;417;418;419;424;425;Transition Val Remap;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;117;-378.4756,-796.624;Inherit;False;cellCenter3D;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.AbsOpNode;219;-4714.198,-614.7684;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;218;-4741.198,-781.7683;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;111;-4075.91,1167.545;Inherit;False;Property;_GlobalControl;Global Control;5;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;217;-4744.532,-918.0502;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;335;-4559.589,202.1158;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;336;-4563.589,349.1158;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-4456.129,3372.415;Inherit;False;117;cellCenter3D;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-4402.395,1844.057;Inherit;False;Property;_FlipFuzz;Flip Fuzz;12;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;248;-4246.02,-1174.522;Inherit;False;Constant;_Vector11;Vector 11;9;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;13;-3944.64,972.8411;Inherit;False;Property;_Transition;Transition;11;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-3939.91,1077.545;Inherit;False;Global;KVRL_PanelTransition;KVRL_PanelTransition;6;0;Create;True;0;0;0;False;0;False;0;0.353;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;292;-3876.766,1168.101;Inherit;False;useGlobals;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;236;-4460.839,-883.7426;Inherit;False;float m = min(min(TestA, TestB), TestC)@$if (TestA == m) {$return OutA@$}$if (TestB == m) {$return OutB@$}$return OutC@;3;Create;6;True;TestA;FLOAT;0;In;;Inherit;False;True;TestB;FLOAT;0;In;;Inherit;False;True;TestC;FLOAT;0;In;;Inherit;False;True;OutA;FLOAT3;0,0,0;In;;Inherit;False;True;OutB;FLOAT3;0,0,0;In;;Inherit;False;True;OutC;FLOAT3;0,0,0;In;;Inherit;False;Selector;False;False;0;;False;6;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;387;-4612.379,783.6744;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;247;-4247.113,-1024.081;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;417;-3905.532,3467.766;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;-4090.039,1829.758;Inherit;False;fuzzy;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;112;-3634.91,1052.545;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-3977.294,-912.7094;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;250;-3986.806,-1099.266;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;147;-3938.684,2760.048;Inherit;False;Constant;_Float1;Float 1;10;0;Create;True;0;0;0;False;0;False;7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;295;-4134.606,2876.973;Inherit;False;292;useGlobals;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;290;-4447.629,2697.51;Inherit;False;Global;KVRL_TransitionSphere;KVRL_TransitionSphere;10;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.8127849,-2.997974,6.111092;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SignOpNode;359;-4411.627,748.998;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;416;-3523.183,3385.54;Inherit;False;Property;_Keyword4;Keyword 4;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;251;-3761.079,-1103.699;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-3717.715,2933.48;Inherit;False;149;fuzzy;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;291;-4145.913,3165.969;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;293;-3716.492,2758.255;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;310;-3451.134,1052.969;Inherit;False;rawTransitionVal;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;309;-2282.843,66.48943;Inherit;False;1966.944;1044.021;Use input coordinates, centers, radii, and direction to apply a tile flip on the UV. Output resulting UV and masks;23;308;44;28;121;136;27;134;132;123;126;135;158;189;60;157;122;41;42;87;340;384;413;415;Tile Flip;1,1,1,1;0;0
Node;AmplifyShaderEditor.StepOpNode;392;-4184.86,856.5701;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;394;-4351.901,141.0119;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;418;-3295.183,3383.54;Inherit;False;transitionCellCenter;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;143;-4164.358,2968.666;Inherit;False;Constant;_Vector2;Vector 2;10;0;Create;True;0;0;0;False;0;False;0,1,-2.7;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;252;-3560.699,-1052.77;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;153;-3478.891,2873.767;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-3715.33,2664.453;Inherit;False;310;rawTransitionVal;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;308;-2245.443,677.8147;Inherit;False;671.8411;335.4459;Use Object Scale to compute correct cell size;7;139;142;124;140;141;364;365;;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;393;-4090.332,208.6819;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;118;-364.4754,-602.6241;Inherit;False;cellRadius3D;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;294;-3898.26,3146.541;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;419;-3742.105,3065.738;Inherit;False;418;transitionCellCenter;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;253;-3406.534,-1051.762;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.LerpOp;146;-3351.626,2776.178;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;124;-2195.443,746.8349;Inherit;False;118;cellRadius3D;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;338;-3373.375,257.4808;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;145;-3445.791,3110.747;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;139;-2186.601,828.2606;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;254;-3261.727,-1024.007;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;150;-3082.715,2883.48;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;151;-3096.715,3025.48;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;142;-1991.6,837.2606;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;361;-3205.245,256.5953;Inherit;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;123;-2255.384,456.9818;Inherit;False;117;cellCenter3D;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;-3277.891,3038.767;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;140;-1994.264,728.8147;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TransformPositionNode;126;-1989.438,339.2987;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-3085.3,-1024.762;Inherit;False;selectTileAxis;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;148;-2907.051,2906.378;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;141;-1708.601,724.9182;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;339;-2999.352,254.7769;Inherit;False;refactorAxis;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;25;-377.9794,-870.1939;Inherit;False;cellCenter2D;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;34;-370.2935,-708.0635;Inherit;False;cellRadius2D;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;27;-1689.644,113.4894;Inherit;False;26;inputCoord;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;132;-2096.625,123.4662;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;364;-1852.594,907.3409;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-1511.862,361.1412;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;135;-1703.812,372.6415;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-2636.241,2919.886;Inherit;False;transitionValue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;158;-1460.965,805.5922;Inherit;False;Constant;_Vector3;Vector 3;11;0;Create;True;0;0;0;False;0;False;1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;189;-1519.112,921.8953;Inherit;False;188;selectTileAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;340;-1492.213,998.1715;Inherit;False;339;refactorAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;134;-1863.986,164.4829;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;413;-1929.722,518.5256;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;415;-1482.296,228.39;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;384;-1476.317,637.9719;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1537.596,565.2913;Inherit;False;34;cellRadius2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;365;-1700.594,830.3409;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;60;-1215.843,997.5098;Inherit;False;59;transitionValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;157;-1209.873,838.683;Inherit;False;Property;_Keyword3;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;122;-1240.039,589.6588;Inherit;False;Property;_Keyword1;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;121;-1243.871,402.4005;Inherit;False;Property;_Keyword0;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;136;-1242.523,118.4458;Inherit;False;Property;_Keyword2;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;379;-904.2029,513.1496;Inherit;False;UV Tile Flip;0;;30;6daf8d5c4b1e8a34692471ef82b8bba2;0;5;21;FLOAT2;0,0;False;22;FLOAT2;0,0;False;24;FLOAT2;0,0;False;29;FLOAT2;1,0;False;23;FLOAT;0;False;3;FLOAT2;27;FLOAT;0;FLOAT;28
Node;AmplifyShaderEditor.CommentaryNode;312;159.8743,-268.1654;Inherit;False;1076.345;654.6147;Render Stuff based on Tile UVs, Tile Side, and Mask;12;108;107;109;100;137;223;222;221;47;90;48;49;Tile Rendering;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-559.6786,671.129;Inherit;False;sideIndex;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;42;-560.9532,529.9887;Inherit;False;outputMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;220.1929,-22.7177;Inherit;False;87;sideIndex;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;108;454.1056,191.2304;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;209.8743,268.6389;Inherit;False;42;outputMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;304;1339.937,-223.4646;Inherit;False;1559.458;686.7066;Alpha Blend on color + alpha, plus Keyword to enable and disable clipping vs opaque debug version;6;303;299;302;300;301;298;Passthrough Magic;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;626.4337,249.4494;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;625.6109,154.6976;Inherit;False;Constant;_Float2;Float 2;3;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;298;1375.187,134.0034;Inherit;False;Constant;_Float9;Float 9;11;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;109;888.9192,227.377;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;432;-4367.616,3777.909;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectScaleNode;409;-2031.105,-531.0309;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectScaleNode;424;-4438.819,3472.844;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;410;-1433.105,-504.0309;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SignOpNode;347;-5851.715,461.0987;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;346;-5833.458,295.4594;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;345;-5840.86,-15.25637;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;395;-5655.8,47.45053;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;397;-5615.112,463.6598;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;396;-5617.112,262.6598;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;348;-5449.04,-13.54609;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;350;-5421.652,376.4241;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;349;-5447.735,196.4377;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;82;-4282.332,1960.128;Inherit;False;Constant;_Float3;Float 3;5;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;63;-4561.794,1516.731;Inherit;False;Constant;_Vector0;Vector 0;3;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;64;-4558.794,1655.731;Inherit;False;Constant;_Vector1;Vector 1;3;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;77;-4059.109,1731.843;Inherit;False;Constant;_Float4;Float 4;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-4075.332,1942.128;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-4537.794,1322.73;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;72;-4312.047,1609.165;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;74;-3903.047,1613.165;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;84;-3855.531,1700.242;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;71;-4306.047,1445.165;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;85;-4135.045,1547.396;Inherit;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;-3727.109,1615.843;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;83;-3720.631,1951.528;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;86;-3867.848,1447.409;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;75;-3467.693,1403.339;Inherit;False;Inverse Lerp;-1;;32;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;-0.05;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;69;-3218.399,1797.369;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;70;-3232.193,1660.647;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;195;1130.824,-1155.97;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;196;753.8233,-1241.97;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;756.8233,-1164.97;Inherit;False;Constant;_Float6;Float 6;8;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;198;754.8233,-1075.97;Inherit;False;Constant;_Float7;Float 7;8;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;199;872.8233,-980.97;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;200;708.8233,-982.97;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;194;458.8233,-989.97;Inherit;False;188;selectTileAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;301;2589.208,-96.35144;Inherit;False;Property;_KVRL_PASSTHROUGH_ON1;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Reference;299;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClipNode;300;2375.084,5.681629;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;302;1874.197,317.5486;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;299;1550.482,220.27;Inherit;False;Property;_KVRL_PASSTHROUGH_ON;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;1;0;0;False;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;303;2043.413,92.8103;Inherit;False;Property;_KVRL_PASSTHROUGH_ON2;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Reference;299;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;3115.251,408.9395;Inherit;False;Property;_Cull;Cull;6;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;-557.8985,394.517;Inherit;False;outputCoord;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;100;522.5889,-116.307;Inherit;False;Screen Tile Rendering;2;;33;ff5237cf56b52f541b4a2ac20bb5bc2f;0;3;1;FLOAT2;0,0;False;4;FLOAT;0;False;2;FLOAT;1;False;2;COLOR;0;FLOAT;9
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;845.593,-115.3231;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;223;1058.219,-114.1815;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;222;843.6926,1.476624;Inherit;False;Property;_DebugOut;Debug Out;10;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;221;815.1431,-218.1654;Inherit;False;220;testOutg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;224.8087,-116.8267;Inherit;False;41;outputCoord;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;239;-3226.597,-872.0632;Inherit;False;selectTileBiaxis;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;-3998.889,58.16248;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;329;-4960.787,7.828888;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;330;-5196.787,255.8289;Inherit;False;Constant;_Float0;Float 0;9;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;67;-3023.229,1358.115;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CrossProductOpNode;353;-4697.171,590.3782;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;354;-4507.805,590.3782;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;355;-4285.891,519.3657;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;357;-4818.986,736.4386;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;356;-4110.554,491.0448;Inherit;False;Inverse Lerp;-1;;35;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;0.9;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;380;-260.6616,864.6898;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;381;-28.3916,970.7711;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;382;-220.6339,1008.057;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.AbsOpNode;383;14.33319,1138.099;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;398;-4601.159,7.441223;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;399;-4351.305,-40.35707;Inherit;False;Inverse Lerp;-1;;38;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;400;-4463.985,956.5336;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;358;-4193.982,711.7;Inherit;False;Inverse Lerp;-1;;34;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;404;-4052.542,-246.4009;Inherit;False;Inverse Lerp;-1;;39;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;401;-5152.948,-374.5777;Inherit;False;Constant;_Vector10;Vector 10;9;0;Create;True;0;0;0;False;0;False;1,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;403;-4688.57,-359.7216;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;402;-4940.644,-374.7116;Inherit;False;Object;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.AbsOpNode;405;-4532.72,-351.1975;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;406;-4385.895,-285.1037;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;407;-4145.599,-118.6402;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;408;-3677.763,188.3113;Inherit;False;2;0;FLOAT;0.5;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;421;96.28723,-876.748;Inherit;False;Random Range;-1;;40;7b754edb8aebbfb4a9ace907af661cfc;0;3;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;423;-1747.889,-475.1966;Inherit;False;FLOAT3;2;1;0;3;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;420;-1417.313,-638.2261;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;422;51.41858,-739.843;Inherit;False;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;425;-4199.819,3517.844;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FractNode;431;-3661.741,3709.668;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;220;217.8441,-584.3639;Inherit;False;testOutg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;429;-72.57673,-616.8711;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;433;76.85048,-536.7961;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;19;New Amplify Shader;8ed3222feb711054bbc0398428fb718f;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;3107.06,176.4736;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;HSS08/FX/Screen Flip (Passthrough);8ed3222feb711054bbc0398428fb718f;True;Forward;0;1;Forward;9;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;0;True;_Cull;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;2;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;22;Surface;0;0;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;0;638452990343335626;  Use Shadow Threshold;0;0;GPU Instancing;1;0;LOD CrossFade;0;638452990374583416;Built-in Fog;0;638452990352633224;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;False;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.CommentaryNode;159;-1125.64,1695.197;Inherit;False;404;117;Proper scaling or whatever of corrected Axis;0;TODO;1,1,1,1;0;0
WireConnection;324;0;320;0
WireConnection;434;0;120;1
WireConnection;434;2;120;3
WireConnection;327;0;324;0
WireConnection;119;1;11;0
WireConnection;119;0;125;0
WireConnection;119;2;125;0
WireConnection;119;3;434;0
WireConnection;167;0;165;0
WireConnection;166;0;164;0
WireConnection;128;0;163;0
WireConnection;316;0;327;0
WireConnection;316;1;327;1
WireConnection;316;2;327;2
WireConnection;316;3;318;0
WireConnection;316;4;319;0
WireConnection;316;5;317;0
WireConnection;26;0;119;0
WireConnection;172;0;128;0
WireConnection;173;0;166;0
WireConnection;174;0;167;0
WireConnection;331;0;316;0
WireConnection;331;1;332;0
WireConnection;435;10;26;0
WireConnection;178;0;172;0
WireConnection;179;0;173;0
WireConnection;180;0;174;0
WireConnection;352;0;331;0
WireConnection;117;0;435;13
WireConnection;219;0;180;1
WireConnection;218;0;179;1
WireConnection;217;0;178;1
WireConnection;335;0;333;0
WireConnection;335;1;352;0
WireConnection;336;0;352;0
WireConnection;336;1;334;0
WireConnection;292;0;111;0
WireConnection;236;0;217;0
WireConnection;236;1;218;0
WireConnection;236;2;219;0
WireConnection;236;3;128;0
WireConnection;236;4;166;0
WireConnection;236;5;167;0
WireConnection;387;0;335;0
WireConnection;387;1;336;0
WireConnection;417;0;144;0
WireConnection;149;0;68;0
WireConnection;112;0;13;0
WireConnection;112;1;110;0
WireConnection;112;2;292;0
WireConnection;249;0;247;0
WireConnection;249;1;236;0
WireConnection;250;0;248;0
WireConnection;250;1;247;0
WireConnection;359;0;387;0
WireConnection;416;1;144;0
WireConnection;416;0;144;0
WireConnection;416;2;144;0
WireConnection;416;3;417;0
WireConnection;251;0;249;0
WireConnection;251;1;250;0
WireConnection;291;0;290;0
WireConnection;293;0;147;0
WireConnection;293;1;290;4
WireConnection;293;2;295;0
WireConnection;310;0;112;0
WireConnection;392;1;359;0
WireConnection;394;0;335;0
WireConnection;418;0;416;0
WireConnection;252;0;251;0
WireConnection;252;1;247;0
WireConnection;153;0;293;0
WireConnection;153;1;152;0
WireConnection;393;0;394;0
WireConnection;393;1;335;0
WireConnection;393;2;392;0
WireConnection;118;0;435;28
WireConnection;294;0;143;0
WireConnection;294;1;291;0
WireConnection;294;2;295;0
WireConnection;253;0;252;0
WireConnection;146;1;153;0
WireConnection;146;2;311;0
WireConnection;338;0;393;0
WireConnection;338;1;336;0
WireConnection;145;0;419;0
WireConnection;145;1;294;0
WireConnection;254;0;253;0
WireConnection;254;1;253;2
WireConnection;150;0;146;0
WireConnection;150;1;152;0
WireConnection;151;0;146;0
WireConnection;151;1;152;0
WireConnection;142;0;139;1
WireConnection;142;1;139;3
WireConnection;361;0;338;0
WireConnection;155;0;152;0
WireConnection;155;1;145;0
WireConnection;140;0;124;0
WireConnection;140;1;124;0
WireConnection;126;0;123;0
WireConnection;188;0;254;0
WireConnection;148;0;155;0
WireConnection;148;1;150;0
WireConnection;148;2;151;0
WireConnection;141;0;140;0
WireConnection;141;1;142;0
WireConnection;339;0;361;0
WireConnection;25;0;435;0
WireConnection;34;0;435;11
WireConnection;364;0;139;3
WireConnection;364;1;139;1
WireConnection;135;0;126;1
WireConnection;135;1;126;3
WireConnection;59;0;148;0
WireConnection;134;0;132;1
WireConnection;134;1;132;3
WireConnection;413;0;123;0
WireConnection;415;0;27;0
WireConnection;384;0;141;0
WireConnection;365;0;140;0
WireConnection;365;1;364;0
WireConnection;157;1;158;0
WireConnection;157;0;189;0
WireConnection;157;2;340;0
WireConnection;157;3;158;0
WireConnection;122;1;44;0
WireConnection;122;0;141;0
WireConnection;122;2;384;0
WireConnection;122;3;365;0
WireConnection;121;1;28;0
WireConnection;121;0;135;0
WireConnection;121;2;135;0
WireConnection;121;3;413;0
WireConnection;136;1;27;0
WireConnection;136;0;134;0
WireConnection;136;2;134;0
WireConnection;136;3;415;0
WireConnection;379;21;136;0
WireConnection;379;22;121;0
WireConnection;379;24;122;0
WireConnection;379;29;157;0
WireConnection;379;23;60;0
WireConnection;87;0;379;28
WireConnection;42;0;379;0
WireConnection;108;0;90;0
WireConnection;107;0;108;0
WireConnection;107;1;48;0
WireConnection;109;0;49;0
WireConnection;109;1;107;0
WireConnection;410;0;120;0
WireConnection;410;1;423;0
WireConnection;347;0;320;3
WireConnection;346;0;320;2
WireConnection;345;0;320;1
WireConnection;395;1;345;0
WireConnection;397;1;347;0
WireConnection;396;1;346;0
WireConnection;348;0;395;0
WireConnection;348;1;318;0
WireConnection;350;0;317;0
WireConnection;350;1;397;0
WireConnection;349;0;319;0
WireConnection;349;1;396;0
WireConnection;81;0;68;0
WireConnection;81;1;82;0
WireConnection;72;0;64;0
WireConnection;72;1;63;0
WireConnection;74;0;72;0
WireConnection;84;0;77;0
WireConnection;84;1;81;0
WireConnection;71;0;61;0
WireConnection;71;1;63;0
WireConnection;85;0;72;0
WireConnection;76;0;74;0
WireConnection;76;1;84;0
WireConnection;83;0;81;0
WireConnection;86;0;71;0
WireConnection;86;1;85;0
WireConnection;75;1;83;0
WireConnection;75;2;76;0
WireConnection;75;3;86;0
WireConnection;69;0;75;0
WireConnection;69;1;68;0
WireConnection;70;0;75;0
WireConnection;70;1;68;0
WireConnection;195;0;199;0
WireConnection;195;1;196;0
WireConnection;195;2;198;0
WireConnection;195;3;197;0
WireConnection;195;4;198;0
WireConnection;199;0;200;0
WireConnection;200;0;194;0
WireConnection;301;1;223;0
WireConnection;301;0;300;0
WireConnection;300;0;223;0
WireConnection;300;1;303;0
WireConnection;302;0;299;0
WireConnection;299;1;298;0
WireConnection;299;0;109;0
WireConnection;303;1;299;0
WireConnection;303;0;302;0
WireConnection;41;0;379;27
WireConnection;100;1;47;0
WireConnection;100;4;90;0
WireConnection;100;2;48;0
WireConnection;137;0;100;0
WireConnection;137;1;48;0
WireConnection;223;0;137;0
WireConnection;223;1;221;0
WireConnection;223;2;222;0
WireConnection;329;0;316;0
WireConnection;329;1;330;0
WireConnection;67;0;112;0
WireConnection;67;1;70;0
WireConnection;67;2;69;0
WireConnection;353;0;332;0
WireConnection;353;1;352;0
WireConnection;354;0;353;0
WireConnection;355;0;316;0
WireConnection;355;1;354;0
WireConnection;357;0;316;0
WireConnection;357;1;332;0
WireConnection;356;3;355;0
WireConnection;380;0;122;0
WireConnection;381;0;380;0
WireConnection;382;0;157;0
WireConnection;383;0;382;1
WireConnection;398;0;331;0
WireConnection;399;3;398;0
WireConnection;400;0;387;0
WireConnection;358;3;359;0
WireConnection;404;3;403;0
WireConnection;403;0;402;0
WireConnection;403;1;352;0
WireConnection;402;0;401;0
WireConnection;405;0;403;0
WireConnection;406;0;405;0
WireConnection;407;0;406;0
WireConnection;408;1;407;0
WireConnection;421;1;117;0
WireConnection;423;0;409;0
WireConnection;420;0;120;0
WireConnection;420;1;409;0
WireConnection;422;0;117;0
WireConnection;425;0;144;0
WireConnection;425;1;424;0
WireConnection;431;0;417;0
WireConnection;220;0;433;1
WireConnection;429;0;117;0
WireConnection;433;0;429;0
WireConnection;1;2;301;0
WireConnection;1;3;299;0
ASEEND*/
//CHKSM=C767D661A53935877BFEBC6F92F4C8F91C783C87