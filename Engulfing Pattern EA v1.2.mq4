//+------------------------------------------------------------------+
//|                                    Engulfing Pattern EA v1.2.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
enum MoneyManagementOptions {
   FixedLot = 0,   // Fixed Lot 
   RiskPercent = 1  // Risk %
};

extern string s0 = "________ EA Settings ________";           // ________
extern MoneyManagementOptions Lots_Cal = RiskPercent;         // Lots Calculation Mode
extern double Fixed_Lots = 1.0;                               // Fixed Lot
extern double Risk_Perc  = 0.25;                              // Risk %
extern double SL_Multiply_Factor = 1;                         // SL Multiply factor
extern double TP_Multiply_Factor = 1;                         // TP Multiply factor
extern int Number_Of_Candles = 15;                            // Delete Stop Order After "X" bars

extern string set2 = "________ MA Setting ________";          //________
extern int Ma_Period = 10;                                           // Period
extern ENUM_MA_METHOD Ma_Method = MODE_EMA;                         // MA Method
extern int Ma_Shift = 0;                                             // Shift
extern ENUM_APPLIED_PRICE Ma_Applied = PRICE_CLOSE;              // Applied Price




datetime prev_time = 0;
int slippage = 5;
int Magic_Number = 987678;
string comment = WindowExpertName();
double point_sz = 0;

int OnInit()
  {
//---
     point_sz = PointSize();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
     DeletePendingOrder();
     
     if(!IsNewCandle())
        return;
        
     double candle_size = High[1] - Low[1]; 
      
     if(TotalOrders() == 0){   
        if(High[1] > High[2] && Low[1] < Low[2]){
            if(Close[1] > Open[1] && Close[2] > Open[2] && Open[1] > MA(1)){
                double open_price = High[1] + 4*point_sz;
                double tp = (High[1] + (candle_size*TP_Multiply_Factor))+4*point_sz;
                double sl = (Low[1] - (candle_size*SL_Multiply_Factor))+4*point_sz;
                double sl_points = open_price - sl;
                
                int ticket = OrderSend(NULL,OP_BUYSTOP,GetLots(sl_points),open_price,slippage,sl,tp,comment,Magic_Number,0,clrGreen);
                if(ticket == -1)
                   Print("OrderSend failed, error #",GetLastError());
            }    
            else if(Open[1] > Close[1] && Open[2] > Close[2] && Open[1] < MA(1)){
                double open_price = Low[1] - 4*point_sz;
                double tp = (Low[1] - (candle_size*TP_Multiply_Factor)) - 4*point_sz;
                double sl = (High[1] + (candle_size*SL_Multiply_Factor)) - 4*point_sz;
                double sl_points = sl - open_price;
                
                int ticket = OrderSend(NULL,OP_SELLSTOP,GetLots(sl_points),open_price,slippage,sl,tp,comment,Magic_Number,0,clrRed);
                if(ticket == -1)
                   Print("OrderSend failed, error #",GetLastError());
                
            }
        } 
     }         
  }
//+------------------------------------------------------------------+
int TotalOrders()
{  
   int count = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number){
            count++;
         } 
      }
   }
   return count;
}
void DeletePendingOrder()
{  
   for(int i = OrdersTotal()-1; i >= 0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Number && OrderType() > OP_SELL){
            if(iBarShift(NULL,0,OrderOpenTime()) - iBarShift(NULL,0,Time[0]) >= Number_Of_Candles){
               if(!OrderDelete(OrderTicket(),clrNONE))
                  Print("Order Delete failed, error #",GetLastError()); 
            }
         } 
      }
   }
}


bool IsNewCandle()
{
   if(prev_time == Time[0])
      return false;
   prev_time = Time[0];
   
   return true;    

}

double MA(int index)
{
   return iMA(NULL,0,Ma_Period,Ma_Shift,Ma_Method,Ma_Applied,index);
}
double GetLots(double stoploss)
{  
   double lots = 0;
   
   if(Lots_Cal == RiskPercent && stoploss != 0){
      double acc_balance = AccountBalance();
      double risk_amount = (Risk_Perc * acc_balance)/100;
      double tick_size = MarketInfo(NULL,MODE_TICKSIZE);
      double tick_value = MarketInfo(NULL,MODE_TICKVALUE);
      
      lots = (risk_amount*tick_size)/(stoploss*tick_value);
   }  
   else if(Lots_Cal == FixedLot)
      lots = Fixed_Lots;
      
   double minlot = MarketInfo(NULL,MODE_MINLOT);
   if(lots < minlot)
      lots = minlot;
      
   return lots;
}


double PointSize()
{
   if(Digits() == 2 || Digits() == 3) return(0.01);
   else if(Digits() == 4 || Digits() == 5) return(0.0001);
   return(Point);
}

