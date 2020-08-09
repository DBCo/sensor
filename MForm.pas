unit MForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.JSON, Graphics, Math,
  XMLDoc, XMLIntf, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.StdCtrls,
  System.Generics.Collections, System.StrUtils, Vcl.Buttons, Winapi.CommCtrl, System.Actions, Vcl.ActnList, shellapi,
  System.UITypes, System.NetEncoding, myTypes, Version1, Version2, Version3, CommDrv, Elements, // MSHTML,
  TlHelp32, Vcl.OleCtrls, SHDocVw, Vcl.Imaging.GIFImg, Vcl.Imaging.pngimage;

const
  ipWellcome = 200;
  ipAddition = 201;
  ipDevice = 202;
  EmptyValue = #13#10#13#10#13#10;
  DefaultPassword = '123456';

  act_PasswordDo = 'PasswordDo';
  act_SettingsGet = 'SettingsGet';
  act_SettingsSet = 'SettingsSet';
  act_MemoryRead = 'MemoryRead';
  act_MemoryReadAll = 'MemoryReadAll';
  act_UpdateFirmware34 = 'UpdateFirmware34';
  act_FindSensors250 = 'FindSensors250';

  UpdateEmptyURL = 'http://usb.duotec.ru/info_application.php';
  UpdateDeviceURL = 'http://usb.duotec.ru/info_device.php?idsn=%s&type=%s&imei=%s&soft=%s';
  UpdateAdditionURL = 'http://ws.arusnavi.ru:8089/public-api/v1/device-types/configurations/current';
  UpdateJSONURL = 'http://ws.arusnavi.ru:8089/public-api/v1/device-types/%s/configuration/with-translations';

  // 'http://usb.duotec.ru/data.php?ver=%s&typ=%s&idd=%s';

  DBT_DEVNODES_CHANGED = $0007;
  ItemLangID = 100; // ID номер для пункта меню. Может быть любым
  ItemStyleID = 200; // ID номер для пункта меню. Может быть любым

  iZero = 0;
  iBlack = 1;
  iGreen = 2;
  iRed = 3;
  iGray = 4;

  stReady = 0;
  stAlien = 1;
  stConnected = 2;
  stError = 3;

  cUnknown = 0;
  cString = 1;
  cNumber = 2;
  cFlag = 3;
  cDictionary = 4;
  cButton = 5;

type
  TLang = Record
    ID: Integer;
    Name: String;
    Rect: TRect;
  end;

  TWndList = TList<HWnd>;

  PWindowSearch = ^TWindowSearch;

  TWindowSearch = record
    TargetProcessID: DWord;
    ResultList: TList<HWnd>;
  end;

  TStyle = Record
    ColorBack: TColor;
    ColorPanel: TColor;
    ColorShadow: TColor;
    ColorIndicator: TColor;
    ColorLabel: TColor;
    ColorValue: TColor;
    ColorValueError: TColor;
    ColorValueSelect: TColor;
    ColorValueEmpty: TColor;
    ColorSeparator: TColor;
    FontSize: Integer;
  end;

  TSetting = Record
    Alias: String;
    Default: String;
    Control: Integer;
    Number: Integer;
    VarType: TVarType;
    Min: Int64;
    Max: Int64;
    Bit: Integer;
    TextBefore: String;
    TextAfter: String;
    WinControl: TWinControl;
  end;

type
  TMoveStyle = (moveNone, MoveLeft, MoveRight, MoveBottom, moveCaption);

  TInfoPanel = class(TPanel)
  private
  protected
  public
    property Canvas;
  end;

  TDrawPanel = class(TPanel)
  private
    FOnPaint: TNotifyEvent;
  protected
    procedure Paint; override;
  public
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property Canvas;
  end;

  DevBroadcastIface = record
    dbcc_size: Integer;
    dbcc_devicetype: Integer;
    dbcc_reserved: Integer;
    dbcc_classguid: TGUID;
    dbcc_name: array [0 .. 128] of Char;
  end;

  PDevBroadcastIface = ^DevBroadcastIface;

  TPortInfo = class(TAction)
  private
    FActiveTime: TTime;
    FWaitInfo: Boolean;
    FPortName: String;
    FDeviceName: String;
    FDeviceVer: String;
    FDeviceIMEI: String;
    FDeviceSOFT: String;
    FDevicePID_VID: String;
    FHaveSettings: Boolean;
    FReadLocked: Integer;
    FDevicePassword: String;
    FUserPassword: String;
    FExist: Boolean;
    FCom: TCommPortDriver;
    FActive: Boolean;
    FSelected: Boolean;
    FStoped: Boolean;
    FOperation: Byte;
    procedure SetDeviceName(const Value: String);
    procedure SetDeviceVer(const Value: String);
    function GetDeviceVer: String;
    procedure SetDeviceIMEI(const Value: String);
    procedure SetDeviceSOFT(const Value: String);
    procedure SetActive(const Value: Boolean);
    procedure SetSelected(const Value: Boolean);
    procedure SetStoped(const Value: Boolean);
    procedure DoUpdateInfo;
    procedure SetDevicePassword(const Value: String);
    procedure SetOperation(const Value: Byte);
    function GetReadLocked: Boolean;
    function GetWriteLocked: Boolean;
    procedure SetUserPassword(const Value: String);
    procedure SetHaveSettings(const Value: Boolean);
    procedure SetReadLocked(const Value: Boolean);
  protected
    procedure SetVisible(Value: Boolean); override;
  public
    FMemoryWrite: Integer;
    FMemorySend1: Integer;
    FMemorySend2: Integer;
    FMemoryIndex: Integer;
    FMemoryCount: Integer;
    FMemoryOffset: Integer;
    FMemoryTime: TTime;
    FMemoryFile: String;
    FMemory: array of array [-1 .. 255] of Byte;
    FPanelO, FPanelI: TPanel;
    FLetters: TList<AnsiString>;
    procedure InnerSend;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateStyle;
    property PortName: string read FPortName write FPortName;
    property Com: TCommPortDriver read FCom write FCom;
    property DeviceName: String read FDeviceName write SetDeviceName;
    property DeviceVer: String read GetDeviceVer write SetDeviceVer;
    property DeviceIMEI: String read FDeviceIMEI write SetDeviceIMEI;
    property DeviceSOFT: String read FDeviceSOFT write SetDeviceSOFT;
    property DevicePID_VID: String read FDevicePID_VID write FDevicePID_VID;
    property DevicePassword: String read FDevicePassword write SetDevicePassword;
    property UserPassword: String read FUserPassword write SetUserPassword;
    property Active: Boolean read FActive write SetActive;
    property Selected: Boolean read FSelected write SetSelected;
    property Stoped: Boolean read FStoped write SetStoped;
    property Exist: Boolean read FExist write FExist;
    property Operation: Byte read FOperation write SetOperation;
    function WaitInfo: Boolean;
    property ReadLocked: Boolean read GetReadLocked write SetReadLocked;
    property WriteLocked: Boolean read GetWriteLocked;
    property HaveSettings: Boolean read FHaveSettings write SetHaveSettings;
    procedure SendAnsiString(aString: AnsiString);
  end;

  TPortInfoList = class(TList)
  private
    function Get(const Index: Integer): TPortInfo; overload;
  protected
    // procedure Notify(Ptr: pointer; Action: TListNotification); override;
  public
    FControlParent: TWinControl;
    property Items[const ID: Integer]: TPortInfo read Get; default;
    function New(aPortName: String): Integer;
    function IndexByName(Value: String): Integer;
    function PortCount: Integer;
  end;

  TCommand = Record
    Ident: String;
    NameEN: String;
    NameRU: String;
    Confirmation: Boolean;
    Show: Boolean;
    DeviceMin: Integer;
    DeviceMax: Integer;
    Send: AnsiString;
    Operation: Integer;
    function Caption: string;
    function Visible(aPortInfo: TPortInfo): Boolean;
    function Enabled(aPortInfo: TPortInfo): Boolean;
  end;

  TCommandList = TList<TCommand>;

  PHIDDAttributes = ^THIDDAttributes;

  HIDD_ATTRIBUTES = record
    Size: ULONG; // size of structure (set before call)
    VendorID: Word;
    ProductID: Word;
    VersionNumber: Word;
    // Additional fields will be added to the end of this structure.
  end;

  THIDDAttributes = HIDD_ATTRIBUTES;

type
  SP_DEVINFO_DATA = record
    cbSize: DWord;
    ClassGuid: TGUID;
    DevInst: DWord; // DEVINST handle
    Reserved: LongInt;
  end;

  PSP_DEVINFO_DATA = ^SP_DEVINFO_DATA;
  PGuid = ^TGUID;
  H_DEV = Pointer;

function SetupDiCreateDeviceInfoList(ClassGuid: PGuid; hwndParent: cardinal)
  : Pointer; stdcall; external 'setupapi.dll';
function SetupDiGetClassDevsExA(ClassGuid: PGuid; Enumerator: PChar;
  hwndParent: cardinal; Flags: DWord; DeviceInfoSet: Pointer;
  MachineName: PChar; Reserved: DWord): Pointer; stdcall;
  external 'setupapi.dll';
function SetupDiGetClassDevsA(ClassGuid: PGuid; Enumerator: PChar;
  hwndParent: cardinal; Flags: DWord): Pointer; stdcall;
  external 'setupapi.dll';
function SetupDiGetDeviceRegistryPropertyA(DeviceInfoSet: Pointer;
  DeviceInfoData: PSP_DEVINFO_DATA; Property_: DWord;
  PropertyRegDataType: Pointer; PropertyBuffer: Pointer;
  PropertyBufferSize: cardinal; RequiredSize: Pointer): longbool; stdcall;
  external 'setupapi.dll';
function SetupDiEnumDeviceInfo(DeviceInfoSet: Pointer; MemberIndex: DWord;
  var DeviceInfoData: SP_DEVINFO_DATA): longbool; stdcall;
  external 'setupapi.dll';
function SetupDiDestroyDeviceInfoList(DeviceInfoSet: Pointer): longbool;
  stdcall; external 'setupapi.dll';

