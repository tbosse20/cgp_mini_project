Shader "Unlit/Lego"
{
    Properties
    {
        _Color ("Color", Color) = (.09, .8, .8, 1)
        _Resolution ("Resolution", Integer) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform float4 _LightColor0; 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 normal: TEXCOORD1;
                float4 col : COLOR;
            };

            float4 _Color;
            float _Resolution;

            float sigmoid(float4 v) {
                return v;
                // return 1 / (1 + exp(-v));
            }

            v2f vert (appdata v) {
                v2f o;

                v.vertex *= _Resolution;
                v.vertex = floor(v.vertex * _Resolution + .5);
                v.vertex /= _Resolution * _Resolution;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
 
                // https://en.wikibooks.org/wiki/Cg_Programming/Unity/Diffuse_Reflection
                float4x4 modelMatrix = unity_ObjectToWorld;
                float4x4 modelMatrixInverse = unity_WorldToObject;
    
                float3 normalDirection = normalize(
                    mul(v.normal, modelMatrixInverse).xyz);
                // alternative: 
                // float3 normalDirection = UnityObjectToWorldNormal(input.normal);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
    
                float3 diffuseReflection = _LightColor0.rgb * _Color.rgb
                * max(0.0, dot(normalDirection, lightDirection));
    
                o.col = float4(diffuseReflection, 1.0);
                // o.pos = UnityObjectToClipPos(input.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target {

                return i.col;
            }
            ENDCG
        }
    }
}
