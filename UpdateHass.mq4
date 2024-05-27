//+------------------------------------------------------------------+
//|                                                   UpdateHass.mq4 |
//|                                                  James Pattinson |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "James Pattinson"
#property link      "https://github.com/SupraJames/MT4-HA"
#property version   "1.00"
#property strict

input string HassUrl = "https://hass.domain.org/";
input string HassToken = "";
input string webHookId = "";
input string HassSensorPrefix = "forexacct";
input string HassUpdateInterval = 120;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(HassUpdateInterval);
   Print("Timer registered with interval " + HassUpdateInterval + " seconds");
   UpdateHass();
   webhookHeartbeat();
   
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
  
double getClosedPnlOfDay()
{
   // Note that this is the timestamp of the LAST TRADE/TICK and NOT the actual Time!
   const datetime curTime = TimeCurrent();
   const datetime timeStart = StrToTime(IntegerToString(Year()) + "." + IntegerToString(Month()) + "." + IntegerToString(Day()) + " 00:00");
                  
   double result=0.;
   
   for(int i=OrdersHistoryTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
      // Filter out any trades without 'Standard' as the comment
      if(!StringCompare(StringSubstr(OrderComment(),0,7),"Deposit" )) continue;
      if(!StringCompare(StringSubstr(OrderComment(),0,8),"Withdraw" )) continue;
      if(!StringCompare(StringSubstr(OrderComment(),0,8),"Transfer" )) continue;
      //Print("DEBUG: Comment of order #", OrderTicket(), " is ", OrderComment());
      if(OrderCloseTime()<timeStart || OrderCloseTime()>=curTime) continue;
      double ordProfit = OrderProfit() + OrderCommission() + OrderSwap();
      //Print("DEBUG: Order " + OrderTicket() + " value " + ordProfit);
      result+=ordProfit;
   }
   //Print("DEBUG: total is " + result);
   return result;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void UpdateHass()
  {

  UpdateSensor(HassSensorPrefix + "_ping", StringFormat( "{\"state\": %.1f, \"attributes\": {\"unit_of_measurement\": \"ms\" }}", TerminalInfoInteger(TERMINAL_PING_LAST)/1000));
  UpdateSensor(HassSensorPrefix + "_openpos", StringFormat( "{\"state\": %.2f, \"attributes\": {\"unit_of_measurement\": \"EUR\" }}", -AccountProfit()));
  UpdateSensor(HassSensorPrefix + "_profit", StringFormat( "{\"state\": %.2f, \"attributes\": {\"unit_of_measurement\": \"EUR\" }}", getClosedPnlOfDay()));
  UpdateSensor(HassSensorPrefix + "_balance", StringFormat( "{\"state\": %.2f, \"attributes\": {\"unit_of_measurement\": \"EUR\" }}", AccountBalance()));
  UpdateSensor(HassSensorPrefix + "_ddpct", StringFormat( "{\"state\": %.2f, \"attributes\": {\"unit_of_measurement\": \"%\" }}", (-AccountProfit()/AccountBalance())*100));

  }
//+------------------------------------------------------------------+

void UpdateSensor(string HassSensorEntity, string JSON_string)
  {
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
                //Print( "DATA:: ", result_DecodedFromSERVER );
                //Print( "HDRs:: ", result_RECVed_HDRs_FromSERVER );
          }
   
  }
  
void webhookHeartbeat()
  {
          string  ReqSERVER_URL = HassUrl + "api/webhook/" + webHookId,
                  ReqCOOKIE     = NULL,
                  ReqHEADERs    = "Content-Type: application/json\r\n";
          int     ReqTIMEOUT    =  5000;                            
          char    POSTed_DATA[],
                  result_RECVed_DATA_FromSERVER[];
          int     result_RetCODE;
          string  result_DecodedFromSERVER,
                  result_RECVed_HDRs_FromSERVER;

          string JSON_string = "{dummydata: 0}";

          StringToCharArray( JSON_string, POSTed_DATA, 0, StringLen(JSON_string) );

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
                //Print(ReqSERVER_URL);
                //Print( "DATA:: ", result_DecodedFromSERVER );
                //Print( "HDRs:: ", result_RECVed_HDRs_FromSERVER );
          }
   
  }

void OnTimer()
  {
  UpdateHass();
  //webhookHeartbeat();
  }