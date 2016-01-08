/******************************************
        Reconfigurable Interaction
        No.2
        2015 Seiya Iwasaki
******************************************/


/*
* アクションパターン一覧（電極：A, B, C, D)
*
* [基本パターン]
*   なし = 0
*   A = 1
*   B = 2
*   C = 3
*   D = 4
* [派生パターン]
*   E = A(1) and B(2) = 5
*   F = A(1) and C(3) = 6
*   G = A(1) and D(4) = 7
*   H = B(2) and C(3) = 8
*   I = B(2) and D(4) = 9
*   J = C(3) and D(4) = 10
*   K = A(1) and B(2) and C(3) = 11
*   L = A(1) and B(2) and D(4) = 12
*   M = B(2) and C(3) and D(4) = 13
*   N = A(1) and B(2) and C(3) and D = 14
*/

/*-- Interface --*/
public static interface OnActionListener{
    public void onTouch(int direction);
    public void onLRSwipe(int direction);
    public void onUDSwipe(int direction);
    public void onWheel(int direction);
}

class OperationDetect implements OnActionListener{
    /*-- Interface --*/
    private OnActionListener listener;
    public void setOnActionListener(OnActionListener listener){
        this.listener = listener;
    }

    /*-- Field --*/
    private int fps;                                                    // フレームレート
    private int wheelInterval;                                          // ホイール操作が連続して入力されているときの受付間隔
    private int threshold;                                              // 電極に指が触れているかどうかのしきい値
    private int thDouble;                                               // ２つの電極に同時に触れた際のそれらの測定値の最大差分
    private int capVal[] = new int[]{0, 0, 0, 0};                       // それぞれ電極A, B, C, Dから得られる静電容量の測定値
    private int historyResetTimer;                                      // アクションがないとき，ユーザアクション履歴を一定時間ごとにリセットする
    private int resetCounter = 0, pushCounter = 0, iCounter = 0;        // フレームカウンター
    private int swipeFactor = 0;                                        // ホイール操作中のスワイプ誤認識を防止
    private int userActionHistory[] = new int[]{0, 0, 0, 0, 0, 0, 0, 0};
    private boolean userOperation[] = new boolean[]{false, false, false, false};
    private int operateDirection[] = new int[]{0, 0, 0, 0};
    
    private final boolean DEBUG = false;

    // アクションパターン識別用配列
    private int ap_double[][] = new int[][]{
        {1, 2},
        {1, 3},
        {1, 4},
        {2, 3},
        {2, 4},
        {3, 4},
        {2, 1},
        {3, 1},
        {4, 1},
        {3, 2},
        {4, 2},
        {4, 3}
    };

    // タッチ操作の操作パターン
    private int ap_touch = 14;
    // 左右方向のスライド操作の操作パターン（前半：正, 後半：負）
    private int ap_lrSwipe[][] = new int[][]{
        {2, 1, 3},
        {2, 4, 3},
        {3, 1, 2},
        {3, 4, 2}
    };
    // 上下方向のスライド操作の操作パターン（前半：正, 後半：負）
    private int ap_udSwipe[][] = new int[][]{
        {4, 2, 1},
        {4, 3, 1},
        {1, 2, 4},
        {1, 3, 4}
    };
    // ホイール操作の操作パターン（前半：正, 後半：負）
    private int ap_wheel[][] = new int[][]{
        {5, 3, 4},
        {3, 4, 5},
        {4, 5, 3},
        {10, 2, 1},
        {2, 1, 10},
        {1, 10, 2},
        {4, 3, 5},
        {3, 5, 4},
        {5, 4, 3},
        {1, 2, 10},
        {2, 10, 1},
        {10, 1, 2}
    };


    /*-- Constractor --*/
    OperationDetect(int th, int thD, int fps){
        threshold = th;
        thDouble = thD;
        this.fps = fps;
        historyResetTimer = fps * 2;
        wheelInterval = fps / 2;
    }


    /*-- Callback Method --*/
    public void onTouch(int direction){
        if(userActionHistory[userActionHistory.length - 1] != userActionHistory[userActionHistory.length - 2]){
            if(millis() - swipeFactor > 1000){
               listener.onTouch(direction);
               
               if(DEBUG){
                   println("touch detection");
               }
            }
        }
    }
    public void onLRSwipe(int direction){
        if(millis() - swipeFactor > 2000){
            listener.onLRSwipe(direction);
            
            if(DEBUG){
                println("Left Right Swipe detection");
                print("direction:");
                println(getOperateDirection());
            }
        }
    }
    public void onUDSwipe(int direction){
        if(millis() - swipeFactor > 2000){
            listener.onUDSwipe(direction);

            if(DEBUG){
                println("Up Down Swipe detection");
                print("direction:");
                println(getOperateDirection());
            }
        }
    }
    public void onWheel(int direction){
        if(iCounter > wheelInterval){
            listener.onWheel(direction);
            iCounter = 0;
        }else{
            iCounter++;
        }
        
        if(DEBUG){
            println("wheel detection");
            print("direction:");
            println(getOperateDirection());
        }
    }


