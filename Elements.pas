unit Elements;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Graphics, Math, StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.StdCtrls, ClipBrd, Vcl.Buttons,
  Generics.Collections,
  myTypes;

const
  _OffsetH = 12;
  _OffsetV =  4;
  _OffsetVV = 8;//11;
  _TabHeight = 48;
type
  TValues = Record
    ID: Integer;
    Dict: String;
    State: Integer;
  end;

//  TBaseClass = class(TGraphicControl)
  TBaseClass = class(TCustomControl)
  private
  protected
    FValues: TList<TValues>;
    FValue: Variant;
    FBackValue: Variant;
    FValueAlter: Variant;
    FShowValue: Variant;
    FColor: TColor;
    FHeader: TPanel;
    FBody: TPanel;
    FCaption: String;
    FFormat: String;
    FSize: Integer;
    FPos: Integer;
    FVisible: Boolean;
    FIdent: String;
    FDict: String;
    FAutoHide: Boolean;
    procedure SetIdent(const Value: String); virtual;
    procedure SetAutoHide(const aValue: Boolean); virtual;
    procedure SetVisible(const aValue: Boolean); virtual;
    procedure SetCaption(const aValue: String); virtual;
    function GetFullHeight: Integer; virtual;
    procedure SetValue(aValue: Variant); virtual;
    function GetValue: Variant; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Init; virtual;
    procedure UpdateHeight; virtual;
    procedure AddDicItem(aID: Integer; aDict: String);
    property Values: TList<TValues> read FValues;
    property Body: TPanel read FBody;
    property Size : Integer read FSize;
    property Position: Integer Read FPos write FPos;
    property Visible: Boolean read FVisible write SetVisible;
    property Dict: String read FDict write FDict;
    property Caption: String read FCaption write SetCaption;
    procedure SetColor(aColor: TColor); virtual;
    property Value: Variant read GetValue write SetValue;
    property ValueAlter: Variant read FValueAlter write FValueAlter;
    property Format: String read FFormat write FFormat;
    property Ident: String read FIdent write SetIdent;
    property FullHeight: Integer read GetFullHeight;
    property AutoHide: Boolean read FAutoHide write SetAutoHide;
    property BackValue: Variant read FBackValue;
    function Changed: Boolean;
  end;

