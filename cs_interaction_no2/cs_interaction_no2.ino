/******************************************
	実験用 Arduino プログラム
	2015 Seiya Iwasaki
******************************************/

#include <CapacitiveSensor.h>		// 静電容量センサライブラリ

#define SAMPLING 10					// 静電容量をセンシングする際のサンプリング数
#define BUFFER_LENGTH 1             // バッファサイズ（サイズが大きいとラグる）

/*
* 構成位置の数は Arduino 側のプログラムと
* Processing 側のプログラムで一致させる必要がある
*
* ＜静電容量の測定の際の注意＞
* 片手でPCに触れながらもう片方の手で布スイッチを操作しても正しく静電容量が得られない
*/
const int position_qty = 1;         			// 構成位置の数（着脱位置の数）
long capVal[position_qty][4];		         	// 静電容量の測定値
CapacitiveSensor *sensor[position_qty][4];	    // 静電容量センサオブジェクト
long capBuffer[position_qty][4][BUFFER_LENGTH]; // 静電容量の測定値を均すためのバッファ
int index = 0;


void setup(){
	// 静電容量センサの初期化
    sensor[0][0] = new CapacitiveSensor(43, 41);
    sensor[0][1] = new CapacitiveSensor(43, 39);
    sensor[0][2] = new CapacitiveSensor(43, 37);
    sensor[0][3] = new CapacitiveSensor(43, 35);
    sensor[0][0]->set_CS_AutocaL_Millis(0xFFFFFFFF);
    sensor[0][1]->set_CS_AutocaL_Millis(0xFFFFFFFF);
    sensor[0][2]->set_CS_AutocaL_Millis(0xFFFFFFFF);
    sensor[0][3]->set_CS_AutocaL_Millis(0xFFFFFFFF);
    sensor[0][0]->reset_CS_AutoCal();
    sensor[0][1]->reset_CS_AutoCal();
    sensor[0][2]->reset_CS_AutoCal();
    sensor[0][3]->reset_CS_AutoCal();

	// 配列の初期化
	for(int i = 0; i < position_qty; i++){
		for(int j = 0; j < 4; j++){
			capVal[i][j] = 0;
		}
	}

	// シリアル通信
	Serial.begin(9600);
}

void loop(){
	// 静電容量の測定
	for(int i = 0; i < position_qty; i++){
		for(int j = 0; j < 4; j++){
			capVal[i][j] = sensor[i][j]->capacitiveSensor(SAMPLING);
			delay(10);
		}
	}

    // 静電容量の測定値をバッファに溜める
	for(int i = 0; i < position_qty; i++){
		for(int j = 0; j < 4; j++){
			capBuffer[i][j][index] = capVal[i][j];
		}
	}
    index = (index + 1) % BUFFER_LENGTH;

	// 測定値をシリアル通信で送信
	for(int i = 0; i < position_qty; i++){
    	for(int j = 0; j < 4; j++){
    		Serial.print(smoothByMeanFilter(capBuffer[i][j]));
    		Serial.print(',');
    	}
    }
	Serial.println();
}

// 平均化
long smoothByMeanFilter(long *box){
    int sum = 0;
    for(int i = 0; i < BUFFER_LENGTH; i++){
        sum += box[i];
    }
    return (int)(sum / BUFFER_LENGTH);
}
