/******************************************
        事前練習用アプリケーション
        2015 Seiya Iwasaki
******************************************/

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


// アプリケーション：「パズル合わせ」
AppPuzzle appPuzzle;

// DEBUG
final boolean DEBUG = false;
int count = 0;
int operationID = 0;
final String operationName[] = new String[]{"Nothing", "Touch", "LeftRight Slide", "UpDown Slide", "Wheel"};
int start = 0;


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

    /*--- 各アプリケーションクラスの初期化 ---*/
    appPuzzle = new AppPuzzle(fps);


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
}


void draw(){
    background(#ffffff);

    // 各アプリケーションの描画
    appPuzzle.draw();
    textSize(24);
    textAlign(CENTER);
    fill(#3c3c3c);
    text("Puzzle Game", width / 2, 100);
    
    // 操作説明
    textSize(18);
    textAlign(LEFT);
    text("操作説明\n", 20, 40);
    text("左右スライド：図形の色を変更", 20, 60);
    text("上下スライド：図形の角数を変更", 20, 80);
    text("ホイール操作：図形の角度を変更", 20, 100);
    text("タッチ操作：図形の決定（判定結果が表示されます）", 20, 120);
    text("\nこれらの操作を用いて，図形を target で示される\n図形と一致するように変更します．", 20, 140);
    
    if(DEBUG){
        textSize(64);
        textAlign(CENTER);
        fill(#2c2c2c);
        text(operationName[operationID], width / 2, height / 2);
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


/*-- 静電容量の測定値を入力し，ユーザのアクションを検出 --*/
void detectAction(){
    for(int i = 0; i < position_qty; i++){
        opeDet[i].inputCapValue(capVal[i]);
    }
    // 各構成位置のアクションを検出
    for(int i = 0; i < position_qty; i++){
        opeDet[i].operationDetect();
    }
    println(millis() - start);
    start = millis();
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
                if(!appPuzzle.playingAnimation()){
                    println("Checking Puzzle");
                    appPuzzle.checkPuzzle();
                }

                // DEBUG
                if(DEBUG){
                    operationID = 1;
                    if(direction >= 0) count++;
                    else count--;
                }
            }

            @Override // 左右スライド
            public void onLRSwipe(int direction){
                if(!appPuzzle.playingAnimation()){
                    appPuzzle.changeColor(direction);
                    appPuzzle.playAnimation(1, direction);
                }

                // DEBUG
                if(DEBUG){
                    operationID = 2;
                    if(direction >= 0) count++;
                    else count--;
                }
            }

            @Override // 上下スライド
            public void onUDSwipe(int direction){
                if(!appPuzzle.playingAnimation()){
                    appPuzzle.changeVertex(direction);
                    appPuzzle.playAnimation(2, direction);
                }

                // DEBUG
                if(DEBUG){
                    operationID = 3;
                    if(direction >= 0) count++;
                    else count--;
                }
            }

            @Override // ホイール
            public void onWheel(int direction){
                if(!appPuzzle.playingAnimation()){
                    appPuzzle.changeAngle(direction);
                }
                
                // DEBUG
                if(DEBUG){
                    operationID = 4;
                    if(direction >= 0) count++;
                    else count--;
                }
            }
        });
    }
}

void stop(){
    super.stop();
}