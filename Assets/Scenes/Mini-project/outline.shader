Shader "Unlit/outline"
{
    Properties
    {
        _BaseColor ("Base color", Color) = (.09, .8, .8, 1)
        _Outline ("Base color", Color) = (.09, .8, .8, 1)
        _OutlineWidth ("Height", range(0, 25)) = 15.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // Outside rim
        Pass {
            
            Cull Front
            // ZWrite Off

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
                float2 uv : TEXCOORD0;
                float2 textUv : TEXCOORD5;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
                half4 thickNormal : TEXCOORD6;
            };

            float4 _Outline;
            sampler2D _CameraDepthTexture; // ############
            float _OutlineWidth; 
            float _Intensity; 
            sampler2D _NoiseTex; // ############
            float4 _NoiseTex_ST;
            float _Test; 

            v2f vert (appdata v) {
                v2f o;
                // v.vertex.y = v.vertex.y / 10;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex * _OutlineWidth / 10 + v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.textUv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.normal = v.normal;
                // half4 emission = _BaseColor * _Intensity;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _Outline;

                return col;
            }
            ENDCG
        }

        Pass {
            
            Cull Off

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
                float2 uv : TEXCOORD0;
                float2 textUv : TEXCOORD5;
                float4 vertex : SV_POSITION;
                float4 screenuv : TEXCOORD1; // ############
                float4 worldPos : TEXCOORD2;
                // half3 worldNormal : TEXCOORD3;
                half4 normal : TEXCOORD4;
                half4 thickNormal : TEXCOORD6;
            };

            float4 _BaseColor;
            sampler2D _CameraDepthTexture; // ############
            float _Height; 
            float _Intensity; 
            sampler2D _NoiseTex; // ############
            float4 _NoiseTex_ST;
            float _Test; 

            v2f vert (appdata v) {
                v2f o;
                // v.vertex.y = v.vertex.y / 10;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // o.vertex = UnityObjectToClipPos(v.vertex * _Test + v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.uv);
                o.screenuv = ComputeScreenPos(o.vertex); // ############
                COMPUTE_EYEDEPTH(o.screenuv.z); // ############
                // o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.textUv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.normal = v.normal;
                // half4 emission = _BaseColor * _Intensity;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                
                float4 col = _BaseColor;

                return col;
            }
            ENDCG
        }
    }
}
