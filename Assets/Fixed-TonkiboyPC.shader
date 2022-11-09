// https://forum.unity.com/threads/alpha-mask-shader-help.181605/
// https://gist.github.com/2600th/2df0691b025ba61feea4
// https://www.youtube.com/watch?v=EthjeNeNTsM&ab_channel=N3KEN
// https://www.youtube.com/watch?v=H12xHzuzjpI

Shader "Universal Render Pipeline/Fixed" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (0, 0, 0, 1)
        _TransOOS ("OOS transparency", range(0, 1)) = .2

        [Header(Major gradient)]
        _TransL ("Transparency", range(0, 1)) = .4
        _UpperLerpL ("Upper lerp", range(0, 2)) = .15
        _LowerLerpL ("Lower lerp", range(-1, 1)) = .0

        [Header(Minor gradient)]
        _TransS ("Transparency", range(0, 1)) = .9
        _UpperLerpS ("Upper lerp", range(0, 2)) = .05
        _LowerLerpS ("Lower lerp", range(-2, 1)) = .03

    }

    SubShader {

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        ColorMask RGB

        Tags {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
            }

        // In seight 
        Pass {

            ZTest LEqual // Render in front objects

            CGPROGRAM
            #include "Fixed_plugin-TonkiboyPC.cginc"

            fixed4 frag (v2f i) : SV_Target {
                return make_gradients(i);
            }
            ENDCG
        }

        // Out of seight 
        Pass {

            ZTest GEqual // Render behind objects

            CGPROGRAM
            #include "Fixed_plugin-TonkiboyPC.cginc"
            float _TransOOS; // Out of seight opacity

            fixed4 frag (v2f i) : SV_Target {
                fixed4 col = make_gradients(i);
                col.a *= _TransOOS;
                return col;
            }
            ENDCG
        }
    }
}