type
  TTabPanel = Class(TPanel)
  private
    BPanel: TPanel;
    RPanel: TPanel;
    LPanel: TPanel;
    APanel: TPanel;
    SPanel: TPanel;
    FOwner: TWinControl;
    FIndex: Integer;
    FChecked: Boolean;
    FNotifyEvent: TNotifyEvent;
    FCaption: String;
    FWinControl: TWinControl;
    FDict: String;
    procedure SetChecked(const Value: Boolean);
    procedure OnPanelClick(Sender: TObject);
    procedure SetCaption(const Value: String);
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateStyle;
    property Dict: String read FDict write FDict;
    property Index: Integer read FIndex;
    property Checked: Boolean read FChecked write SetChecked;
    property NotifyEvent: TNotifyEvent read FNotifyEvent write FNotifyEvent;
    property Caption: String read FCaption write SetCaption;
    property WinControl: TWinControl read FWinControl write FWinControl;
  end;

  TCaptionClass = class(TBaseClass)
  private
    FImage : TImage;
    FLabel : TLabel;
    FFlipped : Boolean;
    FSingle : Boolean;
    FSeparator: TPanel;
    FDict: string;
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
    procedure SetIcon(const aValue: string);
    procedure SetFlipped(const aValue: Boolean);
    Procedure GetFullHeightInner(var aHeightItems: Integer; var aHeightColumns: Integer; var aColumnsCount: Integer);
  protected
    procedure SetCaption(const aValue: String); override;
    function GetFullHeight: Integer; override;
    procedure FlipFlop(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Icon: string write SetIcon;
    property Flipped : Boolean read FFlipped write SetFlipped;
    property Single : Boolean read FSingle write FSingle;
    property Dict: string read FDict write FDict;
  end;

  TColumnClass = class(TBaseClass)
  private
    FEquil: Boolean;
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
  protected
    function GetFullHeight: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Equil: Boolean read FEquil write FEquil;
  end;

  TItemClass = class(TBaseClass)
  private
    F_Units: string;
    FUnits: string;
    procedure WMPaint(var Message: TWmPaint); message WM_PAINT;
    procedure WMDblClick(var Message: TWmPaint); message WM_LBUTTONDBLCLK;
    procedure WMMouseLeave(var Message: TWmPaint); message WM_MOUSELEAVE;
    procedure WMMouseMove(var Message: TWmPaint); message  WM_MOUSEMOVE;
  protected
    function GetFullHeight: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    property _Units: string read F_Units write F_Units;
    property Units: string read FUnits write FUnits;
  end;

  TControlClass = class(TBaseClass)
  private
    FIsSet: Boolean;
    FCLabel: TLabel;
    FULabel: TLabel;
    FControl: TControl;
    FSetting: Integer;
    FBit: Integer;
    FMin: Variant;
    FMax: Variant;
    FUnits: string;
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
    procedure SetUnits(const Value: String);
  protected
    function GetFullHeight: Integer; override;
    procedure SetCaption(const aValue: String); override;
    procedure SetValue(aValue: Variant); override;
    procedure OnEnter(Sender: TObject);
    procedure OnExit(Sender: TObject);
    procedure SetSetting(const Value: Integer); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Init; override;
    property Caption: String read FCaption write SetCaption;
    property Units: String read FUnits write SetUnits;
    property Settings: Integer read FSetting write SetSetting;
    property Bit: Integer read FBit write FBit;
    property Min: Variant read FMin write FMin;
    property Max: Variant read FMax write FMax;
    property WinControl: TControl read FControl;
    property IsSet: Boolean read FIsSet;
    procedure Colorize;
  end;

  TStringClass = class(TControlClass)
  protected
    function GetValue: Variant; override;
    procedure SetValue(aValue: Variant); override;
    procedure StringEditChange(Sender: TObject);
    procedure SetSetting(const Value: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TIntegerClass = class(TControlClass)
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
    function GetValue: Variant; override;
    procedure SetValue(aValue: Variant); override;
    procedure IntEditChange(Sender: TObject);
    procedure SetSetting(const Value: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TFlagClass = class(TControlClass)
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
  protected
    function GetValue: Variant; override;
    procedure SetValue(aValue: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TMySpeedButton = class(TSpeedButton)
  end;

  TButtonClass = class(TControlClass)
    procedure WMSize(var Message: TWmPaint); message WM_SIZE;
  private
  protected
    function GetFullHeight: Integer; override;
    procedure SetCaption(const aValue: String); override;
    procedure OnClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;


  TMyComboBox = class(TComboBox)
  protected
    procedure MsgMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL;
  end;

  TListClass = class(TControlClass)
  protected
    function GetValue: Variant; override;
  protected
    procedure SetValue(aValue: Variant); override;
    procedure SetSetting(const Value: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Init; override;
  end;

  TSeparatorClass = class(TBaseClass)
  private
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation
  uses MForm, Dictionary;
{ TBaseClass }

function TBaseClass.Changed: Boolean;
begin
  Result:= (Value <> FBackValue);
end;

constructor TBaseClass.Create(AOwner: TComponent);
begin
  FAutoHide:= False;
  inherited Create(AOwner);
//  Parent:= AOwner;
  StyleElements:= [];
  FValue:= unassigned;
  FShowValue:= unassigned;
//  DoubleBuffered:= True;
  ParentColor:= True;
  FValues:= TList<TValues>.Create;
end;

destructor TBaseClass.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TBaseClass.GetFullHeight: Integer;
begin
  Result:= Height;
end;

function TBaseClass.GetValue: Variant;
begin
  Result:= FValue;
end;

procedure TBaseClass.Init;
begin
  inherited;
end;

procedure TBaseClass.SetAutoHide(const aValue: Boolean);
begin
  FAutoHide := aValue;
  Height:= GetFullHeight;
end;

procedure TBaseClass.SetCaption(const aValue: String);
var p: integer;
    NewCaption: String;
begin
  p:= Pos('|', aValue);
  if 0 < p then NewCaption := Copy(aValue, 1, p-1)
           else NewCaption := aValue;

  if Not(NewCaption = FCaption) then
    begin
      FCaption:= NewCaption;
//      Invalidate;
 //     Repaint;
    end;
end;

procedure TBaseClass.SetColor(aColor: TColor);
begin
  FColor:= aColor;
end;

procedure TBaseClass.SetIdent(const Value: String);
begin
  FIdent := Value;
end;

procedure TBaseClass.SetValue(aValue: Variant);
begin
 // if (VarIsEmpty(FValue)<>VarIsEmpty(aValue)) {or Not (FValue = aValue){} then
    begin
      FValue:= aValue;
      FBackValue:= aValue;
      FShowValue:= aValue;
      if AutoHide and (Height<>GetFullHeight) then
        UpdateHeight;
      Repaint;//Invalidate;
    end;
end;

procedure TBaseClass.SetVisible(const aValue: Boolean);
begin
  FVisible := aValue;
end;

procedure TBaseClass.UpdateHeight;
begin
  Height:= GetFullHeight;
  if (Parent is TPanel) then
    begin
      if TPanel(Parent).Parent is TBaseClass then
        TBaseClass(Parent.Parent).UpdateHeight;

      if Assigned(TPanel(Parent.Parent).OnResize) then
        TPanel(Parent.Parent).OnResize(nil);
    end;
end;

procedure TBaseClass.AddDicItem(aID: Integer; aDict: String);
var V:  TValues;
begin
  V.ID:= aID;
  V.Dict:= aDict;
  Values.Add(V);
end;

{ TItemClass }

constructor TItemClass.Create(AOwner: TComponent);
begin
  inherited Create( TWinControl(aOwner) );
  Height:= 22;
end;

function TItemClass.GetFullHeight: Integer;
begin
  if FAutoHide and (VarIsEmpty(FValue)) then Result:= 0
                                        else Result:= 22;
end;

procedure TItemClass.WMDblClick(var Message: TWmPaint);
var TC: TClipBoard;
begin
  TC:= TClipBoard.Create;
  TC.Open;
  TC.AsText:= VarToStr(FValue);
  TC.Close;
  MF.MainHintShow(2, Translate(MF.Language, 'mes_copyclipboard') +' "'+ VarToStr(FValue)+'"');
end;

procedure TItemClass.WMMouseLeave(var Message: TWmPaint);
begin
  if FShowValue <> FValue then
    begin
      FShowValue:= FValue;
      repaint;
    end;
end;

procedure TItemClass.WMMouseMove(var Message: TWmPaint);
begin
  if 0 < Length(FValueAlter) then
    begin
      FShowValue:= FValueAlter;
      repaint;
    end;
end;

procedure TItemClass.WMPaint(var Message: TWmPaint);
var
  i, H, CW, VW: Integer;
  s, sCaption: String;
  _Color: TColor;
begin
// if (csDestroying in ComponentState) then Exit;
 inherited;
  try
    if VarIsEmpty(FValue) or VarIsNull(FValue)  then
      begin
        s:= Translate(MF.Language, 'No');
        _Color:= _Gray;
      end
    else
      begin
        s:= VarToStr(FShowValue);
        if 0 < Length(FUnits) then
          s:= s + ' ' + FUnits;
        _Color:= FColor;
      end;

    CW:= Canvas.TextWidth(FCaption);
    VW:= Canvas.TextWidth(s);
    sCaption:= FCaption;

    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Color:= _Color;

    if (CW + _OffsetH <= Width div 2) and (VW <= Width div 2) then
      Canvas.TextOut(Width div 2, 3, s) else

    if (CW + VW + _OffsetH <= Width) and (VW <= Width div 2) then
      Canvas.TextOut(CW + _OffsetH, 3, s) else

      begin
        Canvas.TextOut(Width - VW, 3, s);
        if (CW + VW + _OffsetH > Width) then
          begin
            H:= Pos(' ', FCaption);
            CW:= Canvas.TextWidth(Copy(FCaption, 1, H-1) + '..');
            if (0 < H) and (CW + VW + _OffsetH <= Width)
              then sCaption:= Copy(FCaption, 1, H-1) + '..'
              else sCaption:= Copy(FCaption, 1,   1) + '..';
          end;
      end;

      Canvas.Font.Color:= self.Font.Color;
      Canvas.TextOut(0, 3, sCaption);

      Hint:= FCaption;
      ShowHint:= (sCaption <> FCaption);

      H:= Pred(Height);
      for i:= CW to Width do
        if i mod 3 = 0 then Canvas.Pixels[i, H]:= _Gray
  finally
  end;
end;

{ TCaptionClass }

constructor TCaptionClass.Create(AOwner: TComponent);
begin
  FFlipped:= False;
  inherited Create( TWinControl(aOwner) );

  ParentColor:= True;

  FHeader:= TPanel.Create(self);
  FHeader.StyleElements:=[];
  FHeader.Parent:= self;
  FHeader.Height:= _OffsetV + 16 + _OffsetV ;
  FHeader.Align:= alTop;
  FHeader.BevelOuter:= bvNone;
  FHeader.ShowCaption:= False;
  FHeader.ParentColor:= True;
  FHeader.DoubleBuffered:= True;
//  FHeader.Color:= $00281F16; // $0030261C;//

  FSeparator:= TPanel.Create(self);
  FSeparator.StyleElements:=[];
  FSeparator.Parent:= FHeader;
  FSeparator.BevelOuter:= bvNone;
  FSeparator.ShowCaption:= False;
  FSeparator.DoubleBuffered:= True;
  FSeparator.Color:= clSilver;//White;//$00281F16;

  FImage:= TImage.Create(self);
  FImage.Parent:= FHeader;
  FImage.Left:= _OffsetV;//0;
  FImage.Top:= _OffsetV;
  FImage.OnClick:= FlipFlop;

  FLabel:= TLabel.Create(self);
  FLabel.Parent:= FHeader;
  FLabel.Top:= _OffsetV;
  FLabel.Transparent:= False;
  FLabel.ParentColor:= True;
  FLabel.BringToFront;
  FLabel.AutoSize:= true;

  FBody:= TPanel.Create(self);
  FBody.BevelOuter:= bvNone;
  FBody.ParentColor:= True;
  FBody.Parent:= self;
  FBody.FullRepaint:= False;
  FBody.doubleBuffered:= True;

  Height:= FHeader.Height +_OffsetVV + _OffsetVV;
end;

destructor TCaptionClass.Destroy;
begin
  inherited;
end;

Procedure TCaptionClass.GetFullHeightInner(var aHeightItems: Integer; var aHeightColumns: Integer; var aColumnsCount: Integer);
var i: Integer;
begin
  aHeightItems:= 0;
  aHeightColumns:= 0;
  aColumnsCount:= 0;
  for i:=0 to Pred(FBody.ControlCount) do
    if FBody.Controls[i] is TColumnClass then
      begin
        Inc(aColumnsCount);
        aHeightColumns:= Max(aHeightColumns, TBaseClass(FBody.Controls[i]).GetFullHeight);
      end
    else
      begin
        Inc(aHeightItems, TBaseClass(FBody.Controls[i]).GetFullHeight);
      end;
end;

function TCaptionClass.GetFullHeight: Integer;
var HI, HC, CC : Integer;
begin
  GetFullHeightInner(HI, HC, CC);
  if FAutoHide and (HI + HC = 0) then Result:= 0
                                 else if FFlipped then Result:= FHeader.Height + _OffsetVV
                                                  else Result:= FHeader.Height + _OffsetVV + HI + HC + _OffsetVV;
end;

procedure TCaptionClass.WMSize(var Message: TWmPaint);
var i, N, W, HI, HC, CC : Integer;
begin
  GetFullHeightInner(HI, HC, CC);
  if FAutoHide and (HI + HC = 0) then Height:= 0
                                 else if FFlipped then Height:= FHeader.Height + _OffsetVV
                                                  else Height:= FHeader.Height + _OffsetVV + HI + HC + _OffsetVV;
   {
  FLabel.SetBounds(16 +_OffsetH,
                   _OffsetV,
                   ClientWidth - (16 + _OffsetH),
                   16);
 {}
  FLabel.Left:= 16 +_OffsetH;
  FLabel.Top:= _OffsetV;

  FSeparator.SetBounds(16 +_OffsetH + FLabel.Width+ _OffsetH, _OffsetV + 7, MaxInt, 1 );

  FBody.SetBounds( 0,
                   FHeader.Height + _OffsetVV,
                   ClientWidth - 2,
                   ClientHeight - (FHeader.Height + _OffsetVV + _OffsetVV));

  if 0 < CC then
    begin
      N:= 0;
      W:= (ClientWidth - (CC - 1) * 2 * _OffsetH) div CC;
      for i:=0 to Pred(FBody.ControlCount) do
        if FBody.Controls[i] is TColumnClass then
          begin
            FBody.Controls[i].SetBounds( N * (W + 2 * _OffsetH), HI, W, HC );
            Inc(N);
          end;
    end;

    W:= ClientWidth;
    HI:= 0;
    for i:=0 to Pred(FBody.ControlCount) do
      if (FBody.Controls[i] is TItemClass) or (FBody.Controls[i] is TSeparatorClass) then
        begin
          HC:=  TBaseClass(FBody.Controls[i]).GetFullHeight;
          TBaseClass(FBody.Controls[i]).Visible:= (0<HC);
          FBody.Controls[i].SetBounds( 0, HI, W-1, HC );
          Inc(HI, HC);
        end;

  inherited;
end;

procedure TCaptionClass.SetCaption(const aValue: String);
var P,H: Integer;
begin
  inherited;
  FCaption:= aValue;
  P:= Pos('|', FCaption);
  if 0<P then FLabel.Caption:= Copy(FCaption,1,P-1)
         else FLabel.Caption:= FCaption;

  if Length(FCaption)=0 then H:= 0
                        else H:= _OffsetV + 16 + _OffsetV;

  if FHeader.Height<>H  then FHeader.Height:=H;

  FSeparator.SetBounds(16 +_OffsetH + FLabel.Width+ _OffsetH, _OffsetV + 7, MaxInt, 1 );
end;

procedure TCaptionClass.SetFlipped(const aValue: Boolean);
var i: Integer;
begin
  FFlipped:= aValue;
  if aValue then UpdateHeight;

  if FSingle then
    begin
      for i:=0 to Pred(Parent.ControlCount) do
        if (Parent.Controls[i] is TCaptionClass) then
          if Not (Parent.Controls[i] = self) then
             if TCaptionClass(Parent.Controls[i]).Single then
               if not TCaptionClass(Parent.Controls[i]).Flipped then
                  if Not self.Flipped then
                     TCaptionClass(Parent.Controls[i]).Flipped:= True;
    end;

  if Not aValue then UpdateHeight;
end;

procedure TCaptionClass.FlipFlop(Sender: TObject);
begin
  Flipped:= Not Flipped;
end;

procedure TCaptionClass.SetIcon(const aValue: string);
var FIcon: TIcon;

begin
  FIcon := TIcon.Create;
  try
    FIcon.Handle := LoadImage(hInstance, PChar(aValue),  IMAGE_ICON, 16, 16, LR_SHARED);
  finally
  end;

  if FIcon.Handle = 0  then
    FIcon.Handle := LoadImage(hInstance, PChar('I_DEFAULT'),  IMAGE_ICON, 16, 16, LR_SHARED);

  FImage.Picture.Assign(FIcon);
  FIcon.Free;
end;

{ TSeparatorClass }

constructor TSeparatorClass.Create(AOwner: TComponent);
begin
  inherited Create( TWinControl(aOwner) );
  Height:= _OffsetVV;
end;

{ TPanelClass }

constructor TColumnClass.Create(AOwner: TComponent);
begin
  FAutoHide:= False;
  FEquil:= False;
  inherited Create(AOwner);
  Align:= alClient;
//  DoubleBuffered:= True;

  FBody:= TPanel.Create(self);
  FBody.Parent:= self;
  FBody.ParentColor:= True;
  FBody.BevelOuter:= bvNone;
  FBody.Align:= alClient;
  FBody.FullRepaint:= False;
end;

function TColumnClass.GetFullHeight: Integer;
var i, H : Integer;
begin
  H:=0;
  for i:=0 to Pred(FBody.ControlCount) do
    Inc(H, TBaseClass(FBody.Controls[i]).GetFullHeight);

  if {FAutoHide and} (H = 0) then Result:= 0
                             else Result:= H;
end;

procedure TColumnClass.WMSize(var Message: TWmPaint);
var i, H, HHH, MinH, AddH, RealH, CCount, FCount : Integer;
    zH: Array of Integer;
begin
  HHH := 0;
  Setlength(zH, FBody.ControlCount);

  CCount:=0;
  for i:=0 to Pred(FBody.ControlCount) do
    begin
      zH[i]:= TBaseClass(FBody.Controls[i]).GetFullHeight;
      if 0 < zH[i] then Inc(CCount);
    end;

  if 0 < CCount then
    begin
      RealH:= Parent.Parent.Parent.ClientHeight - 24;
      MinH:= RealH div CCount;

      AddH:= 0;
      FCount:= 0;
      for i:=0 to Pred(FBody.ControlCount) do
        if 0 < zH[i] then
          if MinH < zH[i] then Inc(AddH, zH[i])
                          else Inc(FCount);

      if 0 < FCount then MinH:= (RealH - AddH) div FCount
                    else MinH:= 0;

      for i:=0 to Pred(FBody.ControlCount) do
        begin
          if Not FEquil then H:= zH[i] else
          if 0 < zH[i]  then H:= Max(MinH, zH[i]) else
                             H:= 0;

          TBaseClass(FBody.Controls[i]).SetBounds(0, HHH, ClientWidth, H);
          Inc(HHH, H);
        end;

    end;

  Height:= HHH;
  inherited;
end;

{ TControlClass }

procedure TControlClass.Colorize;
begin
  if Not IsSet then
    begin
      FCLabel.Font.Color:= clRed;
      FULabel.Font.Color:= clRed;
    end;
end;

constructor TControlClass.Create(AOwner: TComponent);
begin
  inherited Create( AOwner );
  FIsSet:= False;
  FCLabel:= TLabel.Create(self);
  FCLabel.Parent:= self;
  FCLabel.Font.Color:= _Green;
  FULabel:= TLabel.Create(self);
  FULabel.Parent:= self;
  FULabel.Font.Color:= _Green;
  Top:= MaxInt;
  Align:= alTop;
  FCLabel.Alignment:= taRightJustify;
  Height:= 23;
  Top:= Height * AOwner.ComponentCount;
end;

function TControlClass.GetFullHeight: Integer;
begin
  Result:= 23;
end;

procedure TControlClass.Init;
begin
  inherited;
  Align:= alTop;
end;

procedure TControlClass.OnEnter(Sender: TObject);
begin
  if Not IsSet then
    if (FControl is TEdit) then
      begin
        if not TEdit(FControl).readonly then
          MF.MainHintShow(2, System.SysUtils.Format(Translate(MF.Language, 'mes_valuedisable'), [Caption]));
      end else

      begin
        FControl.Enabled:= False;
        MF.MainHintShow(2, System.SysUtils.Format(Translate(MF.Language, 'mes_valuedisable'), [Caption]));
      end;
end;

procedure TControlClass.OnExit(Sender: TObject);
begin
  if Not IsSet then
    begin
      FControl.Enabled:= True;
    end;
end;

procedure TControlClass.SetCaption(const aValue: String);
begin
//  inherited;
  FCaption:= aValue;
  FCLabel.Caption:= aValue;
end;

procedure TControlClass.SetSetting(const Value: Integer);
begin
  FSetting := Value;
end;

procedure TControlClass.SetUnits(const Value: String);
begin
  FUnits := Value;
  FULabel.Caption:= Value;
end;

procedure TControlClass.SetValue(aValue: Variant);
begin
  inherited;
  FValue:= aValue;
  FIsSet:= True;
end;

procedure TControlClass.WMSize(var Message: TWmPaint);
var W: Integer;
begin
  if assigned(FULabel)  then FULabel.Visible:= (0 < Length(FUnits));
  W:= Width - 2 * _OffsetH;
  if assigned(FCLabel)  then FCLabel.SetBounds ( 0, 2, Round(W*0.60), Height-2);

  if FULabel.Visible then
    begin
      if assigned(FControl) then FControl.SetBounds( Round(W*0.60) + _OffsetH, 0, Round(W*0.20), FControl.Height);
      if assigned(FULabel)  then FULabel.SetBounds ( Round(W*0.80) + 2*_OffsetH, 2, Round(W*0.20), Height-2);
    end
  else
    begin
     if assigned(FControl) then FControl.SetBounds( Round(W*0.60) + _OffsetH, 0, Round(W*0.40) + _OffsetH, FControl.Height);
    end;

  if assigned(FControl) then FControl.Invalidate;
end;

{ TStringClass }

constructor TStringClass.Create(AOwner: TComponent);
begin
  inherited;
  FControl:= TEdit.Create(AOwner);
  FControl.Parent:= self;
  TEdit(FControl).OnChange:= StringEditChange;
  TEdit(FControl).Font.Color:= clMenuText;
  TEdit(FControl).OnEnter:= OnEnter;
  TEdit(FControl).OnExit:= OnExit;
 // TEdit(FControl).ReadOnly:= True;
end;

procedure TStringClass.StringEditChange(Sender: TObject);
var E, V: Integer;
    s,t: string;
begin
  s:= TEdit(FControl).Text;
  if 0 < Length(Caption) then t:= ' "' + Caption + '"'
                         else t:= '';
  Val(s, V, E);

  if (Settings = 5) and (Length(s) <> 0) and (Length(s) <> 6) then s:= Translate(MF.Language, 'mes_passwordlength') else
  if Length(s)< FMin then  s:= Translate(MF.Language, 'mes_valueminlength') + t + ': '+IntToStr(FMin) else
  if FMax < Length(s) then s:= Translate(MF.Language, 'mes_valuemaxlength') + t + ': '+IntToStr(FMax) else
                           s:= '';
  MF.SettingsError(FSetting, s);
end;

procedure TStringClass.SetSetting(const Value: Integer);
begin
  inherited;
  if Value = 0 then
    begin
      TEdit(FControl).ReadOnly:= True;
      TEdit(FControl).ParentColor:= True;
      TEdit(FControl).Alignment:= taCenter;
   // TEdit(FControl).BorderStyle:= bsNone;
      TEdit(FControl).ParentFont:= True;
    end;
end;

procedure TStringClass.SetValue(aValue: Variant);
begin
  inherited;
  TEdit(FControl).Text:= VarToStr(avalue);
end;

function TStringClass.GetValue: Variant;
begin
  Result:= TEdit(FControl).Text;
end;
{

_regexp:=TRegExpr.Create;
_regexp.Expression:='([^s]+)s([^s]+)s([d.]+)s([d+-]+)';
_tempFile:=TStringList.Create;
_tempFile.LoadFromFile(OpenDialog1.FileName);
for i:=0 to _tempFile.Count-1 do
begin
 _regexp.Exec(_tempFile.Strings[i]);

 if (_regexp.Exec) then
  with ListView1.Items.Add do
  begin
   Caption:=_regexp.Match[1];
   SubItems.Add(_regexp.Match[2]);
   SubItems.Add(_regexp.Match[3]);
   SubItems.Add(_regexp.Match[4]);
  end;
end;
_regexp.Free;
}


{ TIntegerClass }

constructor TIntegerClass.Create(AOwner: TComponent);
begin
  inherited;
  FControl:= TEdit.Create(AOwner);
  FControl.Parent:= self;
  TEdit(FControl).OnChange:= IntEditChange;
  TEdit(FControl).Font.Color:= clMenuText;
  TEdit(FControl).OnEnter:= OnEnter;
  TEdit(FControl).OnExit:= OnExit;
end;

procedure TIntegerClass.IntEditChange(Sender: TObject);
var E, V: Integer;
    s: string;
begin
  s:= TEdit(FControl).Text;
  Val(s, V, E);
//  if Length(s) = 0 then else
  if (s='-') or (s='+') then s:= '' else
  if (0<Length(s)) and (E<>0) then s:= Translate(MF.Language, 'mes_valuechar') + ' "' + Caption + '"' else
  if Not VarIsEmpty(FMin) and (V < FMin) then s:= Translate(MF.Language, 'mes_valuemin') + ' "' + Caption + '": '+IntToStr(FMin) else
  if Not VarIsEmpty(FMax) and (FMax < V) then s:= Translate(MF.Language, 'mes_valuemax') + ' "' + Caption + '": '+IntToStr(FMax) else
                                              s:= '';
  MF.SettingsError(FSetting, s);
end;

function TIntegerClass.GetValue: Variant;
begin
  FValue:= StrToIntDef( TEdit(FControl).Text, 0);
  Result:= FValue;
end;

procedure TIntegerClass.SetSetting(const Value: Integer);
begin
  inherited;
  if Value = 0 then
    begin
      TEdit(FControl).ReadOnly:= True;
      TEdit(FControl).ParentColor:= True;
      TEdit(FControl).Alignment:= taCenter;
//    TEdit(FControl).BorderStyle:= bsNone;
      TEdit(FControl).ParentFont:= True;
    end;
end;

procedure TIntegerClass.SetValue(aValue: Variant);
begin
  inherited;
  FValue:= aValue;
  TEdit(FControl).Text:= VarToStr(avalue);
end;

procedure TIntegerClass.WMSize(var Message: TWmPaint);
var W: Integer;
begin
  if assigned(FCLabel)  then FCLabel.Visible:= (0 < Length(FCaption));
  if assigned(FULabel)  then FULabel.Visible:= (0 < Length(FUnits));

  if FCLabel.Visible then
    begin
      W:= Width - 2 * _OffsetH;
      if assigned(FCLabel)  then FCLabel.SetBounds ( 0, 2, Round(W*0.60), Height-2);
      if assigned(FControl) then FControl.SetBounds( Round(W*0.60) + _OffsetH, 0, Round(W*0.15), FControl.Height);
      if assigned(FULabel)  then FULabel.SetBounds ( Round(W*0.75) + 2*_OffsetH, 2, Round(W*0.25), Height-2);
    end
  else
    begin
      W:= Width - 3 * _OffsetH;
      if assigned(FControl) then FControl.SetBounds( 2 *_OffsetH, 0, Round(W*0.15), FControl.Height);
      if assigned(FULabel)  then FULabel.SetBounds ( Round(W*0.15) + 3 *_OffsetH, 2,
                                                     Round(W*0.85), Height-2);
    end;
end;

{ TFlagClass }

constructor TFlagClass.Create(AOwner: TComponent);
begin
  inherited;
  FControl:= TCheckBox.Create(AOwner);
  FControl.Parent:= self;

  TCheckBox(FControl).Caption:= '';
  TCheckBox(FControl).OnClick:= OnEnter;
  TCheckBox(FControl).OnExit:= OnExit;
end;

function TFlagClass.GetValue: Variant;
begin
  if TCheckBox(FControl).Checked then result:= 1
                                 else result:= 0;
end;

procedure TFlagClass.SetValue(aValue: Variant);
begin
  inherited;
  TCheckBox(FControl).Checked:= (aValue='1');
end;

procedure TFlagClass.WMSize(var Message: TWmPaint);
var W: Integer;
begin
  if assigned(FCLabel)  then FCLabel.Visible:= (0 < Length(FCaption));
  if assigned(FULabel)  then FULabel.Visible:= (0 < Length(FUnits));


  if FCLabel.Visible then
    begin
      W:= Width - 2 * _OffsetH;
      if assigned(FCLabel)  then FCLabel.SetBounds ( 0, 2, Round(W*0.60), Height-2);
      if assigned(FControl) then FControl.SetBounds( Round(W*0.60) + _OffsetH, 0, FControl.Height, FControl.Height);
      if assigned(FULabel)  then FULabel.SetBounds ( Round(W*0.60) + FControl.Height + 2*_OffsetH, 2,
                                                     Round(W*0.40) - FControl.Height, Height-2);
    end
  else
    begin
      W:= Width - 3 * _OffsetH;
      if assigned(FControl) then FControl.SetBounds( 2 *_OffsetH, 0, FControl.Height, FControl.Height);
      if assigned(FULabel)  then FULabel.SetBounds ( FControl.Height + 3*_OffsetH, 2,
                                                     Round(W) - FControl.Height - 3*_OffsetH, Height-2);
    end;
end;

{ TListClass }

constructor TListClass.Create(AOwner: TComponent);
begin
  inherited;
  FControl:= TMyComboBox.Create(AOwner);
  FControl.StyleElements:=[];
  FControl.Parent:= self;
  TComboBox(FControl).Style:= csDropDownList;//csOwnerDrawFixed;//csDropDownList;
  TComboBox(FControl).DropDownCount:= 12;
  TComboBox(FControl).BevelKind:= bkSoft;//bkFlat;
  TComboBox(FControl).Font.Color:= clMenuText;
  TComboBox(FControl).OnEnter:= OnEnter;
  TComboBox(FControl).OnExit:= OnExit;
end;

function TListClass.GetValue: Variant;
begin
  Result:= Values[TComboBox(FControl).ItemIndex].ID;
end;

procedure TListClass.Init;
var i,N: Integer;
begin
  N:= TComboBox(FControl).ItemIndex;
  for i:= 0 to Pred(Values.Count) do
    if Pred(TComboBox(FControl).Items.Count) < i
      then TComboBox(FControl).Items.Add( Translate(MF.Language, Values[i].Dict))
      else TComboBox(FControl).Items[i]:= Translate(MF.Language, Values[i].Dict);
  TComboBox(FControl).ItemIndex:= N;
end;

procedure TListClass.SetSetting(const Value: Integer);
begin
  inherited;
  if Value = 0 then
    begin
      TComboBox(FControl).Enabled:= False;// .ReadOnly:= True;
      TComboBox(FControl).ParentColor:= True;
//      TComboBox(FControl).BorderStyle:= bsNone;
      TComboBox(FControl).ParentFont:= True;
      TComboBox(FControl).BevelKind:= bkFlat;
      TComboBox(FControl).BevelInner:= bvNone;
      TComboBox(FControl).BevelOuter:= bvLowered;//bvNone;
      TComboBox(FControl).Style:= csOwnerDrawFixed;
    end;
end;

procedure TListClass.SetValue(aValue: Variant);
var i: Integer;
begin
  inherited;
  FValue:= aValue;
  if VarIsEmpty(aValue) then
    TComboBox(FControl).ItemIndex:= -1
  else
    try
    for i:=0 to Pred(Values.Count) do
      if Values[i].ID = aValue then
        begin
          TComboBox(FControl).ItemIndex:= i;
          Break;
        end;
    except

    end;
end;

{ TTabPanel }

constructor TTabPanel.Create(AOwner: TComponent);
begin
  TWinControl(AOwner).Height:= _TabHeight * Succ(TWinControl(AOwner).ComponentCount);

  FIndex:= (AOwner as TWinControl).ComponentCount;
  FOwner:= (AOwner as TWinControl);

  inherited;
  FullRepaint:= False;
  self.DoubleBuffered:= True;

  StyleElements:= [];
  BevelOuter:= bvNone;
  Height:= _TabHeight;
  Parent:= TWinControl(AOwner);
  Align:= alBottom;
  Align:= alTop;
  onClick:= OnPanelClick;
  onMouseEnter:= PanelMouseEnter;
  onMouseLeave:= PanelMouseLeave;
  Caption:= IntToStr(FIndex);
  ParentColor:= False;

  BPanel:= TPanel.Create(self);
  BPanel.StyleElements:= [];
  BPanel.BevelOuter:= bvNone;
  BPanel.Height:=5;
  BPanel.ParentColor:= False;
  BPanel.Color:= $00392D23;
  BPanel.FullRepaint:= False;
  BPanel.Parent:= self;
  BPanel.Align:= alBottom;

  RPanel:= TPanel.Create(self);
  RPanel.StyleElements:= [];
  RPanel.BevelOuter:= bvNone;
  RPanel.Width:=5;
  RPanel.ParentColor:=False;
  RPanel.Color:= $00281F16;
  RPanel.FullRepaint:= False;
  RPanel.Parent:= self;
  RPanel.Align:= alRight;

  LPanel:= TPanel.Create(self);
  LPanel.StyleElements:= [];
  LPanel.BevelOuter:= bvNone;
  LPanel.Width:= 4;
  LPanel.ParentColor:=False;
  LPanel.Color:= $00392D23;
  LPanel.FullRepaint:= False;
  LPanel.Parent:= self;
  LPanel.Align:= alLeft;

  APanel:= TPanel.Create(self);
  APanel.StyleElements:= [];
  APanel.BevelOuter:= bvNone;
  APanel.Width:=5;
  APanel.ParentColor:=False;
  APanel.Color:= $00281F16;
  APanel.FullRepaint:= False;
  APanel.Parent:= BPanel;
  APanel.Align:= alRight;

  SPanel:= TPanel.Create(self);
  SPanel.StyleElements:= [];
  SPanel.BevelOuter:= bvNone;
  SPanel.ParentColor:=False;
  SPanel.Color:= $00281F16;
  SPanel.FullRepaint:= False;
  SPanel.Parent:= BPanel;
  SPanel.Align:= alNone;
  SPanel.SetBounds(12,2,BPanel.Width-12-12-5,1);
  SPanel.Anchors:=[akLeft,akTop,akRight,akBottom];

  FChecked:= False;
end;

procedure TTabPanel.OnPanelClick(Sender: TObject);
begin
  Checked:= True;
end;

procedure TTabPanel.SetCaption(const Value: String);
begin
  FCaption := Value;
  Text:= FCaption;
end;

procedure TTabPanel.UpdateStyle;
begin
  Color:= _Style.ColorPanel;

  if FChecked then
    begin
      LPanel.Color:= _Green;
      RPanel.Color:= _Style.ColorPanel;
      BPanel.Color:= _Style.ColorBack;
    end
  else
    begin
      LPanel.Color:= _Style.ColorPanel;
      RPanel.Color:= _Style.ColorBack;
      if (FIndex + 1 = FOwner.Tag) then BPanel.Color:= _Style.ColorBack
                                   else BPanel.Color:= _Style.ColorPanel;
    end;

  APanel.Color:= _Style.ColorBack;
  SPanel.Color:= _Style.ColorBack;
  Font.color:= MF.Font.Color;
end;

procedure TTabPanel.SetChecked(const Value: Boolean);
var i: Integer;
begin
  FChecked := Value;

  if Value then
    begin
      FOwner.Tag:= FIndex;
      for i:=0 to Pred(FOwner.ComponentCount) do
        if (FOwner.Components[i] is TTabPanel) then
          if i<>FIndex then
            (FOwner.Components[i] as TTabPanel).Checked:= False;
    end;

  UpdateStyle;

  if Assigned(FWinControl) then
    begin
      FWinControl.Visible:= Value;
      if Value and (FWinControl.ClassType = TColumnClass) then
        TColumnClass(FWinControl).UpdateHeight;
      FWinControl.Realign;
    end;

  PanelMouseLeave(self);
end;

procedure TTabPanel.PanelMouseEnter(Sender: TObject);
begin
  LPanel.Color:= clSilver;
end;

procedure TTabPanel.PanelMouseLeave(Sender: TObject);
begin
  if TTabPanel(Sender).Checked then LPanel.Color:= _Green
                               else LPanel.Color:= Color;
end;

{ TMyComboBox }

procedure TMyComboBox.MsgMouseWheel(var Message: TMessage);
begin
  //
end;

{ TButtonClass }

constructor TButtonClass.Create(AOwner: TComponent);
begin
  inherited;
  FControl:= TMySpeedButton.Create(AOwner);
  FControl.Parent:= self;
  TMySpeedButton(FControl).Flat:= True;
  TMySpeedButton(FControl).OnClick:= OnClick;
  Height := 42;
end;

function TButtonClass.GetFullHeight: Integer;
begin
  Result:= 42;
end;

procedure TButtonClass.OnClick(Sender: TObject);
begin
  MF.Commands_Exec(Ident);
end;

procedure TButtonClass.SetCaption(const aValue: String);
begin
 // inherited;
  TMySpeedButton(FControl).Caption:= aValue;
end;

procedure TButtonClass.WMSize(var Message: TWmPaint);
var W: Integer;
begin
  W:= Math.Max(60, Width div 6);
  TMySpeedButton(FControl).SetBounds( W, _OffsetV, Width - 2*W, Height-2*_OffsetV);
end;

end.
