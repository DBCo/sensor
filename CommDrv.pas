unit CommDrv;

interface

uses
  Windows, Messages, SysUtils, Classes, SyncObjs;

type
  // COM Port Baud Rates
  TPortBaudRate = ( br110, br300, br600, br1200, br2400, br4800, br9600,
                       br14400, br19200, br38400, br56000, br57600, br115200 );
  // COM Port Stop bits
  TPortStopBits = ( sb1BITS, sb1HALFBITS, sb2BITS );
  // COM Port Parity
  TPortParity = ( ptNONE, ptODD, ptEVEN, ptMARK, ptSPACE );
  // COM Port Hardware Handshaking
  TPortHwHandshaking = ( hhNONE, hhRTSCTS );
  // COM Port Software Handshaing
  TPortSwHandshaking = ( shNONE, shXONXOFF );

  TPortReceiveDataEvent = procedure( Sender: TObject; DataPtr: pointer; DataSize: integer ) of object;

  TCommPortDriver = class(TComponent)
  protected
    FPortHandle             : THANDLE; // COM Port Device Handle
    FPort                   : String; // COM Port to use (1..8)
    FPortBaudRate           : TPortBaudRate; // COM Port speed (brXXXX)
    FPortDataBits           : Byte; // Data bits size (5..8)
    FPortStopBits           : TPortStopBits; // How many stop bits to use (1,1.5,2)
    FPortParity             : TPortParity; // Type of parity to use (none,odd,even,mark,space)
    FPortHwHandshaking      : TPortHwHandshaking; // Type of hw handshaking to use
    FPortSwHandshaking      : TPortSwHandshaking; // Type of sw handshaking to use
    FPortInBufSize          : word; // Size of the input buffer
    FPortOutBufSize         : word; // Size of the output buffer
    FPortReceiveData        : TPortReceiveDataEvent; // Event to raise on data reception
    FPortPollingDelay       : word; // ms of delay between COM port pollings
    FEndByte                : Integer;
    FNotifyWnd              : HWND; // This is used for the timer
    FInBuffer               : pointer;
    FOffsetBuffer           : word;
    FCriticalSection        : TCriticalSection;
    procedure SetPort( Value: String);
    procedure SetPortBaudRate( Value: TPortBaudRate );
    procedure SetPortDataBits( Value: byte );
    procedure SetPortStopBits( Value: TPortStopBits );
    procedure SetPortParity( Value: TPortParity );
    procedure SetPortHwHandshaking( Value: TPortHwHandshaking );
    procedure SetPortSwHandshaking( Value: TPortSwHandshaking );
    procedure SetPortInBufSize( Value: word );
    procedure SetPortOutBufSize( Value: word );
    procedure SetPortPollingDelay( Value: word );
    procedure ApplyCOMSettings;

    procedure SetEndByte(Value:Integer);

    procedure TimerWndProc( var msg: TMessage );
  public
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;

    function Connect: boolean;
    procedure Disconnect;
    function GetStatus: Integer;
    function GetState: Boolean;
    function GetConfig(var aCommConfig: TCommConfig; var aSize: Cardinal): Boolean;
    function GetProperties(var aCommProp: TCommProp): Boolean;
    function Connected: boolean;
    function ErrorConnected: Integer;
    function SendData( DataPtr: pointer; DataSize: DWORD ): boolean;
    function SendString( s: ansistring ): boolean;
  published
      // Which COM Port to use
    property Port: String read FPort write SetPort;
      // COM Port speed (bauds)
    property PortSpeed: TPortBaudRate read FPortBaudRate write SetPortBaudRate default br9600;
      // Data bits to used (5..8, for the 8250 the use of 5 data bits with 2 stop bits is an invalid combination,
      // as is 6, 7, or 8 data bits with 1.5 stop bits)
    property PortDataBits: byte read FPortDataBits write SetPortDataBits default 8;
      // Stop bits to use (1, 1.5, 2)
    property PortStopBits: TPortStopBits read FPortStopBits write SetPortStopBits default sb1BITS;
      // Parity Type to use (none,odd,even,mark,space)
    property PortParity: TPortParity read FPortParity write SetPortParity default ptNONE;
      // Hardware Handshaking Type to use:
      //  cdNONE          no handshaking
      //  cdCTSRTS        both cdCTS and cdRTS apply (** this is the more common method**)
    property PortHwHandshaking: TPortHwHandshaking read FPortHwHandshaking write SetPortHwHandshaking default hhNONE;
      // Software Handshaking Type to use:  cdNONE        no handshaking
      //                                    cdXONXOFF     XON/XOFF handshaking
    property PortSwHandshaking: TPortSwHandshaking read FPortSwHandshaking write SetPortSwHandshaking default shNONE;
      // Input Buffer size
    property PortInBufSize: word read FPortInBufSize write SetPortInBufSize default 2048;
      // Output Buffer size
    property PortOutBufSize: word read FPortOutBufSize write SetPortOutBufSize default 2048;
      // ms of delay between COM port pollings
    property PortPollingDelay: word read FPortPollingDelay write SetPortPollingDelay default 100;
      // Event to raise when there is data available (input buffer has data)
    property OnReceiveData: TPortReceiveDataEvent read FPortReceiveData write FPortReceiveData;
    property EndByte: Integer read FEndByte write SetEndByte default -1;
    property Handle: THandle read FPortHandle;
    function BufferSize: Word;
  end;