type
  TMF = class(TForm)
    LPanel: TPanel;
    MainPanel: TPanel;
    btnInfo: TSpeedButton;
    BtnLog: TSpeedButton;
    InfoPanel: TPanel;
    PanelS1: TPanel;
    PanelS2: TPanel;
    PanelS3: TPanel;
    PanelS4: TPanel;
    LogPanel: TPanel;
    Panel9: TPanel;
    PanelL1: TPanel;
    PanelL2: TPanel;
    SendPanel: TPanel;
    Panel2: TPanel;
    PanelL3: TPanel;
    btn_Send: TSpeedButton;
    SendMemo: TMemo;
    btnShowHEX: TSpeedButton;
    btnShowTEXT: TSpeedButton;
    Panel17: TPanel;
    Panel16: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    btn_Clear: TSpeedButton;
    Panel24: TPanel;
    Panel26: TPanel;
    Panel31: TPanel;
    btn_Save: TSpeedButton;
    Splitter3: TSplitter;
    btn_Commands: TSpeedButton;
    Panel1: TPanel;
    CommandsPopupMenu: TPopupMenu;
    ActionList: TActionList;
    BtnCONFIG: TSpeedButton;
    SettingsPanel: TPanel;
    PanelT11: TPanel;
    act_PageInfo: TAction;
    act_PageLog: TAction;
    act_PageSettings: TAction;
    act_Clear: TAction;
    act_Save: TAction;
    SaveDialog: TSaveDialog;
    CheckNameTimer: TTimer;
    HideHint: TTimer;
    EmptyPanel: TPanel;
    Panel21: TPanel;
    Image1: TImage;
    Label_NoDevice: TLabel;
    DataTimer: TTimer;
    PanelT0: TPanel;
    Panel8: TPanel;
    Panel3: TPanel;
    Panel7: TPanel;
    PanelT2: TPanel;
    T1ScrollBox: TScrollBox;
    PanelT1: TPanel;
    OpenDialog1: TOpenDialog;
    act_SaveCFG: TAction;
    act_OpenCFG: TAction;
    act_SetCFG: TAction;
    Panel4: TPanel;
    Panel11: TPanel;
    Panel13: TPanel;
    Panel12: TPanel;
    Panel15: TPanel;
    InListView: TListView;
    Panel6: TPanel;
    SettingsToolsPanel: TPanel;
    btnSave: TSpeedButton;
    btnOpen: TSpeedButton;
    btnSet: TSpeedButton;
    Label_Password: TLabel;
    PasswordEdit: TEdit;
    SettingsPasswordPanel: TPanel;
    Panel10: TPanel;
    Panel14: TPanel;
    Panel18: TPanel;
    CaptionPanel: TPanel;
    CaptionLabel: TLabel;
    CloseButton: TSpeedButton;
    NormalizeButton: TSpeedButton;
    MinimizeButton: TSpeedButton;
    Panel22: TPanel;
    Panel25: TPanel;
    Panel27: TPanel;
    ButtonEN: TSpeedButton;
    ButtonRU: TSpeedButton;
    Panel28: TPanel;
    CaptionImage: TImage;
    BorderR: TPanel;
    BorderB: TPanel;
    BorderL: TPanel;
    PanelBTop: TPanel;
    LangLabel: TPanel;
    Panel35: TPanel;
    PageLabel: TPanel;
    DataLabel: TPanel;
    Panel23: TPanel;
    Panel36: TPanel;
    Panel37: TPanel;
    Panel30: TPanel;
    WellcomePanel: TPanel;
    UpdatePanel: TPanel;
    PanelWC: TPanel;
    btnWellcome: TSpeedButton;
    act_PageWellcome: TAction;
    Panel44: TPanel;
    UpdateProLabel2: TLabel;
    UpdateProLabel1: TLabel;
    Panel47: TPanel;
    act_UpdatePro: TAction;
    Panel45: TPanel;
    Panel46: TPanel;
    UpdateImage: TImage;
    UpdateBtnPanel: TPanel;
    UpdateProButton: TSpeedButton;
    Panel43: TPanel;
    Panel42: TPanel;
    WellcomeCaption: TLabel;
    WellcomeText: TLabel;
    Panel39: TPanel;
    act_UpdateModule: TAction;
    Panel33: TPanel;
    Panel40: TPanel;
    act_checkUpdate: TAction;
    EmptyImage: TImage;
    Timer1: TTimer;
    PanelWB: TPanel;
    BrowserPanel: TPanel;
    Panel51: TPanel;
    Panel38: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    FuelPanel: TPanel;
    PanelF1: TPanel;
    PanelF2: TPanel;
    PanelFF: TPanel;
    Panel49: TPanel;
    btnFuel: TSpeedButton;
    act_PageFuel: TAction;
    Panel34: TPanel;
    PathLabel: TLabel;
    Button5: TButton;
    Button6: TButton;
    ProgressPanel: TPanel;
    ProgressLabel: TLabel;
    PercentLabel: TLabel;
    btnShowEnter: TSpeedButton;
    Panel29: TPanel;
    WellcomeWebBrowser: TWebBrowser;
    LockedPanel: TPanel;
    mes_locked: TLabel;
    Panel5: TPanel;
    Panel32: TPanel;
    Panel41: TPanel;
    btnPlay: TSpeedButton;
    btnPause: TSpeedButton;
    Panel48: TPanel;
    Panel50: TPanel;
    Panel52: TPanel;
    Panel53: TPanel;
    OutByteCountLabel: TLabel;
    InByteCountLabel: TLabel;
    CommandList: TActionList;
    btnGet: TSpeedButton;
    act_GetCFG: TAction;
    act_debug: TAction;
    Button7: TButton;
    procedure ControlsLoadSettings(aVersion: String = '');
    procedure ControlsLoadMonitor;
    procedure QWaitData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
    procedure QOperationData1(const aIndex: Int64);
    procedure QOperationData2(const aIndex: Int64);
    procedure LogChange(var mes: TMessage); message WM_LOGNOTIFY;
    procedure QReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
    procedure InfoPanelResize(Sender: TObject);
    procedure LogPanelResize(Sender: TObject);
    procedure UpdateFolders(Sender: TObject);
    procedure InListViewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure UpdatePortListCOM;
    procedure UpdatePortListUSB;
    procedure ClearControlsRecursive(Sender: TObject);
    procedure act_PortExecute(Sender: TObject);
    procedure SetVersion(aVersion: TVersionType);
    procedure SetLanguageIndicator(aPosition: Integer = 0; aCount: Integer = 0);
    procedure SetLanguage(aLanguage: Integer);
    procedure SetHEX(aHEX: Boolean);
    procedure btnShowHEXClick(Sender: TObject);
    procedure btnShowTEXTClick(Sender: TObject);
    procedure InListViewResize(Sender: TObject);
    procedure btn_SendClick(Sender: TObject);
    procedure Splitter3CanResize(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
    procedure InListViewDblClick(Sender: TObject);
    procedure Commands_Do(N: Integer);
    function Commands_Exec(aName: String): Boolean;
    procedure Commands_New(aIdent: String; aDeviceMin: Integer;
      aDeviceMax: Integer; aSend: AnsiString; aOperation: Integer = 0;
      aConfirmation: Boolean = False; aShow: Boolean = True);
    procedure Commands_Fill(Sender: TObject);
    procedure Commands_Update(Sender: TObject);
    procedure Commands_MenuClick(Sender: TObject);
    procedure btn_CommandsClick(Sender: TObject);
    procedure act_PageInfoExecute(Sender: TObject);
    procedure act_PageLogExecute(Sender: TObject);
    procedure act_PageSettingsExecute(Sender: TObject);
    procedure act_ClearExecute(Sender: TObject);
    procedure act_SaveExecute(Sender: TObject);
    // procedure FormResize(Sender: TObject);
    procedure CheckNameTimerTimer(Sender: TObject);
    procedure MainHintShow(aType: Integer; aText: string);
    procedure MainHintHide(Sender: TObject);
    function ConfigToString: String;
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);
    procedure PanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DataTimerTimer(Sender: TObject);
    procedure SettingsPanelResize(Sender: TObject);
    procedure PanelT2Click(Sender: TObject);
    procedure act_SaveCFGExecute(Sender: TObject);
    procedure act_OpenCFGExecute(Sender: TObject);
    procedure act_SetCFGExecute(Sender: TObject);
    procedure PasswordChanged(Sender: TObject);
    procedure PasswordEditChange(Sender: TObject);
    procedure btnSpeedMouseEnter(Sender: TObject);
    procedure btnSpeedMouseLeave(Sender: TObject);
    procedure CaptionPanelDblClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure MinimizeButtonClick(Sender: TObject);
    procedure NormalizeButtonClick(Sender: TObject);
    procedure ButtonRUClick(Sender: TObject);
    procedure ButtonENClick(Sender: TObject);
    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BorderBMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BorderBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BorderBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BorderRMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BorderRMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BorderRMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BorderLMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BorderLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BorderLMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure UpdateBrowser(Sender: TObject);
    procedure act_PageWellcomeExecute(Sender: TObject);
    procedure act_UpdateProExecute(Sender: TObject);
    procedure act_UpdateModuleExecute(Sender: TObject);
    procedure act_checkUpdateExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure act_PageFuelExecute(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure PathLabelMouseEnter(Sender: TObject);
    procedure PathLabelMouseLeave(Sender: TObject);
    procedure PathLabelClick(Sender: TObject);
    procedure btnShowEnterClick(Sender: TObject);
    procedure InListViewClick(Sender: TObject);
    procedure actPlayExecute(Sender: TObject);
    procedure actPauseExecute(Sender: TObject);
    procedure act_GetCFGExecute(Sender: TObject);
    procedure act_debugExecute(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    FErrors: array [0 .. 255] of string;
    FCurrentError: Integer;
    FIsMove: TMoveStyle;
    FPos, FMove: TPoint;
    FLanguage: Integer;
    FUpdateVersion: TDateTime;
    FUpdateModule: String;
    FUpdateProURL: String;
    FUpdateSettingsURL: String;
    FPortIndex: Integer;
    FVersion: TVersionType;
    FSettingsReady: Boolean;
    FHEX: Boolean;
    FShowEnter: Boolean;
    FFollow: Boolean;
    FInfoPanel: TInfoPanel;
    FConfigPassword: AnsiString;
    FCanShowSettings: Boolean;
    FBrowserURL: String;
    FBrowsed: Boolean;

    procedure SetPortIndex(const Value: Integer);
    procedure OnDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure UpdateTitle;
    procedure SetShowEnter(const Value: Boolean);
    procedure SetFollow(const Value: Boolean);
    procedure SetBrowserURL(const Value: string);
    { Private declarations }
  public
    QList: TPortInfoList;
    FWellcomeFile: String;
    FAdditionFile: String;
    FDeviceFile: String;
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StyleApply;
    procedure UpdateWellcome;
    // procedure
    procedure InfoExternal(var mes: TMessage); message WM_INFONOTIFY;
    function VisualFind(const aParent: TWinControl; const aName: String; var aControl: TObject): Boolean; overload;
    function VisualFind(const aParent: TWinControl; const aID: Integer; var aControl: TObject): Boolean; overload;
    function VisualSetValue(aName: String; aValue: Variant; aColor: TColor = _Green; aValueAlter: String = ''): Boolean;
    property Language: Integer read FLanguage write SetLanguage;
    property UpdateProURL: String read FUpdateProURL write FUpdateProURL;
    property Version: TVersionType read FVersion write SetVersion;
    property HEX: Boolean read FHEX write SetHEX;
    property ShowEnter: Boolean read FShowEnter write SetShowEnter;
    property Follow: Boolean read FFollow write SetFollow;
    property PortIndex: Integer read FPortIndex write SetPortIndex;
    property ConfigPassword: AnsiString read FConfigPassword write FConfigPassword;
    function Q: TPortInfo;
    property SettingsReady: Boolean read FSettingsReady write FSettingsReady;
    procedure SettingsError(const Index: Integer; const Value: String);
    property BrowserURL: string read FBrowserURL write SetBrowserURL;
  end;

var
  Langs: Array of TLang;
  MF: TMF;
  MS: TMemoryStreamEx;
  FInCount, FOutCount: Int64;
  FInSource: TPacketArray;
  FInStart: Integer;
  FInPacketV1: TPacketArray;
  FInPacketV2: TPacketArray;
  FInPacketV3: TPacketArray;
  PInPacket: PPacketArray;
  ColorB, ColorT, ColorH: TColor;
  sVersion: TDate;
  FWellcomeUpdateThread, FAdditionUpdateThread, FDeviceUpdateThread : TUpdateThread;
  FTabPanel: TTabPanel;
  _Style, StyleA, StyleB: TStyle;
  z: Array of TSetting;
  BeConnected: Boolean;
  DataDir: String;
  FDataFile: TMemoryStreamEx;
  FCommandList: TCommandList;
  Tabs: Array of TTabPanel;

implementation

uses Dictionary;
{$R *.dfm}
// ......................................................................................................................

procedure ClearPanel(aParent: TWinControl);
begin
  while 0 < aParent.ControlCount do
    aParent.Controls[Pred(aParent.ControlCount)].Free;
  aParent.Repaint;
end;

// ......................................................................................................................

procedure TMF.UpdateTitle;
var
  s: String;
  FIcon: TIcon;
begin
  s := Translate(FLanguage, 'ApplicationCaption');
  if Q = nil then
    Caption := s
  else if Length(Q.DeviceName) = 0 then
    Caption := s
  else
    Caption := Q.DeviceName + ' - ' + s;
  CaptionLabel.Caption := Caption;

  FIcon := TIcon.Create;
  FIcon.Handle := LoadImage(hInstance, PChar('I_MINIMIZE'), IMAGE_ICON, 16, 16,
    LR_SHARED);
  MinimizeButton.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, PChar('I_NO'), IMAGE_ICON, 16, 16,
    LR_SHARED);
  CloseButton.Glyph.Assign(FIcon);
  if WindowState = wsMaximized then
    FIcon.Handle := LoadImage(hInstance, PChar('I_NORMALIZE'), IMAGE_ICON, 16,
      16, LR_SHARED)
  else
    FIcon.Handle := LoadImage(hInstance, PChar('I_MAXIMIZE'), IMAGE_ICON, 16,
      16, LR_SHARED);
  NormalizeButton.Glyph.Assign(FIcon);

  FIcon.Free;
end;

procedure TMF.InListViewClick(Sender: TObject);
begin
  Follow := False;
  inherited;
end;

procedure TMF.InListViewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  sTime: string;
  sData: string;
  i, _Index, _Left, _Top: Integer;
begin
  _Index := Item.Index;
  _Left := Item.DisplayRect(drLabel).Left;
  _Top := Item.DisplayRect(drLabel).Top;

  // InListView.Canvas.FillRect(Item.DisplayRect(drLabel));
  if PInPacket^[_Index].State = 255 then
    sTime := 'PC > DEVICE'
  else
    DateTimeToString(sTime, 'hh:mm:ss.zzz', PInPacket^[_Index].Time);
  {
    if (_Index = 0) or (PInPacket^[_Index].Time <> PInPacket^[_Index-1].Time)
    then DateTimeToString(sTime, 'hh:mm:ss.zzz', PInPacket^[_Index].Time)
    else sTime:=                 '            ';
    { }

  sData := '';
  if HEX then
    for i := 0 to Pred(PInPacket^[_Index].Size) do
      sData := sData + IntToHex(TByteArray(MS.Memory^)[PInPacket^[_Index].Position + i], 2) + ' '
  else
  begin
    for i := 0 to Pred(PInPacket^[_Index].Size) do
      sData := sData + Char(TByteArray(MS.Memory^)[PInPacket^[_Index].Position + i]);
    if ShowEnter then
      sData := StringReplace(sData, #13#10, '¶', []);
  end;

  // Sender.Canvas.Font.Size := 9;
  // Sender.Canvas.Font.Name := 'Courier';

  if _Index = Sender.ItemIndex then
  begin
    Sender.Canvas.Font.Color := MF.Font.Color;
    Sender.Canvas.TextOut(_Left, _Top, '►');
    // Sender.Canvas.Rectangle(Rect(_Left, _Top, 500, 20) );//_Left, _Top, Item.DisplayRect(drLabel).Top);
  end
  else
  begin
    if FInSource[FInStart].Position > PInPacket^[_Index].Position then
      Sender.Canvas.Font.Color := clGray
    else
      Sender.Canvas.Font.Color := PInPacket^[_Index].Color
  end;

  // if Colored then InListView.Canvas.Font.Color:= clSilver;
  Sender.Canvas.TextOut(_Left + 10, _Top + 1, sTime);

  // if Colored then InListView.Canvas.Font.Color:= clGreen;
  Sender.Canvas.TextOut(_Left + 120, _Top + 1, sData);

  DefaultDraw := False;
end;

procedure TMF.InListViewDblClick(Sender: TObject);
var
  i: Integer;
  sData: String;
begin
  sData := '';
  if -1 < InListView.ItemIndex then
  begin
    if HEX then
      for i := 0 to Pred(PInPacket^[InListView.ItemIndex].Size) do
        sData := sData + IntToHex(TByteArray(MS.Memory^)
          [PInPacket^[InListView.ItemIndex].Position + i], 2) + ' '
    else
    begin
      for i := 0 to Pred(PInPacket^[InListView.ItemIndex].Size) do
        sData := sData + Char(TByteArray(MS.Memory^)
          [PInPacket^[InListView.ItemIndex].Position + i]);
      sData := StringReplace(sData, #13#10, '¶', []);
    end;
  end;
  SendMemo.Text := sData;
end;

procedure TMF.InListViewResize(Sender: TObject);
begin
  InListView.Columns[0].Width := InListView.ClientWidth - 50;
end;

procedure TMF.btn_SendClick(Sender: TObject);
begin
  Q.SendAnsiString(SendMemo.Text + #13#10);
end;

procedure TMF.Button5Click(Sender: TObject);
begin
  _Style := StyleA;
  StyleApply;
end;

procedure TMF.Button6Click(Sender: TObject);
begin
  _Style := StyleB;
  StyleApply;
end;

procedure TMF.Button7Click(Sender: TObject);
begin {
    QList[FPortIndex].FCom.Disconnect;
    QList[FPortIndex].FCom.PortSpeed:= br19200;
    QList[FPortIndex].FCom.Connect;  { }
  QList[FPortIndex].DeviceVer := '250';
  QList[FPortIndex].DevicePassword:= '123456';
  Version:= vtVersion3;
end;

function TMF.ConfigToString: String;
var
  aControl: TObject;
  i, k, L, CRC: Word;
  V: Variant;
  B: TBytes;
  _VarType: TVarType;
  _AnsiString: AnsiString;
  _Byte: Byte;
  _ShortInt: ShortInt absolute _Byte;
  _Word: Word;
  _SmallInt: SmallInt absolute _Word;
  _LongWord: LongWord;
  _Integer: Integer absolute _LongWord;
begin
  SetLength(B, 4);

  for k := 1 to 255 do
    try
      V := 0;
      _VarType := varEmpty;

      for i := Low(z) to High(z) do
        if (z[i].Number = k) then
          if VisualFind(self, z[i].Alias, aControl) then
          begin
            _VarType := z[i].VarType;
            if (aControl is TFlagClass) and (-1 < z[i].Bit) then
              V := V + (TFlagClass(aControl).Value shl z[i].Bit)
            else
              V := TControlClass(aControl).Value;
          end;

      if Not VarIsNull(V) and Not VarIsEmpty(V) and TControlClass(aControl).IsSet
      then
        case _VarType of
          VarString:
            begin
              _AnsiString := V;
              // Если пароль пустой и очень длинный, то его не передаем
              if (k <> 5) or ((0 < Length(_AnsiString)) and
                (Length(_AnsiString) < 7)) then
              begin
                L := Length(B);
                SetLength(B, L + 3 + Length(_AnsiString));
                B[L] := ORD('#');
                B[L + 1] := k;
                B[L + 2] := Length(_AnsiString);
                for i := 1 to Length(_AnsiString) do
                  B[L + 2 + i] := ORD(_AnsiString[i]);
              end;
            end;
          VarByte, varShortInt:
            begin
              L := Length(B);
              SetLength(B, L + 3 + 1);
              if _VarType=VarByte then _Byte:= V
                                  else _ShortInt:= V;
              B[L] := ORD('#');
              B[L + 1] := k;
              B[L + 2] := 1;
              B[L + 3] := _Byte;
              Move(_Byte, B[L + 3], 1);
            end;
          VarWord, VarSmallInt :
            begin
              L := Length(B);
              SetLength(B, L + 3 + 2);
              if _VarType=VarWord then _Word:= V
                                  else _SmallInt:= V;
              B[L] := ORD('#');
              B[L + 1] := k;
              B[L + 2] := 2;
              B[L + 3] := _Word div 256;
              B[L + 4] := _Word mod 256;
            end;
          varLongWord, VarInteger:
            begin
              L := Length(B);
              SetLength(B, L + 3 + 4);
              if _VarType = varLongWord then _LongWord:= V
                                        else _Integer:= V;
              B[L] := ORD('#');
              B[L + 1] := k;
              B[L + 2] := 4;
              B[L + 3] := (_LongWord div 16777216);
              B[L + 4] := (_LongWord div 65536) mod 256;
              B[L + 5] := (_LongWord div 256) mod 256;
              B[L + 6] := (_LongWord) mod 256;
            end;
        end;
    except
    end;

  if 0 < Length(B) then
  begin
    CRC := CRC16CCITT(B, 4, High(B));
    B[0] := (Length(B) - 4) div 256;
    B[1] := (Length(B) - 4) mod 256;
    B[2] := CRC div 256;
    B[3] := CRC mod 256;
  end;

  result := EncodeBase64(B)
end;

procedure TMF.act_SetCFGExecute(Sender: TObject);
var
  aControl1, aControl2, aControl3, aControl4, aControl5: TObject;
  s,t: AnsiString;
  i: Integer;
begin
  if 0 = Length(PasswordEdit.Text) then
  begin
    PasswordEdit.SetFocus;
    MF.MainHintShow(0, Translate(MF.Language, 'mes_passwordempty'));
    Exit;
  end;

  if Q.FDeviceVer <> '250' then
    begin
      s := ConfigToString;
      if 0 = Length(s) then
        MF.MainHintShow(0, Translate(MF.Language, 'mes_settingsempty'))
      else
      begin
        if Q.DeviceVer = '5' then
          Q.SendAnsiString('settings set ' + s + #13#10)
        else
          Q.SendAnsiString(PasswordEdit.Text + '*CONF*' + s + #13#10);
      end;
    end;

  if Q.FDeviceVer = '250' then
    begin
      for i:=1 to 3 do
        if VisualFind(self, 'master_'+IntToStr(i)+'_1', aControl1) and
           VisualFind(self, 'master_'+IntToStr(i)+'_2', aControl2) and
           VisualFind(self, 'master_'+IntToStr(i)+'_3', aControl3) then
           begin
             if TControlClass(aControl1).Changed or TControlClass(aControl2).Changed or
                TControlClass(aControl3).Changed then
                begin
                  s:= #49#16#178 + AnsiChar(Pred(i)) +
                      ReverseAnsiStr(copy(HexToStr(AnsiString(TStringClass(aControl1).Value))+#0#0#0#0#0#0,1,6)) +
                      AnsiChar(Byte(TIntegerClass(aControl2).Value)) +
                      AnsiChar(Byte(TListClass(aControl3).Value)) + #0#0#0#0#0#0#0#0;
                  Q.SendAnsiString(MasterCRC(s));
                end;
           end;

      for i:=1 to 3 do
        if VisualFind(self, 'sensor_'+IntToStr(i)+'_4', aControl1) and
           VisualFind(self, 'sensor_'+IntToStr(i)+'_5', aControl2) and
           VisualFind(self, 'sensor_'+IntToStr(i)+'_6', aControl3) and
           VisualFind(self, 'sensor_'+IntToStr(i)+'_7', aControl4) and
           VisualFind(self, 'sensor_'+IntToStr(i)+'_8', aControl5) then
           begin
             if TControlClass(aControl1).Changed or TControlClass(aControl2).Changed or
                TControlClass(aControl3).Changed or TControlClass(aControl4).Changed or
                TControlClass(aControl5).Changed then
                begin
                  s:= #49#16#181 + AnsiChar(Pred(i))+
                      ByteToStr(TIntegerClass(aControl1).Value) +
                      WordToStr(TIntegerClass(aControl2).Value) +
                      WordToStr(TIntegerClass(aControl3).Value) +
                      CardinalToStr(TIntegerClass(aControl4).Value) +
                      CardinalToStr(TIntegerClass(aControl5).Value) + #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0;
                  Q.SendAnsiString(MasterCRC(s));
                end;
           end;
    end;
end;

procedure TMF.act_GetCFGExecute(Sender: TObject);
begin
  Commands_Exec(act_SettingsGet);
end;

procedure TMF.act_SaveCFGExecute(Sender: TObject);
var
  F: TextFile;
  s: string;
begin
  begin
    SaveDialog.InitialDir := GetCurrentDir;
    SaveDialog.DefaultExt := '*.cfg';
    SaveDialog.FilterIndex := 3;
    SaveDialog.FileName := Q.DeviceName + '.cfg';
    if SaveDialog.Execute then
      try
        AssignFile(F, SaveDialog.FileName);
        Rewrite(F);
        s := ConfigToString;
        Write(F, s);
        CloseFile(F);
        MF.MainHintShow(1, Translate(MF.Language, 'mes_filesave'));
      except
        MF.MainHintShow(0, Translate(MF.Language, 'mes_filesaveerror'));
      end;
  end;
end;

procedure TMF.act_OpenCFGExecute(Sender: TObject);
var
  F: TextFile;
  s: string;
  bytes: TBytes;
  i, j, CC, LL, P: Integer;
  V: Variant;
  _Byte: Byte;
  _ShortInt: ShortInt absolute _Byte;
  _Word: Word;
  _SmallInt: SmallInt absolute _Word;
  _LongWord: LongWord;
  _Integer: Integer absolute _LongWord;
begin
  begin
    OpenDialog1.InitialDir := GetCurrentDir;
    OpenDialog1.FilterIndex := 1;
    OpenDialog1.DefaultExt := '.cfg';
    if OpenDialog1.Execute then
      try
        AssignFile(F, OpenDialog1.FileName);
        Reset(F);
        Read(F, s);
        CloseFile(F);

        try
          bytes := TBase64Encoding.Base64.DecodeStringToBytes(s);

          P := 4;
          while P < Length(bytes) do
          begin
            CC := bytes[P + 1];
            LL := bytes[P + 2];
            if bytes[P] = $23 then
            begin
              for i := Low(z) to High(z) do
                if z[i].Number = CC then
                begin
                  V := unassigned;
                  case z[i].VarType of
                    VarByte:
                      V := bytes[P + 3];
                    VarWord:
                      V := 256 * bytes[P + 3] + bytes[P + 4];
                    varLongWord:
                      V := 16777216 * bytes[P + 3] + 65536 * bytes[P + 4] + 256 * bytes[P + 5] + bytes[P + 6];
                    VarShortInt:
                      begin _Byte:= bytes[P + 3]; V:= _ShortInt; end;
                    VarSmallInt:
                      begin _Word:= 256 * bytes[P + 3] + bytes[P + 4]; V:=_SmallInt; end;
                    varInteger:
                      begin _LongWord := 16777216 * bytes[P + 3] + 65536 * bytes[P + 4] + 256 * bytes[P + 5] + bytes[P + 6]; V:=_Integer; end;

                    VarString:
                      begin
                        V := '';
                        for j := 0 to Pred(LL) do
                          V := V + Char(bytes[P + 3 + j]);
                        if CC = 5 then
                          MF.ConfigPassword := V;
                      end;
                  end;
                  if (-1 < z[i].Bit) and
                    (z[i].VarType in [VarByte, VarWord, varLongWord]) then
                    if (V and (1 shl z[i].Bit)) = 0 then
                      V := 0
                    else
                      V := 1;

                  MF.VisualSetValue(z[i].Alias, V);
                end;
            end;
            P := P + LL + 3;
          end;
          MF.MainHintShow(1, Translate(MF.Language, 'mes_fileopen'));
        except

          MF.MainHintShow(0, Translate(MF.Language, 'mes_filedataerror'));
        end;

      except
        MF.MainHintShow(0, Translate(MF.Language, 'mes_fileopenerror'));
      end;
  end;
end;

procedure TMF.act_UpdateProExecute(Sender: TObject);
var
  sUpdate, sBack, sDataDir, sAppName: String;
  ErrorCode: Integer;
  IsStopped: Boolean;
begin
  sAppName := ExtractFileName(Application.ExeName);

  sDataDir := StringReplace(GetDOSEnvVar('AppData'), #0, '', [rfReplaceAll]);
  if (0 < Length(sDataDir)) and (sDataDir[Length(sDataDir)] = #0) then
    Delete(sDataDir, Length(sDataDir), 1);
  sDataDir := sDataDir + PathDelim + ApplicationName;
  ForceDirectories(sDataDir);

  sBack := sDataDir + PathDelim + FormatDateTime('dd.mm.yyyy', sVersion) + '_'
    + sAppName;
  sUpdate := sDataDir + PathDelim + 'update_' + sAppName;
  if fileExists(sUpdate) then
    DeleteFile(sUpdate);

  if GetInetFile(UpdateProURL, sUpdate) then
  begin
    if -1 < PortIndex then
    begin
      IsStopped := Q.Stoped;
      Q.Stoped := True;
    end;

    ErrorCode := ShellExecute(0, nil, PChar(sUpdate), '', nil, SW_SHOWNORMAL);

    if HINSTANCE_ERROR < ErrorCode then
    begin
      Application.Minimize;
      MoveFile(PChar(Application.ExeName), PChar(sBack));
      MoveFile(PChar(sUpdate), PChar(Application.ExeName));
      Close;
    end
    else
    begin
      if -1 < PortIndex then
        Q.Stoped := IsStopped;
      if fileExists(sUpdate) then
        DeleteFile(sUpdate);
    end;
  end
  else
  begin
    if fileExists(sUpdate) then
      DeleteFile(sUpdate);
  end;
  UpdateWellcome;
end;

procedure TMF.act_UpdateModuleExecute(Sender: TObject);
var
  fn: string;
  i, N: Integer;
  intFileAge: LongInt;
  JO: TJSONObject;
  JUpdates: TJSONArray;
  fs: TFormatSettings;
  DateTimeU, DateTimeF: TDateTime;
begin
  if 0 < Length(FAdditionFile) then
    try

      JO := TJSONObject.ParseJSONValue(FAdditionFile) as TJSONObject;
      if Assigned(JO) then
        try
          fs := TFormatSettings.Create;
          fs.DateSeparator := '-';
          fs.ShortDateFormat := 'yyyy-MM-dd';
          fs.TimeSeparator := ':';
          fs.ShortTimeFormat := 'hh:mm';
          fs.LongTimeFormat := 'hh:mm:ss';

          FUpdateModule := '';

          JUpdates := TJSONArray((JO as TJSONObject).GetValue('data'));
          for i := 0 to Pred(JUpdates.Count) do
            try
              N := StrToIntDef((JUpdates.Items[i] as TJSONObject).Values['deviceTypeId'].Value, 0);
              DateTimeU := StrToDateTime((JUpdates.Items[i] as TJSONObject).Values['createdAt'].Value, fs);
              fn := DataDir + IntToStr(N) + '.json';
              if fileExists(fn) then
              begin
                intFileAge := FileAge(fn);
                if intFileAge = -1 then
                  DateTimeF := 0
                else
                  DateTimeF := FileDateToDateTime(intFileAge)
              end
              else
                DateTimeF := 0;

         //     if (sVersion < DateTimeU) then
          //      if (DateTimeF < DateTimeU) or (DateTimeF = 0) then
                begin
                  if GetInetFile(Format(UpdateJSONURL, [IntToStr(N)]), fn + '.download') then
                  begin
                    if fileExists(fn) then
                      DeleteFile(fn);
                    SetFileDateTime(fn + '.download', DateTimeU);
                    RenameFile(fn + '.download', fn);
                    if not(Q = nil) then
                      if 0 < Length(Q.DeviceVer) then
                        if Q.DeviceVer = IntToStr(N) then
                          ControlsLoadSettings(Q.DeviceVer);
                  end;
                end;
            finally
            end;

        finally
        end;

    except
    end;
  UpdateWellcome;
end;

procedure TMF.btnSpeedMouseEnter(Sender: TObject);
var
  FIcon: TIcon;
begin
  FIcon := TIcon.Create;
  with TSpeedButton(Sender) do
  begin
    FIcon.Handle := LoadImage(hInstance,
      PChar(IcoPrefix(Enabled) + Copy(Name, 4, MaxInt)), IMAGE_ICON, 16, 16, LR_SHARED);
    Glyph.Assign(FIcon);
    Caption := TSpeedButton(Sender).Hint;
  end;
end;

procedure TMF.btnSpeedMouseLeave(Sender: TObject);
var
  FIcon: TIcon;
begin
  FIcon := TIcon.Create;
  with TSpeedButton(Sender) do
  begin
    FIcon.Handle := LoadImage(hInstance,
      PChar(IcoPrefix(Enabled and ShowHint) + Copy(Name, 4, MaxInt)), IMAGE_ICON, 24, 24, LR_SHARED);
    Glyph.Assign(FIcon);
    Caption := '';
  end;
end;

procedure TMF.btnShowEnterClick(Sender: TObject);
begin
  ShowEnter := not ShowEnter;
end;

procedure TMF.btnShowHEXClick(Sender: TObject);
begin
  HEX := True;
end;

procedure TMF.btnShowTEXTClick(Sender: TObject);
begin
  HEX := False;
end;

procedure TMF.act_checkUpdateExecute(Sender: TObject);
begin
  UpdateWellcome;
end;

procedure TMF.act_ClearExecute(Sender: TObject);
begin
  SetLength(FInSource, 0);
  SetLength(FInPacketV1, 0);
  SetLength(FInPacketV2, 0);
  SetLength(FInPacketV3, 0);
  FInCount := 0;
  FOutCount := 0;
  FInStart := 0;
  VisualSetValue('InByteCount', unassigned);
  VisualSetValue('OutByteCount', unassigned);
 // InListView.Clear;
  Follow := True;
end;

procedure TMF.act_debugExecute(Sender: TObject);
begin
  act_PageFuel.Visible := not act_PageFuel.Visible;
end;

procedure TMF.act_SaveExecute(Sender: TObject);
var
  F: TextFile;
  i, N: Integer;
  sTime, sData: String;
begin
  if (Q = nil) then
    Exit;

  SaveDialog.FilterIndex := 1;
  SaveDialog.DefaultExt := '*.log';
  SaveDialog.FileName := Q.DeviceName + ' ' + DateToStr(Now()) + ' ' +
    StringReplace(TimeToStr(Now()), ':', '-', [rfReplaceAll]);
  if SaveDialog.Execute(Handle) then
  begin
    AssignFile(F, SaveDialog.FileName);
    Rewrite(F);

    for N := 0 to Pred(Length(PInPacket^)) do
    begin
      if PInPacket^[N].State = 255 then
        sTime := 'PC > DEVICE'
      else
        DateTimeToString(sTime, 'hh:mm:ss.zzz', PInPacket^[N].Time);
      {
        if (N = 0) or (PInPacket^[N].Time <> PInPacket^[N-1].Time)
        then DateTimeToString(sTime, 'hh:mm:ss.zzz', PInPacket^[N].Time)
        else sTime:= '            ';
        { }
      sData := '';
      if HEX then
        for i := 0 to Pred(PInPacket^[N].Size) do
          sData := sData + IntToHex(TByteArray(MS.Memory^)
            [PInPacket^[N].Position + i], 2) + ' '
      else
      begin
        for i := 0 to Pred(PInPacket^[N].Size) do
          sData := sData + Char(TByteArray(MS.Memory^)
            [PInPacket^[N].Position + i]);
        sData := StringReplace(sData, #13#10, '', []); // '¶'
      end;

      WriteLN(F, sTime + #9 + sData);
    end;

    CloseFile(F);
  end;
end;

procedure TMF.Commands_Do(N: Integer);
begin
  if (Q = nil) then
    Exit;

  if (Q.FReadLocked = -1) then
    Q.SendAnsiString(Q.FUserPassword + #13#10)
  else if (Q.FReadLocked = 1) then
    Exit
  else if 0 < FCommandList[N].Operation then
    Q.Operation := FCommandList[N].Operation
  else
    Q.SendAnsiString(FCommandList[N].Send);
end;

function TMF.Commands_Exec(aName: String): Boolean;
var
  i: Integer;
begin
  result := False;
  for i := 0 to Pred(FCommandList.Count) do
    if FCommandList[i].Ident = aName then
      if FCommandList.Items[i].Enabled(Q) then
      begin
        Commands_Do(i);
        Break;
      end;
end;

procedure TMF.Commands_MenuClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    Commands_Do(TMenuItem(Sender).Tag);
end;

procedure TMF.Commands_New(aIdent: String; aDeviceMin: Integer;
  aDeviceMax: Integer; aSend: AnsiString; aOperation: Integer = 0;
  aConfirmation: Boolean = False; aShow: Boolean = True);
var
  C: TCommand;
  P: Integer;
begin
  P := Pos('|', aIdent);
  if aIdent = '-' then
  begin
    C.Ident := '';
    C.NameRU := aIdent;
    C.NameEN := aIdent;
  end
  else if P = 0 then
  begin
    C.Ident := aIdent;
    C.NameRU := Translate(0, aIdent);
    C.NameEN := Translate(1, aIdent);
  end
  else
  begin
    C.Ident := '';
    C.NameRU := Copy(aIdent, 1, P - 1);
    C.NameEN := Copy(aIdent, P + 1, MaxInt);
  end;

  C.Confirmation := aConfirmation;
  C.Show := aShow;
  C.DeviceMin := aDeviceMin;
  C.DeviceMax := aDeviceMax;
  C.Send := aSend;
  C.Operation := aOperation;
  FCommandList.Add(C);
end;

procedure TMF.Commands_Fill(Sender: TObject);
begin
  if -1 < PortIndex then
    Commands_New(act_PasswordDo, 5, 5, QList[PortIndex].FUserPassword + #13#10, 0, False, False);
  Commands_New('-', 0, 255, '');
  Commands_New('act_Reboot',            5,   5, 'restart' + #13#10);
  Commands_New('act_Reboot',            6, 249, '>D 1' + #13#10);
  Commands_New('act_Reboot',          250, 250, MasterCRC(#49#16#183#00#01));

  Commands_New('-', 0, 255, '');
  Commands_New('act_UpdateSoftLocal',   5,   5, 'upgrade extflash' + #13#10);
  Commands_New('act_UpdateSoftLocal',   6,  33, '>D 3;0' + #13#10);
  Commands_New(act_UpdateFirmware34,   34,  34, '', 1);
  Commands_New('act_UpdateSoftLocal',  35, 249, '>D 3;0' + #13#10);
  Commands_New('act_UpdateSoftWEB',     5,   5, 'webconf getfw' + #13#10);
  Commands_New('act_UpdateSoftWEB',     6, 249, '>D 2;0' + #13#10);
  Commands_New('act_UpdateSettingsWEB', 5,   5, 'webconf getconf' + #13#10);
  Commands_New('act_UpdateSettingsWEB', 6, 249, '>D 0;0' + #13#10);

  Commands_New('-', 0, 255, '');
  Commands_New(act_MemoryRead,         33,  33, '', 2);
  Commands_New(act_MemoryRead,        213, 213, '', 2);
  Commands_New(act_MemoryReadAll,      33,  33, '', 3);
  Commands_New(act_MemoryReadAll,     213, 213, '', 3);

  Commands_New('act_EraseExternalMemory', 5,   5, 'storage clear' + #13#10);
  Commands_New('act_EraseExternalMemory', 6, 249, '>D 8;0' + #13#10);

  Commands_New('-', 0, 255, '');
  Commands_New(act_SettingsGet, 5, 5, 'settings get' + #13#10, 0, False, False);
  Commands_New(act_SettingsGet, 6, 249, '>D 15;0' + #13#10, 0, False, False);
  Commands_New(act_SettingsGet, 250, 250, MasterCRC(#49#16#177), 0, False, False);

  Commands_New('Послать пакет с координатами|Send packet with coordinates', 5, 5, 'sendpacket' + #13#10);
  Commands_New('Послать пакет с координатами|Send packet with coordinates', 6, 249, '>D 4;1' + #13#10);

  Commands_New('Получить информацию о мастере|Get info about master',  250, 250, MasterCRC(#49#16#176) );
  Commands_New('Получить список датчиков|Get sensor list',             250, 250, MasterCRC(#49#16#177) );
  Commands_New(act_FindSensors250, 250, 250, MasterCRC(#49#16#184) );
end;

procedure TMF.Commands_Update(Sender: TObject);
var
  i, Cat: Integer;
  MI: TMenuItem;
  D: Integer;
begin
  for i := Pred(CommandsPopupMenu.Items.Count) downto 0 do
    if 0 <= CommandsPopupMenu.Items[i].Tag then
      CommandsPopupMenu.Items.Delete(i);

  if -1 < PortIndex then
  begin
    D := StrToIntDef(QList[PortIndex].DeviceVer, -1);
    for i := 0 to Pred(FCommandList.Count) do
      if FCommandList[i].Enabled(QList[PortIndex]) then
      begin
        MI := TMenuItem.Create(CommandsPopupMenu);
        CommandsPopupMenu.Items.Add(MI);
        MI.Visible := FCommandList.Items[i].Visible(Q);
        MI.Enabled := FCommandList.Items[i].Enabled(Q);
        MI.Caption := FCommandList.Items[i].Caption;
        MI.OnClick := Commands_MenuClick;
        MI.Tag := i;
      end;
  end;

  btn_Commands.Visible := (0 < QList.PortCount);

  for i := 0 to Pred(ActionList.ActionCount) do
  begin
    Cat := StrToIntDef(ActionList.Actions[i].Category, -1);
    if 0 <= Cat then
      if 0 <= FPortIndex then
      begin
        ActionList.Actions[i].Enabled := QList[FPortIndex].Active;
        ActionList.Actions[i].Visible := ((Cat = 0) or (ActionList.Actions[i].Category = QList[FPortIndex].FDeviceVer));
      end
      else
      begin
        ActionList.Actions[i].Enabled := False;
        ActionList.Actions[i].Visible := (Cat = 0);
      end;
  end;
end;

procedure TMF.btn_CommandsClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X := btn_Commands.Left;
  P.Y := btn_Commands.Top + btn_Commands.Height;
  P := LPanel.ClientToScreen(P);
  CommandsPopupMenu.Popup(P.X, P.Y);
end;

procedure TMF.ClearControlsRecursive(Sender: TObject);
var
  i: Integer;
begin
  if Sender is TItemClass then
    TItemClass(Sender).Value := unassigned
  else if Sender is TControlClass then
    TControlClass(Sender).Value := unassigned
  else if Sender is TWinControl then
    for i := Pred(TWinControl(Sender).ControlCount) downto 0 do
      ClearControlsRecursive(TWinControl(Sender).Controls[i]);
end;

procedure TMF.CloseButtonClick(Sender: TObject);
begin
  PortIndex := -1;
  Close;
end;

procedure TMF.ControlsLoadSettings(aVersion: String = '');
var
  intFileAge: LongInt;
  aTabPanel: TTabPanel;
  i, j, k, L, m, N, zL: Integer;
  buffer: String;
  s, t1, t2, sItem, aName: string;
  cSection, cColumn, cSubSection, cItem: TWinControl;
  fCaption: TCaptionClass;
  TS: TStrings;
  FStream: TFileStream;
  RStream: TResourceStream;
  JData, JSECTION, JV, JITEM, JSetting: TJSONValue;
  JO: TJSONObject;
  JSectionList, JArraySubSection, JArrayItem, JSettingViewList, JSettingDictionaryList, JItems: TJSONArray;
  JTranslations, JTranslationList: TJSONArray;
  // JTranslateList: TJSONArray;
  T2Empty: Boolean;

begin
  FCanShowSettings := False;

  // PanelT2.Height := 0;
  T2Empty := False;
  ClearPanel(PanelT1);
  SetLength(z, 0);

  PasswordEdit.Enabled := False;
  act_SetCFG.Enabled := False;
  act_OpenCFG.Enabled := False;
  act_SaveCFG.Enabled := False;

  if Length(aVersion) = 0 then
    Exit;

  LockedPanel.Visible := Q.ReadLocked;
  T1ScrollBox.Visible := not Q.ReadLocked;

  JO := nil;
  if fileExists(DataDir + aVersion + '.json') then
  begin
    intFileAge := FileAge(DataDir + aVersion + '.json');
    if (sVersion <= FileDateToDateTime(intFileAge)) or
      (FindResource(hInstance, PChar('Resource_' + aVersion), RT_RCDATA) = 0)
    then
      try
        FStream := TFileStream.Create(DataDir + aVersion + '.json', fmOpenRead);
        TS := TStringList.Create;
        TS.LoadFromStream(FStream, TEncoding.UTF8);
        FStream.Free;

        JO := TJSONObject.ParseJSONValue(TS.GetText) as TJSONObject;
      except
        JO := nil;
      end;
  end;

  if Not Assigned(JO) and
    (FindResource(hInstance, PChar('Resource_' + aVersion), RT_RCDATA) <> 0)
  then
    try
      RStream := TResourceStream.Create(hInstance,
        PChar('Resource_' + aVersion), RT_RCDATA);
      TS := TStringList.Create;
      TS.LoadFromStream(RStream, TEncoding.UTF8);
      RStream.Free;

      JO := TJSONObject.ParseJSONValue(TS.GetText) as TJSONObject;
    except
      JO := nil;
    end;

  if Assigned(JO) then
    try
      JData := (JO as TJSONObject).GetValue('data');

      JTranslations := TJSONArray((JData as TJSONObject).GetValue('translations'));
      if Assigned(JTranslations) then
      begin
        SetLength(Dictionary.DTranslates, JTranslations.Count);
        for i := 0 to Pred(JTranslations.Count) do
          try
            JV := JTranslations.Items[i];
            Dictionary.DTranslates[i, 0] := (JV as TJSONObject).Values['key'].Value;
            JTranslationList := TJSONArray((JTranslations.Items[i] as TJSONObject).Values['translationList']);
            for j := 0 to Pred(JTranslationList.Count) do
            begin
              s := (JTranslationList.Items[j] as TJSONObject).Values['lang'].Value;
              if SameText(s, 'ru') then
                Dictionary.DTranslates[i, 1] := (JTranslationList.Items[j] as TJSONObject).Values['text'].Value
              else if SameText(s, 'en') then
                Dictionary.DTranslates[i, 2] := (JTranslationList.Items[j] as TJSONObject).Values['text'].Value;
            end;
          except
          end;
      end;

      JSectionList := TJSONArray((JData as TJSONObject).GetValue('sectionList'));
      JSettingViewList := TJSONArray((JData as TJSONObject).GetValue('settingViewList'));
      JSettingDictionaryList := TJSONArray((JData as TJSONObject).GetValue('settingDictionaryList'));

      SetLength(Tabs, JSectionList.Count);
      if not T2Empty then
      begin
        ClearPanel(PanelT2);
        T2Empty := True;
      end;

      for i := 0 to Pred(JSectionList.Count) do
      begin
        aTabPanel := TTabPanel.Create(PanelT2);
        aTabPanel.Dict := (JSectionList.Items[i] as TJSONObject).Values['name'].Value;
        aTabPanel.Caption := Translate(FLanguage, aTabPanel.Dict);
        aTabPanel.Parent := PanelT2;
        Tabs[i] := aTabPanel;
      end;

      for i := 0 to Pred(JSectionList.Count) do
      begin
        cSection := TColumnClass.Create(self);
        cSection.Parent := PanelT1;
        cSection := TColumnClass(cSection).Body;

        Tabs[i].WinControl := cSection.Parent;
        {
          aTabPanel := TTabPanel.Create(PanelT2);
          aTabPanel.Parent := PanelT2;
          aTabPanel.Dict := (JSectionList.Items[i] as TJSONObject).Values['name'].Value;
          aTabPanel.Caption := Translate(FLanguage, aTabPanel.Dict);
          aTabPanel.WinControl := cSection.Parent;
          { }
        JArraySubSection := TJSONArray((JSectionList.Items[i] as TJSONObject).GetValue('subSectionList'));
        for j := 0 to Pred(JArraySubSection.Count) do
        // sectionList > subSectionList
        begin
          fCaption := TCaptionClass.Create(self);
          fCaption.Tag := -1;
          fCaption.Parent := cSection;
          try
            fCaption.Ident := (JArraySubSection.Items[j] as TJSONObject).Values['id'].Value;
          except
          end;
          try
            fCaption.Dict := (JArraySubSection.Items[j] as TJSONObject).Values['name'].Value;
            fCaption.Tag := -1;
          except
            fCaption.Dict := fCaption.Ident;
          end;
          fCaption.Caption := Translate(FLanguage, fCaption.Dict);
          cSubSection := fCaption.Body;

          TCaptionClass(cSubSection.Parent).Icon := '';
          JArrayItem := TJSONArray((JArraySubSection.Items[j] as TJSONObject).GetValue('settingViewAliasList'));
          for k := 0 to Pred(JArrayItem.Count) do
            // sectionList > subSectionList > settingViewAliasList
            try
              sItem := JArrayItem.Items[k].Value;
              for L := 0 to Pred(JSettingViewList.Count) do // settingViewList
                if (JSettingViewList.Items[L] as TJSONObject).Values['alias'].Value = sItem then
                begin
                  zL := Length(z);
                  SetLength(z, Succ(zL));

                  z[zL].Alias := sItem;
                  z[zL].TextBefore := (JSettingViewList.Items[L] as TJSONObject).Values['textBefore'].Value;
                  z[zL].TextAfter := (JSettingViewList.Items[L] as TJSONObject).Values['textAfter'].Value;
                  z[zL].Default := (JSettingViewList.Items[L] as TJSONObject).Values['defaultValue'].Value;

                  t1 := (JSettingViewList.Items[L] as TJSONObject).Values['type'].Value;
                  if SameText(t1, 'string') then z[zL].Control := cString else
                  if SameText(t1, 'int') or SameText(t1, 'signint') then z[zL].Control := cNumber else
                  if SameText(t1, 'flag') then z[zL].Control := cFlag else
                  if SameText(t1, 'dictionary') then z[zL].Control := cDictionary else
                  if SameText(t1, 'button') then z[zL].Control := cButton else
                                                 z[zL].Control := cUnknown;

                  JSetting := TJSONArray((JSettingViewList.Items[L] as TJSONObject).GetValue('setting'));

                  z[zL].Number := StrToIntDef((JSetting as TJSONObject).Values['number'].Value, -1);
                  t1 := (JSetting as TJSONObject).Values['type'].Value;
                  t2 := (JSetting as TJSONObject).Values['length'].Value;

                  if SameText(t1, 'string') then
                  begin
                    z[zL].VarType := VarString;
                    z[zL].Min := 0;
                    z[zL].Max := 255;
                  end
                  else if SameText(t1, 'int') and (t2 = '1') then
                  begin
                    z[zL].VarType := VarByte;
                    z[zL].Min := 0;
                    z[zL].Max := 255;
                  end
                  else if SameText(t1, 'int') and (t2 = '2') then
                  begin
                    z[zL].VarType := VarWord;
                    z[zL].Min := 0;
                    z[zL].Max := 65535;
                  end
                  else if SameText(t1, 'int') and (t2 = '4') then
                  begin
                    z[zL].VarType := varLongWord;
                    z[zL].Min := 0;
                    z[zL].Max := 4294967295;
                  end
                  else if SameText(t1, 'signInt') and (t2 = '1') then
                  begin
                    z[zL].VarType := varShortInt;
                    z[zL].Min := -127;
                    z[zL].Max := 127;
                  end
                  else if SameText(t1, 'signInt') and (t2 = '2') then
                  begin
                    z[zL].VarType := varSmallint;
                    z[zL].Min := -32767;
                    z[zL].Max := 32767;
                  end
                  else if SameText(t1, 'signInt') and (t2 = '4') then
                  begin
                    z[zL].VarType := varInteger;
                    z[zL].Min := -2147483647;
                    z[zL].Max := 2147483647;
                  end
                  else
                    z[zL].VarType := varEmpty;

                  // ..........................................................................................
                  z[zL].Bit := -1;

                  case z[zL].Control of
                    cNumber:
                      begin
                        z[zL].WinControl := TIntegerClass.Create(self);

                        JV := (JSettingViewList.Items[L] as TJSONObject).Values['min'];
                        if Not(JV = nil) then
                          TIntegerClass(z[zL].WinControl).Min := StrToIntDef(JV.Value, z[zL].Min)
                        else
                          TIntegerClass(z[zL].WinControl).Min := z[zL].Min;

                        JV := (JSettingViewList.Items[L] as TJSONObject).Values['max'];
                        if Not(JV = nil) then
                          TIntegerClass(z[zL].WinControl).Max := StrToIntDef(JV.Value, z[zL].Max)
                        else
                          TIntegerClass(z[zL].WinControl).Max := z[zL].Max;
                      end;
                    cFlag:
                      begin
                        z[zL].WinControl := TFlagClass.Create(self);
                        JV := (JSettingViewList.Items[L] as TJSONObject).Values['bit'];
                        if Not(JV = nil) then
                          z[zL].Bit := StrToIntDef(JV.Value, -1);
                        TFlagClass(z[zL].WinControl).Bit := z[zL].Bit;
                      end;
                    cButton:
                      begin
                        z[zL].WinControl := TButtonClass.Create(self);
                      end;
                    cString:
                      begin
                        z[zL].WinControl := TStringClass.Create(self);

                        JV := (JSetting as TJSONObject).Values['length'];
                        if Not(JV = nil) then
                          TStringClass(z[zL].WinControl).Max := StrToIntDef((JV.Value), 255)
                        else
                          TStringClass(z[zL].WinControl).Max := 255;
                      end;
                    cDictionary:
                      begin
                        z[zL].WinControl := TListClass.Create(self);
                        z[zL].WinControl.Parent := cSubSection;
                        for m := 0 to Pred(JSettingDictionaryList.Count) do
                          if (JSettingDictionaryList.Items[m] as TJSONObject).Values['settingView'].Value = sItem then
                          begin
                            JItems := TJSONArray((JSettingDictionaryList.Items[m] as TJSONObject).GetValue('items'));
                            for N := 0 to Pred(JItems.Count) do
                            begin
                              TListClass(z[zL].WinControl).AddDicItem
                                (StrToIntDef((JItems.Items[N] as TJSONObject).Values['number'].Value, -1),
                                (JItems.Items[N] as TJSONObject).Values['name'].Value);
                            end;
                            Break;
                          end;
                      end;
                  end;
                  // ..........................................................................................

                  if Assigned(z[zL].WinControl) then
                  begin
                    z[zL].WinControl.Parent := cSubSection;
                    // z[zL].WinControl.align:= alTop;
                    // z[zL].WinControl.Top:=  cSubSection.ControlCount*50;
                    TControlClass(z[zL].WinControl).Ident := z[zL].Alias;
                    TControlClass(z[zL].WinControl).Settings := z[zL].Number;
                    TControlClass(z[zL].WinControl).Caption := Translate(FLanguage, z[zL].TextBefore);
                    TControlClass(z[zL].WinControl).Units := Translate(FLanguage, z[zL].TextAfter);
                    TBaseClass(z[zL].WinControl).Init;
                  end;
                end;
            except
            end;
        end;
      end;
    finally
      PasswordEdit.Enabled := True;
      PasswordEdit.OnChange(PasswordEdit);
      Commands_Exec(act_SettingsGet);

      if 0 < PanelT2.ControlCount then
        if PanelT2.Controls[0] is TTabPanel then
          TTabPanel(PanelT2.Controls[0]).Checked := True;
      FCanShowSettings := True;
    end
  else
  begin
    MF.MainHintShow(0, Translate(MF.Language, 'mes_settingsnoversion') + ' ' + aVersion);
  end;

  if not T2Empty then
  begin
    ClearPanel(PanelT2);
  end;
end;

procedure TMF.ControlsLoadMonitor;
var
  FDocument: TXMLDocument;
  FRoot: IXMLNode;
  RStream: TResourceStream;
  i: Integer;
  aName: String;

  procedure DoControls(aParent: TWinControl; aNode: IXMLNode);
  var
    i: Integer;
    fItem: TItemClass;
    fCaption: TCaptionClass;
    fControl: TControlClass;
    fColumn: TColumnClass;
    fSeparator: TSeparatorClass;
  begin
    for i := 0 to Pred(aNode.ChildNodes.Count) do
    begin

      if SameText(aNode.ChildNodes[i].NodeName, 'section') then
      begin
        fCaption := TCaptionClass.Create(self);
        fCaption.Parent := aParent;
        fCaption.Ident := VarToStr(aNode.ChildNodes[i].Attributes['ident']);
        fCaption.Icon := VarToStr(aNode.ChildNodes[i].Attributes['ico']);
        fCaption.Caption := Translate(FLanguage, fCaption.Ident);
        fCaption.AutoHide := (StrToIntDef(VarToStr(aNode.ChildNodes[i].Attributes['hide']), 0) = 1);
        fCaption.Single := (StrToIntDef(VarToStr(aNode.ChildNodes[i].Attributes['single']), 0) <> 0);
        if fCaption.Single then
          fCaption.Flipped := (StrToIntDef(VarToStr(aNode.ChildNodes[i].Attributes['single']), 0) = 1);

        DoControls(fCaption.Body, aNode.ChildNodes[i]);
      end
      else

        if SameText(aNode.ChildNodes[i].NodeName, 'column') then
      begin
        fColumn := TColumnClass.Create(self);
        fColumn.Parent := aParent;
        fColumn.Ident := VarToStr(aNode.ChildNodes[i].Attributes['ident']);
        fColumn.Equil := True;
        fColumn.AutoHide := (StrToIntDef(VarToStr(aNode.ChildNodes[i].Attributes['hide']), 0) = 1);

        DoControls(fColumn.Body, aNode.ChildNodes[i]);
      end
      else

        if SameText(aNode.ChildNodes[i].NodeName, 'item') then
      begin
        fItem := TItemClass.Create(self);
        fItem.Parent := aParent;
        fItem.Ident := aNode.ChildNodes[i].Attributes['ident'];
        fItem._Units := VarToStr(aNode.ChildNodes[i].Attributes['units']);
        fItem.Units := Translate(MF.Language, fItem._Units);
        fItem.AutoHide := (StrToIntDef(VarToStr(aNode.ChildNodes[i].Attributes['hide']), 0) = 1);
        fItem.Caption := Translate(FLanguage, fItem.Ident);
      end
      else

        if SameText(aNode.ChildNodes[i].NodeName, 'integer') then
      begin
        fControl := TIntegerClass.Create(self);
        fControl.Parent := aParent;
        fControl.Ident := aNode.ChildNodes[i].Attributes['ident'];
        fControl.Units := VarToStr(aNode.ChildNodes[i].Attributes['units']);
        fControl.Caption := Translate(FLanguage, fControl.Ident);
      end
      else

        if SameText(aNode.ChildNodes[i].NodeName, 'string') or
        SameText(aNode.ChildNodes[i].NodeName, 'boolean') or
        SameText(aNode.ChildNodes[i].NodeName, 'list') then
      begin
        fControl := TStringClass.Create(self);
        fControl.Parent := aParent;
        fControl.Ident := aNode.ChildNodes[i].Attributes['ident'];
        fControl.Units := Translate(MF.Language, VarToStr(aNode.ChildNodes[i].Attributes['units']));
        fControl.Caption := Translate(FLanguage, fControl.Ident);
      end
      else

        if SameText(aNode.ChildNodes[i].NodeName, 'separator') then
      begin
        fSeparator := TSeparatorClass.Create(self);
        fSeparator.Parent := aParent;
      end;

    end;
  end;

begin
  ClearPanel(PanelS1);
  ClearPanel(PanelS2);
  ClearPanel(PanelS3);
  ClearPanel(PanelS4);
  ClearPanel(PanelT1);

  if FindResource(hInstance, PChar('Resource_XML'), RT_RCDATA) <> 0 then
  begin
    RStream := TResourceStream.Create(hInstance, PChar('Resource_XML'),
      RT_RCDATA);
    FDocument := TXMLDocument.Create(self);
    try
      FDocument.Active := False;
      FDocument.XML.LoadFromStream(RStream);
      FDocument.Active := True;
      FRoot := FDocument.ChildNodes.FindNode('root');
      if Assigned(FRoot) then
        for i := 0 to Pred(FRoot.ChildNodes.Count) do
        begin
          aName := FRoot.ChildNodes[i].Attributes['name'];
          if SameText(aName, PanelS1.Name) then DoControls(PanelS1, FRoot.ChildNodes[i])
          else if SameText(aName, PanelS2.Name) then DoControls(PanelS2, FRoot.ChildNodes[i])
          else if SameText(aName, PanelS3.Name) then DoControls(PanelS3, FRoot.ChildNodes[i])
          else if SameText(aName, PanelS4.Name) then DoControls(PanelS4, FRoot.ChildNodes[i])
          else if SameText(aName, PanelT1.Name) then DoControls(PanelT1, FRoot.ChildNodes[i])
          else
        end;
    finally
      RStream.Free;
      FDocument.Free;
    end;
  end;
end;

procedure TMF.SetShowEnter(const Value: Boolean);
begin
  if Value then
  begin
    btnShowEnter.Down := True;
    btnShowEnter.Font.Color := _Green;
  end
  else
  begin
    btnShowEnter.Down := False;
    btnShowEnter.ParentFont := True;
  end;

  FShowEnter := Value;
  InListView.Repaint;
end;

procedure TMF.SetFollow(const Value: Boolean);
begin
  if Value then
    begin
      InListView.Items.BeginUpdate;
      InListView.Items.Count := Length(PInPacket^);
      InListView.ItemIndex := Pred(InListView.Items.Count);
      if 0 < InListView.ItemIndex then
        SendMessage(InListView.Handle, LVM_ENSUREVISIBLE, InListView.ItemIndex, 0);
      InListView.Items.EndUpdate;
    end;

  InListView.Repaint;

  FFollow := Value;
  btnPlay.Down:= Value;
  btnPause.Down := Not Value;
end;

procedure TMF.SetHEX(aHEX: Boolean);
begin
  FHEX := aHEX;

  if FHEX then
  begin
    btnShowHEX.Down := True;
    btnShowHEX.Font.Color := _Green;
    btnShowTEXT.ParentFont := True;
  end
  else
  begin
    btnShowTEXT.Down := True;
    btnShowTEXT.Font.Color := _Green;
    btnShowHEX.ParentFont := True;
  end;

  InListView.Repaint;
end;

procedure TMF.UpdateWellcome;
var
  FDocument: TXMLDocument;
  FRoot, FNode: IXMLNode;
  FWellcomeURL, fn: String;
  i, N: Integer;
  intFileAge: LongInt;
  JO: TJSONObject;
  JUpdates: TJSONArray;
  fs: TFormatSettings;
  DateTimeU, DateTimeF: TDateTime;
  {
    Doc : IHTMLDocument2;
    Element : IHTMLElement;
    { }
begin
  fs := TFormatSettings.Create;
  fs.DateSeparator := '-';
  fs.ShortDateFormat := 'yyyy-MM-dd';
  fs.TimeSeparator := ':';
  fs.ShortTimeFormat := 'hh:mm';
  fs.LongTimeFormat := 'hh:mm:ss';

  try
    if 0 < Length(FWellcomeFile) then
    begin
      FDocument := TXMLDocument.Create(self);
      FDocument.XML.Text := Copy(FWellcomeFile, Pos('<info>', FWellcomeFile), MaxInt);
      FDocument.Active := True;
      FRoot := FDocument.ChildNodes.FindNode('info');
      FNode := FRoot.ChildNodes.FindNode('version');
      if Assigned(FNode) then
      begin
        UpdateProURL := FNode.Attributes['url'];
        fn := FNode.Attributes['date'];
        if Length(fn) = 6 then
          fn := '20' + Copy(fn, 1, 2) + '-' + Copy(fn, 3, 2) + '-' + Copy(fn, 5, 2);
        FUpdateVersion := StrToDateTime(fn, fs);
      end;

      FRoot := nil;
      FNode := nil;
      FDocument.Active := False;
      FDocument.Free;
    end
    else
    begin
      FUpdateVersion := 0;
      UpdateProURL := '';
    end;
  Except
    FUpdateVersion := 0;
    UpdateProURL := '';
    MainHintShow(2, 'Ошибка в структуре файла обновления и новости');
  end;

  // --------------------------------------------------------------------------------------------------------------------
  try
    if 0 < Length(FDeviceFile) then
    begin
      FDocument := TXMLDocument.Create(self);
      FDocument.XML.Text := Copy(FDeviceFile,
        Pos('<info>', FDeviceFile), MaxInt);
      FDocument.Active := True;
      FRoot := FDocument.ChildNodes.FindNode('info');

      FNode := nil;
      if FLanguage = 0 then
        FNode := FRoot.ChildNodes.FindNode('ru')
      else
        FNode := FRoot.ChildNodes.FindNode('en');

      if Assigned(FNode) then
      begin
        WellcomeCaption.Caption := FNode.Attributes['name'];
        WellcomeText.Caption := FNode.NodeValue;
        if FNode.HasAttribute('URL') then
          FWellcomeURL := FNode.Attributes['URL']
        else
          FWellcomeURL := '';
      end;

      FRoot := nil;
      FNode := nil;
      FDocument.Active := False;
      FDocument.Free;
    end
    else
    begin
      FWellcomeURL := '';
      WellcomeCaption.Caption := Translate(FLanguage, '_WellcomeCaption');
      WellcomeText.Caption := Translate(FLanguage, '_WellcomeText');
    end;
  Except
    FWellcomeURL := '';
    WellcomeCaption.Caption := Translate(FLanguage, '_WellcomeCaption');
    WellcomeText.Caption := Translate(FLanguage, '_WellcomeText');

    MainHintShow(2, 'Ошибка в структуре файла обновления и новости');
  end;

  // --------------------------------------------------------------------------------------------------------------------

  if 0 < Length(FAdditionFile) then
    try

      JO := TJSONObject.ParseJSONValue(FAdditionFile) as TJSONObject;
      if Assigned(JO) then
        try
          FUpdateModule := '';

          JUpdates := TJSONArray((JO as TJSONObject).GetValue('data'));
          for i := 0 to Pred(JUpdates.Count) do
            try
              N := StrToIntDef((JUpdates.Items[i] as TJSONObject).Values['deviceTypeId'].Value, 0);
              DateTimeU := StrToDateTime((JUpdates.Items[i] as TJSONObject).Values['createdAt'].Value, fs);
              fn := DataDir + IntToStr(N) + '.json';
              if fileExists(fn) then
              begin
                intFileAge := FileAge(fn);
                if intFileAge = -1 then
                  DateTimeF := 0
                else
                  DateTimeF := FileDateToDateTime(intFileAge)
              end
              else
                DateTimeF := 0;

              if (sVersion < DateTimeU) then
                if (DateTimeF < DateTimeU) or (DateTimeF = 0) then
                begin
                  if 0 = Length(FUpdateModule) then
                    FUpdateModule := 'v' + IntToStr(N)
                  else
                    FUpdateModule := FUpdateModule + '; v' + IntToStr(N);
                end;
            finally
            end;

        finally
        end;

    except
    end;

  // --------------------------------------------------------------------------------------------------------------------
  BrowserURL := FWellcomeURL;
  UpdateBrowser(nil);

  if (FUpdateVersion = 0) and (Length(FUpdateModule) = 0) then
  begin
    act_UpdatePro.Enabled := False;
    UpdatePanel.Color := _Style.ColorPanel;
    UpdateProLabel1.Caption := Translate(FLanguage, 'mes_versionempty');
    UpdateProLabel2.Caption := Translate(FLanguage, '_SoftVersion') + ': ' + FormatDateTime('dd.mm.yyyy', sVersion);
    UpdateProLabel2.Font.Color := _Green;
    UpdateBtnPanel.Width := 0;
    UpdateProButton.Action := act_checkUpdate;
  end
  else

    if (sVersion >= FUpdateVersion) and (Length(FUpdateModule) = 0) then
  begin
    act_UpdatePro.Enabled := False;
    UpdatePanel.Color := _Style.ColorPanel;
    UpdateProLabel1.Caption := Translate(FLanguage, 'mes_versionislast');
    UpdateProLabel2.Caption := Translate(FLanguage, '_SoftVersion') + ': ' + FormatDateTime('dd.mm.yyyy', sVersion);
    UpdateProLabel2.Font.Color := _Green;
    UpdateBtnPanel.Width := 0;
    UpdateProButton.Action := act_checkUpdate;
    UpdateProButton.Action := act_UpdateModule;
  end
  else

    if (sVersion < FUpdateVersion) then
  begin
    act_UpdatePro.Enabled := True;
    UpdatePanel.Color := $0062B75A;
    UpdateProLabel1.Caption := Translate(FLanguage, 'mes_versionupdate') + ': ' + DateToStr(FUpdateVersion);
    UpdateProLabel2.Caption := Translate(FLanguage, '_SoftVersion') + ': ' + FormatDateTime('dd.mm.yyyy', sVersion);
    UpdateProLabel2.Font.Color := clBlack;
    UpdateBtnPanel.Width := 126;
    UpdateProButton.Action := act_UpdatePro;
  end
  else

  begin
    act_UpdatePro.Enabled := True;
    UpdatePanel.Color := $0062B75A;
    UpdateProLabel1.Caption := Translate(FLanguage, 'mes_moduleupdate');
    UpdateProLabel2.Caption := FUpdateModule;
    UpdateProLabel2.Font.Color := clBlack;
    UpdateBtnPanel.Width := 126;
    UpdateProButton.Action := act_UpdateModule;
  end
end;

procedure TMF.SetLanguageIndicator(aPosition: Integer = 0; aCount: Integer = 0);
begin
  if ProgressPanel.Visible <> (0 < aCount) then
  begin
    ProgressPanel.Visible := (0 < aCount);
    Repaint;
  end;

  if 0 < aCount then
    PercentLabel.Caption := IntToStr((100 * aPosition) div aCount) + '%';

  if 0 < aCount then
    LangLabel.SetBounds(0, 0, (LangLabel.Parent.Width * aPosition) div aCount, LangLabel.Height)
  else if FLanguage = 0 then
    LangLabel.SetBounds(ButtonRU.Left, 0, ButtonRU.Width, LangLabel.Height)
  else
    LangLabel.SetBounds(ButtonEN.Left, 0, ButtonRU.Width, LangLabel.Height)
end;

procedure TMF.SetLanguage(aLanguage: Integer);
var
  i, P: Integer;
  FClass: TClass;
  s: string;

  procedure SetControlLanguage(aParent: TWinControl; aLanguage: Integer);
  var
    i, P: Integer;
  begin
    for i := 0 to Pred(aParent.ControlCount) do
      if aParent.Controls[i].ClassType = TLabel then
      begin
        P := Pos('_', aParent.Controls[i].Name);
        if (0 < P) then
          TLabel(aParent.Controls[i]).Caption := Translate(FLanguage, Copy(aParent.Controls[i].Name, P + 1, MaxInt))
      end
      else if aParent.Controls[i].ClassType = TTabPanel then
      begin
        TTabPanel(aParent.Controls[i]).Caption := Translate(FLanguage, TTabPanel(aParent.Controls[i]).Dict);
      end
      else if aParent.Controls[i] is TCaptionClass then
      begin
        if 0 < Length(TCaptionClass(aParent.Controls[i]).Dict) then
          TCaptionClass(aParent.Controls[i]).Caption := Translate(FLanguage, TCaptionClass(aParent.Controls[i]).Dict);
      end
      else
        if aParent.Controls[i] is TWinControl then
        SetControlLanguage(TWinControl(aParent.Controls[i]), aLanguage);
  end;

begin
  FLanguage := aLanguage;
  UpdateTitle;
  UpdateWellcome;

  SetControlLanguage(self, FLanguage);
  for i := Low(z) to High(z) do
    if z[i].WinControl is TControlClass then
      with TControlClass(z[i].WinControl) do
      begin
        Caption := Translate(FLanguage, z[i].TextBefore);
        Units := Translate(FLanguage, z[i].TextAfter);
        Init;
      end;

  for i := 0 to Pred(ComponentCount) do
    if -1 <= Components[i].Tag then
    begin
      FClass := Components[i].ClassType;
      P := Pos('_', Components[i].Name);

      if (FClass = TSpeedButton) and (0 < P) then
        TSpeedButton(Components[i]).Caption := Translate(FLanguage, Copy(Components[i].Name, P + 1, MaxInt))
      else

        if (FClass = TItemClass) then
      begin
        TItemClass(Components[i]).Caption := Translate(FLanguage, TItemClass(Components[i]).Ident);
        TItemClass(Components[i]).Units := Translate(FLanguage, TItemClass(Components[i])._Units);
        TItemClass(Components[i]).Repaint;
      end
      else

        if (FClass = TCaptionClass) then
        if TCaptionClass(Components[i]).Tag <> -1 then
        begin
          TCaptionClass(Components[i]).Caption := Translate(FLanguage, TCaptionClass(Components[i]).Ident);
          TCaptionClass(Components[i]).Repaint;
        end
        else

          if (FClass = TStringClass) or (FClass = TIntegerClass) or (FClass = TButtonClass) then
        begin
          TControlClass(Components[i]).Caption := Translate(FLanguage, TControlClass(Components[i]).Ident);
          TControlClass(Components[i]).Repaint;
        end
        else

          if (FClass = TLabel) and (0 < P) then
        begin
          TLabel(Components[i]).Caption := Translate(FLanguage, Copy(Components[i].Name, P + 1, MaxInt));
        end;
    end;

  for i := 0 to Pred(ActionList.ActionCount) do
    if -1 <= ActionList.Actions[i].Tag then
    begin
      s := Translate(FLanguage, ActionList.Actions[i].Name);
      P := Pos('|', s);
      if 0 < P then
      begin
        if (-1 < ActionList.Actions[i].Tag) then
          ActionList.Actions[i].Caption := Copy(s, 1, P - 1);
        ActionList.Actions[i].Hint := Copy(s, P + 1, MaxInt);
      end
      else
      begin
        if (-1 < ActionList.Actions[i].Tag) then
          ActionList.Actions[i].Caption := s;
        ActionList.Actions[i].Hint := s;
      end
    end;

  // DrawCaptButton;
  SetLanguageIndicator;
  MF.Repaint;
end;

procedure TMF.InfoPanelResize(Sender: TObject);
var
  i, C, HH, WW, W: Integer;
begin
  inherited;
  C := 3;
  for i := 0 to Pred(PanelS4.ControlCount) do
    if (PanelS4.Controls[i] is TBaseClass) then
      if (PanelS4.Controls[i].Visible) and (0 < TBaseClass(PanelS4.Controls[i]).FullHeight) then
      begin
        C := 4;
        Break;
      end;

  WW := (MainPanel.ClientWidth - (C - 1) * 5);
  HH := (MainPanel.ClientHeight);
  W := WW div C;
  if C = 3 then
  begin
    PanelS1.SetBounds(0 * (W + 5), 0, W, HH);
    PanelS1.Repaint;
    PanelS2.SetBounds(1 * (W + 5), 0, W, HH);
    PanelS2.Repaint;
    PanelS3.SetBounds(2 * (W + 5), 0, MainPanel.ClientWidth - 2 * (W + 5), HH);
    PanelS3.Repaint;
    PanelS4.SetBounds(3 * (W + 5), 0, 0, HH);
    PanelS4.Visible := False;
  end
  else
  begin
    PanelS1.SetBounds(0 * (W + 5), 0, W, HH);
    PanelS1.Repaint;
    PanelS2.SetBounds(1 * (W + 5), 0, W, HH);
    PanelS2.Repaint;
    PanelS3.SetBounds(2 * (W + 5), 0, W, HH);
    PanelS3.Repaint;
    PanelS4.SetBounds(3 * (W + 5), 0, MainPanel.ClientWidth - 3 * (W + 5), HH);
    PanelS4.Visible := True;
    PanelS4.Repaint;
  end;
end;

procedure TMF.SettingsError(const Index: Integer; const Value: String);
var
  X1, X2, i: Integer;
begin
  if FErrors[index] = Value then
    Exit;
  FCurrentError := Index;
  FErrors[Index] := Value;

  if (Length(Value) = 0) then
  begin
    MainHintHide(nil);
    FCurrentError := -1;
    for i := Low(FErrors) to High(FErrors) do
      if 0 < Length(FErrors[i]) then
      begin
        FCurrentError := i;
        Break;
      end;

    act_SetCFG.Enabled := (FCurrentError = -1);
    if FCurrentError = -1 then
      Exit;
  end
  else
    act_SetCFG.Enabled := False;

  if not Assigned(FInfoPanel) then
  begin
    FInfoPanel := TInfoPanel.Create(self);
    FInfoPanel.ParentColor := False;
    FInfoPanel.AutoSize := False;
    FInfoPanel.StyleElements := [];
    FInfoPanel.BevelOuter := bvNone;
    FInfoPanel.DoubleBuffered := False;

    FInfoPanel.Left := ClientWidth;
    FInfoPanel.Top := ClientHeight - 96;
    FInfoPanel.Height := 48;
    FInfoPanel.Anchors := []; // [akRight,akBottom];
    FInfoPanel.DisableAlign;

    FInfoPanel.Parent := self;
    X1 := ClientWidth + FInfoPanel.Width;
  end
  else
  begin
    X1 := FInfoPanel.Left;
  end;

  FInfoPanel.Color := clRed;
  FInfoPanel.Caption := FErrors[FCurrentError];
  FInfoPanel.Width := 48 + FInfoPanel.Canvas.TextWidth(FInfoPanel.Caption);
  X2 := ClientWidth - FInfoPanel.Width;

  if X1 <> X2 then
    for i := 15 to 30 do
    begin
      FInfoPanel.Left := LiteResize(X1, X2, 30, i, 30);
      FInfoPanel.Invalidate;
      FInfoPanel.Repaint;
    end;
end;

procedure TMF.SettingsPanelResize(Sender: TObject);
var
  W: Integer;
begin
  W := (SettingsPanel.ClientWidth) div 3;
  PanelT0.Width := Max(W, 300);
  PanelT0.Realign;
  PanelT1.Realign;
end;

procedure TMF.LogPanelResize(Sender: TObject);
var
  W: Integer;
begin
  W := (LogPanel.ClientWidth - PanelL3.Width) div 2;
  PanelL1.Width := W;
  PanelL2.Width := W;
  PanelL1.Realign;
  PanelL2.Realign;
end;

function TMF.VisualFind(const aParent: TWinControl; const aName: String; var aControl: TObject): Boolean;
var
  i: Integer;
begin
  result := False;

  for i := 0 to Pred(aParent.ControlCount) do
    if (aParent.Controls[i].ClassType = TStringClass) or
      (aParent.Controls[i].ClassType = TIntegerClass) or
      (aParent.Controls[i].ClassType = TFlagClass) or
      (aParent.Controls[i].ClassType = TListClass) or
      (aParent.Controls[i].ClassType = TItemClass) or
      (aParent.Controls[i].ClassType = TCaptionClass) then
      if SameText(TItemClass(aParent.Controls[i]).Ident, aName) then
      begin
        aControl := aParent.Controls[i];
        Exit(True);
      end;

  for i := 0 to Pred(aParent.ControlCount) do
    if (aParent.Controls[i] is TWinControl) then
      if VisualFind(TWinControl(aParent.Controls[i]), aName, aControl) then
        Exit(True);
end;

function TMF.VisualFind(const aParent: TWinControl; const aID: Integer; var aControl: TObject): Boolean;
var
  i: Integer;
begin
  // на время детекции протокола отключаем отображениеж
  // if Version = vtDetect then Exit(False);
  result := False;

  for i := 0 to Pred(aParent.ControlCount) do
    if (aParent.Controls[i].ClassType = TStringClass) or
      (aParent.Controls[i].ClassType = TIntegerClass) or
      (aParent.Controls[i].ClassType = TFlagClass) or
      (aParent.Controls[i].ClassType = TListClass) then
      if TControlClass(aParent.Controls[i]).Settings = aID then
      begin
        aControl := aParent.Controls[i];
        Exit(True);
      end;

  for i := 0 to Pred(aParent.ControlCount) do
    if (aParent.Controls[i] is TWinControl) then
      if VisualFind(TWinControl(aParent.Controls[i]), aID, aControl) then
        Exit(True);
end;

function TMF.VisualSetValue(aName: String; aValue: Variant; aColor: TColor = _Green; aValueAlter: String = ''): Boolean;
var
  aControl: TObject;
begin
  // на время детекции протокола отключаем отображениеж
  // if Version = vtDetect then Exit(False);
  if (-1 < PortIndex) then
  begin
    if SameText(aName, '_DeviceID') then QList[PortIndex].DeviceName := aValue;
    if SameText(aName, '_DeviceType') then QList[PortIndex].DeviceVer := aValue;
    if SameText(aName, '_SoftVersion') then QList[PortIndex].DeviceSOFT := aValue;
    if SameText(aName, '_DeviceIMEI') then QList[PortIndex].DeviceIMEI := aValue;
  end;

  result := VisualFind(self, aName, aControl);
  if result then
    if (aControl is TItemClass) then
    begin
      (aControl as TItemClass).SetColor(aColor);
      (aControl as TItemClass).Value := aValue;
      (aControl as TItemClass).ValueAlter := aValueAlter;
    end
    else if (aControl is TStringClass) then
    begin
      (aControl as TStringClass).Value := aValue;
    end
    else if (aControl is TIntegerClass) then
    begin
      (aControl as TIntegerClass).Value := aValue;
    end
    else if (aControl is TFlagClass) then
    begin
      (aControl as TFlagClass).Value := aValue;
    end
    else if (aControl is TListClass) then
    begin
      (aControl as TListClass).Value := aValue;
    end
    else
      result := False;
end;

procedure TMF.QWaitData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
var
  i: Integer;
begin
  for i := 0 to Pred(QList.Count) do
    if QList[i].Com = Sender then
    begin
      SetPortIndex(i);
      QReceiveData(Sender, DataPtr, DataSize);
    end;
end;

procedure TMF.QOperationData1(const aIndex: Int64);
var
  CRC: Word;
  a: Array of Byte;
  i, N, P, FileSize: Integer;
  s: AnsiString;
begin

  FileSize := FDataFile.Size;
  P := MS.AsByte(FInSource[aIndex].Position + 0) +
    MS.AsByte(FInSource[aIndex].Position + 1) * 256 +
    MS.AsByte(FInSource[aIndex].Position + 2) * 256 * 256 +
    MS.AsByte(FInSource[aIndex].Position + 3) * 256 * 256 * 256;

  SetLanguageIndicator(P, FileSize);

  N := Min(1024, FileSize - P);
  SetLength(a, 4 + N + 2);

  a[0] := N mod 256;
  a[1] := N div 256;
  a[2] := 0;
  a[3] := 0;

  for i := 0 to Pred(N) do
    a[4 + i] := TByteArray(FDataFile.Memory^)[P + i];

  CRC := CRC16CCITT(a, 0, Pred(4 + N));
  a[4 + N + 0] := CRC mod 256;
  a[4 + N + 1] := CRC div 256;

  s := '';
  for i := 0 to Pred(Length(a)) do
    s := s + ansichar(a[i]);

  Q.SendAnsiString(s);

  if N = 0 then
  begin
    Q.Operation := 0;
    FDataFile.Free;
    FDataFile := nil;
  end;
end;

procedure TMF.QOperationData2(const aIndex: Int64);
var
  s, sData: AnsiString;
  P, i, Number: Integer;
  bytes: TBytes;
  CRC: Word;
begin
  if FInPacketV1[aIndex].State > 0 then
  begin
    sData := '';

    for i := 0 to Pred(FInPacketV1[aIndex].Size) do
      sData := sData + ansichar(TByteArray(MForm.MS.Memory^)[FInPacketV1[aIndex].Position + i]);

    if Copy(sData, 1, 4) = '>FD=' then
    begin
      case Q.Operation of
        2: SetLanguageIndicator(Q.FMemoryIndex, Q.FMemoryWrite);
        3: SetLanguageIndicator(Q.FMemoryIndex, Q.FMemoryCount);
      end;

      Delete(sData, 1, 4);
      P := Pos(',', sData);
      if 0 < P then
        Number := StrToIntDef(Copy(sData, 1, P - 1), -1)
      else
        Number := -1;

      if Number = Q.FMemoryIndex + Q.FMemoryOffset then
      begin
        P := Pos('"', sData);
        if 0 < P then
          Delete(sData, 1, P);
        P := Pos('"', sData);
        if 0 < P then
          Delete(sData, P, MaxInt);

        sData := sData;
        bytes := TBase64Encoding.Base64.DecodeStringToBytes(sData);
        CRC := CRC16CCITT(bytes, 0, Pred(Length(bytes)) - 2);
        if (Length(bytes) = 258) and (bytes[256] = CRC div 256) and (bytes[257] = CRC mod 256) then
        begin
          if not Assigned(FDataFile) then
            FDataFile := TMemoryStreamEx.Create;
          FDataFile.WriteData(bytes, 256);
          FInPacketV1[aIndex].State := 2;
          Q.FMemoryIndex := Q.FMemoryIndex + 1;
          Q.FMemoryTime := Time;
        end;
      end;

      if ((Q.Operation = 2) and (Q.FMemoryIndex < Q.FMemoryWrite)) or
        ((Q.Operation = 3) and (Q.FMemoryIndex < Q.FMemoryCount)) then
      begin
        Q.FMemoryTime := Time;
        Q.SendAnsiString('>D 18;' + IntToStr(Q.FMemoryIndex + Q.FMemoryOffset) + #13#10);
      end
      else
      begin
        Q.Operation := 0;
        FDataFile.SaveToFile(Q.FMemoryFile);
        FDataFile.Free;
        FDataFile := nil;
        MF.MainHintShow(1, Translate(MF.Language, 'mes_filesave'));
      end;
    end
    else

      if Q.FMemoryTime + 15 / (24 * 60 * 60) < Time then
    begin
      Q.Operation := 0;
      MF.MainHintShow(0, Translate(MF.Language, 'mes_filesaveerror'));
    end
    else

      if Q.FMemoryTime + 3 / (24 * 60 * 60) < Time then
    begin
      Q.FMemoryTime := Time;
      Q.SendAnsiString('>D 18;' + IntToStr(Q.FMemoryIndex + Q.FMemoryOffset) + #13#10);
    end;
  end;
end;

procedure TMF.LogChange(var mes: TMessage);
begin
  if Follow then
  begin
    InListView.Items.BeginUpdate;
    InListView.Items.Count := Length(PInPacket^);
    InListView.ItemIndex := Pred(InListView.Items.Count);
    InListView.Items.EndUpdate;
    InListView.Repaint;
    SendMessage(InListView.Handle, LVM_ENSUREVISIBLE, Pred(InListView.Items.Count), 0);

    if LogPanel.Parent = MainPanel then
    begin
      SendMessage(LogPanel.Handle, WM_SETREDRAW, 1, 0);
      RedrawWindow(LogPanel.Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
    end;
  end;

  InByteCountLabel.Caption := Translate(MF.Language, 'InByteCount') + ': ' +  FormatFloat('#,##0##', FInCount);
  OutByteCountLabel.Caption := Translate(MF.Language, 'OutByteCount') + ': ' + FormatFloat('#,##0##', FOutCount);
end;

procedure TMF.QReceiveData(Sender: TObject; DataPtr: Pointer;
  DataSize: Integer);
var
  i, j, V1, V2, V3, L: Integer;
  isLast: Boolean;
  BackVersion: TVersionType;
  BackV1,BackV2,BackV3: Integer;
  sData: String;
begin
  BackVersion := FVersion;
  BackV1 := Length(FInPacketV1);
  BackV2 := Length(FInPacketV2);
  BackV3 := Length(FInPacketV3);
  if (0 < BackV1) and (FInPacketV1[BackV1 - 1].State = 0) then Dec(BackV1);

  MS.Write(Pointer(Integer(DataPtr))^, DataSize);

  L := Length(FInSource);
  SetLength(FInSource, Succ(L));
  FInSource[L].Time := Now;
  FInSource[L].Position := MS.Size - DataSize;
  FInSource[L].Size := DataSize;
  FInSource[L].State := 1;

  isLast := (Length(PInPacket^) = 0) or
    (Pred(Length(PInPacket^)) = InListView.ItemIndex);
  case FVersion of
    vtDetect:
      begin
        V1 := 0;
        OnSourceEventV1(L);
        for i := 0 to Pred(Length(FInPacketV1)) do
          if FInPacketV1[i].State = 2 then Inc(V1);

        OnSourceEventV2(L);
        V2 := 0;
        for i := 0 to Pred(Length(FInPacketV2)) do
          if FInPacketV2[i].State = 2 then Inc(V2);

        OnSourceEventV3(L);
        V3 := 0;
        for i := 0 to Pred(Length(FInPacketV3)) do
          if FInPacketV3[i].State = 2 then Inc(V3);

        if V1 > V2 + V3 then
        begin
          Version := vtVersion1;
          for i := Max(0, FInStart) to High(FInSource) do
            OnSourceEventV1(i);
        end else

        if V2 > V1 + V3 then
        begin
          Version := vtVersion2;
          for i := Max(0, FInStart) to High(FInSource) do
            OnSourceEventV2(i);
        end else

        if V3 > V1 + V2 then
        begin
          Setlength(FInPacketV3,0);
          Version := vtVersion3;
          Q.DeviceVer:= '250';
          Q.DevicePassword:= '123456';

          for i := Max(0, FInStart) to High(FInSource) do
            begin
              OnSourceEventV3(i);
              Follow:= True;
            end;
        end;

        if Version <> vtDetect then
          begin
            Follow := True;
            MF.MainHintShow(1, Translate(MF.Language, 'mes_devicestart'));
          end;
      end;
    vtVersion1: OnSourceEventV1(L);
    vtVersion2: OnSourceEventV2(L);
    vtVersion3: OnSourceEventV3(L);
  end;

  case Q.FOperation of
    1:    begin
            if FInSource[L].Size = 5 then QOperationData1(L);
          end;
    2, 3: begin
            for i := BackV1 to Pred(Length(FInPacketV1)) do
              QOperationData2(i);
          end;
  end;

  // обработка вне протокола
  if Q.DeviceVer = '5' then
  begin
    sData := '';
    for j := 0 to Pred(FInSource[L].Size) do
      sData := sData + Char(TByteArray(MForm.MS.Memory^)[FInSource[L].Position + j]);

    if 0 < Pos('DEVICE PASSWORD ERROR', sData) then
    begin
      Q.ReadLocked := True;
      MF.MainHintShow(1, Translate(MF.Language, 'mes_passwordneed'));
    end;

    if (0 < Pos('DEVICE PASSWORD OK', sData)) then
    begin
      Q.ReadLocked := False;
      Q.DevicePassword := Q.UserPassword;
    end;

    if (0 < Pos('[Press ENTER to execute the previous command again]', sData))
    then
    begin
      Q.ReadLocked := False;
      Q.DevicePassword := Q.UserPassword;
    end;

    if (0 < Pos('Settings write OK EXTFLASH', sData)) then
    begin
      MF.MainHintShow(1, Translate(MF.Language, 'SR1'));
    end;

    if (0 < Pos('Settings write Error EXTFLASH', sData)) then
    // устройство жрет все, все для него ок...
    begin
      MF.MainHintShow(1, Translate(MF.Language, 'SR0'));
    end;
  end;

  // if LogPanel.Parent = MainPanel then SendMessage(LogPanel.Handle, WM_SETREDRAW, 0, 0);
  FInCount := FInCount + DataSize;
  SendMessage(Handle, WM_LOGNOTIFY, 0, 0);

  if (BackVersion = vtDetect) and (FVersion <> vtDetect) then
  begin
    CheckNameTimer.Enabled := True;
    CheckNameTimer.OnTimer(Sender);
  end;
end;

procedure TMF.CaptionPanelDblClick(Sender: TObject);
begin
  case WindowState of
    wsNormal:
      WindowState := wsMaximized;
    wsMaximized:
      WindowState := wsNormal;
  end;
  UpdateTitle;
end;

procedure TMF.CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := moveCaption;
  FPos.X := Left;
  FPos.Y := Top;

  FMove.X := X;
  FMove.Y := Y;
  FMove := TPanel(Sender).ClientToScreen(FMove);
end;

procedure TMF.CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if FIsMove = moveCaption then
  begin
    P.X := X;
    P.Y := Y;
    P := TPanel(Sender).ClientToScreen(P);
    Left := FPos.X + P.X - FMove.X;
    Top := FPos.Y + P.Y - FMove.Y;
  end;
end;

procedure TMF.CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := moveNone;
end;

procedure TMF.BorderBMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := MoveBottom;
  FPos.X := Width;
  FPos.Y := Height;

  FMove.X := X;
  FMove.Y := Y;
  FMove := TPanel(Sender).ClientToScreen(FMove);
end;

procedure TMF.BorderBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if FIsMove = MoveBottom then
  begin
    P.X := X;
    P.Y := Y;
    P := TPanel(Sender).ClientToScreen(P);
    Height := P.Y - Top;
  end;
end;

procedure TMF.BorderBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := moveNone;
end;

procedure TMF.BorderRMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := MoveRight;
  FPos.X := Width;
  FPos.Y := Height;

  FMove.X := X;
  FMove.Y := Y;
  FMove := TPanel(Sender).ClientToScreen(FMove);
end;

procedure TMF.BorderRMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if FIsMove = MoveRight then
  begin
    P.X := X;
    P.Y := Y;
    P := TPanel(Sender).ClientToScreen(P);
    Width := P.X - Left;
  end;
end;

procedure TMF.BorderRMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := moveNone;
end;

procedure TMF.BorderLMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := MoveLeft;
  FPos.X := Width;
  FPos.Y := Height;

  FMove.X := X;
  FMove.Y := Y;
  FMove := TPanel(Sender).ClientToScreen(FMove);
end;

procedure TMF.BorderLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if FIsMove = MoveLeft then
  begin
    P.X := X;
    P.Y := Y;
    P := TPanel(Sender).ClientToScreen(P);
    SetBounds(P.X, Top, FPos.X + FMove.X - P.X, Height)
  end;
end;

procedure TMF.BorderLMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FIsMove := moveNone;
end;

procedure TMF.CheckNameTimerTimer(Sender: TObject);
begin

  if Not(Q = nil) and (Q.WaitInfo) then
  begin
    if (not Q.ReadLocked) and (FVersion = vtVersion1) then
    begin
      Q.SendAnsiString('>I 0' + #13#10);
      if not(Q.FDeviceVer = '5') then
      begin
        Q.SendAnsiString('>I 1' + #13#10);
        Q.SendAnsiString('>I 4' + #13#10);
        Q.SendAnsiString('>I 7' + #13#10);
      end;

      if SettingsPanel.Parent = MainPanel then
        Commands_Exec(act_SettingsGet);
    end;
  end
  else
    CheckNameTimer.Enabled := False;
end;

procedure TMF.MainHintShow(aType: Integer; aText: string);
var
  X1, X2, i: Integer;
begin
  if Assigned(FInfoPanel) then
  begin
    if FInfoPanel.Caption = aText then
      Exit
    else
      MainHintHide(nil);
  end;

  FInfoPanel := TInfoPanel.Create(self);
  FInfoPanel.ParentColor := False;
  FInfoPanel.AutoSize := False;
  FInfoPanel.StyleElements := [];
  FInfoPanel.BevelOuter := bvNone;
  FInfoPanel.DoubleBuffered := False;

  FInfoPanel.Left := ClientWidth;
  FInfoPanel.Top := ClientHeight - 96;
  FInfoPanel.Height := 48;
  FInfoPanel.Anchors := []; // [akRight,akBottom];
  FInfoPanel.DisableAlign;

  case aType of
    0: FInfoPanel.Color := clRed;
    1: FInfoPanel.Color := _Green;
    2: FInfoPanel.Color := clSilver;
  end;

  FInfoPanel.Parent := self;

  FInfoPanel.Width := 48 + FInfoPanel.Canvas.TextWidth(aText);
  FInfoPanel.Caption := aText;
  X1 := ClientWidth + FInfoPanel.Width;
  X2 := ClientWidth - FInfoPanel.Width;

  for i := 15 to 30 do
  begin
    FInfoPanel.Left := LiteResize(X1, X2, 30, i, 30);
    FInfoPanel.Invalidate;
    FInfoPanel.Repaint;
  end;
  HideHint.Enabled := True;
end;

procedure TMF.MinimizeButtonClick(Sender: TObject);
begin
  WindowState := wsMinimized;
end;

procedure TMF.NormalizeButtonClick(Sender: TObject);
begin
  case WindowState of
    wsNormal: WindowState := wsMaximized;
    wsMaximized: WindowState := wsNormal;
  end;
  UpdateTitle;
end;

procedure TMF.InfoExternal(var mes: TMessage);
begin
  case mes.WParam of
    ipWellcome:
      begin
        FWellcomeFile := PChar(mes.LParam);
        UpdateWellcome;
      end;
    ipAddition:
      begin
        FAdditionFile := PChar(mes.LParam);
        UpdateWellcome;
      end;
    ipDevice:
      begin
        FDeviceFile := PChar(mes.LParam);
        UpdateWellcome;
      end
  else
    MainHintShow(mes.WParam, PChar(mes.LParam));
  end;
end;

procedure TMF.MainHintHide(Sender: TObject);
begin
  if not Assigned(FInfoPanel) then
    Exit;

  FreeAndNil(FInfoPanel);
  Repaint;
  HideHint.Enabled := False;
end;

procedure TMF.SetVersion(aVersion: TVersionType);
begin
  ClearControlsRecursive(self);

  InListView.Items.BeginUpdate;
  InListView.Items.Clear;
  case aVersion of
    vtDetect:
      begin
        FInStart := Length(FInSource);
        PInPacket := @FInSource;
      end;
    vtVersion0:
      begin
        PInPacket := @FInSource;
      end;
    vtVersion1:
      begin
        btnShowTEXT.OnClick(nil);
        PInPacket := @FInPacketV1;
      end;
    vtVersion2:
      begin
        btnShowHEX.OnClick(nil);
        PInPacket := @FInPacketV2;
      end;
    vtVersion3:
      begin
        btnShowHEX.OnClick(nil);
        PInPacket := @FInPacketV3;
      end;
  end;
  InListView.Items.Count := Length(PInPacket^);
  InListView.Items.EndUpdate;
  InListView.Repaint;

  if aVersion <> FVersion then
    SettingsReady := False;
  FVersion := aVersion;
end;

procedure TMF.UpdateFolders(Sender: TObject);
var
  FIcon: TIcon;
begin
  FIcon := TIcon.Create;
  btnWellcome.ShowHint := (WellcomePanel.Parent = MainPanel);
  btnInfo.ShowHint := (InfoPanel.Parent = MainPanel);
  BtnCONFIG.ShowHint := (SettingsPanel.Parent = MainPanel);
  BtnLog.ShowHint := (LogPanel.Parent = MainPanel);
  btnFuel.ShowHint := (FuelPanel.Parent = MainPanel);

  FIcon.Handle := LoadImage(hInstance, PChar(IcoPrefix(WellcomePanel.Parent = MainPanel) + 'WELLCOME'), IMAGE_ICON, 24, 24, LR_SHARED);
  btnWellcome.Glyph.Assign(FIcon);

  FIcon.Handle := LoadImage(hInstance, PChar(IcoPrefix(InfoPanel.Parent = MainPanel) + 'INFO'), IMAGE_ICON, 24, 24, LR_SHARED);
  btnInfo.Glyph.Assign(FIcon);

  FIcon.Handle := LoadImage(hInstance, PChar(IcoPrefix(SettingsPanel.Parent = MainPanel) + 'CONFIG'), IMAGE_ICON, 24, 24, LR_SHARED);
  BtnCONFIG.Glyph.Assign(FIcon);

  FIcon.Handle := LoadImage(hInstance, PChar(IcoPrefix(LogPanel.Parent = MainPanel) + 'LOG'), IMAGE_ICON, 24, 24, LR_SHARED);
  BtnLog.Glyph.Assign(FIcon);

  FIcon.Handle := LoadImage(hInstance, PChar(IcoPrefix(LogPanel.Parent = MainPanel) + 'FUEL'), IMAGE_ICON, 24, 24, LR_SHARED);
  btnFuel.Glyph.Assign(FIcon);

  if WellcomePanel.Parent = MainPanel then
  begin
    FIcon.Handle := LoadImage(hInstance, 'E_WELLCOME', IMAGE_ICON, 16, 16, LR_SHARED);
    CaptionImage.Picture.Assign(FIcon);
    FIcon.Handle := LoadImage(hInstance, 'E_WELLCOME', IMAGE_ICON, 32, 32, LR_SHARED);
    Application.Icon.Assign(FIcon);
  end
  else

    if InfoPanel.Parent = MainPanel then
  begin
    FIcon.Handle := LoadImage(hInstance, 'E_INFO', IMAGE_ICON, 16, 16, LR_SHARED);
    CaptionImage.Picture.Assign(FIcon);
    FIcon.Handle := LoadImage(hInstance, 'E_INFO', IMAGE_ICON, 32, 32, LR_SHARED);
    Application.Icon.Assign(FIcon);
  end
  else

    if SettingsPanel.Parent = MainPanel then
  begin
    FIcon.Handle := LoadImage(hInstance, 'E_CONFIG', IMAGE_ICON, 16, 16, LR_SHARED);
    CaptionImage.Picture.Assign(FIcon);
    FIcon.Handle := LoadImage(hInstance, 'E_CONFIG', IMAGE_ICON, 32, 32, LR_SHARED);
    Application.Icon.Assign(FIcon);
  end
  else

    if LogPanel.Parent = MainPanel then
  begin
    FIcon.Handle := LoadImage(hInstance, 'E_LOG', IMAGE_ICON, 16, 16, LR_SHARED);
    CaptionImage.Picture.Assign(FIcon);
    FIcon.Handle := LoadImage(hInstance, 'E_LOG', IMAGE_ICON, 32, 32, LR_SHARED);
    Application.Icon.Assign(FIcon);
  end;

  if FuelPanel.Parent = MainPanel then
  begin
    FIcon.Handle := LoadImage(hInstance, 'E_FUEL', IMAGE_ICON, 16, 16, LR_SHARED);
    CaptionImage.Picture.Assign(FIcon);
    FIcon.Handle := LoadImage(hInstance, 'E_FUEL', IMAGE_ICON, 32, 32, LR_SHARED);
    Application.Icon.Assign(FIcon);
  end;

  FIcon.Free;
end;

procedure TMF.SetBrowserURL(const Value: string);
begin
  FBrowsed := False;
  FBrowserURL := Value;
  UpdateBrowser(nil);
end;

procedure TMF.UpdateBrowser(Sender: TObject);
begin
  if Length(FBrowserURL) = 0 then
  begin
    PanelWC.Align := alClient;

    BrowserPanel.Align := alBottom;
    BrowserPanel.Height := 5;
  end
  else
  begin
    if FBrowsed = False then
    begin
      if WellcomePanel.Parent = MainPanel then
        try
          WellcomeWebBrowser.Navigate(FBrowserURL);
          FBrowsed := True;
        except
          FBrowsed := False;
        end;

      if FBrowsed then
      begin
        PanelWC.Align := alTop;
        PanelWC.Realign;

        BrowserPanel.Align := alClient;
        WellcomeWebBrowser.Repaint;
      end
      else
      begin
        PanelWC.Align := alClient;

        BrowserPanel.Align := alBottom;
        BrowserPanel.Height := 5;
      end
    end;
  end;
end;

procedure TMF.act_PageWellcomeExecute(Sender: TObject);
begin
  WellcomePanel.Parent := MainPanel;
  WellcomePanel.Repaint;
  WellcomePanel.BringToFront;

  // WellcomePanel.Parent:= TabSheet1;
  InfoPanel.Parent := TabSheet2;
  SettingsPanel.Parent := TabSheet3;
  LogPanel.Parent := TabSheet4;
  FuelPanel.Parent := TabSheet5;

  PageLabel.Top := btnWellcome.Top;
  UpdateFolders(Sender);
  UpdateBrowser(Sender);
end;

procedure TMF.actPauseExecute(Sender: TObject);
begin
  Follow := False;
end;

procedure TMF.actPlayExecute(Sender: TObject);
begin
  Follow := True;
end;

procedure TMF.act_PageInfoExecute(Sender: TObject);
begin
  if Not BeConnected then
  begin
    MF.MainHintShow(2, Translate(MF.Language, 'mes_settingsnodevice'));
    Exit;
  end;

  InfoPanel.Parent := MainPanel;
  InfoPanel.Repaint;
  InfoPanel.BringToFront;

  WellcomePanel.Parent := TabSheet1;
  // InfoPanel.Parent:= TabSheet2;
  SettingsPanel.Parent := TabSheet3;
  LogPanel.Parent := TabSheet4;
  FuelPanel.Parent := TabSheet5;

  PageLabel.Top := btnInfo.Top;
  UpdateFolders(Sender);
end;

procedure TMF.act_PageSettingsExecute(Sender: TObject);
begin
  if (Q = nil) then
  begin
    MF.MainHintShow(2, Translate(MF.Language, 'mes_settingsnodevice'));
    Exit;
  end;

  if Not FCanShowSettings then
  begin
    MF.MainHintShow(2, Translate(MF.Language, 'mes_settingsnoversion') + ' ' +
      Q.FDeviceVer);
    Exit;
  end;

  SettingsPanel.Parent := MainPanel;
  SettingsPanel.Repaint;
  SettingsPanel.BringToFront;

  WellcomePanel.Parent := TabSheet1;
  InfoPanel.Parent := TabSheet2;
  // SettingsPanel.Parent:= TabSheet3;
  LogPanel.Parent := TabSheet4;
  FuelPanel.Parent := TabSheet5;

  PageLabel.Top := BtnCONFIG.Top;
  UpdateFolders(Sender);

  if Assigned(FTabPanel) then
  begin
    FTabPanel.Checked := True;
    FTabPanel := nil;
  end;

  SettingsPanel.Invalidate;
  PanelT1.Realign;
  UpdateFolders(Sender);

  if Not SettingsReady then
    Commands_Exec(act_SettingsGet);
end;

procedure TMF.act_PageLogExecute(Sender: TObject);
begin
  LogPanel.Parent := MainPanel;
  LogPanel.Repaint;
  LogPanel.BringToFront;

  WellcomePanel.Parent := TabSheet1;
  InfoPanel.Parent := TabSheet2;
  SettingsPanel.Parent := TabSheet3;
  // LogPanel.Parent:= TabSheet4;
  FuelPanel.Parent := TabSheet5;

  PageLabel.Top := BtnLog.Top;
  UpdateFolders(Sender);
end;

procedure TMF.act_PageFuelExecute(Sender: TObject);
begin
  FuelPanel.Parent := MainPanel;
  FuelPanel.BringToFront;

  WellcomePanel.Parent := TabSheet1;
  InfoPanel.Parent := TabSheet2;
  SettingsPanel.Parent := TabSheet3;
  LogPanel.Parent := TabSheet4;
  // FuelPanel.Parent:= TabSheet5;

  PageLabel.Top := btnFuel.Top;
  UpdateFolders(Sender);
end;

procedure TMF.ButtonENClick(Sender: TObject);
begin
  Language := 1;
end;

procedure TMF.ButtonRUClick(Sender: TObject);
begin
  Language := 0;
end;

procedure TMF.Splitter3CanResize(Sender: TObject; var NewSize: Integer;
  var Accept: Boolean);
begin
  Accept := (60 <= NewSize) and (NewSize <= 300);
end;

// --------------------------------------------------------------------------------------------------------------------

// Достает из строки с нуль-терминированными подстроками следующую нуль-терминированную
// подстроку начиная с позиции aStartPos, потом устанавливает aStartPos на символ
// следующий за терминирующим #0.
function GetNextSubstring(aBuf: string; var aStartPos: Integer): string;
var
  vLastPos: Integer;
begin
  if (aStartPos < 1) then
  begin
    raise ERangeError.Create('aStartPos должен быть больше 0');
  end;

  if (aStartPos > Length(aBuf)) then
  begin
    result := '';
    Exit;
  end;

  vLastPos := PosEx(#0, aBuf, aStartPos);
  result := Copy(aBuf, aStartPos, vLastPos - aStartPos);
  aStartPos := aStartPos + (vLastPos - aStartPos) + 1;
end;

function TMF.Q: TPortInfo;
begin
  if (0 <= FPortIndex) and (FPortIndex < QList.Count) then
    result := QList[FPortIndex]
  else
    result := nil;
end;

procedure TMF.SetPortIndex(const Value: Integer);
var
  i: Integer;
begin
  if -1 < Value then
    BeConnected := True;

  for i := 0 to Pred(QList.Count) do
    QList[i].Active := (i = Value);

  if (FPortIndex <> Value) then
  begin
    if (-1 < FPortIndex) and Not(Q = nil) then
      Q.Com.Disconnect;
    if (-1 < Value) then
      Version := vtDetect;
  end;

  for i := 0 to Pred(QList.Count) do
    if i = Value then
    begin
      QList[i].Com.OnReceiveData := QReceiveData;
      QList[i].Com.Connect;

      if QList[i].Com.Connected then
        QList[i].ImageIndex := stConnected
      else
        QList[i].ImageIndex := stError;

      QList[i].DeviceName := '';
      QList[i].DeviceVer := '';
      QList[i].DeviceIMEI := '';
      QList[i].DeviceSOFT := '';
    end
    else
    begin
      QList[i].Com.Disconnect;
      QList[i].Com.OnReceiveData := QWaitData;
      if QList[i].Category = 'RS232' then
        QList[i].ImageIndex := stAlien
      else
        QList[i].ImageIndex := stReady;
      QList[i].DeviceName := '';
      QList[i].DeviceVer := '';
      QList[i].DeviceIMEI := '';
      QList[i].DeviceSOFT := '';
    end;

  ControlsLoadSettings;
  UpdateTitle;

  if (FPortIndex <> Value) then
  begin
    FPortIndex := Value;
    if -1 < Value then
      PasswordEdit.Text := DefaultPassword;
    if (Value = -1) and (SettingsPanel.Parent = MainPanel) then
      act_PageWellcomeExecute(nil)
    else if (Value > -1) and (WellcomePanel.Parent = MainPanel) then
      act_PageInfoExecute(nil);
  end;

  Commands_Update(nil);
end;

procedure TMF.act_PortExecute(Sender: TObject);
begin
  if Sender is TPortInfo then
    SetPortIndex(QList.IndexOf(TPortInfo(Sender)));
end;

constructor TMF.Create(AOwner: TComponent);
var
  fn: String;
  Info: Pointer;
  FI: PVSFixedFileInfo;
  InfoSize, LMemSize: DWord;
  FIcon: TIcon;
begin
  inherited;
  WellcomeWebBrowser.StyleElements := [];
  PInPacket := @FInSource;

  FFollow := True;
  FUpdateProURL := '';
  FCurrentError := -1;
  PathLabel.Caption := DataDir;
  act_PageFuel.Visible := False;

  // ........................................................ program version ...
  fn := Application.ExeName;
  InfoSize := GetFileVersionInfoSize(PChar(fn), LMemSize);
  if InfoSize > 0 then
  begin
    GetMem(Info, InfoSize);
    GetFileVersionInfo(PChar(fn), 0, InfoSize, Info);
    VerQueryValue(Info, '\', Pointer(FI), LMemSize);
    FreeMem(Info, LMemSize);
  end;
  FUpdateVersion := 0;
  FUpdateModule := '';

  FWellcomeUpdateThread := TUpdateThread.Create(True);
  FWellcomeUpdateThread.Ident := ipWellcome;
  FWellcomeUpdateThread.URL := UpdateEmptyURL + '?soft=' + FormatDateTime('YYYYMMDD', sVersion);
  FWellcomeUpdateThread.Start;

  FAdditionUpdateThread := TUpdateThread.Create(True);
  FAdditionUpdateThread.Ident := ipAddition;
  FAdditionUpdateThread.URL := UpdateAdditionURL;
  FAdditionUpdateThread.Start;

  FInCount := 0;
  FOutCount := 0;

  QList := TPortInfoList.Create;
  QList.FControlParent := LPanel;
  QList.Clear;
  FPortIndex := -1;

  Language := 0;
  FVersion := vtDetect;
  HEX := False;

  MS := TMemoryStreamEx.Create;

  FInStart := 0;
  SetLength(FInSource, 0);
  SetLength(FInPacketV1, 0);
  SetLength(FInPacketV2, 0);

  WellcomePanel.Parent := MainPanel;

  FCommandList := TCommandList.Create;
  Commands_Fill(nil);

  ControlsLoadMonitor;
  UpdatePortListUSB; // COM;

  FIcon := TIcon.Create;
  FIcon.Handle := LoadImage(hInstance, 'I_PAUSE', IMAGE_ICON, 16, 16, LR_SHARED);
  btnPause.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'I_PLAY', IMAGE_ICON, 16, 16, LR_SHARED);
  btnPlay.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'I_OPEN', IMAGE_ICON, 24, 24, LR_SHARED);
  btnOpen.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'I_SAVE', IMAGE_ICON, 24, 24, LR_SHARED);
  btnSave.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'E_GET', IMAGE_ICON, 24, 24, LR_SHARED);
  btnGet.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'E_SET', IMAGE_ICON, 24, 24, LR_SHARED);
  btnSet.Glyph.Assign(FIcon);
  FIcon.Handle := LoadImage(hInstance, 'E_ATTENTION', IMAGE_ICON, 32, 32, LR_SHARED);
  UpdateImage.Picture.Assign(FIcon);
  FIcon.Free;

  StyleApply;
end;

procedure TMF.StyleApply;
const
  B: Integer = 12;
var
  i: Integer;
begin
  MF.Color := _Style.ColorBack;
  MF.Font.Color := _Style.ColorLabel;
  // LPanel.Color:= _Style.ColorBack;
  Panel3.Color := _Style.ColorBack;

  PanelS1.Color := _Style.ColorPanel;
  PanelS2.Color := _Style.ColorPanel;
  PanelS3.Color := _Style.ColorPanel;
  PanelS4.Color := _Style.ColorPanel;
  Panel9.Color := _Style.ColorPanel;
  Panel4.Color := _Style.ColorPanel;
  SendPanel.Color := _Style.ColorPanel;
  PanelT0.Color := _Style.ColorPanel;
  PanelT11.Color := _Style.ColorPanel;
  PanelT2.Color := _Style.ColorPanel;
  PanelFF.Color := _Style.ColorPanel;
  PanelF1.Color := _Style.ColorPanel;
  PanelF2.Color := _Style.ColorPanel;
  PanelWC.Color := _Style.ColorPanel;
  PanelWB.Color := _Style.ColorPanel;
  CaptionPanel.Color := _Style.ColorPanel;

  UpdateFolders(nil);
  for i := 0 to Pred(PanelT2.ComponentCount) do
    if PanelT2.Components[i] is TTabPanel then
      TTabPanel(PanelT2.Components[i]).UpdateStyle;

  for i := 0 to Pred(QList.Count) do
    QList[i].UpdateStyle;

end;

procedure TMF.Timer1Timer(Sender: TObject);
begin
  Timer1.Tag := (Timer1.Tag + 1) mod 250;
  case Timer1.Tag of
    0 .. 15:
      EmptyImage.Top := LPanel.Height - EmptyImage.Height + 16 -  LiteResize(0, 60, 15, Timer1.Tag, 0);
    30 .. 45:
      EmptyImage.Top := LPanel.Height - EmptyImage.Height + 16 - LiteResize(0, 60, 15, Timer1.Tag - 30, 0);
    60 .. 75:
      EmptyImage.Top := LPanel.Height - EmptyImage.Height + 16 - LiteResize(60, 0, 15, Timer1.Tag - 60, 0);
  end;
  EmptyImage.Repaint;
end;

procedure TMF.DataTimerTimer(Sender: TObject);
var
  T: TTime;
begin
  T := Now;
  if (0 < Length(PInPacket^)) then
    begin
      DataLabel.SetBounds(92 + Round((T - PInPacket^[Length(PInPacket^) - 1].Time) *
                         (24 * 60 * 60 * 500)), 0, 2 * PInPacket^[Length(PInPacket^) -  1].Size, 4);
      DataLabel.Color := PInPacket^[Length(PInPacket^) - 1].Color;
    end
  else
    begin
      DataLabel.SetBounds(-100, 0, 0, 4);
    end;

  if -1 < PortIndex then
    if QList[PortIndex].FActiveTime + 2/(24*60*60) < Now then
      if (Length(FInSource) = 0) and (FVersion = vtDetect ) then
        QList[PortIndex].SendAnsiString(MasterCRC(#49#16#176));
end;

destructor TMF.Destroy;
begin
  SetLength(FInSource, 0);
  SetLength(FInPacketV1, 0);
  SetLength(FInPacketV2, 0);

  if FWellcomeUpdateThread <> nil then
    try
      FWellcomeUpdateThread.Terminate;
      FreeAndNil(FWellcomeUpdateThread);
    except
    end;

  if FAdditionUpdateThread <> nil then
    try
      FAdditionUpdateThread.Terminate;
      FreeAndNil(FAdditionUpdateThread);
    except
    end;

  FCommandList.Free;
  inherited;
end;

procedure TMF.UpdatePortListUSB;
const
  DIGCF_ALLCLASSES = $00000004;
  DIGCF_PRESENT = $00000002;
  DIGCF_PROFILE = $00000008;
  DIGCF_DEVICEINTERFACE = $00000010;

  SPDRP_DEVICEDESC = $00000000;
  SPDRP_HARDWAREID = $00000001;
  SPDRP_COMPATIBLEIDS = $00000002;
  SPDRP_SERVICE = $00000004;
  SPDRP_CLASS = $00000007;
  SPDRP_CLASSGUID = $00000008;
  SPDRP_DRIVER = $00000009;
  SPDRP_CONFIGFLAGS = $0000000A;
  SPDRP_MFG = $0000000B;
  SPDRP_FRIENDLYNAME = $0000000C;
  SPDRP_LOCATION_INFORMATION = $0000000D;
  SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = $0000000E;
  SPDRP_CAPABILITIES = $0000000F;
  SPDRP_UI_NUMBER = $00000010;
  SPDRP_UPPERFILTERS = $00000011;
  SPDRP_LOWERFILTERS = $00000012;
  SPDRP_BUSTYPEGUID = $00000013;
  SPDRP_LEGACYBUSTYPE = $00000014;
  SPDRP_BUSNUMBER = $00000015;
  SPDRP_ENUMERATOR_NAME = $00000016;
  SPDRP_SECURITY = $00000017;
  SPDRP_SECURITY_SDS = $00000018;
  SPDRP_DEVTYPE = $00000019;
  SPDRP_EXCLUSIVE = $0000001A;
  SPDRP_CHARACTERISTICS = $0000001B;
  SPDRP_ADDRESS = $0000001C;
  SPDRP_UI_NUMBER_DESC_FORMAT = $0000001D;
  SPDRP_DEVICE_POWER_DATA = $0000001E;
  SPDRP_REMOVAL_POLICY = $0000001F;
  SPDRP_REMOVAL_POLICY_HW_DEFAULT = $00000020;
  SPDRP_REMOVAL_POLICY_OVERRIDE = $00000021;
  SPDRP_INSTALL_STATE = $00000022;
  SPDRP_LOCATION_PATHS = $00000023;
var
  dwRequired: DWord;
  hDev, hAllDevices: H_DEV;
  dwInfo: DWord;
  Data: SP_DEVINFO_DATA;
  Buff: array [0 .. 1023] of ansichar;
  V1, v12, vName: AnsiString;
  Guid: TGUID;
  i, P: Integer;
begin
  for i := 0 to Pred(QList.Count) do
    QList[i].Exist := False;

  Guid := StringToGUID('{4D36E978-E325-11CE-BFC1-08002BE10318}');
  hDev := SetupDiCreateDeviceInfoList(@Guid, 0);
  if DWord(hDev) <> INVALID_HANDLE_VALUE then
    try
      hAllDevices := SetupDiGetClassDevsExA(nil, nil, 0, DIGCF_PRESENT or DIGCF_ALLCLASSES, hDev, nil, 0);
      if DWord(hAllDevices) <> INVALID_HANDLE_VALUE then
        try
          FillChar(Data, SizeOf(SP_DEVINFO_DATA), 0);
          Data.cbSize := SizeOf(SP_DEVINFO_DATA);
          dwInfo := 0;
          if SetupDiEnumDeviceInfo(hAllDevices, dwInfo, Data) then
          begin
            while SetupDiEnumDeviceInfo(hAllDevices, dwInfo, Data) do
            begin
              dwRequired := 0; // SPDRP_HARDWAREID
              // SPDRP_FRIENDLYNAME
              FillChar(Buff[0], 1024, #0);
              if SetupDiGetDeviceRegistryPropertyA(hAllDevices, @Data,
                SPDRP_HARDWAREID, nil, @Buff[0], 1024, @dwRequired) then
              begin
                V1 := Buff;
                if (1 = Pos('USB', V1)) and (0 < Pos('VID_0483&PID_5740', V1))
                  or (0 < Pos('VID_0483&PID_5742', V1)) or (0 < Pos('VID_1CBE&PID_0009', V1)) then
                begin
                  if SetupDiGetDeviceRegistryPropertyA(hAllDevices, @Data,
                    SPDRP_FRIENDLYNAME, nil, @Buff[0], 1024, @dwRequired) then
                  begin
                    v12 := Buff;
                    vName := v12;
                    P := Pos('(COM', vName);
                    if 0 < P then
                      Delete(vName, 1, P);

                    P := Pos(')', vName);
                    if 0 < P then
                      Delete(vName, P, MaxInt);

                    if (Copy(vName, 1, 3) = 'COM') and (0 < StrToIntDef(Copy(vName, 4, MaxInt), -1)) then
                    begin // нашли  COM port
                      P := QList.IndexByName(vName);
                      if -1 < P then
                        QList[P].Exist := True
                      else
                      begin
                        P := QList.New(vName);
                        QList[P].Hint := v12;
                      end;
                      QList[P].DevicePID_VID := V1;
                    end;
                  end;
                end;
              end;
              {
                Ключ драйвера    213 -  master
                                \0004  - \0010
                Адрес            000001 000002
//                Код базового контейнера     6113349e-62b6-5a32-8598-f804f2dac4c5   8eff9aed-ccc9-557a-8e76-27abbb2d4ee9


                Имя физического устройства ??


              {}
              {
                for i:=0 to 36 do
                begin
                FillChar(Buff[0], 1024, #0);
                if SetupDiGetDeviceRegistryPropertyA(hAllDevices, @Data, i , nil, @Buff[0], 1024, @dwRequired) then
                begin
                v2:= Buff;
                if 0 < pos('COM6',v2) then
                dwInfo:= dwInfo;
                end;
                end;
                { }
              Inc(dwInfo);
            end;
          end;
        finally
          SetupDiDestroyDeviceInfoList(hAllDevices);
        end;
    finally
      SetupDiDestroyDeviceInfoList(hDev);
    end;

  // Выключаем
  for i := 0 to Pred(QList.Count) do
    if Not QList[i].Exist then
      QList[i].Com.Disconnect;

  // Cкрываем
  for i := 0 to Pred(QList.Count) do
    if Not QList[i].Exist then
      QList[i].Visible := False;

  // Показываем заглушку если уcтройств нет
  EmptyPanel.Visible := (0 = QList.PortCount);
  Timer1.Enabled := EmptyPanel.Visible;
  EmptyImage.Visible := EmptyPanel.Visible;

  // Показываем и
  for i := 0 to Pred(QList.Count) do
    if QList[i].Exist then
      QList[i].Visible := True;

  // Сообщем об отключении
  if (-1 < PortIndex) and not QList[PortIndex].Exist then
    MF.MainHintShow(0, Translate(MF.Language, 'mes_devicelost'));

  // Если порт выбран и он существует
  if (-1 < PortIndex) and QList[PortIndex].Exist then
    QList[PortIndex].Com.Connect
    // Выбранного порта нет - надо искать
  else
  begin
    for i := 0 to Pred(QList.Count) do
      if QList[i].Exist then
        QList[i].Com.OnReceiveData := QWaitData;

    for i := 0 to Pred(QList.Count) do
      if QList[i].Exist then
        QList[i].Com.Connect;
  end;

  if (0 = QList.PortCount) then PortIndex := -1;
  if (1 = QList.PortCount) then PortIndex :=  0;
end;

procedure TMF.UpdatePortListCOM;
const
  aNameStart = 'COM';
  GUID_DEVINTERFACE_SERENUM_BUS_ENUMERATOR: TGUID = '{4D36E978-E325-11CE-BFC1-08002BE10318}';
  GUID_DEVINTERFACE_COMPORT: TGUID = '{86e0d1e0-8089-11d0-9ce4-08003e301f73}';
var
  i, P: Integer;
  vBuf: string;
  vRes: Integer;
  vErr: Integer;
  vBufSize: Integer;
  vNameStartPos: Integer;
  vName: string;
begin
  vBufSize := 1024 * 16;
  vRes := 0;

  while vRes = 0 do
  begin
    SetLength(vBuf, vBufSize);
    SetLastError(ERROR_SUCCESS);
    vRes := QueryDosDevice(nil, @vBuf[1], vBufSize);
    vErr := GetLastError();

    // Вариант для двухтонки
    if (vRes <> 0) and (vErr = ERROR_INSUFFICIENT_BUFFER) then
    begin
      vBufSize := vRes;
      vRes := 0;
    end;

    if (vRes = 0) and (vErr = ERROR_INSUFFICIENT_BUFFER) then
    begin
      vBufSize := vBufSize + 1024;
    end;

    if (vErr <> ERROR_SUCCESS) and (vErr <> ERROR_INSUFFICIENT_BUFFER) then
    begin
      raise Exception.Create(SysErrorMessage(vErr));
    end
  end;
  SetLength(vBuf, vRes);

  for i := 0 to Pred(QList.Count) do
    QList[i].Exist := False;

  vNameStartPos := 1;
  vName := GetNextSubstring(vBuf, vNameStartPos);
  try
    while vName <> '' do
    begin
      if Pos(aNameStart, vName) = 1 then
      begin // нашли  COM port
        P := QList.IndexByName(vName);
        if -1 < P then
          QList[P].Exist := True
        else
          QList.New(vName);
      end;
      vName := GetNextSubstring(vBuf, vNameStartPos);
    end;
  finally
  end;

  EmptyPanel.Visible := (0 = QList.PortCount);
  btn_Commands.Visible := Not EmptyPanel.Visible;
  Timer1.Enabled := EmptyPanel.Visible;
  EmptyImage.Visible := EmptyPanel.Visible;

  // Выключаем
  for i := 0 to Pred(QList.Count) do
    if Not QList[i].Exist then
      QList[i].Com.Disconnect;

  // Показываем или скрываем
  for i := 0 to Pred(QList.Count) do
    QList[i].Visible := QList[i].Exist;

  // Если порт выбран и он существует
  if (-1 < PortIndex) and QList[PortIndex].Exist then
    QList[PortIndex].Com.Connect

    // Выбранного порта нет - надо искать
  else
  begin
    for i := 0 to Pred(QList.Count) do
      if QList[i].Exist then
        QList[i].Com.OnReceiveData := QWaitData;

    for i := 0 to Pred(QList.Count) do
      if QList[i].Exist then
        QList[i].Com.Connect;
  end;

  if (0 = QList.PortCount) then
    PortIndex := -1;
end;

procedure TMF.OnDeviceChange(var Msg: TMessage);
const
  DBT_DEVICEARRIVAL = $8000;
begin
  if Msg.WParam = DBT_DEVNODES_CHANGED then
    UpdatePortListUSB;
end;

procedure TMF.PanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if PortIndex = TPanel(Sender).Tag then
    if QList[TPanel(Sender).Tag].Stoped then
    begin
      QList[TPanel(Sender).Tag].Stoped := False;
      MF.MainHintShow(1, Translate(MF.Language, 'mes_deviceresume'));
    end
    else
    begin
      QList[TPanel(Sender).Tag].Stoped := True;
      MF.MainHintShow(0, Translate(MF.Language, 'mes_devicepause'));
    end
  else
    PortIndex := TPanel(Sender).Tag
end;

procedure TMF.PanelMouseEnter(Sender: TObject);
begin
  QList[TPanel(Sender).Tag].Selected := True;
  QList[TPanel(Sender).Tag].FPanelO.Repaint;
end;

procedure TMF.PanelMouseLeave(Sender: TObject);
begin
  QList[TPanel(Sender).Tag].Selected := False;
  QList[TPanel(Sender).Tag].FPanelO.Repaint;
end;

procedure TMF.PanelT2Click(Sender: TObject);
begin
  if Sender is TTabPanel then
    TTabPanel(Sender).Checked := True;
end;

procedure TMF.PasswordChanged(Sender: TObject);
var
  C: TObject;
  E: Boolean;
  i, H, Hold: Integer;
begin
  SettingsPasswordPanel.Visible := (Q.WriteLocked);

  act_SetCFG.Enabled := not Q.WriteLocked;
  act_OpenCFG.Enabled := not Q.WriteLocked;
  act_SaveCFG.Enabled := not Q.ReadLocked;
  SettingsToolsPanel.Visible := not Q.ReadLocked;

  PanelT1.Enabled := not Q.WriteLocked;

  if not Q.ReadLocked then
    H := 47 // 56
  else
    H := 1;

  if H <> SettingsToolsPanel.Height then
  begin
    Hold := SettingsToolsPanel.Height;

    for i := 1 to 15 do
    begin
      SettingsToolsPanel.Height := LiteResize(Hold, H, 15, i, 15);
      SettingsToolsPanel.Repaint;
      SettingsPasswordPanel.Repaint;
    end;
  end;

  act_SetCFG.Enabled := not Q.WriteLocked;
  act_OpenCFG.Enabled := not Q.WriteLocked;
  act_SaveCFG.Enabled := not Q.ReadLocked;
  SettingsToolsPanel.Visible := not Q.ReadLocked;

  if MF.VisualFind(PanelT1, 5, C) then
    if C is TStringClass then
      if Assigned(TStringClass(C).WinControl) then
        if TStringClass(C).WinControl is TEdit then
          if Q.WriteLocked then
            TEdit(TStringClass(C).WinControl).PasswordChar := '*'
          else
            TEdit(TStringClass(C).WinControl).PasswordChar := #0;
end;

procedure TMF.PasswordEditChange(Sender: TObject);
begin
  Q.UserPassword := PasswordEdit.Text;

  if (Q.ReadLocked) and (Length(PasswordEdit.Text) = 6) then
    Q.SendAnsiString(PasswordEdit.Text + #13#10);

  PasswordChanged(Sender);
end;

procedure TMF.PathLabelClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(PathLabel.Caption), nil, nil, SW_SHOWNORMAL);
end;

procedure TMF.PathLabelMouseEnter(Sender: TObject);
begin
  PathLabel.Font.Style := [fsUnderline];
end;

procedure TMF.PathLabelMouseLeave(Sender: TObject);
begin
  PathLabel.Font.Style := [];
end;

{ TPortInfoList }

function TPortInfoList.Get(const Index: Integer): TPortInfo;
begin
  result := TPortInfo(TList(self).Items[Index]);
end;

function TPortInfoList.IndexByName(Value: String): Integer;
var
  i: Integer;
begin
  result := -1;
  for i := 0 to Pred(Count) do
    if SameText(Items[i].PortName, Value) then
      Exit(i);
end;

function TPortInfoList.New(aPortName: String): Integer;
begin
  result := Add(TPortInfo.Create(nil));
  Items[result].OnExecute := MF.act_PortExecute;
  Items[result].Exist := True;

  Items[result].Com := TCommPortDriver.Create(nil);
  Items[result].Com.Port := '\\.\' + aPortName;
  Items[result].Com.OnReceiveData := MF.QWaitData;
  Items[result].Com.Connect;

  Items[result].FPanelO := TPanel.Create(MF);
  Items[result].FPanelO.Tag := result;
  Items[result].FPanelO.StyleElements := [];
  Items[result].FPanelO.BevelOuter := bvNone;
  Items[result].FPanelO.ParentColor := False;
  Items[result].FPanelO.Color := _Style.ColorPanel;
  Items[result].FPanelO.Height := 76;
  Items[result].FPanelO.ShowCaption := False;
  Items[result].FPanelO.FullRepaint := True;;
  Items[result].FPanelO.Parent := FControlParent;
  Items[result].FPanelO.Align := alBottom;

  Items[result].FPanelI := TDrawPanel.Create(MF);
  Items[result].FPanelI.Tag := result;
  Items[result].FPanelI.StyleElements := [];
  Items[result].FPanelI.BevelOuter := bvNone;
  Items[result].FPanelI.Color := _Style.ColorBack; // $00392D23;
  Items[result].FPanelI.ShowCaption := False;
  Items[result].FPanelI.FullRepaint := False;
  Items[result].FPanelI.DoubleBuffered := True;
  Items[result].FPanelI.Parent := Items[result].FPanelO;
  Items[result].FPanelI.Align := alNone;
  Items[result].FPanelI.SetBounds(2, 2, 72, 72);
  Items[result].FPanelI.OnMouseEnter := MF.PanelMouseEnter;
  Items[result].FPanelI.OnMouseLeave := MF.PanelMouseLeave;
  Items[result].FPanelI.OnMouseDown := MF.PanelMouseDown;

  Items[result].PortName := aPortName;
  Items[result].Caption := aPortName;
  Items[result].DeviceName := '';
  Items[result].Hint := aPortName;

  Items[result].UpdateStyle;
end;

function TPortInfoList.PortCount: Integer;
var
  i: Integer;
begin
  result := 0;
  for i := 0 to Pred(Count) do
    if Items[i].Exist then
      Inc(result);
end;

{ TPortInfo }

procedure TPortInfo.UpdateStyle;
begin
  FPanelI.Color := _Style.ColorBack; // $00392D23;
  FPanelO.Color := _Style.ColorPanel;
end;

function TPortInfo.WaitInfo: Boolean;
begin
  result := (FDeviceName = '') or (FDeviceVer = '') or (DeviceSOFT = '') or
    FWaitInfo;
end;

constructor TPortInfo.Create(AOwner: TComponent);
begin
  inherited;
  Operation := 0;
  FMemoryWrite := 0;
  FMemorySend1 := 0;
  FMemorySend2 := 0;
  FMemoryCount := 0;
  FMemoryOffset := 0;
  FHaveSettings := False;
  FDevicePassword := EmptyValue;
  FUserPassword := DefaultPassword;
  FLetters:= TList<AnsiString>.Create;
end;

destructor TPortInfo.Destroy;
begin
  FLetters.Free;
  inherited;
end;

procedure TPortInfo.DoUpdateInfo;
begin
  if (0 < Length(FDeviceName)) and (0 < Length(FDeviceVer)) and
    (0 < Length(FDeviceIMEI)) and (0 < Length(FDeviceSOFT)) then
  begin
    if FDeviceUpdateThread <> nil then
      try
        FDeviceUpdateThread.Terminate;
        FreeAndNil(FDeviceUpdateThread);
      except
      end;

    FDeviceUpdateThread := TUpdateThread.Create(True);
    // 'http://usb.duotec.ru/info_device.php?idsn=%s&type=%s&imei=%s&soft=%s';
    FDeviceUpdateThread.URL := Format(UpdateDeviceURL,
      [FDeviceName, FDeviceVer, FDeviceIMEI, FDeviceSOFT]);
    FDeviceUpdateThread.Ident := ipDevice;
    FDeviceUpdateThread.Start;
  end;
end;

function TPortInfo.GetDeviceVer: String;
begin
  if (0 < Pos('VID_0483&PID_5742', FDevicePID_VID)) then
    result := '5'
  else
    result := FDeviceVer;
end;

function TPortInfo.GetReadLocked: Boolean;
begin
  if DeviceVer = '5' then
    result := GetWriteLocked
  else
    result := False;
end;

function TPortInfo.GetWriteLocked: Boolean;
begin
  result := (FReadLocked = 1) or Not(FDevicePassword = FUserPassword);
end;

procedure TPortInfo.InnerSend;
var
  s, P, N: Integer;
  aString: AnsiString;
begin
  if FLetters.Count > 0 then
    if not (DeviceVer='250') or (Length(PInPacket^) = 0) or (PInPacket^[Pred(Length(PInPacket^))].State <> 255) then
      begin
        aString:= FLetters[0];
        FLetters.Delete(0);
        if Com.SendData(PByteArray(PAnsiChar(aString)), Length(aString)) then
          begin

            s := Length(FInSource);
            SetLength(FInSource, Succ(s));
            FInSource[s].Time := Time;
            FInSource[s].Position := MS.Size;
            FInSource[s].Size := Length(aString);
            FInSource[s].State := 255;

            MS.Write(PAnsiChar(aString)^, Length(aString));
            if FInSource <> PInPacket^ then
              begin
                P := Length(PInPacket^);
                SetLength(PInPacket^, Succ(P));
                PInPacket^[P] := FInSource[s];
              end;

            Inc(FOutCount, Length(aString));
            SendMessage(Application.MainForm.Handle, WM_LOGNOTIFY, 0, 0);
          end;
      end;
end;

procedure TPortInfo.SendAnsiString(aString: AnsiString);
begin
  FLetters.Add(aString);
  InnerSend(  );
end;

procedure TPortInfo.SetActive(const Value: Boolean);
begin
  if (Value <> FActive) or (not FActive) then
  begin
    Operation := 0;
    FWaitInfo := True;
    FStoped := False;
    FActiveTime:= Now;
  end;
  FActive := Value;
  MF.Commands_Update(nil);
  FPanelI.Repaint;
end;

procedure TPortInfo.SetDeviceName(const Value: String);
var
  NeedUpdate: Boolean;
begin
  NeedUpdate := (FDeviceName <> Value);

  if NeedUpdate then
    if (0 < Pos('VID_0483&PID_5742', FDevicePID_VID)) then
    begin
      FDeviceVer := '5';
      FReadLocked := -1;
      MF.ControlsLoadSettings(FDeviceVer);
    end
    else
    begin
      ReadLocked := False;
    end;

  FDeviceName := Value;
  if FPanelI.HandleAllocated then
    FPanelI.Repaint;

  if NeedUpdate then
  begin
    DoUpdateInfo;
    MF.UpdateTitle;
  end;
end;

procedure TPortInfo.SetDeviceIMEI(const Value: String);
var
  NeedUpdate: Boolean;
begin
  FWaitInfo := False;

  NeedUpdate := (FDeviceIMEI <> Value);
  FDeviceIMEI := Value;
  if NeedUpdate then
    DoUpdateInfo;
end;

procedure TPortInfo.SetDeviceSOFT(const Value: String);
var
  NeedUpdate: Boolean;
begin
  NeedUpdate := (FDeviceSOFT <> Value);
  FDeviceSOFT := Value;
  if NeedUpdate then
    DoUpdateInfo;
end;

procedure TPortInfo.SetDeviceVer(const Value: String);
var
  NeedUpdate: Boolean;
begin
  NeedUpdate := Not(FDeviceVer = Value);
  if Length(Value) = 0 then
    MF.ControlsLoadSettings('');

  FDeviceVer := Value;
  FPanelI.Repaint;

  if NeedUpdate then
  begin
    MF.ControlsLoadSettings(FDeviceVer);
    MF.Commands_Update(nil);
    DoUpdateInfo;
  end;
end;

procedure TPortInfo.SetHaveSettings(const Value: Boolean);
begin
  FHaveSettings := Value;
  ReadLocked := False;
  MF.LockedPanel.Visible := not FHaveSettings;
  MF.T1ScrollBox.Visible := FHaveSettings;
end;

procedure TPortInfo.SetDevicePassword(const Value: String);
begin
  FDevicePassword := Value;
  ReadLocked := False;
  MF.PasswordEdit.OnChange(MF.PasswordEdit);
end;

procedure TPortInfo.SetUserPassword(const Value: String);
begin
  FUserPassword := Value;
end;

procedure TPortInfo.SetOperation(const Value: Byte);
var
  sDate: string;
begin
  case Value of
    0:
      begin
        MF.SetLanguageIndicator;
      end;

    1:
      begin
        MF.OpenDialog1.InitialDir := GetCurrentDir;
        MF.OpenDialog1.DefaultExt := '.fwr';
        MF.OpenDialog1.FilterIndex := 2;
        if MF.OpenDialog1.Execute then
        begin
          FDataFile := TMemoryStreamEx.Create;
          FDataFile.LoadFromFile(MF.OpenDialog1.FileName);

          SendAnsiString('>D 3;0' + #13#10);
          FOperation := 1;
          MF.ProgressLabel.Caption := Translate(MF.Language, 'mes_deviceupdateloading');
          MF.SetLanguageIndicator(0, FDataFile.Size);
        end;
      end;

    2, 3:
      begin
        if (0 = FMemoryOffset) or (0 = FMemoryCount) then
        begin
          MF.MainHintShow(1, Translate(MF.Language, 'mes_devicememoryempty'));
        end
        else
        begin
          MF.SaveDialog.InitialDir := GetCurrentDir;
          MF.SaveDialog.DefaultExt := '*.dump';
          MF.SaveDialog.FilterIndex := 2;
          DateTimeToString(sDate, 'YYYYMMDD', Date);
          MF.SaveDialog.FileName := DeviceName + '_' + sDate + '.dump';
          if MF.SaveDialog.Execute then
          begin
            MF.ProgressLabel.Caption := Translate(MF.Language, 'mes_devicememoryreading');
            FMemoryFile := MF.SaveDialog.FileName;
            FMemoryIndex := 0;
            if Assigned(FDataFile) then
            begin
              FDataFile.Free;
              FDataFile := nil;
            end;
            MF.SetLanguageIndicator(0, 1);
            FMemoryTime := Time;
            FOperation := Value;
            SendAnsiString('>D 18;' + IntToStr(FMemoryIndex + FMemoryOffset) + #13#10);
          end;
        end;
      end;
  end;

  FOperation := Value;
end;

procedure TPortInfo.SetReadLocked(const Value: Boolean);
var
  PreValue: Integer;
begin
  PreValue := FReadLocked;

  if Value then
  begin
    FReadLocked := 1
  end
  else
  begin
    FReadLocked := 0;
    if (PreValue <> 0) and (not HaveSettings) then
      MF.Commands_Exec(act_SettingsGet);
  end;
end;

procedure TPortInfo.SetSelected(const Value: Boolean);
begin
  FSelected := Value;
  FPanelI.Repaint;
end;

procedure TPortInfo.SetStoped(const Value: Boolean);
begin
  FStoped := Value;
  if FStoped then
    Com.Disconnect
  else
    Com.Connect;
  FPanelI.Repaint;
end;

procedure TPortInfo.SetVisible(Value: Boolean);
begin
  inherited SetVisible(Value);
  if Assigned(FPanelO) then
    FPanelO.Visible := Value;
end;

{ TDrawPanel }

procedure TDrawPanel.Paint;
var
  s: String;
begin
  inherited;
  if MF.QList[Tag].Selected then
    MF.QList[Tag].FPanelO.Color := clWhite
  else if MF.QList[Tag].Active then
    if MF.QList[Tag].Stoped then
      MF.QList[Tag].FPanelO.Color := clRed
    else
      MF.QList[Tag].FPanelO.Color := _Green
  else
    MF.QList[Tag].FPanelO.Color := MF.LPanel.Color;

  s := MF.QList[Tag].PortName;
  Canvas.Font.Size := 8;
  Canvas.Font.Color := clGray;
  Canvas.TextOut(36 - Canvas.TextWidth(s) div 2, 5, s);

  s := MF.QList[Tag].DeviceVer;
  Canvas.Font.Size := 8;
  Canvas.Font.Color := MF.Font.Color;

  if s='250' then s:= 'master' else
  if 0 < Length(s) then s := 'v. ' + s;
  Canvas.TextOut(36 - Canvas.TextWidth(s) div 2, 52, s);

  s := MF.QList[Tag].DeviceName;
  Canvas.Font.Color := _Green;
  if 0 = Length(s) then
    s := '------';

  if Length(s) <= 8  then Canvas.Font.Size := 12 else
  if Length(s) <= 10 then Canvas.Font.Size := 10 else
                          Canvas.Font.Size := 7;
  // 24
  Canvas.TextOut(36 - Canvas.TextWidth(s) div 2, 34 - Canvas.TextHeight(s) div 2, s);
end;

{ TCommand }

function TCommand.Enabled(aPortInfo: TPortInfo): Boolean;
var
  i, D: Integer;
begin
  result := False;
  if aPortInfo = nil then
    Exit(False);
  D := StrToIntDef(aPortInfo.DeviceVer, -1);
  for i := 0 to Pred(FCommandList.Count) do
    if (DeviceMin <= D) and (D <= DeviceMax) then
      Exit(True);
end;

function TCommand.Visible(aPortInfo: TPortInfo): Boolean;
var
  i, D: Integer;
begin
  result := False;
  if aPortInfo = nil then
    Exit(False);
  D := StrToIntDef(aPortInfo.DeviceVer, -1);
  for i := 0 to Pred(FCommandList.Count) do
    if (DeviceMin <= D) and (D <= DeviceMax) then
      Exit(Show);
end;

function TCommand.Caption: string;
begin
  if MF.Language = 0 then
    if 0 < Length(NameRU) then
      result := NameRU
    else
      result := Translate(0, Ident)
  else if 0 < Length(NameEN) then
    result := NameEN
  else
    result := Translate(1, Ident);
  {
    if result <> '-' then
    result := result + ' ' + IntToStr(DeviceMin) + '-' + IntToStr(DeviceMax);
    { }
end;

initialization

begin
  sVersion := EncodeDate(2020, 08, 09);

  DataDir := StringReplace(GetDOSEnvVar('AppData'), #0, '', [rfReplaceAll]);
  if (0 < Length(DataDir)) and (DataDir[Length(DataDir)] = #0) then
    Delete(DataDir, Length(DataDir), 1);
  DataDir := GetEnvironmentVariable('APPDATA');
  DataDir := DataDir + PathDelim + 'SensorHUB' + PathDelim;
  ForceDirectories(DataDir);

  StyleA.ColorBack := RGB(22, 31, 40);
  StyleA.ColorPanel := RGB(35, 45, 57);
  StyleA.ColorShadow := RGB(GetRValue(StyleA.ColorBack) div 2,
    GetGValue(StyleA.ColorBack) div 2, GetBValue(StyleA.ColorBack) div 2);
  StyleA.ColorLabel := clWhite;

  StyleB.ColorBack := RGB(224, 224, 224);
  StyleB.ColorPanel := RGB(255, 255, 255);
  StyleB.ColorShadow := RGB(Round(0.9 * GetRValue(StyleB.ColorBack)),
    Round(0.9 * GetGValue(StyleB.ColorBack)),
    Round(0.9 * GetBValue(StyleB.ColorBack)));
  StyleB.ColorLabel := clBlack;

  ColorB := RGB(22, 31, 40);
  ColorT := RGB(35, 45, 57);
  ColorH := RGB(GetRValue(ColorB) div 2, GetGValue(ColorB) div 2, GetBValue(ColorB) div 2);
  SetLength(Langs, 2);

  Langs[0].Name := 'Русский';
  Langs[1].Name := 'English';

  _Style := StyleA;
end;

finalization

begin

end;

end.
