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

			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
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

			

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

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
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_TANGENT
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
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
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

			sampler2D _SideA;
			float4 KVRL_TransitionSphere;
			float KVRL_TransitionFuzz;
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
				float3 ase_vertexBitangent = cross( v.normalOS, v.ase_tangent.xyz ) * v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				o.ase_texcoord8.xyz = ase_vertexBitangent;
				
				o.ase_texcoord6.xy = v.ase_texcoord.xy;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord7 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.zw = 0;
				o.ase_texcoord8.w = 0;

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
				float3 normalizeResult352 = normalize( cross( localSelector316 , ase_worldNormal ) );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , sign( ( dotResult335 * dotResult336 ) ) ));
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
				float2 temp_output_29_0_g56 = staticSwitch157;
				float2 normalizeResult30_g56 = normalize( temp_output_29_0_g56 );
				float2 texCoord11 = IN.ase_texcoord6.xy * float2( 1,1 ) + float2( 0,0 );
				float3 temp_output_1_0_g86 = IN.ase_texcoord7.xyz;
				float dotResult9_g86 = dot( IN.ase_tangent.xyz , temp_output_1_0_g86 );
				float3 ase_vertexBitangent = IN.ase_texcoord8.xyz;
				float dotResult12_g86 = dot( temp_output_1_0_g86 , ase_vertexBitangent );
				float3 _Vector0 = float3(0,0,0);
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = ( ( ( dotResult9_g86 * IN.ase_tangent.xyz ) + ( ase_vertexBitangent * dotResult12_g86 ) + _Vector0 ) * ase_parentObjectScale );
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float2 appendResult134 = (float2(IN.ase_texcoord7.xyz.x , IN.ase_texcoord7.xyz.z));
				float3 temp_output_1_0_g88 = inputCoord26;
				float dotResult9_g88 = dot( IN.ase_tangent.xyz , temp_output_1_0_g88 );
				float temp_output_502_2 = dotResult9_g88;
				float dotResult12_g88 = dot( temp_output_1_0_g88 , ase_vertexBitangent );
				float temp_output_502_21 = dotResult12_g88;
				float2 appendResult497 = (float2(temp_output_502_2 , temp_output_502_21));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( appendResult497 ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float3 temp_output_10_0_g55 = inputCoord26;
				float2 appendResult12_g55 = (float2(temp_output_10_0_g55.xy));
				float2 temp_output_39_0_g55 = _GridSize;
				float2 gridSize2D22_g55 = temp_output_39_0_g55;
				float2 temp_output_7_0_g55 = ( ( 1.0 / gridSize2D22_g55 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g55 * gridSize2D22_g55 ) ) / gridSize2D22_g55 ) + temp_output_7_0_g55 );
				float cellSize3D25_g55 = ( 1.0 / temp_output_39_0_g55.x );
				float3 temp_output_16_0_g55 = floor( ( temp_output_10_0_g55 / cellSize3D25_g55 ) );
				float temp_output_17_0_g55 = ( cellSize3D25_g55 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g55 * cellSize3D25_g55 ) + temp_output_17_0_g55 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float3 temp_output_1_0_g89 = worldToObj126;
				float dotResult9_g89 = dot( IN.ase_tangent.xyz , temp_output_1_0_g89 );
				float dotResult12_g89 = dot( temp_output_1_0_g89 , ase_vertexBitangent );
				float2 appendResult135 = (float2(dotResult9_g89 , dotResult12_g89));
				float3 temp_output_1_0_g90 = cellCenter3D117;
				float dotResult9_g90 = dot( IN.ase_tangent.xyz , temp_output_1_0_g90 );
				float dotResult12_g90 = dot( temp_output_1_0_g90 , ase_vertexBitangent );
				float2 appendResult510 = (float2(dotResult9_g90 , dotResult12_g90));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = appendResult510;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g56 = staticSwitch121;
				float2 temp_output_5_0_g56 = ( staticSwitch136.xy - center77_g56 );
				float dotResult31_g56 = dot( normalizeResult30_g56 , temp_output_5_0_g56 );
				float temp_output_1_0_g57 = 0.0;
				float useGlobals292 = _GlobalControl;
				float lerpResult293 = lerp( 7.0 , KVRL_TransitionSphere.w , useGlobals292);
				float transitionRadius452 = lerpResult293;
				float lerpResult449 = lerp( _FlipFuzz , KVRL_TransitionFuzz , useGlobals292);
				float fuzzy149 = lerpResult449;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( transitionRadius452 + fuzzy149 ) , rawTransitionVal310);
				float lerpResult453 = lerp( -fuzzy149 , transitionRadius452 , rawTransitionVal310);
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( ( cellCenter3D117 / ase_parentObjectScale ), 1 ) ).xyz;
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
				float smoothstepResult457 = smoothstep( lerpResult146 , lerpResult453 , distance( transitionCellCenter418 , lerpResult294 ));
				float transitionValue59 = smoothstepResult457;
				float temp_output_4_0_g56 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float cosFactor57_g56 = temp_output_4_0_g56;
				float2 cellRadius2D34 = temp_output_7_0_g55;
				float cellRadius3D118 = abs( temp_output_17_0_g55 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float3 temp_output_1_0_g87 = ase_parentObjectScale;
				float dotResult9_g87 = dot( IN.ase_tangent.xyz , temp_output_1_0_g87 );
				float dotResult12_g87 = dot( temp_output_1_0_g87 , ase_vertexBitangent );
				float2 appendResult142 = (float2(dotResult9_g87 , dotResult12_g87));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = appendResult140;
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g56 = staticSwitch122;
				float dotResult36_g56 = dot( temp_output_29_0_g56 , cellRadius59_g56 );
				float flipRadius55_g56 = abs( dotResult36_g56 );
				float temp_output_53_0_g56 = ( ( dotResult31_g56 - temp_output_1_0_g57 ) / ( ( cosFactor57_g56 * flipRadius55_g56 ) - temp_output_1_0_g57 ) );
				float2 temp_output_62_0_g56 = ( ( temp_output_53_0_g56 * flipRadius55_g56 ) * normalizeResult30_g56 );
				float side73_g56 = saturate( step( temp_output_4_0_g56 , 0.0 ) );
				float2 lerpResult75_g56 = lerp( temp_output_62_0_g56 , -temp_output_62_0_g56 , side73_g56);
				float2 deltaUV39_g56 = temp_output_5_0_g56;
				float2 flipDelta64_g56 = ( dotResult31_g56 * normalizeResult30_g56 );
				float2 nonFlipUV67_g56 = ( deltaUV39_g56 - flipDelta64_g56 );
				float2 outputCoord41 = ( lerpResult75_g56 + nonFlipUV67_g56 + center77_g56 );
				float2 temp_output_1_0_g59 = outputCoord41;
				float sideIndex87 = side73_g56;
				float4 lerpResult5_g59 = lerp( tex2D( _SideA, temp_output_1_0_g59 ) , tex2D( _SideB, temp_output_1_0_g59 ) , sideIndex87);
				float outputMask42 = step( abs( temp_output_53_0_g56 ) , 1.0 );
				float2 testOutg220 = appendResult497;
				float4 lerpResult223 = lerp( ( lerpResult5_g59 * outputMask42 ) , float4( testOutg220, 0.0 , 0.0 ) , _DebugOut);
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				clip( staticSwitch299 - 0.5);
				#ifdef _KVRL_PASSTHROUGH_ON
				float4 staticSwitch301 = lerpResult223;
				#else
				float4 staticSwitch301 = lerpResult223;
				#endif
				
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch522 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch522 = staticSwitch299;
				#endif
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = staticSwitch301.rgb;
				float Alpha = staticSwitch522;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

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

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_TANGENT
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
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
				float4 ase_tangent : TANGENT;
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
			CBUFFER_END

			float4 KVRL_TransitionSphere;
			float KVRL_TransitionFuzz;
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

				float3 ase_vertexBitangent = cross( v.normalOS, v.ase_tangent.xyz ) * v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				o.ase_texcoord4.xyz = ase_vertexBitangent;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord5.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord6.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord3 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;

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
				float transitionRadius452 = lerpResult293;
				float lerpResult449 = lerp( _FlipFuzz , KVRL_TransitionFuzz , useGlobals292);
				float fuzzy149 = lerpResult449;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( transitionRadius452 + fuzzy149 ) , rawTransitionVal310);
				float lerpResult453 = lerp( -fuzzy149 , transitionRadius452 , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float3 temp_output_1_0_g86 = IN.ase_texcoord3.xyz;
				float dotResult9_g86 = dot( IN.ase_tangent.xyz , temp_output_1_0_g86 );
				float3 ase_vertexBitangent = IN.ase_texcoord4.xyz;
				float dotResult12_g86 = dot( temp_output_1_0_g86 , ase_vertexBitangent );
				float3 _Vector0 = float3(0,0,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = WorldPosition;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = ( ( ( dotResult9_g86 * IN.ase_tangent.xyz ) + ( ase_vertexBitangent * dotResult12_g86 ) + _Vector0 ) * ase_parentObjectScale );
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g55 = inputCoord26;
				float2 temp_output_39_0_g55 = _GridSize;
				float cellSize3D25_g55 = ( 1.0 / temp_output_39_0_g55.x );
				float3 temp_output_16_0_g55 = floor( ( temp_output_10_0_g55 / cellSize3D25_g55 ) );
				float temp_output_17_0_g55 = ( cellSize3D25_g55 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g55 * cellSize3D25_g55 ) + temp_output_17_0_g55 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( ( cellCenter3D117 / ase_parentObjectScale ), 1 ) ).xyz;
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
				float smoothstepResult457 = smoothstep( lerpResult146 , lerpResult453 , distance( transitionCellCenter418 , lerpResult294 ));
				float transitionValue59 = smoothstepResult457;
				float temp_output_4_0_g56 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g56 = saturate( step( temp_output_4_0_g56 , 0.0 ) );
				float sideIndex87 = side73_g56;
				float2 _Vector3 = float2(1,0);
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
				float3 ase_worldTangent = IN.ase_texcoord5.xyz;
				float3 ase_worldNormal = IN.ase_texcoord6.xyz;
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
				float3 normalizeResult352 = normalize( cross( localSelector316 , ase_worldNormal ) );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord7.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , sign( ( dotResult335 * dotResult336 ) ) ));
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
				float2 temp_output_29_0_g56 = staticSwitch157;
				float2 normalizeResult30_g56 = normalize( temp_output_29_0_g56 );
				float2 appendResult134 = (float2(IN.ase_texcoord3.xyz.x , IN.ase_texcoord3.xyz.z));
				float3 temp_output_1_0_g88 = inputCoord26;
				float dotResult9_g88 = dot( IN.ase_tangent.xyz , temp_output_1_0_g88 );
				float temp_output_502_2 = dotResult9_g88;
				float dotResult12_g88 = dot( temp_output_1_0_g88 , ase_vertexBitangent );
				float temp_output_502_21 = dotResult12_g88;
				float2 appendResult497 = (float2(temp_output_502_2 , temp_output_502_21));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( appendResult497 ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g55 = (float2(temp_output_10_0_g55.xy));
				float2 gridSize2D22_g55 = temp_output_39_0_g55;
				float2 temp_output_7_0_g55 = ( ( 1.0 / gridSize2D22_g55 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g55 * gridSize2D22_g55 ) ) / gridSize2D22_g55 ) + temp_output_7_0_g55 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float3 temp_output_1_0_g89 = worldToObj126;
				float dotResult9_g89 = dot( IN.ase_tangent.xyz , temp_output_1_0_g89 );
				float dotResult12_g89 = dot( temp_output_1_0_g89 , ase_vertexBitangent );
				float2 appendResult135 = (float2(dotResult9_g89 , dotResult12_g89));
				float3 temp_output_1_0_g90 = cellCenter3D117;
				float dotResult9_g90 = dot( IN.ase_tangent.xyz , temp_output_1_0_g90 );
				float dotResult12_g90 = dot( temp_output_1_0_g90 , ase_vertexBitangent );
				float2 appendResult510 = (float2(dotResult9_g90 , dotResult12_g90));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = appendResult510;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g56 = staticSwitch121;
				float2 temp_output_5_0_g56 = ( staticSwitch136.xy - center77_g56 );
				float dotResult31_g56 = dot( normalizeResult30_g56 , temp_output_5_0_g56 );
				float temp_output_1_0_g57 = 0.0;
				float cosFactor57_g56 = temp_output_4_0_g56;
				float2 cellRadius2D34 = temp_output_7_0_g55;
				float cellRadius3D118 = abs( temp_output_17_0_g55 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float3 temp_output_1_0_g87 = ase_parentObjectScale;
				float dotResult9_g87 = dot( IN.ase_tangent.xyz , temp_output_1_0_g87 );
				float dotResult12_g87 = dot( temp_output_1_0_g87 , ase_vertexBitangent );
				float2 appendResult142 = (float2(dotResult9_g87 , dotResult12_g87));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = appendResult140;
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g56 = staticSwitch122;
				float dotResult36_g56 = dot( temp_output_29_0_g56 , cellRadius59_g56 );
				float flipRadius55_g56 = abs( dotResult36_g56 );
				float temp_output_53_0_g56 = ( ( dotResult31_g56 - temp_output_1_0_g57 ) / ( ( cosFactor57_g56 * flipRadius55_g56 ) - temp_output_1_0_g57 ) );
				float outputMask42 = step( abs( temp_output_53_0_g56 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch522 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch522 = staticSwitch299;
				#endif
				

				float Alpha = staticSwitch522;
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

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_TANGENT
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
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
				float4 ase_tangent : TANGENT;
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
			float KVRL_TransitionFuzz;
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
				float3 ase_vertexBitangent = cross( v.normalOS, v.ase_tangent.xyz ) * v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				o.ase_texcoord3.xyz = ase_vertexBitangent;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord2 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				o.ase_texcoord3.w = 0;
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
				float transitionRadius452 = lerpResult293;
				float lerpResult449 = lerp( _FlipFuzz , KVRL_TransitionFuzz , useGlobals292);
				float fuzzy149 = lerpResult449;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( transitionRadius452 + fuzzy149 ) , rawTransitionVal310);
				float lerpResult453 = lerp( -fuzzy149 , transitionRadius452 , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 temp_output_1_0_g86 = IN.ase_texcoord2.xyz;
				float dotResult9_g86 = dot( IN.ase_tangent.xyz , temp_output_1_0_g86 );
				float3 ase_vertexBitangent = IN.ase_texcoord3.xyz;
				float dotResult12_g86 = dot( temp_output_1_0_g86 , ase_vertexBitangent );
				float3 _Vector0 = float3(0,0,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = ( ( ( dotResult9_g86 * IN.ase_tangent.xyz ) + ( ase_vertexBitangent * dotResult12_g86 ) + _Vector0 ) * ase_parentObjectScale );
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g55 = inputCoord26;
				float2 temp_output_39_0_g55 = _GridSize;
				float cellSize3D25_g55 = ( 1.0 / temp_output_39_0_g55.x );
				float3 temp_output_16_0_g55 = floor( ( temp_output_10_0_g55 / cellSize3D25_g55 ) );
				float temp_output_17_0_g55 = ( cellSize3D25_g55 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g55 * cellSize3D25_g55 ) + temp_output_17_0_g55 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( ( cellCenter3D117 / ase_parentObjectScale ), 1 ) ).xyz;
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
				float smoothstepResult457 = smoothstep( lerpResult146 , lerpResult453 , distance( transitionCellCenter418 , lerpResult294 ));
				float transitionValue59 = smoothstepResult457;
				float temp_output_4_0_g56 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g56 = saturate( step( temp_output_4_0_g56 , 0.0 ) );
				float sideIndex87 = side73_g56;
				float2 _Vector3 = float2(1,0);
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
				float3 normalizeResult352 = normalize( cross( localSelector316 , ase_worldNormal ) );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , sign( ( dotResult335 * dotResult336 ) ) ));
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
				float2 temp_output_29_0_g56 = staticSwitch157;
				float2 normalizeResult30_g56 = normalize( temp_output_29_0_g56 );
				float2 appendResult134 = (float2(IN.ase_texcoord2.xyz.x , IN.ase_texcoord2.xyz.z));
				float3 temp_output_1_0_g88 = inputCoord26;
				float dotResult9_g88 = dot( IN.ase_tangent.xyz , temp_output_1_0_g88 );
				float temp_output_502_2 = dotResult9_g88;
				float dotResult12_g88 = dot( temp_output_1_0_g88 , ase_vertexBitangent );
				float temp_output_502_21 = dotResult12_g88;
				float2 appendResult497 = (float2(temp_output_502_2 , temp_output_502_21));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( appendResult497 ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g55 = (float2(temp_output_10_0_g55.xy));
				float2 gridSize2D22_g55 = temp_output_39_0_g55;
				float2 temp_output_7_0_g55 = ( ( 1.0 / gridSize2D22_g55 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g55 * gridSize2D22_g55 ) ) / gridSize2D22_g55 ) + temp_output_7_0_g55 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float3 temp_output_1_0_g89 = worldToObj126;
				float dotResult9_g89 = dot( IN.ase_tangent.xyz , temp_output_1_0_g89 );
				float dotResult12_g89 = dot( temp_output_1_0_g89 , ase_vertexBitangent );
				float2 appendResult135 = (float2(dotResult9_g89 , dotResult12_g89));
				float3 temp_output_1_0_g90 = cellCenter3D117;
				float dotResult9_g90 = dot( IN.ase_tangent.xyz , temp_output_1_0_g90 );
				float dotResult12_g90 = dot( temp_output_1_0_g90 , ase_vertexBitangent );
				float2 appendResult510 = (float2(dotResult9_g90 , dotResult12_g90));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = appendResult510;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g56 = staticSwitch121;
				float2 temp_output_5_0_g56 = ( staticSwitch136.xy - center77_g56 );
				float dotResult31_g56 = dot( normalizeResult30_g56 , temp_output_5_0_g56 );
				float temp_output_1_0_g57 = 0.0;
				float cosFactor57_g56 = temp_output_4_0_g56;
				float2 cellRadius2D34 = temp_output_7_0_g55;
				float cellRadius3D118 = abs( temp_output_17_0_g55 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float3 temp_output_1_0_g87 = ase_parentObjectScale;
				float dotResult9_g87 = dot( IN.ase_tangent.xyz , temp_output_1_0_g87 );
				float dotResult12_g87 = dot( temp_output_1_0_g87 , ase_vertexBitangent );
				float2 appendResult142 = (float2(dotResult9_g87 , dotResult12_g87));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = appendResult140;
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g56 = staticSwitch122;
				float dotResult36_g56 = dot( temp_output_29_0_g56 , cellRadius59_g56 );
				float flipRadius55_g56 = abs( dotResult36_g56 );
				float temp_output_53_0_g56 = ( ( dotResult31_g56 - temp_output_1_0_g57 ) / ( ( cosFactor57_g56 * flipRadius55_g56 ) - temp_output_1_0_g57 ) );
				float outputMask42 = step( abs( temp_output_53_0_g56 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch522 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch522 = staticSwitch299;
				#endif
				

				surfaceDescription.Alpha = staticSwitch522;
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

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

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

			#define ASE_NEEDS_FRAG_TANGENT
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
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
				float4 ase_tangent : TANGENT;
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
			float KVRL_TransitionFuzz;
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
				float3 ase_vertexBitangent = cross( v.normalOS, v.ase_tangent.xyz ) * v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				o.ase_texcoord3.xyz = ase_vertexBitangent;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord2 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				o.ase_texcoord3.w = 0;
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
				float transitionRadius452 = lerpResult293;
				float lerpResult449 = lerp( _FlipFuzz , KVRL_TransitionFuzz , useGlobals292);
				float fuzzy149 = lerpResult449;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( transitionRadius452 + fuzzy149 ) , rawTransitionVal310);
				float lerpResult453 = lerp( -fuzzy149 , transitionRadius452 , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord1.xyz;
				float3 temp_output_1_0_g86 = IN.ase_texcoord2.xyz;
				float dotResult9_g86 = dot( IN.ase_tangent.xyz , temp_output_1_0_g86 );
				float3 ase_vertexBitangent = IN.ase_texcoord3.xyz;
				float dotResult12_g86 = dot( temp_output_1_0_g86 , ase_vertexBitangent );
				float3 _Vector0 = float3(0,0,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = ( ( ( dotResult9_g86 * IN.ase_tangent.xyz ) + ( ase_vertexBitangent * dotResult12_g86 ) + _Vector0 ) * ase_parentObjectScale );
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g55 = inputCoord26;
				float2 temp_output_39_0_g55 = _GridSize;
				float cellSize3D25_g55 = ( 1.0 / temp_output_39_0_g55.x );
				float3 temp_output_16_0_g55 = floor( ( temp_output_10_0_g55 / cellSize3D25_g55 ) );
				float temp_output_17_0_g55 = ( cellSize3D25_g55 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g55 * cellSize3D25_g55 ) + temp_output_17_0_g55 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( ( cellCenter3D117 / ase_parentObjectScale ), 1 ) ).xyz;
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
				float smoothstepResult457 = smoothstep( lerpResult146 , lerpResult453 , distance( transitionCellCenter418 , lerpResult294 ));
				float transitionValue59 = smoothstepResult457;
				float temp_output_4_0_g56 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g56 = saturate( step( temp_output_4_0_g56 , 0.0 ) );
				float sideIndex87 = side73_g56;
				float2 _Vector3 = float2(1,0);
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
				float3 normalizeResult352 = normalize( cross( localSelector316 , ase_worldNormal ) );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , sign( ( dotResult335 * dotResult336 ) ) ));
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
				float2 temp_output_29_0_g56 = staticSwitch157;
				float2 normalizeResult30_g56 = normalize( temp_output_29_0_g56 );
				float2 appendResult134 = (float2(IN.ase_texcoord2.xyz.x , IN.ase_texcoord2.xyz.z));
				float3 temp_output_1_0_g88 = inputCoord26;
				float dotResult9_g88 = dot( IN.ase_tangent.xyz , temp_output_1_0_g88 );
				float temp_output_502_2 = dotResult9_g88;
				float dotResult12_g88 = dot( temp_output_1_0_g88 , ase_vertexBitangent );
				float temp_output_502_21 = dotResult12_g88;
				float2 appendResult497 = (float2(temp_output_502_2 , temp_output_502_21));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( appendResult497 ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g55 = (float2(temp_output_10_0_g55.xy));
				float2 gridSize2D22_g55 = temp_output_39_0_g55;
				float2 temp_output_7_0_g55 = ( ( 1.0 / gridSize2D22_g55 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g55 * gridSize2D22_g55 ) ) / gridSize2D22_g55 ) + temp_output_7_0_g55 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float3 temp_output_1_0_g89 = worldToObj126;
				float dotResult9_g89 = dot( IN.ase_tangent.xyz , temp_output_1_0_g89 );
				float dotResult12_g89 = dot( temp_output_1_0_g89 , ase_vertexBitangent );
				float2 appendResult135 = (float2(dotResult9_g89 , dotResult12_g89));
				float3 temp_output_1_0_g90 = cellCenter3D117;
				float dotResult9_g90 = dot( IN.ase_tangent.xyz , temp_output_1_0_g90 );
				float dotResult12_g90 = dot( temp_output_1_0_g90 , ase_vertexBitangent );
				float2 appendResult510 = (float2(dotResult9_g90 , dotResult12_g90));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = appendResult510;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g56 = staticSwitch121;
				float2 temp_output_5_0_g56 = ( staticSwitch136.xy - center77_g56 );
				float dotResult31_g56 = dot( normalizeResult30_g56 , temp_output_5_0_g56 );
				float temp_output_1_0_g57 = 0.0;
				float cosFactor57_g56 = temp_output_4_0_g56;
				float2 cellRadius2D34 = temp_output_7_0_g55;
				float cellRadius3D118 = abs( temp_output_17_0_g55 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float3 temp_output_1_0_g87 = ase_parentObjectScale;
				float dotResult9_g87 = dot( IN.ase_tangent.xyz , temp_output_1_0_g87 );
				float dotResult12_g87 = dot( temp_output_1_0_g87 , ase_vertexBitangent );
				float2 appendResult142 = (float2(dotResult9_g87 , dotResult12_g87));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = appendResult140;
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g56 = staticSwitch122;
				float dotResult36_g56 = dot( temp_output_29_0_g56 , cellRadius59_g56 );
				float flipRadius55_g56 = abs( dotResult36_g56 );
				float temp_output_53_0_g56 = ( ( dotResult31_g56 - temp_output_1_0_g57 ) / ( ( cosFactor57_g56 * flipRadius55_g56 ) - temp_output_1_0_g57 ) );
				float outputMask42 = step( abs( temp_output_53_0_g56 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch522 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch522 = staticSwitch299;
				#endif
				

				surfaceDescription.Alpha = staticSwitch522;
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

        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

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

			#define ASE_NEEDS_FRAG_TANGENT
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
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
				float4 ase_tangent : TANGENT;
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
			float KVRL_TransitionFuzz;
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
				float3 ase_vertexBitangent = cross( v.normalOS, v.ase_tangent.xyz ) * v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				o.ase_texcoord4.xyz = ase_vertexBitangent;
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord5.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord3 = v.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
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
				float transitionRadius452 = lerpResult293;
				float lerpResult449 = lerp( _FlipFuzz , KVRL_TransitionFuzz , useGlobals292);
				float fuzzy149 = lerpResult449;
				float lerpResult112 = lerp( _Transition , KVRL_PanelTransition , useGlobals292);
				float rawTransitionVal310 = lerpResult112;
				float lerpResult146 = lerp( 0.0 , ( transitionRadius452 + fuzzy149 ) , rawTransitionVal310);
				float lerpResult453 = lerp( -fuzzy149 , transitionRadius452 , rawTransitionVal310);
				float2 texCoord11 = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float3 ase_worldPos = IN.ase_texcoord2.xyz;
				float3 temp_output_1_0_g86 = IN.ase_texcoord3.xyz;
				float dotResult9_g86 = dot( IN.ase_tangent.xyz , temp_output_1_0_g86 );
				float3 ase_vertexBitangent = IN.ase_texcoord4.xyz;
				float dotResult12_g86 = dot( temp_output_1_0_g86 , ase_vertexBitangent );
				float3 _Vector0 = float3(0,0,0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				#if defined(_UVMODE_UV)
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch119 = ase_worldPos;
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch119 = ( ( ( dotResult9_g86 * IN.ase_tangent.xyz ) + ( ase_vertexBitangent * dotResult12_g86 ) + _Vector0 ) * ase_parentObjectScale );
				#else
				float3 staticSwitch119 = float3( texCoord11 ,  0.0 );
				#endif
				float3 inputCoord26 = staticSwitch119;
				float3 temp_output_10_0_g55 = inputCoord26;
				float2 temp_output_39_0_g55 = _GridSize;
				float cellSize3D25_g55 = ( 1.0 / temp_output_39_0_g55.x );
				float3 temp_output_16_0_g55 = floor( ( temp_output_10_0_g55 / cellSize3D25_g55 ) );
				float temp_output_17_0_g55 = ( cellSize3D25_g55 * 0.5 );
				float3 cellCenter3D117 = ( ( temp_output_16_0_g55 * cellSize3D25_g55 ) + temp_output_17_0_g55 );
				float3 objToWorld417 = mul( GetObjectToWorldMatrix(), float4( ( cellCenter3D117 / ase_parentObjectScale ), 1 ) ).xyz;
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
				float smoothstepResult457 = smoothstep( lerpResult146 , lerpResult453 , distance( transitionCellCenter418 , lerpResult294 ));
				float transitionValue59 = smoothstepResult457;
				float temp_output_4_0_g56 = cos( ( transitionValue59 * ( ( _FlipCount * 0.5 ) * PI ) ) );
				float side73_g56 = saturate( step( temp_output_4_0_g56 , 0.0 ) );
				float sideIndex87 = side73_g56;
				float2 _Vector3 = float2(1,0);
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
				float3 ase_worldTangent = IN.ase_texcoord5.xyz;
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
				float3 normalizeResult352 = normalize( cross( localSelector316 , IN.normalWS ) );
				float dotResult335 = dot( ase_worldTangent , normalizeResult352 );
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float dotResult336 = dot( normalizeResult352 , ase_worldBitangent );
				float lerpResult393 = lerp( -dotResult335 , dotResult335 , step( 0.0 , sign( ( dotResult335 * dotResult336 ) ) ));
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
				float2 temp_output_29_0_g56 = staticSwitch157;
				float2 normalizeResult30_g56 = normalize( temp_output_29_0_g56 );
				float2 appendResult134 = (float2(IN.ase_texcoord3.xyz.x , IN.ase_texcoord3.xyz.z));
				float3 temp_output_1_0_g88 = inputCoord26;
				float dotResult9_g88 = dot( IN.ase_tangent.xyz , temp_output_1_0_g88 );
				float temp_output_502_2 = dotResult9_g88;
				float dotResult12_g88 = dot( temp_output_1_0_g88 , ase_vertexBitangent );
				float temp_output_502_21 = dotResult12_g88;
				float2 appendResult497 = (float2(temp_output_502_2 , temp_output_502_21));
				#if defined(_UVMODE_UV)
				float3 staticSwitch136 = inputCoord26;
				#elif defined(_UVMODE_WORLDGRID)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_WORLDGRID2)
				float3 staticSwitch136 = float3( appendResult134 ,  0.0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float3 staticSwitch136 = float3( appendResult497 ,  0.0 );
				#else
				float3 staticSwitch136 = inputCoord26;
				#endif
				float2 appendResult12_g55 = (float2(temp_output_10_0_g55.xy));
				float2 gridSize2D22_g55 = temp_output_39_0_g55;
				float2 temp_output_7_0_g55 = ( ( 1.0 / gridSize2D22_g55 ) * 0.5 );
				float2 cellCenter2D25 = ( ( floor( ( appendResult12_g55 * gridSize2D22_g55 ) ) / gridSize2D22_g55 ) + temp_output_7_0_g55 );
				float3 worldToObj126 = mul( GetWorldToObjectMatrix(), float4( cellCenter3D117, 1 ) ).xyz;
				float3 temp_output_1_0_g89 = worldToObj126;
				float dotResult9_g89 = dot( IN.ase_tangent.xyz , temp_output_1_0_g89 );
				float dotResult12_g89 = dot( temp_output_1_0_g89 , ase_vertexBitangent );
				float2 appendResult135 = (float2(dotResult9_g89 , dotResult12_g89));
				float3 temp_output_1_0_g90 = cellCenter3D117;
				float dotResult9_g90 = dot( IN.ase_tangent.xyz , temp_output_1_0_g90 );
				float dotResult12_g90 = dot( temp_output_1_0_g90 , ase_vertexBitangent );
				float2 appendResult510 = (float2(dotResult9_g90 , dotResult12_g90));
				#if defined(_UVMODE_UV)
				float2 staticSwitch121 = cellCenter2D25;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch121 = appendResult135;
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch121 = appendResult510;
				#else
				float2 staticSwitch121 = cellCenter2D25;
				#endif
				float2 center77_g56 = staticSwitch121;
				float2 temp_output_5_0_g56 = ( staticSwitch136.xy - center77_g56 );
				float dotResult31_g56 = dot( normalizeResult30_g56 , temp_output_5_0_g56 );
				float temp_output_1_0_g57 = 0.0;
				float cosFactor57_g56 = temp_output_4_0_g56;
				float2 cellRadius2D34 = temp_output_7_0_g55;
				float cellRadius3D118 = abs( temp_output_17_0_g55 );
				float2 appendResult140 = (float2(cellRadius3D118 , cellRadius3D118));
				float3 temp_output_1_0_g87 = ase_parentObjectScale;
				float dotResult9_g87 = dot( IN.ase_tangent.xyz , temp_output_1_0_g87 );
				float dotResult12_g87 = dot( temp_output_1_0_g87 , ase_vertexBitangent );
				float2 appendResult142 = (float2(dotResult9_g87 , dotResult12_g87));
				float2 temp_output_141_0 = ( appendResult140 / appendResult142 );
				#if defined(_UVMODE_UV)
				float2 staticSwitch122 = cellRadius2D34;
				#elif defined(_UVMODE_WORLDGRID)
				float2 staticSwitch122 = temp_output_141_0;
				#elif defined(_UVMODE_WORLDGRID2)
				float2 staticSwitch122 = abs( temp_output_141_0 );
				#elif defined(_UVMODE_OBJECTGRID)
				float2 staticSwitch122 = appendResult140;
				#else
				float2 staticSwitch122 = cellRadius2D34;
				#endif
				float2 cellRadius59_g56 = staticSwitch122;
				float dotResult36_g56 = dot( temp_output_29_0_g56 , cellRadius59_g56 );
				float flipRadius55_g56 = abs( dotResult36_g56 );
				float temp_output_53_0_g56 = ( ( dotResult31_g56 - temp_output_1_0_g57 ) / ( ( cosFactor57_g56 * flipRadius55_g56 ) - temp_output_1_0_g57 ) );
				float outputMask42 = step( abs( temp_output_53_0_g56 ) , 1.0 );
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch299 = step( 0.001 , ( ( 1.0 - sideIndex87 ) * outputMask42 ) );
				#else
				float staticSwitch299 = 1.0;
				#endif
				#ifdef _KVRL_PASSTHROUGH_ON
				float staticSwitch522 = ( 1.0 - staticSwitch299 );
				#else
				float staticSwitch522 = staticSwitch299;
				#endif
				

				surfaceDescription.Alpha = staticSwitch522;
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
Node;AmplifyShaderEditor.CommentaryNode;305;-2458.404,-1045.513;Inherit;False;2356.331;912.241;Create Grid out of input coordinates, output grid centers and cell sizes;23;463;461;447;34;25;118;117;446;26;119;410;125;11;434;409;120;464;465;468;466;469;470;500;UV Grid;1,1,1,1;0;0
Node;AmplifyShaderEditor.PosVertexDataNode;120;-2429.312,-714.3236;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;320;-6166.855,-136.1776;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectScaleNode;409;-1725.696,-373.6931;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;500;-2021.412,-373.9776;Inherit;False;Mask Tangent Space;-1;;86;b5934695b2afef042bab2384c1f05b90;3,18,1,19,0,17,1;1;1;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;2;FLOAT;21;FLOAT;22
Node;AmplifyShaderEditor.CommentaryNode;313;-5626.014,-1224.522;Inherit;False;2782.714;796.3502;To align flip axist to closest World Space axis;26;165;163;164;167;166;128;172;173;174;178;179;180;219;218;217;236;249;247;248;250;251;252;253;254;188;239;Flip Axis;1,1,1,1;0;0
Node;AmplifyShaderEditor.AbsOpNode;324;-5544.352,-143.306;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1505.309,-977.5526;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;410;-1443.546,-563.6511;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;125;-1473.753,-799.5029;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;317;-6145.236,369.8335;Inherit;False;Constant;_Vector7;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;318;-6157,54.18637;Inherit;False;Constant;_Vector8;Vector 4;8;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;319;-6148.236,215.8333;Inherit;False;Constant;_Vector9;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;165;-5564.251,-613.1718;Inherit;False;Constant;_Vector6;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;163;-5576.014,-928.8188;Inherit;False;Constant;_Vector4;Vector 4;8;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;164;-5567.251,-767.1718;Inherit;False;Constant;_Vector5;Vector 4;8;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;327;-5407.352,-138.306;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.StaticSwitch;119;-1219.958,-830.7115;Inherit;False;Property;_UVMode;UV Mode;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;4;UV;WorldGrid;WorldGrid2;ObjectGrid;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;167;-5369.251,-613.1718;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;166;-5368.251,-766.1718;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;128;-5360.166,-920.5337;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;332;-5215.448,391.0483;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;316;-5218.146,2.29301;Inherit;False;float m = min(min(TestA, TestB), TestC)@$if (TestA == m) {$return OutA@$}$if (TestB == m) {$return OutB@$}$return OutC@;3;Create;6;True;TestA;FLOAT;0;In;;Inherit;False;True;TestB;FLOAT;0;In;;Inherit;False;True;TestC;FLOAT;0;In;;Inherit;False;True;OutA;FLOAT3;0,0,0;In;;Inherit;False;True;OutB;FLOAT3;0,0,0;In;;Inherit;False;True;OutC;FLOAT3;0,0,0;In;;Inherit;False;Selector;False;False;0;;False;6;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-945.4172,-823.0781;Inherit;False;inputCoord;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;172;-5087.924,-922.0229;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;173;-5086.924,-766.0228;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;174;-5088.924,-610.0228;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;331;-4993.795,298.8884;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;446;-678.6062,-824.7858;Inherit;False;UV Grid;8;;55;00fc8464f2b1b2f4182579db99f68779;0;2;10;FLOAT3;0,0,0;False;39;FLOAT2;0,0;False;4;FLOAT2;0;FLOAT3;13;FLOAT2;11;FLOAT;28
Node;AmplifyShaderEditor.CommentaryNode;314;-4497.629,2614.453;Inherit;False;2137.327;1031.889;Handle logic to transform uniform transition value into something more dynamic;24;294;145;59;146;311;144;153;293;291;143;152;290;295;147;416;417;418;419;424;439;452;453;456;457;Transition Val Remap;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;111;-4075.91,1167.545;Inherit;False;Property;_GlobalControl;Global Control;5;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;178;-4914.736,-920.9029;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;179;-4913.736,-765.903;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;180;-4917.736,-607.903;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.VertexTangentNode;333;-4964.405,117.4828;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexBinormalNode;334;-4961.463,445.6952;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;352;-4784.885,305.9114;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;117;-355.9152,-803.2443;Inherit;False;cellCenter3D;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-4456.129,3372.415;Inherit;False;117;cellCenter3D;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;424;-4438.819,3472.844;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;292;-3876.766,1168.101;Inherit;False;useGlobals;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;219;-4714.198,-614.7684;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;218;-4741.198,-781.7683;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;217;-4744.532,-918.0502;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;335;-4559.589,202.1158;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;336;-4563.589,349.1158;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-5006.627,1875.895;Inherit;False;Property;_FlipFuzz;Flip Fuzz;12;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;448;-4948.442,1988.868;Inherit;False;Global;KVRL_TransitionFuzz;KVRL_TransitionFuzz;9;0;Create;True;0;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;450;-4917.442,2130.868;Inherit;False;292;useGlobals;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;248;-4246.02,-1174.522;Inherit;False;Constant;_Vector11;Vector 11;9;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;236;-4460.839,-883.7426;Inherit;False;float m = min(min(TestA, TestB), TestC)@$if (TestA == m) {$return OutA@$}$if (TestB == m) {$return OutB@$}$return OutC@;3;Create;6;True;TestA;FLOAT;0;In;;Inherit;False;True;TestB;FLOAT;0;In;;Inherit;False;True;TestC;FLOAT;0;In;;Inherit;False;True;OutA;FLOAT3;0,0,0;In;;Inherit;False;True;OutB;FLOAT3;0,0,0;In;;Inherit;False;True;OutC;FLOAT3;0,0,0;In;;Inherit;False;Selector;False;False;0;;False;6;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;247;-4247.113,-1024.081;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;387;-4418.26,405.4437;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;439;-4223.656,3449.271;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-3944.64,972.8411;Inherit;False;Property;_Transition;Transition;11;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-3939.91,1077.545;Inherit;False;Global;KVRL_PanelTransition;KVRL_PanelTransition;6;0;Create;True;0;0;0;False;0;False;0;0.002053499;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;449;-4605.442,1964.868;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-3977.294,-912.7094;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;250;-3986.806,-1099.266;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;295;-4134.606,2876.973;Inherit;False;292;useGlobals;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;290;-4447.629,2697.51;Inherit;False;Global;KVRL_TransitionSphere;KVRL_TransitionSphere;10;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.8127849,-2.997974,6.111092;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SignOpNode;359;-4411.622,512.8539;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;417;-4089.213,3451.559;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;147;-4151.684,2729.048;Inherit;False;Constant;_Float1;Float 1;10;0;Create;True;0;0;0;False;0;False;7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;309;-2645.518,43.09111;Inherit;False;2395.913;1129.815;Use input coordinates, centers, radii, and direction to apply a tile flip on the UV. Output resulting UV and masks;35;443;41;442;42;87;379;60;157;136;121;122;158;44;384;415;413;134;340;189;135;28;126;132;27;123;308;497;504;505;507;502;508;503;509;510;Tile Flip;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;112;-3634.91,1052.545;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;-4388.15,1882.304;Inherit;False;fuzzy;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CrossProductOpNode;251;-3761.079,-1103.699;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;394;-4351.901,141.0119;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;392;-4224.881,498.3516;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;416;-3866.776,3316.385;Inherit;False;Property;_Keyword4;Keyword 4;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;293;-3916.492,2762.255;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;308;-2608.118,654.4164;Inherit;False;671.8411;335.4459;Use Object Scale to compute correct cell size;6;139;142;124;140;141;444;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;291;-4145.913,3165.969;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;310;-3451.134,1052.969;Inherit;False;rawTransitionVal;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;143;-4164.358,2968.666;Inherit;False;Constant;_Vector2;Vector 2;10;0;Create;True;0;0;0;False;0;False;0,1,-2.7;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;252;-3560.699,-1052.77;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;393;-4090.332,208.6819;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;418;-3657.145,3317.63;Inherit;False;transitionCellCenter;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-3566.17,2962.326;Inherit;False;149;fuzzy;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;452;-3706.086,2761.427;Inherit;False;transitionRadius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;118;-341.915,-609.2443;Inherit;False;cellRadius3D;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;139;-2549.276,804.8623;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;294;-3898.26,3146.541;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;253;-3406.534,-1051.762;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;124;-2558.118,723.4366;Inherit;False;118;cellRadius3D;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;338;-3373.375,257.4808;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;419;-3740.105,3101.738;Inherit;False;418;transitionCellCenter;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;456;-3275.718,2962.824;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-3589.709,2870.568;Inherit;False;310;rawTransitionVal;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;153;-3283.139,2713.738;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;123;-2618.059,433.5835;Inherit;False;117;cellCenter3D;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;501;-2463.472,987.3553;Inherit;False;Mask Tangent Space;-1;;87;b5934695b2afef042bab2384c1f05b90;3,18,1,19,0,17,1;1;1;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;2;FLOAT;21;FLOAT;22
Node;AmplifyShaderEditor.GetLocalVarNode;27;-1910.455,84.24331;Inherit;False;26;inputCoord;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;254;-3261.727,-1024.007;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;361;-3205.245,256.5953;Inherit;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;140;-2351.939,703.4164;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;142;-2335.375,842.0624;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;145;-3458.791,3126.747;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;146;-3076.649,2715.519;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;453;-3073.524,2846.814;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;126;-2328.712,310.7004;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;502;-1673.637,186.5631;Inherit;False;Mask Tangent Space;-1;;88;b5934695b2afef042bab2384c1f05b90;3,18,1,19,0,17,1;1;1;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;2;FLOAT;21;FLOAT;22
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-3085.3,-1024.762;Inherit;False;selectTileAxis;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;339;-2999.352,254.7769;Inherit;False;refactorAxis;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PosVertexDataNode;132;-2459.3,100.0679;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;141;-2059.575,698.92;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;457;-2830.199,2923.982;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;25;-355.4191,-876.8141;Inherit;False;cellCenter2D;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;34;-347.7331,-714.6837;Inherit;False;cellRadius2D;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;503;-2024.534,283.5705;Inherit;False;Mask Tangent Space;-1;;89;b5934695b2afef042bab2384c1f05b90;3,18,1,19,0,17,1;1;1;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;2;FLOAT;21;FLOAT;22
Node;AmplifyShaderEditor.FunctionNode;509;-2041.116,467.1765;Inherit;False;Mask Tangent Space;-1;;90;b5934695b2afef042bab2384c1f05b90;3,18,1,19,0,17,1;1;1;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;2;FLOAT;21;FLOAT;22
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-2636.241,2919.886;Inherit;False;transitionValue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;134;-2226.66,141.0846;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-1457.673,359.895;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;-1464.923,920.6494;Inherit;False;188;selectTileAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;340;-1438.024,996.9255;Inherit;False;339;refactorAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;384;-1422.128,636.726;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1483.407,564.0453;Inherit;False;34;cellRadius2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;158;-1459.154,791.7657;Inherit;False;Constant;_Vector3;Vector 3;11;0;Create;True;0;0;0;False;0;False;1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;497;-1243.076,187.4058;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;135;-1699.486,336.8433;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;510;-1680.408,482.5767;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;122;-1185.85,588.4128;Inherit;False;Property;_Keyword1;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;121;-1189.682,401.1543;Inherit;False;Property;_Keyword0;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;157;-1062.684,783.437;Inherit;False;Property;_Keyword3;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;60;-1072.654,958.2639;Inherit;False;59;transitionValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;136;-1028.334,100.1997;Inherit;False;Property;_Keyword2;Keyword 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;119;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;379;-850.0125,511.9034;Inherit;False;UV Tile Flip;0;;56;6daf8d5c4b1e8a34692471ef82b8bba2;0;5;21;FLOAT2;0,0;False;22;FLOAT2;0,0;False;24;FLOAT2;0,0;False;29;FLOAT2;1,0;False;23;FLOAT;0;False;3;FLOAT2;27;FLOAT;0;FLOAT;28
Node;AmplifyShaderEditor.CommentaryNode;312;159.8743,-268.1654;Inherit;False;1076.345;654.6147;Render Stuff based on Tile UVs, Tile Side, and Mask;12;108;107;109;100;137;223;222;221;47;90;48;49;Tile Rendering;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-505.4884,669.8831;Inherit;False;sideIndex;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;220.1929,-22.7177;Inherit;False;87;sideIndex;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;42;-506.763,528.7427;Inherit;False;outputMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;108;454.1056,191.2304;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;209.8743,268.6389;Inherit;False;42;outputMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;304;1339.937,-223.4646;Inherit;False;1559.458;686.7066;Alpha Blend on color + alpha, plus Keyword to enable and disable clipping vs opaque debug version;7;303;299;302;300;301;298;522;Passthrough Magic;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;626.4337,249.4494;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;625.6109,154.6976;Inherit;False;Constant;_Float2;Float 2;3;0;Create;True;0;0;0;False;0;False;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;298;1375.187,134.0034;Inherit;False;Constant;_Float9;Float 9;11;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;109;888.9192,227.377;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;299;1550.482,220.27;Inherit;False;Property;_KVRL_PASSTHROUGH_ON;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;1;0;0;False;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;302;1874.197,317.5486;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;507;-1410.394,191.2069;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;508;-1414.394,262.2069;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;413;-2292.397,495.1273;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;504;-1259.596,311.7089;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;434;-1679.174,-692.3764;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SignOpNode;347;-5851.715,461.0987;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;346;-5833.458,295.4594;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;345;-5840.86,-15.25637;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;395;-5655.8,47.45053;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;397;-5615.112,463.6598;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;396;-5617.112,262.6598;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;348;-5449.04,-13.54609;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;350;-5421.652,376.4241;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;349;-5447.735,196.4377;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;63;-4561.794,1516.731;Inherit;False;Constant;_Vector0;Vector 0;3;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;64;-4558.794,1655.731;Inherit;False;Constant;_Vector1;Vector 1;3;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;77;-4059.109,1731.843;Inherit;False;Constant;_Float4;Float 4;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-4537.794,1322.73;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;72;-4312.047,1609.165;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;74;-3903.047,1613.165;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;84;-3855.531,1700.242;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;71;-4306.047,1445.165;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;85;-4135.045,1547.396;Inherit;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;-3727.109,1615.843;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;86;-3867.848,1447.409;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;75;-3467.693,1403.339;Inherit;False;Inverse Lerp;-1;;58;09cbe79402f023141a4dc1fddd4c9511;0;3;1;FLOAT;-0.05;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;69;-3218.399,1797.369;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;70;-3232.193,1660.647;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;195;1130.824,-1155.97;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;196;753.8233,-1241.97;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;756.8233,-1164.97;Inherit;False;Constant;_Float6;Float 6;8;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;198;754.8233,-1075.97;Inherit;False;Constant;_Float7;Float 7;8;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;199;872.8233,-980.97;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;200;708.8233,-982.97;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;194;458.8233,-989.97;Inherit;False;188;selectTileAxis;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClipNode;300;2375.084,5.681629;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;100;522.5889,-116.307;Inherit;False;Screen Tile Rendering;2;;59;ff5237cf56b52f541b4a2ac20bb5bc2f;0;3;1;FLOAT2;0,0;False;4;FLOAT;0;False;2;FLOAT;1;False;2;COLOR;0;FLOAT;9
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;845.593,-115.3231;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;223;1058.219,-114.1815;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;222;843.6926,1.476624;Inherit;False;Property;_DebugOut;Debug Out;10;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;221;815.1431,-218.1654;Inherit;False;220;testOutg;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;239;-3226.597,-872.0632;Inherit;False;selectTileBiaxis;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;-3998.889,58.16248;Inherit;False;25;cellCenter2D;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;67;-3023.229,1358.115;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;401;-5152.948,-374.5777;Inherit;False;Constant;_Vector10;Vector 10;9;0;Create;True;0;0;0;False;0;False;1,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;403;-4688.57,-359.7216;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;402;-4940.644,-374.7116;Inherit;False;Object;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.AbsOpNode;405;-4532.72,-351.1975;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;422;51.41858,-739.843;Inherit;False;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;444;-2115.562,854.6542;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;82;-4005.907,2095.684;Inherit;False;Constant;_Float3;Float 3;5;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-3798.905,2077.684;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;83;-3444.204,2087.084;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;301;2589.208,-96.35144;Inherit;False;Property;_KVRL_PASSTHROUGH_ON1;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Reference;299;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BitangentVertexDataNode;459;2928.162,-317.4828;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TangentVertexDataNode;458;3296.286,-282.7583;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.AbsOpNode;460;3232.125,-68.18195;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;447;-871.6061,-595.6429;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;442;-1265.075,797.9131;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;-503.7083,393.2708;Inherit;False;outputCoord;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;443;-1218.624,886.2417;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TangentVertexDataNode;461;-2423.245,-924.9204;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;466;-1794.28,-839.2699;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;470;-1845.963,-579.3473;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;469;-1947.963,-839.3473;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BitangentVertexDataNode;463;-2424.245,-553.9204;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.AbsOpNode;468;-2163.28,-441.2699;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;464;-2178.749,-922.0186;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;465;-2021.749,-505.0186;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;218.8087,-116.8267;Inherit;False;41;outputCoord;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;220;-1231.513,-104.1186;Inherit;False;testOutg;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;506;-1498.253,-58.91382;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;415;-1611.107,98.14391;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;505;-1389.596,89.70892;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;3115.251,408.9395;Inherit;False;Property;_Cull;Cull;6;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;303;2043.413,92.8103;Inherit;False;Property;_KVRL_PASSTHROUGH_ON2;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Reference;299;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;522;2233.757,251.2762;Inherit;False;Property;_KVRL_PASSTHROUGH_ON3;KVRL_PASSTHROUGH_ON;11;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Reference;299;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;511;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;512;3107.06,176.4736;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;HSS08/FX/Screen Flip (Passthrough);2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;0;True;_Cull;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;True;True;2;5;False;;10;False;;2;5;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;21;Surface;0;0;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;0;638460049264641696;  Use Shadow Threshold;0;0;GPU Instancing;1;0;LOD CrossFade;0;638460049254398795;Built-in Fog;0;638460049243836269;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;False;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;513;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;514;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;True;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;515;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;516;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;517;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;518;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;519;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;520;3107.06,176.4736;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.CommentaryNode;521;3094.43,523.6182;Inherit;False;734;100;Set BlendOp to Alpha Blend for RGB and A cause this shit likes to reset it to One Zero;0;IMPORTANT;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;159;-1125.64,1695.197;Inherit;False;404;117;Proper scaling or whatever of corrected Axis;0;TODO;1,1,1,1;0;0
WireConnection;500;1;120;0
WireConnection;324;0;320;0
WireConnection;410;0;500;0
WireConnection;410;1;409;0
WireConnection;327;0;324;0
WireConnection;119;1;11;0
WireConnection;119;0;125;0
WireConnection;119;2;125;0
WireConnection;119;3;410;0
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
WireConnection;446;10;26;0
WireConnection;178;0;172;0
WireConnection;179;0;173;0
WireConnection;180;0;174;0
WireConnection;352;0;331;0
WireConnection;117;0;446;13
WireConnection;292;0;111;0
WireConnection;219;0;180;1
WireConnection;218;0;179;1
WireConnection;217;0;178;1
WireConnection;335;0;333;0
WireConnection;335;1;352;0
WireConnection;336;0;352;0
WireConnection;336;1;334;0
WireConnection;236;0;217;0
WireConnection;236;1;218;0
WireConnection;236;2;219;0
WireConnection;236;3;128;0
WireConnection;236;4;166;0
WireConnection;236;5;167;0
WireConnection;387;0;335;0
WireConnection;387;1;336;0
WireConnection;439;0;144;0
WireConnection;439;1;424;0
WireConnection;449;0;68;0
WireConnection;449;1;448;0
WireConnection;449;2;450;0
WireConnection;249;0;247;0
WireConnection;249;1;236;0
WireConnection;250;0;248;0
WireConnection;250;1;247;0
WireConnection;359;0;387;0
WireConnection;417;0;439;0
WireConnection;112;0;13;0
WireConnection;112;1;110;0
WireConnection;112;2;292;0
WireConnection;149;0;449;0
WireConnection;251;0;249;0
WireConnection;251;1;250;0
WireConnection;394;0;335;0
WireConnection;392;1;359;0
WireConnection;416;1;144;0
WireConnection;416;0;144;0
WireConnection;416;2;144;0
WireConnection;416;3;417;0
WireConnection;293;0;147;0
WireConnection;293;1;290;4
WireConnection;293;2;295;0
WireConnection;291;0;290;0
WireConnection;310;0;112;0
WireConnection;252;0;251;0
WireConnection;252;1;247;0
WireConnection;393;0;394;0
WireConnection;393;1;335;0
WireConnection;393;2;392;0
WireConnection;418;0;416;0
WireConnection;452;0;293;0
WireConnection;118;0;446;28
WireConnection;294;0;143;0
WireConnection;294;1;291;0
WireConnection;294;2;295;0
WireConnection;253;0;252;0
WireConnection;338;0;393;0
WireConnection;338;1;336;0
WireConnection;456;0;152;0
WireConnection;153;0;452;0
WireConnection;153;1;152;0
WireConnection;501;1;139;0
WireConnection;254;0;253;0
WireConnection;254;1;253;2
WireConnection;361;0;338;0
WireConnection;140;0;124;0
WireConnection;140;1;124;0
WireConnection;142;0;501;2
WireConnection;142;1;501;21
WireConnection;145;0;419;0
WireConnection;145;1;294;0
WireConnection;146;1;153;0
WireConnection;146;2;311;0
WireConnection;453;0;456;0
WireConnection;453;1;452;0
WireConnection;453;2;311;0
WireConnection;126;0;123;0
WireConnection;502;1;27;0
WireConnection;188;0;254;0
WireConnection;339;0;361;0
WireConnection;141;0;140;0
WireConnection;141;1;142;0
WireConnection;457;0;145;0
WireConnection;457;1;146;0
WireConnection;457;2;453;0
WireConnection;25;0;446;0
WireConnection;34;0;446;11
WireConnection;503;1;126;0
WireConnection;509;1;123;0
WireConnection;59;0;457;0
WireConnection;134;0;132;1
WireConnection;134;1;132;3
WireConnection;384;0;141;0
WireConnection;497;0;502;2
WireConnection;497;1;502;21
WireConnection;135;0;503;2
WireConnection;135;1;503;21
WireConnection;510;0;509;2
WireConnection;510;1;509;21
WireConnection;122;1;44;0
WireConnection;122;0;141;0
WireConnection;122;2;384;0
WireConnection;122;3;140;0
WireConnection;121;1;28;0
WireConnection;121;0;135;0
WireConnection;121;2;135;0
WireConnection;121;3;510;0
WireConnection;157;1;158;0
WireConnection;157;0;189;0
WireConnection;157;2;340;0
WireConnection;157;3;158;0
WireConnection;136;1;27;0
WireConnection;136;0;134;0
WireConnection;136;2;134;0
WireConnection;136;3;497;0
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
WireConnection;299;1;298;0
WireConnection;299;0;109;0
WireConnection;302;0;299;0
WireConnection;507;0;502;2
WireConnection;508;0;502;21
WireConnection;413;0;123;0
WireConnection;504;0;502;21
WireConnection;434;0;120;1
WireConnection;434;2;120;3
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
WireConnection;300;0;223;0
WireConnection;300;1;299;0
WireConnection;100;1;47;0
WireConnection;100;4;90;0
WireConnection;100;2;48;0
WireConnection;137;0;100;0
WireConnection;137;1;48;0
WireConnection;223;0;137;0
WireConnection;223;1;221;0
WireConnection;223;2;222;0
WireConnection;67;0;112;0
WireConnection;67;1;70;0
WireConnection;67;2;69;0
WireConnection;403;0;402;0
WireConnection;403;1;352;0
WireConnection;402;0;401;0
WireConnection;405;0;403;0
WireConnection;422;0;117;0
WireConnection;444;0;140;0
WireConnection;444;1;142;0
WireConnection;81;0;68;0
WireConnection;81;1;82;0
WireConnection;83;0;81;0
WireConnection;301;1;223;0
WireConnection;301;0;300;0
WireConnection;460;0;459;0
WireConnection;442;0;158;0
WireConnection;442;1;142;0
WireConnection;41;0;379;27
WireConnection;466;0;469;0
WireConnection;466;1;470;0
WireConnection;470;0;463;0
WireConnection;470;1;465;0
WireConnection;469;0;464;0
WireConnection;468;0;463;0
WireConnection;464;0;461;0
WireConnection;464;1;120;0
WireConnection;465;0;120;0
WireConnection;465;1;463;0
WireConnection;220;0;497;0
WireConnection;506;0;27;0
WireConnection;415;0;27;0
WireConnection;505;0;502;2
WireConnection;303;1;299;0
WireConnection;303;0;299;0
WireConnection;522;1;299;0
WireConnection;522;0;302;0
WireConnection;512;2;301;0
WireConnection;512;3;522;0
ASEEND*/
//CHKSM=E1396A9AA86A69C2D63BCB417C7817B86E8762AC