const
  Win32BaudRates: array[br110..br115200] of DWORD =
    ( CBR_110, CBR_300, CBR_600, CBR_1200, CBR_2400, CBR_4800, CBR_9600,
      CBR_14400, CBR_19200, CBR_38400, CBR_56000, CBR_57600, CBR_115200 );

procedure Register;

implementation

constructor TCommPortDriver.Create( AOwner: TComponent );
begin
  inherited Create( AOwner );
  FCriticalSection        := TCriticalSection.Create;
  FPortHandle             := 0;        // Not connected
  FPort                   := '';
  FPortBaudRate           := br19200;//9600;   // 9600 bauds

//  FPortBaudRate           := br115200;//9600;   // 9600 bauds
  FPortDataBits           := 8;        // 8 data bits
  FPortStopBits           := sb1BITS;  // 1 stop bit
  FPortParity             := ptNONE;   // no parity
  FPortHwHandshaking      := hhNONE;   // no hardware handshaking
  FPortSwHandshaking      := shNONE;   // no software handshaking
  FPortInBufSize          := 2048;     // input buffer of 512 bytes
  FPortOutBufSize         := 2048;     // output buffer of 512 bytes
  FPortReceiveData        := nil;      // no data handler
  GetMem( FInBuffer, FPortInBufSize ); // Temporary buffer for received data
  FOffsetBuffer           :=0;
  // Allocate a window handle to catch timer's notification messages
  FEndByte                :=-1;        // Value of the stop byte
  if not (csDesigning in ComponentState) then
    FNotifyWnd := AllocateHWnd( TimerWndProc );
end;
//------------------------------------------------------------------------------
destructor TCommPortDriver.Destroy;
begin
  Disconnect;
  FreeMem( FInBuffer, FPortInBufSize );
  DeallocateHWnd( FNotifyWnd );
  FCriticalSection.Free;
  inherited Destroy;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetEndByte(Value: Integer);
begin
  if value<0   then FEndByte:=-1  else
  if value>255 then FEndByte:=255 else FEndByte:=Value;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPort( Value: String );
begin
  if not Connected then
  begin
    FPort:= Value;
  end;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortBaudRate( Value: TPortBaudRate );
begin
  FPortBaudRate := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortDataBits( Value: byte );
begin
  if Value<5 then FPortDataBits := 5 else
  if Value>8 then FPortDataBits := 8 else FPortDataBits := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortStopBits( Value: TPortStopBits );
begin
  FPortStopBits := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortParity( Value: TPortParity );
begin
  FPortParity := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortHwHandshaking( Value: TPortHwHandshaking );
begin
  FPortHwHandshaking := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortSwHandshaking( Value: TPortSwHandshaking );
begin
  FPortSwHandshaking := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortInBufSize( Value: word );
begin
  FreeMem( FInBuffer, FPortInBufSize );
  FPortInBufSize := Value;
  GetMem( FInBuffer, FPortInBufSize );
          FOffsetBuffer:=0;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortOutBufSize( Value: word );