    /*-- Method --*/

    /** 操作を検出して操作IDを返す **/
    public void operationDetect(){
        // 操作状態配列の初期化
        for(int i = 0; i < userOperation.length; i++){
            userOperation[i] = false;
        }

        // しきい値を基準に電極に指が触れているか確認する
        long cvSum = capVal[0] + capVal[1] + capVal[2] + capVal[3];
        if(cvSum >= threshold){
            actionDetect();
            if(wheelDetect()){
                swipeFactor = millis();
                onWheel(getOperateDirection());
                return;
            }else if(lrSwipeDetect()){
                resetActionHistory();
                onLRSwipe(getOperateDirection());
                return;
            }else if(udSwipeDetect()){
                resetActionHistory();
                onUDSwipe(getOperateDirection());
                return;
            }else if(touchDetect()){
                onTouch(getOperateDirection());
                return;
            }
        }else{
            resetCounter++;
            if(historyResetTimer == resetCounter){
                resetCounter = 0;
                for(int i = 0; i < userActionHistory.length; i++){
                    updateActionHistory(0);
                }
                // DEBUG
                if(DEBUG){
                    println(userActionHistory[0] + ", " + 
                            userActionHistory[1] + ", " + 
                            userActionHistory[2] + ", " + 
                            userActionHistory[3] + ", " + 
                            userActionHistory[4] + ", " + 
                            userActionHistory[5] + ", " + 
                            userActionHistory[6] + ", " + 
                            userActionHistory[7]);
                }
            }
        }
    }


    /** タッチ操作の識別 **/
    private boolean touchDetect(){
        int userAction = userActionHistory[userActionHistory.length - 1];
        if(userAction == ap_touch){
            userOperation[0] = true;
            operateDirection[0] = 1;
            return true;
        }
        return false;
    }


    /** 左右スライド操作の識別 **/
    private boolean lrSwipeDetect(){
        // アクション履歴全体の中にアクションパターンで定義した反応電極の流れが存在するか確認
        // ※要ネスト改善
        int actionCounter[] = new int[ap_lrSwipe.length];
        for(int i = 0; i < actionCounter.length; i++){
            actionCounter[i] = 0;
        }
        for(int i = 0; i < userActionHistory.length; i++){
            for(int j = 0; j < ap_lrSwipe.length; j++){
                if(userActionHistory[i] == ap_lrSwipe[j][actionCounter[j]]){
                    actionCounter[j]++;
                    if(actionCounter[j] == ap_lrSwipe[j].length){
                        userOperation[1] = true;
                        if(j < ap_lrSwipe.length / 2) operateDirection[1] = 1;
                        else operateDirection[1] = -1;
                        return true;
                    }
                }
            }
        }
        return false;
        
        //int userAction[] = new int[]{
        //    userActionHistory[userActionHistory.length - 3],
        //    userActionHistory[userActionHistory.length - 2],
        //    userActionHistory[userActionHistory.length - 1]
        //};
        //for(int i = 0; i < ap_lrSwipe.length; i++){
        //    if(Arrays.equals(userAction, ap_lrSwipe[i])){
        //        userOperation[1] = true;
        //        if(i < ap_lrSwipe.length / 2) operateDirection[1] = 1;
        //        else operateDirection[1] = -1;
        //        return true;
        //    }
        //}
        //return false;
    }


    /** 上下スライド操作の識別 **/
    private boolean udSwipeDetect(){
        // アクション履歴全体の中にアクションパターンで定義した反応電極の流れが存在するか確認
        // ※要ネスト改善
        int actionCounter[] = new int[ap_udSwipe.length];
        for(int i = 0; i < actionCounter.length; i++){
            actionCounter[i] = 0;
        }
        for(int i = 0; i < userActionHistory.length; i++){
            for(int j = 0; j < ap_udSwipe.length; j++){
                if(userActionHistory[i] == ap_udSwipe[j][actionCounter[j]]){
                    actionCounter[j]++;
                    if(actionCounter[j] == ap_udSwipe[j].length){
                        userOperation[2] = true;
                        if(j < ap_udSwipe.length / 2) operateDirection[2] = 1;
                        else operateDirection[2] = -1;
                        return true;
                    }
                }
            }
        }
        return false;
        
        //int userAction[] = new int[]{
        //    userActionHistory[userActionHistory.length - 3],
        //    userActionHistory[userActionHistory.length - 2],
        //    userActionHistory[userActionHistory.length - 1]
        //};
        //for(int i = 0; i < ap_udSwipe.length; i++){
        //    if(Arrays.equals(userAction, ap_udSwipe[i])){
        //        userOperation[2] = true;
        //        if(i < ap_udSwipe.length / 2) operateDirection[2] = 1;
        //        else operateDirection[2] = -1;
        //        return true;
        //    }
        //}
        //return false;
    }


