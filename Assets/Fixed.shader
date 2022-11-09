// https://forum.unity.com/threads/alpha-mask-shader-help.181605/
// https://gist.github.com/2600th/2df0691b025ba61feea4
// https://www.youtube.com/watch?v=EthjeNeNTsM&ab_channel=N3KEN

Shader "Unlit/Fixed" {
    Properties {
        _BaseColor ("BaseColor", Color) = (0, 0, 0, 1)
        _TransOOS ("OOS transparency", range(0, 1)) = 1.0

        [Header(Major gradient)]
        _TransL ("Opacity", range(0, 1)) = .5
        _ColorStartL ("Upper", range(0, 1)) = .7
        _ColorEndL ("Lower", range(-1, 1)) = .0

        [Header(Minor gradient)]
        _TransS ("Opacity", range(0, 1)) = .9
        _ColorStartS ("Upper", range(0, 1)) = .05
        _ColorEndS ("Lower", range(-1, 1)) = .03

    }

    SubShader {
        Tags {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
            }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        ColorMask RGB

        // In seight 
        Pass {

            ZTest LEqual // Render in front objects

            CGPROGRAM
            #include "Fixed_plugin.cginc"

            fixed4 frag (v2f i) : SV_Target {
                return make_gradients(i);
            }
            ENDCG
        }

        // Out of seight 
        Pass {

            ZTest GEqual // Render behind objects

            CGPROGRAM
            #include "Fixed_plugin.cginc"
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
