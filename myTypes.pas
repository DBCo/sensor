unit myTypes;

interface

uses System.Classes, Messages, System.SysUtils, Math, Graphics, Vcl.Forms, Vcl.Controls,
     Winapi.Windows, Winapi.WinInet, XMLDoc, XMLIntf, System.NetEncoding;

const
  WM_INFONOTIFY         = WM_USER + 22; //отображение сообщения в главной форме
  WM_STYLENOTIFY        = WM_USER + 23; //отображение сообщения в главной форме
  WM_LOGNOTIFY          = WM_USER + 24; //отображение сообщения в главной форме

  ApplicationName = 'Devigator';

  HLSMAX = 240;
  RGBMAX = 255;
  UNDEFINED = (HLSMAX*2) div 3;

  _Gray = $005C564B;
  _Green = $0062B75A;
  _White = $00F0F0F0;

  _SignV2B: string = Chr(85)+Chr(170);
//_SignV2B: string = Chr(62);
  _SignV2E: string = '';

type
  TVersionType = (vtDetect, vtVersion0, vtVersion1, vtVersion2, vtVersion3);

  TPacket = Record
    Time: TDateTime;
    Position: Int64;
    Size: Int64;
    State: Byte;
  function Color: TColor;
  end;

  PPacket = ^TPacket;
  TPacketArray = array of TPacket;
  PPacketArray = ^TPacketArray;

  TOnDataEvent = procedure(const aIndex: Int64) of object;

  TMemoryStreamEx = class(TMemoryStream)
  public
    function StringPosition(const aPos, aSize: Int64; const aSign: AnsiString): Int64;
    function ArrayPosition(const aPos, aSize: Int64; const aSign: Pointer; Const aSignLength: Integer): Int64;
    function AsByte(const aPos: Int64): Byte;
    function AsShortInt(const aPos: Int64): ShortInt;
    function AsWord(const aPos: Int64): Word;
    function AsInteger(const aPos: Int64): Word;
    function AsCardinal(const aPos: Int64):  Cardinal;
    function AsSingle(const aPos: Int64):  Single;
    function AsDouble(const aPos: Int64):  Double;
    function AsText(const aPos, aLength: Int64): AnsiString;
    function AsHEX(const aPos, aLength: Int64; aSeparator: AnsiString = ''; aDesc: Boolean = False): AnsiString;
  end;

  TUpdateThread = class(TThread)
  private
  public
    URL: String;
    Ident: Integer;
  protected
    procedure Execute; override;
  end;

function EncodeBase64(const B: TBytes): string;
function ValueToProgress(aMin, aMax, aValue: Integer): String;
function UnixTimeToDateTime(AUnixTime: LongWord; ABias: Integer): TDateTime;
function CRCDallas(s:AnsiString): Byte;
function MasterCRC(s: AnsiString): AnsiString;
function CRC16CCITT(aBuffer: Array of Byte; aFirst, aLast: Integer): word;
function SumCrc(s:AnsiString):Byte;
function StringCrc(s:shortstring):word;
procedure RGBtoHLS(const R, G, B: LongInt; var H, L, S: LongInt);
procedure HLStoRGB(const H, L, S: LongInt; var R, G, B: LongInt);
function LiteResize(x1,x2,Step,i,SleepValue:Integer):Integer;
function IcoPrefix(aValue: Boolean): string;
function GetDOSEnvVar(const VarName: string): string;
function GetInetFile(const fileURL, fileLocal: String): boolean;
function SetFileDateTime( const FileName: string; NewDateTime: TDateTime ): boolean;
function ByteToStr(V: Byte): AnsiString;
function WordToStr(V: Word): AnsiString;
function CardinalToStr(V: Cardinal): AnsiString;
function HexToStr(H: AnsiString): AnsiString;
function ReverseAnsiStr(aString: AnsiString): AnsiString;

implementation

uses MForm;

//==============================================================================
function ByteToStr(V: Byte): AnsiString;
begin
  Result:= AnsiChar(V);
end;

