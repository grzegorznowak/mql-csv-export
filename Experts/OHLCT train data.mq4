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

extern bool do_normalize    = true;
extern bool attach_datetime = true;

// dont maybe export data for low liquidity periods ?
extern int StartHour = 08;
extern int EndHour = 17;
extern int StartDay = 1;
extern int EndDay = 5;


int file_handle = 0;
int barsTotal   = 0;



int start() {

   return (0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+

int OpenExportFile(datetime t) {
   string normalize_str = "normalized";
   string datetime_str = "datetime";

   if(!do_normalize) {
      normalize_str = "UNnormalized";
   }
   if(!attach_datetime) {
      datetime_str = "NOdatetime";
   }
   string time_string = TimeToStr(t,TIME_DATE);
   string folder_name = StringConcatenate("mt4_", Symbol(),"_", Period(), "_", "_range_", EVAL_RANGE, "_", normalize_str, "_", datetime_str, "_", StartHour, "-", EndHour, "_", StartDay, "-", EndDay, "_OHCLT_train_data");
   Print(StringConcatenate(folder_name, "\\", "mt4_", Symbol(),"_", Period(), "_", time_string, "_", "_range_", EVAL_RANGE, "_", normalize_str, "_", datetime_str, "_", StartHour, "-", EndHour, "_", StartDay, "-", EndDay, "_OHCLT_train_data.csv"));
   Print(time_string);
   return FileOpen(StringConcatenate(folder_name, "\\", "mt4_", Symbol(),"_", Period(), "_", time_string, "_range_", StartHour, "-", EndHour, "_", StartDay, "-", EndDay, "_OHCLT_data.csv"),FILE_READ|FILE_WRITE|FILE_CSV);
}

int OnInit() {


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
   if(!do_normalize) {
      return pipized;
   } else {

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
}

string getDataRow(string sym, int period, int range) {
   string result   = "";
   datetime t      = Time[1];
   int hour        = TimeHour(t);
   int minute      = TimeMinute(t);
   int dayOfWeek   = TimeDayOfWeek(t);

   // OHLC data comes first
   if(hour >= StartHour && hour <= EndHour && dayOfWeek >= StartDay && dayOfWeek <= EndDay) {

      if(hour == StartHour && minute == 0) {
         if(file_handle != 0) {
            FileClose(file_handle);
         }
         file_handle = OpenExportFile(t);
      }
      for(int i = range-1; i>=0; i--){
         result = StringConcatenate(result, DoubleToStr(normalize(iOpen(sym, period, i+1)  - iOpen(sym, period, i+2)) , 7), ",");
         result = StringConcatenate(result, DoubleToStr(normalize(iHigh(sym, period, i+1)  - iHigh(sym, period, i+2)) , 7), ",");
         result = StringConcatenate(result, DoubleToStr(normalize(iLow(sym, period, i+1)   - iLow(sym, period, i+2))  , 7), ",");
         if(!attach_datetime && i == 0) {
            result = StringConcatenate(result, DoubleToStr(normalize(iClose(sym, period, i+1) - iClose(sym, period, i+2)), 7)); // dont include last ',' in this case
         } else {
            result = StringConcatenate(result, DoubleToStr(normalize(iClose(sym, period, i+1) - iClose(sym, period, i+2)), 7), ",");
         }
      }

      if(attach_datetime) {
        // dont include number of a day for now
         double day = TimeDayOfWeek(t);


         // now normalized datetime columns


         double decimal_time_normalized = ((hour + (60 * minute) / 3600.0) / 24.0);
         result = StringConcatenate(result,DoubleToStr(decimal_time_normalized, 7));
      }
   }

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
