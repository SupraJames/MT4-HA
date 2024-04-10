//+------------------------------------------------------------------+
//|                                                   UpdateHass.mq4 |
//|                                                  James Pattinson |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "James Pattinson"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string HassUrl = "https://hass.pattinson.org/";
input string HassToken = "";
input string HassSensorEntity = "alchemist";
input string HassUpdateInterval = 60;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(HassUpdateInterval);
   Print("Timer registered with interval " + HassUpdateInterval + " seconds");
   UpdateHass();
   
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
void OnTick()
  {
//---
   
  }
  
double getClosedPnlOfDay(const int indexDay)
{
   const datetime timeStart=iTime(_Symbol,PERIOD_D1,indexDay),
                  timeEnd = timeStart+PeriodSeconds(PERIOD_D1);
   double result=0.;
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
      //filter by OrderSymbol() and OrderMagicNumber() here
      if(OrderCloseTime()<timeStart || OrderCloseTime()>=timeEnd) continue;
      result+=OrderProfit() + OrderCommission() + OrderSwap();
   }
   return result;
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void UpdateHass()
  {
string JSON_string = StringFormat( "{\"state\": \"On\", \"attributes\": {\"ping\": %d, \"dailyProfit\": %.2f, \"activePnl\": %.2f}}", TerminalInfoInteger(TERMINAL_PING_LAST),getClosedPnlOfDay(0),AccountProfit());                                

          string  ReqSERVER_URL = HassUrl + "api/states/sensor." + HassSensorEntity,
                  ReqCOOKIE     =  NULL,
                  ReqHEADERs    = "Content-Type: application/json\r\nauthorization: Bearer " + HassToken + "\r\n";
          int     ReqTIMEOUT    =  5000;                            
          char    POSTed_DATA[],
                  result_RECVed_DATA_FromSERVER[];
          int     result_RetCODE;
          string  result_DecodedFromSERVER,
                  result_RECVed_HDRs_FromSERVER;

          StringToCharArray( JSON_string,   POSTed_DATA, 0, StringLen(  JSON_string   ) );

          ResetLastError();

          result_RetCODE = WebRequest( "POST",
                                       ReqSERVER_URL,
                                       ReqHEADERs,
                                       ReqTIMEOUT,
                                       POSTed_DATA,
                                       result_RECVed_DATA_FromSERVER,
                                       result_RECVed_HDRs_FromSERVER
                                       );
          if (  result_RetCODE == -1 ) Print( "Error in WebRequest. Error code  =", GetLastError() ); // returns error 4060 – "Function is not allowed for call" unless permitted -- ref. Picture in >>> https://stackoverflow.com/questions/39954177/how-to-send-a-post-with-a-json-in-a-webrequest-call-using-mql4
          else {
                for (  int i = 0; i < ArraySize( result_RECVed_DATA_FromSERVER ); i++ ) {
                       if (  ( result_RECVed_DATA_FromSERVER[i] == 10 ) // == '\n'  // <LF>
                          || ( result_RECVed_DATA_FromSERVER[i] == 13 ) // == '\r'  // <CR>
                          ) 
                          continue;
                       else     result_DecodedFromSERVER += CharToStr( result_RECVed_DATA_FromSERVER[i] );
                }
                Print( "DATA:: ", result_DecodedFromSERVER );
                Print( "HDRs:: ", result_RECVed_HDRs_FromSERVER );
          }
   
  }
//+------------------------------------------------------------------+

void OnTimer()
  {
  UpdateHass();
  }