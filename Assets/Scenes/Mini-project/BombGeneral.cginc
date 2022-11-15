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
    float2 uv2 : TEXCOORD6;
    float4 vertex : SV_POSITION;
    float4 screenuv : TEXCOORD1; // ############
    float4 worldPos : TEXCOORD2;
    float4 clipPos : TEXCOORD3;
    half4 normal : TEXCOORD4;
    half3 worldNormal : TEXCOORD5;
    half3 viewDir: POSITION1;
    float2 textUv : TEXCOORD7;
};

float4 _BaseColor;
sampler2D _CameraDepthTexture; // ############
sampler2D _PulseTex; // ############
sampler2D _LineTex; // ############
sampler2D _NoiseTex; // ############
float _Height; 
float4 _PulseTex_ST;
float4 _NoiseTex_ST;
float _Test; 
float _Test2; 

float4 _IntersectColor;
float4 _IntersectColor2;
float _FadeLength;

v2f generalVert (appdata v) {
    v2f o;
    o.worldPos = mul(unity_ObjectToWorld, v.uv);
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.screenuv = ComputeScreenPos(o.vertex);
    COMPUTE_EYEDEPTH(o.screenuv.z);
    o.uv = v.uv;
    o.textUv = TRANSFORM_TEX(v.uv, _NoiseTex);
    o.normal = v.normal;
    return o;
}

float3 getScale() {
    return float3(
        length(unity_ObjectToWorld._m00_m10_m20),
        length(unity_ObjectToWorld._m01_m11_m21),
        length(unity_ObjectToWorld._m02_m12_m22));
}

float getSceneZ(v2f i) {
    return LinearEyeDepth(
        SAMPLE_DEPTH_TEXTURE_PROJ(
            _CameraDepthTexture,
            UNITY_PROJ_COORD(i.screenuv)
            ));
}
                