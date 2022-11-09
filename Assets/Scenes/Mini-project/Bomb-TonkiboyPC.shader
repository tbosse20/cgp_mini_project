// https://lexdev.net/tutorials/case_studies/overwatch_shield.html

Shader "Unlit/Bomb" {
    Properties {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _PulseTex("Hex Pulse Texture", 2D) = "white" {}
        _IntersectColor ("Intersect color", Color) = (0, 0, .7, 1)
        _IntersectColor2 ("Intersect color", Color) = (0, 0, .7, 1)
        _Height ("Height", range(0, 25)) = 15.0
        _Tiling ("Tiling", range(0, 2)) = .5
        _FadeLength ("Fade length", float) = 10.0
        _RimWhite ("RimWhite", range(0, 1)) = .5
        _Outer ("Outer", range(-10, 10)) = .5
    }

    SubShader {
        
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
            }
    
        Blend SrcAlpha OneMinusSrcAlpha 

        // Outside rim
        Pass {
            
            Cull Off
            ZWrite Off
            ZTest Less

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height; 
            float _RimWhite; 

            v2f vert (appdata v) {
                v2f o;
                v.vertex.y /= 10;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                float height = pow((_Height + 10) / 10, 5); // Recalculate height
                // height /= pow(i.uv.x, 1); // Depend to uv scale
                float rimEffect = (1. - saturate(abs(i.uv.y - 0.5) * height));
                float ySides = (abs(i.normal.y) < 0.999);
                float rims = rimEffect * ySides; 
                col.a *= rims;
                col.rgb = saturate(col.rgb * _RimWhite * 10);

                // col.Emission = _BaseColor.rgb; // Add Emission

                return col;
            }
            ENDCG
        }

        // Inside surface
        Pass {
            
            Cull Off
            ZWrite Off
            ZTest Less

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
                half4 vertexuv : TEXCOORD5;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height;
            float _Tiling;
            float _Outer;

            sampler2D _PulseTex;
            float4 _PulseTex_ST; 

            v2f vert (appdata v) {
                v2f o;
                v.vertex.y = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.uv = TRANSFORM_TEX(v.uv, _PulseTex);
                o.uv = v.uv;
                o.vertexuv = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                fixed4 pulseTex = tex2D(_PulseTex, i.vertexuv);
                col.a *= pulseTex;

                float circleGradient = saturate(distance(i.uv, (0, 0, 0.5)) * 2.5 - .9);
                col.rgb += circleGradient;


                float dist = distance(i.uv, (0, 0, sin(0.5)));
                // float pulse = (1 - saturate(sin(dist * i.normal.y * 20 - _Time.y) * .5));
                float pulse = (1 - saturate(sin(dist * 20 - _Time.y) * 10)) * .2;
                // return pulse *;
                col.a += pulse * .6;

                col.a *= i.normal.y > 0.99;

                return col;
            }
            ENDCG
        }

        // In front objects
        Pass {
            
            Cull Front
            ZWrite Off
            ZTest Greater

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                // half3 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            float4 _IntersectColor;
            float4 _IntersectColor2;
            sampler2D _CameraDepthTexture; // ############
            float _FadeLength;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.uv = v.uv;
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                fixed4 col = _IntersectColor;
                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(
                        _CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenuv)
                    ));
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                fixed4 test = fixed4(lerp(i.uv, _BaseColor, intersect));
                
                // col.a *= test;

                return col;
            }
            ENDCG
        }

        // Intersection
        Pass {
            
            Cull Front
            ZWrite Off
            ZTest Greater

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half3 normal : TEXCOORD4;
            };

            float4 _BaseColor;
            float4 _IntersectColor;
            float4 _IntersectColor2;
            sampler2D _CameraDepthTexture; // ############
            float _FadeLength;

            v2f vert (appdata v) {
                v2f o;
                v.vertex.y = v.vertex.y = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.uv = v.uv;
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                fixed4 col = _IntersectColor2;
                float sceneZ = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE_PROJ(
                        _CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenuv)
                    ));
                float partZ = i.screenuv.z;
                float diff = sceneZ - partZ;
                float intersect = saturate(pow(_FadeLength * 2, 5) * diff);
                fixed4 test = fixed4(lerp(i.uv, fixed4(0, 0, 0, 1), intersect));
                
                col.a *= test;

                return col;
            }
            ENDCG
        }
    }
}