function WordToStr(V: Word): AnsiString;
begin
  Result:= AnsiChar(V mod 256) + AnsiChar(V div 256);
end;

function CardinalToStr(V: Cardinal): AnsiString;
begin
  Result:= AnsiChar(V mod 256) + AnsiChar((V div 256) mod 256) +
           AnsiChar((V div (256*256)) mod 256) + AnsiChar((V div (256*256*256)));
end;

function ReverseAnsiStr(aString: AnsiString): AnsiString;
var i: Integer;
begin
  Result:= '';
  for i := Length(aString) downto 1 do
    Result:= Result + aString[i];
end;

function HexToStr(H: AnsiString): AnsiString;
var i: Integer;
    s: AnsiString;
begin
  s:= '';
  for I := 1 to length (H) do
    if not (H[i]=' ') then s:= s + h[i];

  Result:= '';
  for i := 1 to length (s) div 2 do
    Result:= Result + AnsiChar(StrToInt('$'+Copy(s,(i-1)*2+1,2)));
end;

function SetFileDateTime( const FileName: string; NewDateTime: TDateTime ): boolean;
var
  FileHandle: integer;
  FileTime: TFileTime;
  LFT: TFileTime;
  LST: TSystemTime;
begin
   Result := false;
   try
      DecodeDate( NewDateTime, LST.wYear, LST.wMonth, LST.wDay );
      DecodeTime( NewDateTime, LST.wHour, LST.wMinute, LST.wSecond, LST.wMilliSeconds );
      if SystemTimeToFileTime( LST, LFT ) then
      begin
         if LocalFileTimeToFileTime( LFT, FileTime ) then
         try
            FileHandle := FileOpen( FileName, fmOpenReadWrite or fmShareExclusive );
            if SetFileTime( FileHandle, nil, nil, @FileTime ) then
               Result := true;
         finally
            FileClose( FileHandle );
         end;
      end;
   finally
   end;
end;

function EncodeBase64(const B: TBytes): string;
  const  Base64: array[0..63] of Char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  var    i, iLength: Integer;
begin
  Result := '';
  iLength := Length(B);
  i := 0;
  while i < iLength do
    begin
      case iLength - i of
        3..MaxInt: Result:= Result + Base64[B[i] shr 2]
                                   + Base64[((B[i] shl 4) or (B[i+1] shr 4)) and $3F]
                                   + Base64[((B[i+1] shl 2) or (B[i+2] shr 6)) and $3F]
                                   + Base64[B[i+2] and $3F];
        2:         Result:= Result + Base64[B[i] shr 2]
                                   + Base64[((B[i] shl 4) or (B[i+1] shr 4)) and $3F]
                                   + Base64[(B[i+1] shl 2) and $3F] + '=';
        1:         Result:= Result + Base64[B[i] shr 2]
                                   + Base64[(B[i] shl 4) and $3F] + '==';
      end;
      Inc(i, 3);
    end;
end;

function GetDOSEnvVar(const VarName: string): string;
var
  i: integer;
begin
  Result := '';
  try
    i := GetEnvironmentVariable(PChar(VarName), nil, 0);
    if i > 0 then
    begin
      SetLength(Result, i);
      GetEnvironmentVariable(Pchar(VarName), PChar(Result), i);
    end;
  except
    Result := '';
  end;
end;

function GetInetString(const fileURL: String; var aText:String): boolean;
var
  hSession, hURL: HInternet;
  Buffer: array[0..1023] of Byte;
  BufferLen: DWORD;
  sAppName : string;
  i : Integer;