    /** ホイール操作の識別 **/
    private boolean wheelDetect(){
        // アクション履歴全体の中にアクションパターンで定義した反応電極の流れが存在するか確認
        // ※要ネスト改善
        int actionCounter[] = new int[ap_wheel.length];
        for(int i = 0; i < actionCounter.length; i++){
            actionCounter[i] = 0;
        }
        for(int i = 0; i < userActionHistory.length; i++){
            for(int j = 0; j < ap_wheel.length; j++){
                if(userActionHistory[i] == ap_wheel[j][actionCounter[j]]){
                    actionCounter[j]++;
                    if(actionCounter[j] == ap_wheel[j].length){
                        userOperation[3] = true;
                        if(j < ap_wheel.length / 2) operateDirection[3] = 1;
                        else operateDirection[3] = -1;
                        return true;
                    }
                }
            }
        }
        return false;
    }


    /** ユーザのアクションを識別 **/
    private void actionDetect(){
        /*
        * 得られた静電容量の測定値の関係性をしきい値を基準に判定し，履歴に蓄える
        * アクションパターンの認識順序は変更不可
        */

        int sortVal[] = reverse(sort(capVal));
        int avg = (capVal[0] + capVal[1] + capVal[2] + capVal[3]) / 4;

        // 4つの電極に同時に触れている場合
        short count = 0;
        for(int i = 0; i < capVal.length; i++){
            if(abs(avg - capVal[i]) < thDouble * 0.3){
                count++;
            }
        }
        if(count == capVal.length){
            updateActionHistory(14);
            return;
        }
        
        // 3つの電極に同時に触れている場合
        //count = 0;
        //for(int i = 0; i < capVal.length; i++){
        //    if(abs(avg - capVal[i]) < thDouble * 0.75){
        //        count++;
        //    }
        //}
        //if(count == capVal.length - 1){
        //    return;
        //}

        // 2つの電極に同時に触れている場合
        if(sortVal[0] - sortVal[1] <= (sortVal[1] - sortVal[2]) * 1.1){
            int index[] = new int[2];
            for(int i = 0; i < capVal.length; i++){
                if(capVal[i] == sortVal[0]){
                    index[0] = i + 1;
                }else if(capVal[i] == sortVal[1]){
                    index[1] = i + 1;
                }
            }
            for(int i = 0; i < ap_double.length; i++){
                if(Arrays.equals(index, ap_double[i])){
                    updateActionHistory((i % 6) + 5);
                    return;
                }
            }
        }
        
        // 1つの電極のみに触れている場合
        for(int i = 0; i < capVal.length; i++){
            if(capVal[i] == sortVal[0]){
                updateActionHistory(i + 1);
                return;
            }
        }
    }


    /** 静電容量の測定値を得る **/
    public void inputCapValue(long val[]){
        capVal[0] = (int)val[0];
        capVal[1] = (int)val[1];
        capVal[2] = (int)val[2];
        capVal[3] = (int)val[3];
    }


    /** 現在の測定値を返す **/
    public int[] getCapValue(){
            return capVal;   
    }


    /** アクション履歴の更新 **/
    private void updateActionHistory(int id){
        if(userActionHistory[userActionHistory.length - 1] != id || pushCounter > fps){
            // タッチ操作時のノイズ補正
            if(userActionHistory[userActionHistory.length - 1] == 14 && id != 0){
                id = 14;
            }
            // 古いアクション履歴の削除して末尾に追加
            for(int i = 0; i < userActionHistory.length - 1; i++){
                userActionHistory[i] = userActionHistory[i + 1];
            }
            userActionHistory[userActionHistory.length - 1] = id;
            pushCounter = 0;
        }else{
            pushCounter++;
            // ロングタッチ補正
            if(userActionHistory[userActionHistory.length - 1] == 14 && id == 14){
                userActionHistory[userActionHistory.length - 2] = 14;    
            }
        }
        // DEBUG
        if(DEBUG){
            println(userActionHistory[0] + ", " + 
                    userActionHistory[1] + ", " + 
                    userActionHistory[2] + ", " + 
                    userActionHistory[3] + ", " + 
                    userActionHistory[4] + ", " + 
                    userActionHistory[5] + ", " + 
                    userActionHistory[6] + ", " + 
                    userActionHistory[7]);
        }    
    }
    private void resetActionHistory(){
        for(int i = 0; i < userActionHistory.length; i++){
            userActionHistory[i] = 0;   
        }
    }


    /** 操作の種類を返す **/
    public int getOperationID(){
        // 0:タッチ, 1:左右スライド, 2:上下スライド, 3:ホイール, -1:操作なし
        for(int i = 0; i < userOperation.length; i++){
            if(userOperation[i]) return i;
        }
        return -1;

    }

    /** 操作の方向を返す **/
    public int getOperateDirection(){
        if(getOperationID() == -1) return 0;
        return operateDirection[getOperationID()];
    }
}