begin
  FPortOutBufSize := Value;
  if Connected then ApplyCOMSettings;
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.SetPortPollingDelay( Value: word );
begin
  // If new delay is not equal to previous value...
  if Value <> FPortPollingDelay then
  begin
    // Stop the timer
    if Connected then KillTimer( FNotifyWnd, 1 );
    // Store new delay value
    FPortPollingDelay := Value;
    // Restart the timer
    if Connected then SetTimer( FNotifyWnd, 1, FPortPollingDelay, nil );
  end;
end;
//------------------------------------------------------------------------------
const
  dcb_Binary              = $00000001;
  dcb_ParityCheck         = $00000002;
  dcb_OutxCtsFlow         = $00000004;
  dcb_OutxDsrFlow         = $00000008;
  dcb_DtrControlMask      = $00000030;
    dcb_DtrControlDisable   = $00000000;
    dcb_DtrControlEnable    = $00000010;
    dcb_DtrControlHandshake = $00000020;
  dcb_DsrSensivity        = $00000040;
  dcb_TXContinueOnXoff    = $00000080;
  dcb_OutX                = $00000100;
  dcb_InX                 = $00000200;
  dcb_ErrorChar           = $00000400;
  dcb_NullStrip           = $00000800;
  dcb_RtsControlMask      = $00003000;
    dcb_RtsControlDisable   = $00000000;
    dcb_RtsControlEnable    = $00001000;
    dcb_RtsControlHandshake = $00002000;
    dcb_RtsControlToggle    = $00003000;
  dcb_AbortOnError        = $00004000;
  dcb_Reserveds           = $FFFF8000;
//------------------------------------------------------------------------------
procedure TCommPortDriver.ApplyCOMSettings;
var dcb: TDCB;
begin
  if not Connected then exit;

  fillchar( dcb, sizeof(dcb), 0 );
  dcb.DCBLength := sizeof(dcb); // dcb structure size
  dcb.BaudRate := Win32BaudRates[ FPortBaudRate ]; // baud rate to use
  dcb.Flags := dcb_Binary or // Set fBinary: Win32 does not support non binary mode transfers
                             // (also disable EOF check)
               dcb_DtrControlEnable; // Enables the DTR line when the device is opened and leaves it on

  case FPortHwHandshaking of // Type of hw handshaking to use
    hhNONE:; // No hardware handshaking
    hhRTSCTS: // RTS/CTS (request-to-send/clear-to-send) hardware handshaking
      dcb.Flags := dcb.Flags or dcb_OutxCtsFlow or dcb_RtsControlHandshake;
  end;
  case FPortSwHandshaking of // Type of sw handshaking to use
    shNONE   :;                                             // No soft hand...
    shXONXOFF: dcb.Flags:=dcb.Flags or dcb_OutX or dcb_InX; // XON/XOFF hand...
  end;
  dcb.XONLim := FPortInBufSize div 4; // Specifies the minimum number of bytes allowed in
                                      // the input buffer before the XON character is sent
  dcb.XOFFLim := 1; // Specifies the maximum number of bytes allowed in the input buffer
                    // before the XOFF character is sent. The maximum number of bytes
                    // allowed is calculated by subtracting this value from the size,
                    // in bytes, of the input buffer
  dcb.ByteSize := ord(FPortDataBits); // how many data bits to use
  dcb.Parity := ord(FPortParity); // type of parity to use
  dcb.StopBits := ord(FPortStopbits); // how many stop bits to use
  dcb.XONChar := #17; // XON ASCII char
  dcb.XOFFChar := #19; // XOFF ASCII char
  SetCommState( FPortHandle, dcb );
  // Setup buffers size
  SetupComm( FPortHandle, FPortInBufSize, FPortOutBufSize );
end;
//------------------------------------------------------------------------------
function TCommPortDriver.BufferSize: Word;
begin
  Result:= FOffsetBuffer;
end;

function TCommPortDriver.Connect: boolean;
var s: RawByteString;
    tms: TCOMMTIMEOUTS;
