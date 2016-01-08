/******************************************
        実験用アプリケーション
        2015 Seiya Iwasaki
******************************************/

/*
* 基本的にプログラムの自動認識によって実験を進行していく．
* 被験者によるジェスチャ操作完了が認識されない場合，実験者の判断で次のステップに ->キー で進める．
* 何らかのジェスチャが認識された場合は自動的に次に進む
* 検証中の布スイッチを変更するときは，実験者によって布スイッチを貼り替え，ENTERキー で次に進める．
*
* PCの充電状態によって得られる静電容量が不安定になるときがある．
* DEBUGモードをtrueにして，静電容量の変化を充電しているときとしていないときで確認し，安定する状態を選択する．
*/

import processing.serial.*;
import ddf.minim.*;
import ddf.minim.effects.*;
import java.awt.Rectangle;
import java.awt.Point;
import java.util.Arrays;

Serial port;
/*
* 構成位置の数は Arduino 側のプログラムと
* Processing 側のプログラムで一致させる必要がある
*/
final int fps = 30;
final int position_qty = 1;                                     // 構成位置の数（着脱位置の数）
long capVal[][] = new long[position_qty][4];                    // 静電容量の測定値
OperationDetect opeDet[] = new OperationDetect[position_qty];   // 操作検出クラス


// 実験用
boolean available = false;
int time = 7;
int stage = -1;        // -1 is start stage
int iCounter = 0;
int gestureCounter = 0;
int fCounter = 0;
int aCounter = 0;
String cGesture;
String actGes;
int[][] result = new int[7][7];
PrintWriter writer;


// DEBUG
final boolean DEBUG = false;
int count = 0;
int operationID = 0;
final String operationName[] = new String[]{"Nothing", "Touch", "LeftRight Slide", "UpDown Slide", "Wheel"};


void setup(){
    /*--- Arduino 設定 ---*/

    // シリアルポートの設定
    printArray(Serial.list());                 // シリアルポート一覧
    String portName = Serial.list()[0];        // Arduinoと接続しているシリアルを選択
    port = new Serial(this, portName, 9600);  


    /*--- 操作検出クラス初期化 & リスナー登録 ---*/
    for(int i = 0; i < position_qty; i++){
        // 引数：<電極に指が触れているしきい値>, <2つの電極に同時に触れている際のそれらの測定値の最大差分>, <フレームレート>
        opeDet[i] = new OperationDetect(70, 15, fps);
    }
    setListeners();


    /*--- アプリケーション設定 ---*/

    // 画面設定
    size(displayWidth, displayHeight);
    noStroke();
    smooth();
    frameRate(fps);
    imageMode(CENTER);
    ellipseMode(CENTER);
    colorMode(RGB, 256, 256, 256, 256);
    
    PFont myf = createFont("メイリオ", 48, true);
    textFont(myf);


   // ファイル書き込み
   writer = createWriter("gestureResult.txt");
}


