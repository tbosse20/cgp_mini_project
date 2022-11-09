#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

struct appdata {
    float4 vertex : POSITION;
    float4 uv : TEXCOORD0;
    fixed3 normal : NORMAL;
};

struct v2f {
    float2 uv : TEXCOORD0;
    float4 screenuv : TEXCOORD1;
    float4 vertex : SV_POSITION;
    fixed3 normal : NORMAL;
};

sampler2D _CameraDepthTexture;
fixed4 _BaseColor;

float _TransOOS; // Out of seight opacity

float _TransL; // Opacity for major gradient
float _UpperL; // Gradient upper position
float _LowerL; // Gradient lower position

float _TransS; // Opacity for minor gradient
float _UpperS; // Gradient upper position
float _LowerS; // Gradient lower position

v2f vert(appdata v) {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.screenuv = ComputeScreenPos(o.vertex);
    COMPUTE_EYEDEPTH(o.screenuv.z);
    o.uv = v.uv;
    o.normal = v.normal;
    return o;
}

float InverseLerp(float a, float b, float v) {
    return (v-a) / (b-a);
}

float intersection(v2f i) {
    
    float sceneZ = LinearEyeDepth(
        SAMPLE_DEPTH_TEXTURE_PROJ(
            _CameraDepthTexture,
        UNITY_PROJ_COORD(i.screenuv)
        ));
    float partZ = i.screenuv.z;
    float intersect = sceneZ - partZ;

    // Make major gradient mask
    float tL = saturate(InverseLerp(_UpperL, _LowerL, intersect));
    tL *= intersect > 0;
    tL *= _TransL; // Adjust opacity

    // Make minor gradient mask
    float tS = saturate(InverseLerp(_UpperS, _LowerS, intersect));
    tS *= intersect > 0;
    tS *= _TransS; // Adjust opacity

    float4 t = tL + tS; // Add major and minor gradient mask
    return t;
}