begin
  Result := true;
  if Connected then exit;

  s:= FPort;
  FPortHandle := CreateFileA ( PAnsiChar(s),
                              GENERIC_READ or GENERIC_WRITE,
                              0,   // Not shared
                              nil, // No security attributes
                              OPEN_EXISTING,
                              FILE_ATTRIBUTE_NORMAL,// + $40000000 ,     //  FILE_FLAG_SESSION_AWARE
                              0    // No template
                            ) ;
  Result:=Connected;
  if not Result then exit;

  ApplyCOMSettings;
  // Setup timeouts: disable timeouts because polling the com port!
  tms.ReadIntervalTimeout := 1;
  tms.ReadTotalTimeoutMultiplier := 0;
  tms.ReadTotalTimeoutConstant := 1;
  tms.WriteTotalTimeoutMultiplier := 2;//0;
  tms.WriteTotalTimeoutConstant := 2;//0;

   SetCommTimeOuts( FPortHandle, tms );
  // Start the timer (used for polling)
  SetTimer( FNotifyWnd, 1, FPortPollingDelay, nil );
end;
//------------------------------------------------------------------------------
function TCommPortDriver.GetStatus: Integer;
var flag:Cardinal;
begin
  if connected then GetCommModemStatus(FPortHandle,flag)
               else Flag:=0;

  Result:= GetLastError;//Flag;
end;

function TCommPortDriver.GetState: Boolean;
var DCB: TDCB;
begin
  Result:= GetCommState(FPortHandle, DCB);
end;

function TCommPortDriver.GetProperties(var aCommProp: TCommProp): Boolean;
begin
  Result:= GetCommProperties(FPortHandle, aCommProp);
end;

function TCommPortDriver.GetConfig(var aCommConfig: TCommConfig; var aSize: Cardinal): Boolean;
begin
  Result:= GetCommConfig( FPortHandle, aCommConfig, aSize);
end;

//------------------------------------------------------------------------------
procedure TCommPortDriver.Disconnect;
begin
  if Connected then
  begin
    CloseHandle( FPortHandle );
    FPortHandle := 0;
    // Stop the timer (used for polling)
    KillTimer( FNotifyWnd, 1 );
  end else
  begin
    FPortHandle := 0;
  end;
end;
//------------------------------------------------------------------------------
function TCommPortDriver.Connected: boolean;
begin
  Result := (FPortHandle<>INVALID_HANDLE_VALUE) and (FPortHandle > 0);
end;
//------------------------------------------------------------------------------
function TCommPortDriver.ErrorConnected: Integer;
begin
  Result := FPortHandle;
end;
//------------------------------------------------------------------------------
function TCommPortDriver.SendData( DataPtr: pointer; DataSize: DWORD ): boolean;
var nsent: DWORD;
begin
  FCriticalSection.Enter;

  Result := WriteFile( FPortHandle, DataPtr^, DataSize, nsent, nil );
  Result := Result and (nsent=DataSize);

  FCriticalSection.Leave;
end;
//------------------------------------------------------------------------------
function TCommPortDriver.SendString( s: ansistring ): boolean;
begin
  Result := SendData( pansichar(s), length(s) );
end;
//------------------------------------------------------------------------------
procedure TCommPortDriver.TimerWndProc( var msg: TMessage );
var nRead : dword;
    i,j   : Integer;
begin
  if (msg.Msg = WM_TIMER) and (Connected) then
  begin
    FCriticalSection.Enter;

    nRead := 0;
    if ReadFile( FPortHandle,
                 Pointer(Cardinal(FInBuffer)+FOffsetBuffer)^,
                 FPortInBufSize-FOffsetBuffer,
                 nRead,
                 nil ) then
      if (nRead <> 0) and Assigned(FPortReceiveData) then
      begin
        if FEndByte=-1
        then begin FPortReceiveData( Self, FInBuffer, nRead ); end
        else begin Inc(FOffsetBuffer,nRead);
                   i:=0;
                   while i<=FOffsetBuffer-1 do
                   begin if Byte((Pointer(Integer(FInBuffer)+i))^)= FEndByte
                         then begin FPortReceiveData( Self, FInBuffer, i+1 );
                                    for j:=0 to (FOffsetBuffer-(i+1))-1 do
                                      Byte((Pointer(Integer(FInBuffer)+j    ))^):=
                                      Byte((Pointer(Integer(FInBuffer)+j+i+1))^);
                                    Dec(FOffsetBuffer,(i+1));
                                    i:=0;
                              end
                         else begin Inc(i);
                              end;
                   end;
             end;
      end;

    FCriticalSection.Leave;
  end;
end;
//------------------------------------------------------------------------------
procedure Register;
begin
  RegisterComponents('System', [TCommPortDriver]);
end;

end.
