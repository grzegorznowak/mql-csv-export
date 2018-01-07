//+------------------------------------------------------------------+
//|                                             OHCLT train data.mq4 |
//|                                                   Grzegorz Nowak |
//| I wil export OHCL and Time (date and hh::mm) values normalized   |
//| according to be used in NN training                              |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Nowak"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

const int EVAL_RANGE = 1; // for the purpose of RNN network we start playing around one tick per one NN evolution

//extern int PROFIT_THRESHOLD = 50;
//extern int LOSS_THRESHOLD   = 10;
extern int PROFIT_MARGIN    = 0; // by how much to adjust take profit
extern int LOSS_MARGIN    = 0; // by how much to adjust take profit

extern int OpenHour = 08;
extern int OpenMin = 30;
extern int CloseHour = 17;
extern int CloseMin = 30;


int file_handle = FileOpen(StringConcatenate("mt4_",Symbol(),"_", Period(),"_range_", EVAL_RANGE, "_OHCLT_train_data.csv"),FILE_READ|FILE_WRITE|FILE_CSV);
int barsTotal   = 0;

int start() {
   
   return (0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
     //  string data = getCSVHeader(Symbol(), Period(), EVAL_RANGE);
       
       
    //  FileWrite(file_handle, data);
       
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


string getCSVHeader( string sym, int period, int range) {

   string result = "";
 
   for(int i = range; i>=1; i--){
      result = StringConcatenate(result, "H_", i, ",");
      result = StringConcatenate(result, "L_", i, ",");
      result = StringConcatenate(result, "C_", i, ",");
   }
   
   result = StringConcatenate(result, "O");
   
   return result;
}


long pipize(double value) {
   return MathRound(MathPow(10, Digits) * value);
}

/**
* We squeeze the data into values [-1,1]
* Extremes will be flattened in logharitmic fashion with a cutoff at 2.5 (taken value's log10)
*/
double normalize(double value) {
   long pipized = pipize(value);
   double ret   = 0;
   if(pipized > 0) {
      ret = MathLog10(pipized) / 2.5;
   } else if(pipized < 0) {
      ret = MathLog10(MathAbs(pipized)) / -2.5;
   }
   
   if(ret > 1) {
      return 1;
   } else if(ret < -1) {
      return -1;
   } else {
      return ret;
   }   
}

string getDataRow(string sym, int period, int range) {
   string result   = "";
   datetime t      = Time[1];
   double day_norm = TimeDayOfWeek(t) / 6.0;
   int hour        = TimeHour(t);
   int minute      = TimeMinute(t);
   
   // OHCL data comes first
   for(int i = range-1; i>=0; i--){
      result = StringConcatenate(result, DoubleToStr(normalize(iHigh(sym, period, i+1)  - iHigh(sym, period, i+2)) , 7), ",");
      result = StringConcatenate(result, DoubleToStr(normalize(iLow(sym, period, i+1)   - iLow(sym, period, i+2))  , 7), ",");
      result = StringConcatenate(result, DoubleToStr(normalize(iClose(sym, period, i+1) - iClose(sym, period, i+2)), 7), ",");
   }   
   
   // now normalized datetime columns
   double decimal_time_normalized = (hour + (60 * minute) / 3600.0) / 24.0;
   result = StringConcatenate(DoubleToStr(day_norm, 3), ",",DoubleToStr(decimal_time_normalized, 7));

   return result;
} 

void OnTick() {
   if(Bars > barsTotal){
      barsTotal      = Bars;
      string dataRow = getDataRow(Symbol(), Period(), EVAL_RANGE);
      FileWrite(file_handle, dataRow);
   }  
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