void draw(){
    background(#ffffff);

    textSize(24);
    textAlign(LEFT);
    fill(#3c3c3c);

    if(stage != -1 && stage != 0 && stage != 8){
        text(s_currentGesture + actGes, 20, 50);
    }

    textSize(28);
    textAlign(CENTER);

    switch(stage){
        case -1:
            text("ENTERで実験を開始します．", width / 2, height /2);
            if(key == ENTER){
                stage = 0;
                key = 0;
            }
            break;
        case 0:
            if(fCounter <= fps * time){
                text(s_expStart, width / 2, height / 2);
            }else if(fCounter > fps * time){
                text(s_exchangeFirstSwitch, width / 2, height / 2);
                if(key == ENTER){
                    stage++;
                    fCounter = 0;
                    key = 0;
                    break;
                }
            }
                fCounter++;
            break;
        case 1:
            actGes = s_touch;
            if(0 <= fCounter && fCounter <= fps * time){
                text(s_1_start, width / 2, height / 2);
            if(key == ENTER){
                key = 0;
                fCounter = fps * time + 1;
            }
            }else if(fCounter > fps * time){
                text(str(aCounter + 1) + "回目の" + s_touch + "を実行してください．", width / 2, height / 2);
                fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * time;
                    else if(fCounter == -1 && aCounter == 10){
                        stage = 12;
                        aCounter = 0;
                        fCounter = 0;
                        key = 0;
                        break;
                    }
                    fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_touch + "を実行してください．", width / 2, height / 2);
                }
            }
            break;
        case 12:
            text(s_2_change, width / 2, height / 2);
            if(key == ENTER){
                stage = 2;
                key = 0;
            }
            break;
        case 2:
            actGes = s_leftSlide;
            if(0 <= fCounter && fCounter <= fps * (time + 6)){
                text(s_2_start, width / 2, height / 2);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 6) + 1;
            }
            }else if(fCounter > fps * (time + 6)){
                text(str(aCounter + 1) + "回目の" + s_leftSlide + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 6);
                    else if(fCounter == -1 && aCounter == 10){
                        stage++;
                        aCounter = 0;
                        fCounter = 0;
                        break;
                    }
                    fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_leftSlide + "を実行してください．", width / 2, height / 2);   
                }
            }
            break;
        case 3:
            actGes = s_rightSlide;
            if(0 <= fCounter && fCounter <= fps * (time + 6)){
                text(s_3_start, width / 2, height / 2);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 6) + 1;
            }
            }else if(fCounter > fps * (time + 6)){
                text(str(aCounter + 1) + "回目の" + s_rightSlide + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 6);
                    else if(fCounter == -1 && aCounter == 10){
                        stage = 14;
                        aCounter = 0;
                        fCounter = 0;
                            key = 0;
                        break;
                    }
                fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_rightSlide + "を実行してください．", width / 2, height / 2); 
                }
            }
            break;
        case 14:
            text(s_4_change, width / 2, height / 2);
            if(key == ENTER){
                stage = 4;
                key = 0;
            }
            break;
        case 4:
            actGes = s_upSlide;
            if(0 <= fCounter && fCounter <= fps * (time + 6)){
                text(s_4_start, width / 2, height / 2);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 6) + 1;
            }
            }else if(fCounter > fps * (time + 6)){
                text(str(aCounter + 1) + "回目の" + s_upSlide + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 6);
                    else if(fCounter == -1 && aCounter == 10){
                        stage++;
                        aCounter = 0;
                        fCounter = 0;
                        break;
                    }
                fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_upSlide + "を実行してください．", width / 2, height / 2); 
                }
            }
            break;
        case 5:
            actGes = s_downSlide;
            if(0 <= fCounter && fCounter <= fps * (time + 6)){
                text(s_5_start, width / 2, height / 2);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 6) + 1;
            }
            }else if(fCounter > fps * (time + 6)){
                text(str(aCounter + 1) + "回目の" + s_downSlide + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 6);
                    else if(fCounter == -1 && aCounter == 10){
                        stage = 16;
                        aCounter = 0;
                        fCounter = 0;
                            key = 0;
                        break;
                    }
                fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_downSlide + "を実行してください．", width / 2, height / 2); 
                }
            }
            break;
        case 16:
            text(s_6_change, width / 2, height / 2);
            if(key == ENTER){
                stage = 6;
                key = 0;    
            }
            break;
        case 6:
            actGes = s_leftWheel;
            if(0 <= fCounter && fCounter <= fps * (time + 13)){
                text(s_6_start, width / 2, height / 2 - 35);
                fill(#cc2222);
                text(s_6_rule, width / 2, height / 2 + 70);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 13) + 1;
            }
            }else if(fCounter > fps * (time + 13)){
                text(str(aCounter + 1) + "回目の" + s_leftWheel + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 13);
                    else if(fCounter == -1 && aCounter == 10){
                        stage++;
                        aCounter = 0;
                        fCounter = 0;
                        break;
                    }
                fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_leftWheel + "を実行してください．", width / 2, height / 2); 
                }
            }
            break;
        case 7:
            actGes = s_rightWheel;
            if(0 <= fCounter && fCounter <= fps * (time + 10)){
                text(s_7_start, width / 2, height / 2 - 35);
                fill(#cc2222);
                text(s_7_rule, width / 2, height / 2 + 70);
            if(key == ENTER){
                key = 0;
                fCounter = fps * (time + 10) + 1;
            }
            }else if(fCounter > fps * (time + 10)){
                text(str(aCounter + 1) + "回目の" + s_rightWheel + "を実行してください．", width / 2, height / 2);
            fCounter++;
            }else if(fCounter < 0){
                if(available == true){
                    text(str(aCounter) + s_result, width / 2, height / 2 - 30);
                    fill(#992222);
                    text(cGesture + "でした．", width / 2, height / 2 + 30);
                    if(fCounter == -1 && aCounter != 10) fCounter = fps * (time + 10);
                    else if(fCounter == -1 && aCounter == 10){
                        stage++;
                        aCounter = 0;
                        fCounter = 0;
                        break;
                    }
                fCounter++;
                }else{
                    text(str(aCounter) + "回目の" + s_rightWheel + "を実行してください．", width / 2, height / 2); 
                }
            }
            break;
        case 8:
            if(0 <= fCounter && fCounter <= fps * time){
                text(s_expEnd, width / 2, height / 2);
            }else{
                saveResult();
            }
            fCounter++;
            break;
    }
        
    
    if(DEBUG){
        textSize(64);
        textAlign(CENTER);
        fill(#2c2c2c);
        text(operationName[opeDet[0].getOperationID() + 1], width / 2, height / 2);
        text(int(capVal[0][0] + capVal[0][1] + capVal[0][2] + capVal[0][3]), width / 2, height / 2 + 60);

        textSize(18);
        text(count, 40, 40);

        float size[] = new float[4];
        size[0] = map(opeDet[0].getCapValue()[0], 0, 300, 0, 200);
        size[1] = map(opeDet[0].getCapValue()[1], 0, 300, 0, 200);
        size[2] = map(opeDet[0].getCapValue()[2], 0, 300, 0, 200);
        size[3] = map(opeDet[0].getCapValue()[3], 0, 300, 0, 200);
        fill(#ff5555);
        ellipse(width / 3, height / 3, size[0], size[0]);
        fill(#55ff55);
        ellipse(width / 3 * 2, height / 3, size[1], size[1]);
        fill(#5555ff);
        ellipse(width / 3, height / 3 * 2, size[2], size[2]);
        fill(#bbbbbb);
        ellipse(width / 3 * 2, height / 3 * 2, size[3], size[3]);

        fill(#2c2c2c);
        text(opeDet[0].getCapValue()[0], width / 3, height / 3);
        text(opeDet[0].getCapValue()[1], width / 3 * 2, height / 3);
        text(opeDet[0].getCapValue()[2], width / 3, height / 3 * 2);
        text(opeDet[0].getCapValue()[3], width / 3 * 2, height / 3 * 2);


        textAlign(LEFT);
        fill(#2cee2c);
        text("fps = " + (int)frameRate, width - 100, 40);
    }

}

void saveResult(){
    for(int i = 0; i < result.length; i++){
        for(int j = 0; j < result[i].length; j++){
            writer.print(str(result[i][j]) + ",");
        }
        writer.println();
    }
    writer.flush();
    writer.close();
    exit();
}

void keyReleased(){
    // 被験者による操作が完了しても何も認識されない場合（画面変化がない場合），実験者の判断で次に進める
    if(keyCode == RIGHT && 1 <= stage && stage <= 7){
        aCounter++;
        fCounter = -1 * fps * 3;
        cGesture = "何も認識されません";
    }
    key = 0;
    keyCode = 0;
}


/*-- 静電容量の測定値を入力し，ユーザのアクションを検出 --*/
void detectAction(){
    for(int i = 0; i < position_qty; i++){
        opeDet[i].inputCapValue(capVal[i]);
    }
    // 各構成位置のアクションを検出
    for(int i = 0; i < position_qty; i++){
        opeDet[i].operationDetect();
    }
}


/*-- シリアル通信 --*/
void serialEvent(Serial p){
    // 改行区切りでデータを読み込む (¥n == 10)
    String inString = p.readStringUntil(10);
    try{
        // カンマ区切りのデータの文字列をパースして数値として読み込む
        if(inString != null){
            inString = trim(inString);
            int[] value = int(split(inString, ','));
            if(value.length >= position_qty * 4){
                for(int i = 0; i < position_qty; i++){
                    capVal[i][0] = value[i * 4];
                    capVal[i][1] = value[i * 4 + 1];
                    capVal[i][2] = value[i * 4 + 2];
                    capVal[i][3] = value[i * 4 + 3];
                }
            }
        }
    }catch(Exception e){
        e.printStackTrace();
    }
    detectAction();
}


/*-- リスナー登録（匿名クラス） --*/
void setListeners(){
    // 構成位置 No.1
    if(position_qty > 0){
        opeDet[0].setOnActionListener(new OnActionListener(){
            @Override // タッチ
            public void onTouch(int direction){
                if(1 <= stage && stage <= 7 && available){
                    result[stage - 1][0]++;
                    aCounter++;
                    fCounter = -1 * fps * 3;
                    cGesture = s_touch;
                }
                available = false;
                iCounter = 0;
            }

            @Override // 左右スライド
            public void onLRSwipe(int direction){
                if(1 <= stage && stage <= 7 && available){
                    if(direction == -1){
                        result[stage - 1][1]++;
                        cGesture = s_leftSlide;
                    }else if(direction == 1){
                        result[stage - 1][2]++;
                        cGesture = s_rightSlide;
                    }
                    aCounter++;
                    fCounter = -1 * fps * 3;
                }
                available = false;
                iCounter = 0;
            }

            @Override // 上下スライド
            public void onUDSwipe(int direction){
                if(1 <= stage && stage <= 7 && available){
                    if(direction == 1){
                        result[stage - 1][3]++;
                        cGesture = s_upSlide;
                    }else if(direction == -1){
                        result[stage - 1][4]++;
                        cGesture = s_downSlide;
                    }
                    aCounter++;
                    fCounter = -1 * fps * 3;
                }
                available = false;
                iCounter = 0;
            }

            @Override // ホイール
            public void onWheel(int direction){
                println("available = " + str(available));
                println("iCounter = " + str(iCounter));
                if(1 <= stage && stage <= 7 && available){
                    if(direction == -1){
                        result[stage - 1][5]++;
                        cGesture = s_leftWheel;
                    }else if(direction == 1){
                        result[stage - 1][6]++;
                        cGesture = s_rightWheel;
                    }
                    aCounter++;
                    fCounter = -1 * fps * 3;
                }
                available = false;
                iCounter = 0;
            }
            
            @Override // 手が触れてない
            public void onNothing(){
                iCounter++;
                switch(stage){
                    case 1:
                        if(iCounter > fps * 2){
                            available = true;  
                            iCounter = 0;
                        }
                        break;
                    case 2:
                    case 3:
                    case 4:
                    case 5:
                        if(iCounter > fps * 5){
                            available = true;  
                            iCounter = 0;
                        }
                        break;
                    case 6:
                    case 7:
                        if(iCounter > fps * 10){
                            available = true;  
                            iCounter = 0;
                        }
                        break;
                }
            }
        });
    }
}