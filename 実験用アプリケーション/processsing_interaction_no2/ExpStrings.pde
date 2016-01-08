// Gesture Names
final String s_leftSlide = "左方向へのスライドジェスチャ";
final String s_rightSlide = "右方向へのスライドジェスチャ";
final String s_upSlide = "上方向へのスライドジェスチャ";
final String s_downSlide = "下方向へのスライドジェスチャ";
final String s_leftWheel = "左方向へのホイールジェスチャ";
final String s_rightWheel = "右方向へのホイールジェスチャ";
final String s_touch = "タッチジェスチャ";

// Regular Strings
final String s_currentGesture = "現在検証中のジェスチャ：";
final String s_result = "回目の認識結果は";
final String s_complete = "の検証は終了します．";

// Stage 0
final String s_expStart = "それでは，ジェスチャ操作の認識精度検証実験を開始します．\n画面の指示に従って操作を実行してください．";
final String s_exchangeFirstSwitch = "最初にタッチ操作の認識を行います．\n実験者が貼り付けられているデバイスの交換を行います．";

// Stage 1 : Touch
final String s_1_start = "それでは，" + s_touch + "の検証を開始します．";
final String s_1_complete = s_touch + s_complete;

// Stage 2 : Left Slide
final String s_2_change = "次に左右方向のスライドジェスチャの検証を行います．\n実験者がデバイスの交換を行います．";
final String s_2_start = "それでは，はじめに" + s_leftSlide + "の検証を開始します．\n次の画面から右から左に向かってスライドジェスチャを行ってください．";
final String s_2_complete = s_leftSlide + s_complete;

// Stage 3 : Right Slide
final String s_3_start = "次に，" + s_rightSlide + "の検証を開始します．\n次の画面から左から右に向かってスライドジェスチャを行ってください．";
final String s_3_complete = s_rightSlide + s_complete;

// Stage 4 : Up Slide
final String s_4_change = "次に上下方向のスライドジェスチャの検証を行います．\n実験者がデバイスの交換を行います．";
final String s_4_start = "それでは，はじめに" + s_upSlide + "の検証を開始します．\n次の画面から下から上に向かってスライドジェスチャを行ってください．";
final String s_4_complete = s_upSlide + s_complete;

// Stage 5 : Down Slide
final String s_5_start = "次に，" + s_downSlide + "の検証を開始します．\n次の画面から上から下に向かってスライドジェスチャを行ってください．";
final String s_5_complete = s_downSlide + s_complete;

// Stage 6 : Left Wheel
final String s_6_change = "次にホイールジェスチャの検証を行います．\n実験者がデバイスの交換を行います．";
final String s_6_start = "それでは，はじめに" + s_leftWheel + "の検証を開始します．\n次の画面から反時計回りにホイールジェスチャを行ってください．";
final String s_6_rule = "但し，ホイールジェスチャは指が1回転したときを1回のホイールジェスチャとします．\n指が1回転した時点で指を離してください．";
final String s_6_complete = s_leftWheel + s_complete;

// Stage 7 : Right Wheel
final String s_7_start = "次に，" + s_rightWheel + "の検証を開始します．\n次の画面から時計回りにホイールジェスチャを行ってください．";
final String s_7_rule = "但し，ホイールジェスチャは指が1回転したときを1回のホイールジェスチャとします．\n指が1回転した時点で指を離してください．";
final String s_7_complete = s_rightWheel + s_complete;

// Stage 8
final String s_expEnd = "全てのジェスチャ操作の検証が完了しました．\n実験を終了します．";