begin
   Result:= False;
   aText := '';
   sAppName:= ExtractFileName(Application.ExeName);
   hSession:= InternetOpen( PWideChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
   try
     hURL:= InternetOpenURL(hSession, PChar(fileURL), nil, 0, 0, 0);
     if hURL<>nil then
     try
       repeat
         InternetReadFile(hURL, @Buffer, Length(Buffer), BufferLen);
         for i:=0 to Pred(BufferLen) do
           aText:= aText + AnsiChar(Buffer[i]);

       until BufferLen = 0;
       Result:=True;
     finally
       InternetCloseHandle(hURL)
     end
   finally
     InternetCloseHandle(hSession);
   end
end;

function GetInetFile(const fileURL, fileLocal: String): boolean;
const
  BufferSize = 1024;
var
  hSession, hURL: HInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: DWORD;
  sAppName : string;
  FS: TFileStream;
begin
   Result:=False;
   sAppName := ExtractFileName(Application.ExeName);
   hSession := InternetOpen(PChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
   try
      hURL := InternetOpenURL(hSession, PChar(fileURL), nil, 0, 0, 0);
      if hURL<>nil then
      try
         FS:= TFileStream.Create(fileLocal, fmCreate);
         repeat
            InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
            FS.WriteBuffer(Buffer, BufferLen);
         until BufferLen = 0;
         Result:=True;
      finally
        FS.Free;
        InternetCloseHandle(hURL)
      end
   finally
   InternetCloseHandle(hSession);
   end
end;

procedure RGBtoHLS(const R, G, B: LongInt; var H, L, S: LongInt);
Var
 cMax,cMin  : integer;
 Rdelta,Gdelta,Bdelta : single;
Begin
   cMax := max( max(R,G), B);
   cMin := min( min(R,G), B);
   L := round( ( ((cMax+cMin)*HLSMAX) + RGBMAX )/(2*RGBMAX) );

   if (cMax = cMin) then begin
      S := 0; H := UNDEFINED;
   end else begin
      if (L <= (HLSMAX/2)) then
         S := round( ( ((cMax-cMin)*HLSMAX) + ((cMax+cMin)/2) ) / (cMax+cMin) )
      else
         S := round( ( ((cMax-cMin)*HLSMAX) + ((2*RGBMAX-cMax-cMin)/2) )
            / (2*RGBMAX-cMax-cMin) );
      Rdelta := ( ((cMax-R)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
      Gdelta := ( ((cMax-G)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
      Bdelta := ( ((cMax-B)*(HLSMAX/6)) + ((cMax-cMin)/2) ) / (cMax-cMin);
      if (R = cMax) then H := round(Bdelta - Gdelta)
      else if (G = cMax) then H := round( (HLSMAX/3) + Rdelta - Bdelta)
      else H := round( ((2*HLSMAX)/3) + Gdelta - Rdelta );
      if (H < 0) then H:=H + HLSMAX;
      if (H > HLSMAX) then H:= H - HLSMAX;
   end;
   if S<0 then S:=0; if S>HLSMAX then S:=HLSMAX;
   if L<0 then L:=0; if L>HLSMAX then L:=HLSMAX;
end;

procedure HLStoRGB(const H, L, S: LongInt; var R, G, B: LongInt);
Var
 Magic1,Magic2 : single;

  function HueToRGB(n1, n2, hue: Single): Single;
  begin
     if (hue < 0) then hue := hue+HLSMAX;
     if (hue > HLSMAX) then hue:=hue -HLSMAX;
     if (hue < (HLSMAX/6)) then
        result:= ( n1 + (((n2-n1)*hue+(HLSMAX/12))/(HLSMAX/6)) )
     else
     if (hue < (HLSMAX/2)) then result:=n2 else
     if (hue < ((HLSMAX*2)/3)) then
        result:= ( n1 + (((n2-n1)*(((HLSMAX*2)/3)-hue)+(HLSMAX/12))/(HLSMAX/6)))
     else result:= ( n1 );
  end;

begin
   if (S = 0) then begin
      B:=round( (L*RGBMAX)/HLSMAX ); R:=B; G:=B;
   end else begin
      if (L <= (HLSMAX/2)) then Magic2 := (L*(HLSMAX + S) + (HLSMAX/2))/HLSMAX
      else Magic2 := L + S - ((L*S) + (HLSMAX/2))/HLSMAX;
      Magic1 := 2*L-Magic2;
      R := round( (HueToRGB(Magic1,Magic2,H+(HLSMAX/3))*RGBMAX + (HLSMAX/2))/HLSMAX );
      G := round( (HueToRGB(Magic1,Magic2,H)*RGBMAX + (HLSMAX/2)) / HLSMAX );
      B := round( (HueToRGB(Magic1,Magic2,H-(HLSMAX/3))*RGBMAX + (HLSMAX/2))/HLSMAX );
   end;
   if R<0 then R:=0; if R>RGBMAX then R:=RGBMAX;
   if G<0 then G:=0; if G>RGBMAX then G:=RGBMAX;
   if B<0 then B:=0; if B>RGBMAX then B:=RGBMAX;
end;

function LiteResize(x1,x2,Step,i,SleepValue:Integer):Integer;
begin
  if i=Step then
    LiteResize:=x2
  else
    begin
      sleep(SleepValue);
      LiteResize:=x1+Round((x2-x1)*0.5*(1-Cos(i*pi/Step)));
    end;
end;

function ValueToProgress(aMin, aMax, aValue: Integer): String;
var i: Integer;
begin
  Result:='';
  for i:=aMin to aMax do
    if i<aValue then Result:= Result + '|'
                else Result:= Result + '.';
end;

function UnixTimeToDateTime(AUnixTime: LongWord; ABias: Integer): TDateTime;
const
  UnixDateDelta = 25569; { 1970-01-01T00:00:00,0 }
  SecPerDay = 24 * 60 * 60;
  MinDayFraction = 1 / (24 * 60);
begin
  Result := UnixDateDelta + (AUnixTime div SecPerDay) { Days }
  + ((AUnixTime mod SecPerDay) / SecPerDay) { Seconds }
  - ABias * MinDayFraction { Bias to UTC in minutes };
end;

function CRCDallas(s:AnsiString): Byte;
Const
	DallasTable : Array[0..255] of Byte = (
	0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
	157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
	35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
	190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
	70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
	219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
	101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
	248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
	140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
	17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
	175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
	50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
	202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
	87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
	233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
	116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53);

Var
  i: Integer;

begin
  Result:= 0;
  for i:=1 to length(s) do
    Result := DallasTable[Result xor Ord(s[i])];
end;

function MasterCRC(s: AnsiString): AnsiString;
begin
  Result:= s + AnsiChar(CRCDallas(s));
end;

function CRC16CCITT(aBuffer: Array of Byte; aFirst, aLast: Integer): word;
var
  i, j: Word;
begin
  Result:= $FFFF;
  for i:= aFirst to aLast do
    begin
      Result:=Result xor (aBuffer[i] shl 8);
      for j:= 0 to 7 do
        if (Result and $8000)<>0 then Result:= (Result shl 1) xor $1021
                                 else Result:= (Result shl 1);
    end;
  Result:= Result and $ffff;
end;

{ TMemoryStreamEx }

function TMemoryStreamEx.AsByte(const aPos: Int64): Byte;
begin
  Result:= TByteArray(Memory^)[aPos];
end;

function TMemoryStreamEx.AsShortInt(const aPos: Int64): ShortInt;
var B: Byte;
    I: ShortInt absolute B;
begin
  B:= TByteArray(Memory^)[aPos];
  Result:= I;
end;

function TMemoryStreamEx.AsWord(const aPos: Int64): Word;
begin
  Move( TByteArray(Memory^)[aPos], Result, 2);
end;

function TMemoryStreamEx.AsInteger(const aPos: Int64): Word;
begin
  Move( TByteArray(Memory^)[aPos], Result, 4);
end;

function TMemoryStreamEx.AsCardinal(const aPos: Int64):  Cardinal;
begin
  Move( TByteArray(Memory^)[aPos], Result, 4);
end;

function TMemoryStreamEx.AsSingle(const aPos: Int64):  Single;
begin
  Move( TByteArray(Memory^)[aPos], Result, 4);
end;

function TMemoryStreamEx.AsText(const aPos, aLength: Int64): AnsiString;
var i: Integer;
begin
  Result:='';
  for i:= aPos to Pred(aPos + aLength) do
    Result:= Result + AnsiChar(MS.AsByte(i));
end;

function TMemoryStreamEx.AsDouble(const aPos: Int64):  Double;
begin
  Move( TByteArray(Memory^)[aPos], Result, 8);
end;

function TMemoryStreamEx.AsHEX(const aPos, aLength: Int64; aSeparator: AnsiString = ''; aDesc: Boolean = False): AnsiString;
var i: Integer;
begin
  Result:= '';
  if aDesc then
    for i:= Pred(aPos + aLength) downto aPos do
      if 0 = Length(Result) then Result:= IntToHex(MS.AsByte(i), 2)
                            else Result:= Result + aSeparator + IntToHex(MS.AsByte(i), 2)
  else
    for i:= aPos to Pred(aPos + aLength) do
      if 0 = Length(Result) then Result:= IntToHex(MS.AsByte(i), 2)
                            else Result:= Result + aSeparator + IntToHex(MS.AsByte(i), 2);
end;

function TMemoryStreamEx.StringPosition(const aPos, aSize: Int64; const aSign: AnsiString): Int64;
var i,j : integer;
begin
  Result:= -1;
  for i:= aPos to aPos + aSize - Length(aSign) do
    begin
      Result:= i;
      for j:= 0 to Pred(Length(aSign)) do
        if TByteArray(Memory^)[i+j] <> Ord(aSign[Succ(j)]) then
          begin
            Result:= -1;
            Break;
          end;
      if -1 < Result then Break;
    end;
end;

function TMemoryStreamEx.ArrayPosition(const aPos, aSize: Int64; const aSign: Pointer; Const aSignLength: Integer): Int64;
var i,j : integer;
begin
  Result:= -1;
  for i:= aPos to aPos + aSize - aSignLength do
    begin
      Result:= i;
      for j:= 0 to Pred(aSignLength) do
        if TByteArray(Memory^)[i+j] <> TByteArray(aSign^)[j] then
          begin
            Result:= -1;
            Break;
          end;
      if -1 < Result then Break;
    end;
end;

procedure ByteCrc(data:byte; var crc:word);
VAR i:BYTE;
BEGIN
 FOR i:=0 TO 7 DO
  BEGIN
   IF ((data and $01)XOR(crc AND $0001)<>0) THEN
    BEGIN
     crc:=crc shr 1;
     crc:= crc XOR $A001;
    END
   ELSE crc:=crc shr 1;
   data:=data shr 1; // this line is not ELSE and executed anyway.
  END;
END;

function SumCrc(s:Ansistring):Byte;
var i:integer;
begin
  Result:=0;
  for i:=1 to length(s) do
    inc(Result, Ord(s[i]));
end;

function StringCrc(s:shortstring):word;
var len,i:integer;
begin
 result:=0;
 len:=length(s);
 for i:=1 to len do bytecrc(ord(s[i]),result);
end;

{ TPacket }

function TPacket.Color: TColor;
begin
  case State of
    0:  Result:= clRed;
    1:  Result:= clGray;
    2:  Result:= clGreen;
    3:  Result:= RGB(252,15,192);
  255:  Result:= RGB(176,176,0); //clYellow;//RGB(96,96,255);//clBlue;//Yellow;
   else Result:= clWhite;
   end;
end;

{ TUpdateThread }

procedure TUpdateThread.Execute;
var T: String;
begin
  try
    if GetInetString(URL, T) then T:= UTF8Decode(T)
                             else T:= '';
    SendMessage( MF.Handle, WM_INFONOTIFY, Ident, NativeInt(PChar(T)));
  except
    SendMessage( Application.MainForm.Handle, WM_INFONOTIFY, 2, NativeInt(PChar('Не удалось получить обновления и новости')));
  end;

  Terminate;
end;

function IcoPrefix(aValue: Boolean): string;
begin
  if aValue then Result:='E_'
            else Result:='D_';
end;

end.
