unit Version1;

interface

uses System.SysUtils, Classes, Variants, Vcl.Graphics, Vcl.Controls, NetEncoding,
     MyTypes;

const
  _SignV1B: string = '>';
  _SignV1S: string = '=';
  _SignV1E: string = #13#10;

  procedure OnSourceEventV1(const aIndex: Int64);
  procedure OnPacketEventV1(const aIndex: int64);

implementation

uses MForm, Elements, Dictionary;

Function TakePart(Const aString: String; aIndex: Integer): Variant;
var OutList: TStringList;
begin
   Result:= unassigned;
   if aIndex < 0 then Exit;

   OutList := TStringList.Create;
   try
     OutList.Clear;
     OutList.Delimiter       := ';';
     OutList.StrictDelimiter := True;
     OutList.DelimitedText   := StringReplace(aString, _SignV1E, '', []);
     if aIndex < OutList.Count then
       Result:= OutList[aIndex];
   finally
     OutList.Free;
   end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

procedure OnSourceEventV1(const aIndex: Int64);
var CurrentPacket, PBegin, PSeparator, PEnd, SaveLength, D: Integer;
begin
  if (Length(FInPacketV1) = 0 ) or (0 < FInPacketV1[Pred(Length(FInPacketV1))].State) then
    begin
      CurrentPacket:= Length(FInPacketV1);
      SetLength(FInPacketV1, Succ(CurrentPacket));
      FInPacketV1[CurrentPacket].Time:= FInSource[aIndex].Time;
      FInPacketV1[CurrentPacket].Position:= FInSource[aIndex].Position;
      FInPacketV1[CurrentPacket].Size:= FInSource[aIndex].Size;

      if FInSource[aIndex].State = 255 then
        begin
          FInPacketV1[CurrentPacket].State:= 255;
          Exit;
        end
      else
        begin
          FInPacketV1[CurrentPacket].State:= 0;
        end;
    end
  else
    begin
      CurrentPacket:= Pred(Length(FInPacketV1));
      FInPacketV1[CurrentPacket].Size:= (FInSource[aIndex].Position + FInSource[aIndex].Size) - FInPacketV1[CurrentPacket].Position;
    end;

  PBegin:= MS.StringPosition( FInPacketV1[CurrentPacket].Position, FInPacketV1[CurrentPacket].Size, _SignV1B);
  while -1 < PBegin do
    begin
      if PBegin = FInPacketV1[CurrentPacket].Position then
        begin
          PEnd:= MS.StringPosition( FInPacketV1[CurrentPacket].Position, FInPacketV1[CurrentPacket].Size, _SignV1E);
          if PEnd < 0 then Break; //  Конечный символ еще не начитан

          PSeparator:= MS.StringPosition( FInPacketV1[CurrentPacket].Position + Length(_SignV1B),
                                          FInPacketV1[CurrentPacket].Size - length(_SignV1B), _SignV1B);
          if (-1 < PSeparator) and (PSeparator < PEnd) then
            if (0 < CurrentPacket) and (FInPacketV1[Pred(CurrentPacket)].State = 0) then
            begin
              D:= PSeparator - FInPacketV1[CurrentPacket].Position;
              FInPacketV1[Pred(CurrentPacket)].Size:= FInPacketV1[Pred(CurrentPacket)].Size + D;
              FInPacketV1[CurrentPacket].Position:= FInPacketV1[CurrentPacket].Position + D;
            end;

          FInPacketV1[CurrentPacket].Size:= PEnd + Length(_SignV1E) - FInPacketV1[CurrentPacket].Position;
          FInPacketV1[CurrentPacket].State:= 1;

          PSeparator:= MS.StringPosition( FInPacketV1[CurrentPacket].Position, FInPacketV1[CurrentPacket].Size, _SignV1S);
          if (-1 = PSeparator) or (PEnd < PSeparator) then
            if (0 < CurrentPacket) and (FInPacketV1[Pred(CurrentPacket)].State = 0) then
              begin
                FInPacketV1[Pred(CurrentPacket)].Size:= FInPacketV1[Pred(CurrentPacket)].Size + FInPacketV1[CurrentPacket].Size;
                Dec(CurrentPacket);
                SetLength(FInPacketV1, Succ(CurrentPacket));
              end
            else
              begin
                FInPacketV1[CurrentPacket].State:= 0;
              end;

          SaveLength:= Length(FInPacketV1);

          if FInPacketV1[CurrentPacket].State = 1 then
            OnPacketEventV1(CurrentPacket);

          // Сдвигаем указатель, так как могли добавиться исходящие пакеты
          CurrentPacket:= CurrentPacket + Length(FInPacketV1) - SaveLength;

          // Данные во входящем пакете закончились - выходим
          if PEnd + Length(_SignV1E) = FInSource[aIndex].Position + FInSource[aIndex].Size then Break;

          Inc(CurrentPacket);
          SetLength(FInPacketV1, Succ(CurrentPacket));
          FInPacketV1[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV1[CurrentPacket].Position:= PEnd + Length(_SignV1E);
          FInPacketV1[CurrentPacket].Size:= FInSource[aIndex].Position + FInSource[aIndex].Size - FInPacketV1[CurrentPacket].Position;
          FInPacketV1[CurrentPacket].State:= 0;

          if FInPacketV1[CurrentPacket-1].State = 1 then
            OnPacketEventV1(CurrentPacket-1);

        end
      else
        begin
          FInPacketV1[CurrentPacket].Size:= PBegin - FInPacketV1[CurrentPacket].Position;

          CurrentPacket:= Length(FInPacketV1);
          SetLength(FInPacketV1, Succ(CurrentPacket));
          FInPacketV1[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV1[CurrentPacket].Position:= PBegin;
          FInPacketV1[CurrentPacket].Size:= FInSource[aIndex].Position + FInSource[aIndex].Size - PBegin;
          FInPacketV1[CurrentPacket].State:= 0;
        end;

      PBegin:= MS.StringPosition( FInPacketV1[CurrentPacket].Position, FInPacketV1[CurrentPacket].Size, _SignV1B);
    end;
end;

procedure OnPacketEventV1(const aIndex: int64);
var i,j, N, P, PacketState, CC, LL :  Integer;
    Ident, value, sData, s, s0, s1, s2: String;
    A, B : AnsiString;
    V: Variant;
    W: LongWord;
    aControl, bControl: TObject;
    fItem: TItemClass;
    bytes: TBytes;
    Color: TColor;

    _Integer: Integer;
    _Byte: Byte absolute _Integer;
    _ShortInt: ShortInt absolute _Integer;
    _Word: Word absolute _Integer;
    _SmallInt: SmallInt absolute _Integer;
    _LongWord: LongWord absolute _Integer;
begin
  if FInPacketV1[aIndex].State = 1 then
    begin
      sData:= '';

      for i:=Length(_SignV1B) to Pred(FInPacketV1[aIndex].Size) do
        sData:= sData + Char( TByteArray(MForm.MS.Memory^)[FInPacketV1[aIndex].Position+i]);

      P:= Pos('=', sData);
      if 0 < P then
        try
          Ident:= Copy(sData, 1, P-1);
          Value:= Copy(sData, P+1, MaxInt);
          PacketState:= 2;

          if Ident = 'GK' then
            begin
              s0:= TakePart(Value, 0);
              s1:= TakePart(Value, 1);
              if (s0='0.000000') and (s1='0.000000') then
                begin
                  MF.VisualSetValue('_Latitude', unassigned);
                  MF.VisualSetValue('_Longitude', unassigned);
                end
              else
                begin
                  MF.VisualSetValue('_Latitude', s0);
                  MF.VisualSetValue('_Longitude', s1);
                end;
            end else

          if Ident = 'GS' then
            begin
              MF.VisualSetValue('_Satellites', TakePart(Value, 0));
              MF.VisualSetValue('_Speed', TakePart(Value, 1));
              MF.VisualSetValue('_Altitude', TakePart(Value, 2));
              MF.VisualSetValue('_HDOP', TakePart(Value, 3));
              MF.VisualSetValue('_Azimuth', TakePart(Value, 4));
            end else

          if Ident = 'DN' then
            begin
              N:= 0;
              S:= TakePart(Value, 0);
              for i := 1 to Length(s) do
                if s[i] in ['0'..'9'] then Inc(N);

              if N = Length(s) then
                MF.VisualSetValue('_DeviceID', TakePart(Value, 0))
            end else

          if Ident = 'DI' then
            begin
              case StrToIntDef(TakePart(Value, 0), 0) of
                100: MF.VisualSetValue('_DeviceType', '(2000)');
                101: MF.VisualSetValue('_DeviceType', '(1.3)');
                102: MF.VisualSetValue('_DeviceType', '(2100)');
                103: MF.VisualSetValue('_DeviceType', '(2200)');
                104: MF.VisualSetValue('_DeviceType', '(2300)');
                105: MF.VisualSetValue('_DeviceType', 'II');
                106: MF.VisualSetValue('_DeviceType', 'III');
                else MF.VisualSetValue('_DeviceType', TakePart(Value, 0));
              end;
              MF.VisualSetValue('_SoftVersion', TakePart(Value, 1)+'.'+TakePart(Value, 2));
            end else

          if (Ident = 'DS') then
            begin
              W:= StrToIntDef(TakePart(Value, 0), 0);
              if ($0001 and W)>0 then MF.VisualSetValue('_InternalMemory', unassigned{'Ok'})
                                 else MF.VisualSetValue('_InternalMemory', Translate(MF.Language, 'DSnosettings'), clRed);
              if ($0002 and W)>0 then MF.VisualSetValue('_ExternalMemory', unassigned{'Ok'})
                                 else MF.VisualSetValue('_ExternalMemory', Translate(MF.Language, 'Error'), clRed);

              if not (MF.Q = nil) and (0 < Length(MF.Q.DeviceVer)) and (MF.Q.DeviceVer <> '213') and (MF.Q.DeviceVer <> '215')then
              if ($0004 and W)>0 then MF.VisualSetValue('_RealTimeClock', 'Ok')
                                 else MF.VisualSetValue('_RealTimeClock', Translate(MF.Language, 'Error'), clRed);


              if (($0008 and W)>0) and(($0010 and W)>0) and (($0020 and W)>0)
                                 then MF.VisualSetValue('_ModemStatus', 'Ok') else
                if (($0008 and W) =0) then MF.VisualSetValue('_ModemStatus', Translate(MF.Language, 'DSnopower'), clWhite) else
                if (($0010 and W) =0) then MF.VisualSetValue('_ModemStatus', Translate(MF.Language, 'Error'), clRed) else
                if (($0020 and W) =0) then MF.VisualSetValue('_ModemStatus', Translate(MF.Language, 'DSnoanswer'), clRed);

              if ($0040 and W)>0 then begin
                                        if ($2000 and W)=0 then MF.VisualSetValue('_ModemSIM', Translate(MF.Language, 'DSactive'))
                                                           else MF.VisualSetValue('_ModemSIM', Translate(MF.Language, 'DSinstall'));
                                        if ($0080 and W)=0 then
                                          if ($0100 and W)>0 then MF.VisualSetValue('_ModemPIN', Translate(MF.Language, 'DSnopin'))
                                                             else MF.VisualSetValue('_ModemPIN', Translate(MF.Language, 'DSpin'), clWhite)
                                                           else
                                                                  MF.VisualSetValue('_ModemPIN', unassigned)
                                      end
                                 else begin
                                        MF.VisualSetValue('_ModemSIM', unassigned);
                                        MF.VisualSetValue('_ModemPIN', unassigned);
                                      end;

              if ($010000 and W)>0 then begin
                                        if ($2000 and W)>0 then MF.VisualSetValue('_ModemSIM2', Translate(MF.Language, 'DSactive'))
                                                           else MF.VisualSetValue('_ModemSIM2', Translate(MF.Language, 'DSinstall'));
                                        if ($020000 and W)=0 then
                                          if ($040000 and W)>0 then MF.VisualSetValue('_ModemPIN2', Translate(MF.Language, 'DSnopin'))
                                                               else MF.VisualSetValue('_ModemPIN2', Translate(MF.Language, 'DSpin'), clWhite)
                                                             else
                                                                  MF.VisualSetValue('_ModemPIN2', unassigned)
                                      end
                                 else begin
                                        MF.VisualSetValue('_ModemSIM2', unassigned);
                                        MF.VisualSetValue('_ModemPIN2', unassigned);
                                      end;

              if (($0200 and W)>0) and (($0400 and W)>0)
                                 then MF.VisualSetValue('_NavigationStatus', 'Ok')
                                 else MF.VisualSetValue('_NavigationStatus', Translate(MF.Language, 'Error'), clRed);
              if ($0800 and W)>0 then MF.VisualSetValue('_AccelerometerStatus', 'Ok')
                                 else MF.VisualSetValue('_AccelerometerStatus', Translate(MF.Language, 'Error'), clRed);

            end else

          if (Ident = 'DS2') then
            begin
              W:= StrToIntDef(TakePart(Value, 0), 0);
              case $0003 and (W shr 0) of
                0: MF.VisualSetValue('_NavigationStatus', Translate(MF.Language,'DS2_1_0'));
                1: MF.VisualSetValue('_NavigationStatus', Translate(MF.Language,'DS2_1_1'));
                2: MF.VisualSetValue('_NavigationStatus', Translate(MF.Language,'DS2_1_2'));
                3: MF.VisualSetValue('_NavigationStatus', Translate(MF.Language,'DS2_1_3'));
              end;
              case $0007 and (W Shr 2) of
                0: MF.VisualSetValue('_ModemStatus', Translate(MF.Language,'DS2_1_0'));
                1: MF.VisualSetValue('_ModemStatus', Translate(MF.Language,'DS2_1_1'));
                2: MF.VisualSetValue('_ModemStatus', Translate(MF.Language,'DS2_2_2'));
                3: MF.VisualSetValue('_ModemStatus', Translate(MF.Language,'DS2_2_3'));
                4: MF.VisualSetValue('_ModemStatus', Translate(MF.Language,'DS2_2_4'));
              end;

              case $0001 and (W Shr 5) of
                0: Color:= _Green;
                1: Color:= _Gray;
              end;
              case $0007 and (W Shr 6) of
                       $00: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_0'), Color);
                       $01: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_1'), Color);
                       $02: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_2'), Color);
                       $03: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_3'), Color);
                       $04: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_4'), Color);
                       $05: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_5'), Color);
                       $06: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_6'), Color);
                       $07: MF.VisualSetValue('_ModemSIM', Translate(MF.Language,'DS2_4_7'), Color);
              end;

              case $0001 and (W Shr 5) of
                0: Color:= _Gray;
                1: Color:= _Green;
              end;
              case $0007 and (W Shr 9) of
                       $00: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_0'), Color);
                       $01: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_1'), Color);
                       $02: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_2'), Color);
                       $03: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_3'), Color);
                       $04: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_4'), Color);
                       $05: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_5'), Color);
                       $06: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_6'), Color);
                       $07: MF.VisualSetValue('_ModemSIM2', Translate(MF.Language,'DS2_4_7'), Color);
              end;

              case $0003 and (W Shr 12) of
                0: MF.VisualSetValue('_Server0', Translate(MF.Language,'MS_'), _Gray);
                1: MF.VisualSetValue('_Server0', Translate(MF.Language,'MS5'));
                2: MF.VisualSetValue('_Server0', Translate(MF.Language,'MS6'));
                3: MF.VisualSetValue('_Server0', Translate(MF.Language,'MS8'));
              end;
              case $0003 and (W Shr 14) of
                0: MF.VisualSetValue('_Server1', Translate(MF.Language,'MS_'), _Gray);
                1: MF.VisualSetValue('_Server1', Translate(MF.Language,'MS5'));
                2: MF.VisualSetValue('_Server1', Translate(MF.Language,'MS6'));
                3: MF.VisualSetValue('_Server1', Translate(MF.Language,'MS8'));
              end;
              case $0003 and (W Shr 16) of
                0: MF.VisualSetValue('_Server2', Translate(MF.Language,'MS_'), _Gray);
                1: MF.VisualSetValue('_Server2', Translate(MF.Language,'MS5'));
                2: MF.VisualSetValue('_Server2', Translate(MF.Language,'MS6'));
                3: MF.VisualSetValue('_Server2', Translate(MF.Language,'MS8'));
              end;
              case $0003 and (W Shr 18) of
                0: MF.VisualSetValue('_Server3', unassigned);
                1: MF.VisualSetValue('_Server3', Translate(MF.Language,'MS5'));
                2: MF.VisualSetValue('_Server3', Translate(MF.Language,'MS6'));
                3: MF.VisualSetValue('_Server3', Translate(MF.Language,'MS8'));
              end;

              case $0003 and (W Shr 20) of
                0: MF.VisualSetValue('_ModuleReadings', Translate(MF.Language,'TM2'));
                1: MF.VisualSetValue('_ModuleReadings', Translate(MF.Language,'TM0'));
                2: MF.VisualSetValue('_ModuleReadings', Translate(MF.Language,'Error'), clRed);
                3: MF.VisualSetValue('_ModuleReadings', Translate(MF.Language,'ErrorTest'), clRed);
              end;

              case $0001 and (W Shr 25) of
                0: MF.VisualSetValue('_Bluetooth', Translate(MF.Language,'DS2_1_0'), _Gray);
                1: MF.VisualSetValue('_Bluetooth', Translate(MF.Language,'DS2_1_1'));
              end;
            end else

          if Ident = 'MS' then
            begin
              V:= TakePart(Value, 0);
              if (V = '0') or (V = '8') then
                                MF.VisualSetValue('_ModemNetworkState', Translate(MF.Language, 'MS'+V), clWhite) else
              if (V = '1') or (V = '2') or (V = '3') or (V = '4') or (V = '5') or (V = '6') or (V = '7') then
                                MF.VisualSetValue('_ModemNetworkState', Translate(MF.Language, 'MS'+V)) else
                                MF.VisualSetValue('_ModemNetworkState', TakePart(Value, 0), clRed);
            end else

          if Ident = 'DF' then
            begin
              V:= TakePart(Value, 0);
              if (V = '0') then MF.VisualSetValue('_SettingsStatus', Translate(MF.Language, 'DF0')) else
              if (V = '1') or (V = '2') or (V = '3') then
                                MF.VisualSetValue('_SettingsStatus', Translate(MF.Language, 'DF'+V), clRed) else
                                MF.VisualSetValue('_SettingsStatus', unassigned);

              V:= TakePart(Value, 1);
              if (V = '0') then MF.VisualSetValue('_SoftStatus', Translate(MF.Language, 'DF0')) else
              if (V = '1') or (V = '2') or (V = '3') then
                                MF.VisualSetValue('_SoftStatus', Translate(MF.Language, 'DF'+V), clRed) else
                                MF.VisualSetValue('_SoftStatus', unassigned);
            end else

          if Ident = 'TW' then
            begin
              V:= StrToIntDef(TakePart(Value, 0),0);
              V:= DateToStr(UnixTimeToDateTime(V,0))+' '+TimeToStr(UnixTimeToDateTime(V,0));
              MF.VisualSetValue('_InternalTtime', V);

              W:= StrToIntDef(TakePart(Value, 1),0);
              if W=0
                then V:= unassigned
                else begin
                       V:= Format('%.2d',  [W mod 60]);      W:= W div 60;
                       V:= Format('%.2d:', [W mod 60]) + V;  W:= W div 60;
                       V:= Format('%.2d:', [W mod 60]) + V;  W:= W div 24;
                       if 0 < W then
                       V:= Format('%.2d ', [W])+V;
                     end;
              MF.VisualSetValue('_Uptime', V);
            end else

          if Ident = 'TM' then
            begin
              V:= TakePart(Value, 0);
              if (V = '0') or (V = '1') or (V = '2') or (V = '3') then
                      MF.VisualSetValue('_ModuleReadings', Translate(MF.Language, 'TM'+V)) else
                      MF.VisualSetValue('_ModuleReadings', unassigned);
              W:= StrToIntDef(TakePart(Value, 1), 0);
              V:= Format('%.2d',  [W mod 60]);      W:= W div 60;
              V:= Format('%.2d:', [W mod 60]) + V;  W:= W div 60;
              V:= Format('%.2d:', [W mod 60]) + V;  W:= W div 24;
              if 0 < W then
              V:= Format('%.2d ', [W])+V;
              if W=0 then MF.VisualSetValue('_RestTime', unassigned)
                     else MF.VisualSetValue('_RestTime', V);
            end else

          if (Ident = 'WS') then
            begin
              V:= TakePart(Value, 0);
              if (V = '0') or (V = '3') or (V = '5') or (V = '7')
                           then MF.VisualSetValue('_ModuleWiFi', Translate(MF.Language, 'WS'+V), clWhite) else
              if (V = '1') or (V = '2') or (V = '4') or (V = '6') or (V = '8') or (V = '9')
                           then MF.VisualSetValue('_ModuleWiFi', Translate(MF.Language, 'WS'+V)) else
                                MF.VisualSetValue('_ModuleWiFi', unassigned);
            end else

          if Ident = 'PB' then
            begin
              MF.VisualSetValue('_ExternalVoltage', (StrToIntDef(TakePart(Value, 0), 0) div 10) / 100 );
              MF.VisualSetValue('_BatteryVoltage', (StrToIntDef(TakePart(Value, 1), 0) div 10) / 100);
            end else

          if Ident = 'ML' then
            begin
              MF.VisualSetValue('_ModemSignal', ValueToProgress(0,31, StrToIntDef(TakePart(Value, 0), unassigned)), _Green, TakePart(Value, 0));

              if StrToIntDef(TakePart(Value, 1),0) = 0 then
                MF.VisualSetValue('_ModemOperator', unassigned)
              else
                MF.VisualSetValue('_ModemOperator', OperatorNameByCode(TakePart(Value, 1)+TakePart(Value, 2)) + ' - ' +
                                                    CountryNameByCode(TakePart(Value, 1)) );
            end else

          if Ident = 'MO' then
            begin
              MF.VisualSetValue('_ModemSignal', ValueToProgress(0,31, StrToIntDef(TakePart(Value, 0), unassigned) ));
              if (Length(TakePart(Value, 0)) = 0) or (TakePart(Value, 1) ='00000') then
                MF.VisualSetValue('_ModemOperator', unassigned)
              else
                MF.VisualSetValue('_ModemOperator', TakePart(Value, 0) + ' - ' +
                                                    OperatorNameByCode(Copy(TakePart(Value, 1),1,3)) + ' - ' +
                                                    CountryNameByCode(      TakePart(Value, 1)     ) );
            end else

          if Ident = 'MD0' then
            begin
              if (TakePart(Value, 0)<>'') then
                MF.VisualSetValue('_Server0', TakePart(Value, 0)+':'+TakePart(Value, 1)+' ('+TakePart(Value, 2)+')' );
            end else

          if (Ident = 'MD1') or (Ident = 'MD') then
            begin
              if (TakePart(Value, 0)<>'') then
                MF.VisualSetValue('_Server1', TakePart(Value, 0)+':'+TakePart(Value, 1)+' ('+TakePart(Value, 2)+')' );
            end else

          if Ident = 'MD2' then
            begin
              if (TakePart(Value, 0)<>'') then
                MF.VisualSetValue('_Server2', TakePart(Value, 0)+':'+TakePart(Value, 1)+' ('+TakePart(Value, 2)+')' );
            end else

          if Ident = 'MN' then
            begin
              N:= 0;
              S:= TakePart(Value, 0);
              for i := 1 to Length(s) do
                if s[i] in ['0'..'9'] then Inc(N);

              if N = Length(s) then
                MF.VisualSetValue('_DeviceIMEI', s );
            end else

          if Ident = 'RW' then
            begin
              MF.VisualSetValue('_StrorageWrite', TakePart(Value, 1) );
              s:= TakePart(Value, 0);
              MF.VisualSetValue('_StrorageSendServer1', Copy(s,1,Pos('/',s)-1));
              MF.VisualSetValue('_StrorageSendServer2', Copy(s,Pos('/',s)+1, MaxInt));
              MF.Q.FMemoryWrite:=  StrToIntDef(TakePart(Value, 1), 0);
            end else

          if Ident = 'RW1' then
            begin
              MF.VisualSetValue('_StrorageSendServer1', TakePart(Value, 0));
              MF.VisualSetValue('_StrorageWrite', TakePart(Value, 1) );
              MF.Q.FMemorySend1:=  StrToIntDef(TakePart(Value, 0), 0);
              MF.Q.FMemoryWrite:=  StrToIntDef(TakePart(Value, 1), 0);
              MF.Q.FMemoryCount:=  StrToIntDef(TakePart(Value, 2), 0);
              MF.Q.FMemoryOffset:= StrToIntDef(TakePart(Value, 3), 0);
            end else

          if Ident = 'RW2' then
            begin
              MF.VisualSetValue('_StrorageSendServer2', TakePart(Value, 0));
              MF.VisualSetValue('_StrorageWrite', TakePart(Value, 1) );

              MF.Q.FMemorySend2:=  StrToIntDef(TakePart(Value, 0), 0);
              MF.Q.FMemoryWrite:=  StrToIntDef(TakePart(Value, 1), 0);
              MF.Q.FMemoryCount:=  StrToIntDef(TakePart(Value, 2), 0);
              MF.Q.FMemoryOffset:= StrToIntDef(TakePart(Value, 3), 0);
            end else

          if Ident = 'CA' then MF.VisualSetValue('_CanEngineTime', StrToIntDef(TakePart(Value, 0), 0)/100 ) else
          if Ident = 'CB' then MF.VisualSetValue('_CanEngineTime', StrToIntDef(TakePart(Value, 0), 0)/100 ) else // дубль
          if Ident = 'CC' then MF.VisualSetValue('_CanMileage', StrToIntDef(TakePart(Value, 0), 0)/100 ) else
          if Ident = 'CD' then MF.VisualSetValue('_CanMileage', StrToIntDef(TakePart(Value, 0), 0)/100 ) else // дубль
          if Ident = 'CE' then MF.VisualSetValue('_CanFuelConsumption', StrToIntDef(TakePart(Value, 0), 0)/10 ) else
          if Ident = 'CF' then MF.VisualSetValue('_CanFuelConsumption', StrToIntDef(TakePart(Value, 0), 0)/10 ) else  // дубль
          if Ident = 'CG' then MF.VisualSetValue('_CanFuelPercent', StrToIntDef(TakePart(Value, 0), 0)/10 ) else
          if Ident = 'CH' then MF.VisualSetValue('_CanEngineRPM', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CI' then MF.VisualSetValue('_CanEngineTemperature', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CJ' then MF.VisualSetValue('_CanSpeed', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CK' then MF.VisualSetValue('_CanAxle1', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CL' then MF.VisualSetValue('_CanAxle2', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CM' then MF.VisualSetValue('_CanAxle3', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CN' then MF.VisualSetValue('_CanAxle4', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CO' then MF.VisualSetValue('_CanAxle5', StrToIntDef(TakePart(Value, 0), 0) ) else
          if Ident = 'CP' then MF.VisualSetValue('_CanCrash', TakePart(Value, 0)) else
          if Ident = 'CQ' then MF.VisualSetValue('_CanFuelInstant', StrToIntDef(TakePart(Value, 0), 0)/10 ) else
          if Ident = 'CR' then MF.VisualSetValue('_CanFuelReserve', StrToIntDef(TakePart(Value, 0), 0)/10 ) else
          if Ident = 'CS' then MF.VisualSetValue('_CanSecurity', StrToIntDef(TakePart(Value, 0), unassigned) ) else
          if Ident = 'CU' then MF.VisualSetValue('_CanAdBlue', TakePart(Value, 0)) else
          if Ident = 'CV' then MF.VisualSetValue('_CanProgram', TakePart(Value, 0)+'  '+TakePart(Value, 1)+'/'+TakePart(Value, 2)) else

          if Ident = 'SMS' then
            begin
              s0:= TakePart(Value, 0);
              s1:= TakePart(Value, 1);
              s2:= TakePart(Value, 2);
              MF.VisualSetValue('_ModemInSMS', s0 );
              MF.VisualSetValue('_ModemOkSMS', s1 );
              MF.VisualSetValue('_ModemOutSMS', s2 );
              MF.VisualSetValue('_ModemInOutSMS', s0+' / '+s2 );
              V:= StrToIntDef(s0, 0) + StrToIntDef(s2, 0) - StrToIntDef(s1, 0);
              if V=0 then MF.VisualSetValue('_ModemErrorSMS', unassigned )
                     else MF.VisualSetValue('_ModemErrorSMS', IntToStr(V) );
            end else

          if Ident = 'APN' then
            begin
              MF.VisualSetValue('_StringAPN', TakePart(Value, 0));
              MF.VisualSetValue('_LoginAPN', TakePart(Value, 1));
              MF.VisualSetValue('_PasswordAPN', TakePart(Value, 2));
            end else

          if (Length(Ident) in [3,4]) and (Ident[1] in ['I','O']) and (Ident[2] in ['U','D', 'I', 'F', 'A', '1'..'3'])
             and (Ident[3] in ['0'..'9']) and (Ident[4] in [#0,'0'..'9']) then
            begin
              if Not MF.VisualFind( MF, Copy(Ident,3,2)+' _InOut', aControl) then
                if MF.VisualFind( MF, '_InputOutput', bControl) then
                  if (bControl is TCaptionClass) then
                    begin
                       aControl:= TItemClass.Create(MF);
                       TItemClass(aControl).Top:= MaxInt;
                       TItemClass(aControl).Parent:= TCaptionClass(bControl).Body;
                       TItemClass(aControl).Ident:= Copy(Ident,3,2)+' _InOut';
                       TItemClass(aControl).AutoHide:= True;
                    end;

              if assigned(aControl) and (aControl is TItemClass) then
                begin
                  TItemClass(aControl).SetColor(_Green);

                  TItemClass(aControl).Caption:= 'PIN '+Copy(Ident,3,2)+'. '+
                                                 Translate(MF.Language, 'iod_'+Ident[1])+' '+
                                                 Translate(MF.Language, 'iot_'+Ident[2]);
                  V:= TakePart(Value, 0);
                  if (Ident[2] in ['D','1','2','3']) and (V='0') then TItemClass(aControl).Value:= Translate(MF.Language, 'UnitsOFF') else
                  if (Ident[2] in ['D','1','2','3']) and (V='1') then TItemClass(aControl).Value:= Translate(MF.Language, 'UnitsON') else
                                                                      TItemClass(aControl).Value:= V;

                  if (Ident[2]='A') then TItemClass(aControl).Units:= Translate(MF.Language, 'UnitsA') else
                  if (Ident[2]='F') then TItemClass(aControl).Units:= Translate(MF.Language, 'UnitsF') else
                                         TItemClass(aControl).Units:= '';
                end;
            end else

          if Ident = 'LLS' then
            begin
              A:= TakePart(Value, 0);
              B:= TakePart(Value, 1);

              // создаем если его нет
              if Not MF.VisualFind( MF, '_DUT' + A + '.' + B , aControl) then
                if MF.VisualFind( MF, '_SensorDUT', aControl) then
                  begin
                    fItem:= TItemClass.Create(MF);
                    fItem.Parent:=TCaptionClass(TBaseClass(aControl)).Body;
                    fItem.Ident:= '_DUT' + A + '.' + B;
                    fItem.Caption:= Translate(MF.Language, '_DUT') + ' ' +  A + '.' + B;
                    fItem.AutoHide:= True;
                    aControl:= fItem;
                  end;

              // устанавливаем значения
              if assigned(aControl) then
                begin
                  TBaseClass(aControl).Value:= TakePart(Value, 2) + ' / ' +
                                               TakePart(Value, 4) + ' '+Translate(MF.Language,'UnitsF')+' / ' +
                                               TakePart(Value, 3) + '°C';
                  TBaseClass(aControl).SetColor(_Green);
                end;
            end else

          if Ident = 'OWT' then
            begin
              A:= TakePart(Value, 0);
              B:= TakePart(Value, 1);

              // создаем если его нет
              if Not MF.VisualFind( MF, '_OWT ' + A + ' [' + B + ']' , aControl) then
                if MF.VisualFind( MF, '_SensorOWT', aControl) then
                  begin
                    fItem:= TItemClass.Create(MF);
                    fItem.Parent:= TCaptionClass(TBaseClass(aControl)).Body;
                    fItem.Ident:= '_OWT ' + A + ' [' + B + ']';
                    fItem.Caption:= Translate(MF.Language, '_OWT') +' ' + A + ' [' + B + ']';
                    fItem.AutoHide:= True;
                    aControl:= fItem;
                  end;

              // устанавливаем значения
              if assigned(aControl) then
                begin
                  TBaseClass(aControl).Value:= TakePart(Value, 2) + ' °C';
                  TBaseClass(aControl).SetColor(_Green);
                end;
            end else

          if Ident = 'OWK' then
            begin
              A:= TakePart(Value, 0);

              // создаем если его нет
              if Not MF.VisualFind( MF, 'OWK' + A , aControl) then
                if MF.VisualFind( MF, '_SensorOWK', aControl) then
                  begin
                    fItem:= TItemClass.Create(MF);
                    fItem.Parent:= TCaptionClass(TBaseClass(aControl)).Body;
                    fItem.Ident:= 'OWK' + A;
                    fItem.Caption:= Translate(MF.Language, '_OWK') + ' ' + A;
                    fItem.AutoHide:= True;
                    aControl:= fItem;
                  end;

              // устанавливаем значения
              if assigned(aControl) then
                begin
                  TBaseClass(aControl).Value:= TakePart(Value, 1);
                  TBaseClass(aControl).SetColor(_Green);
                end;
            end else

          if Ident = 'SR' then
            begin
              if TakePart(Value, 0) = '1' then MF.MainHintShow(1, Translate(MF.Language, 'SR1'))
                                          else MF.MainHintShow(0, Translate(MF.Language, 'SR0'));
            end else

          if Ident = 'WSP' then MF.VisualSetValue('_PointWIFI', Value) else
          if Ident = 'EMS' then MF.VisualSetValue('_StatusExtmemory', Value) else
          if Ident = 'MSD' then MF.VisualSetValue('_StatusCardSD', Value) else

          if Ident = 'SF' then
            begin
              MF.SettingsReady:= True;

              A:= VarToStr(Value);
              A:= Copy(A,2,Length(A)-4);

              bytes:= TBase64Encoding.Base64.DecodeStringToBytes(A);

              P:=4;
              while P < Length(bytes) do
                begin
                  CC:= bytes[P+1];
                  LL:= bytes[P+2];
                  if bytes[P]= $23 then
                    begin
                      if CC = 5 then
                        begin
                          V:= '';
                          for j:=0 to Pred(LL) do V:= V + Char(bytes[P+3+j]);
                          MF.Q.DevicePassword:= V;
                        end;

                      for i:=Low(z) to High(z) do
                        if z[i].Number = CC then
                          begin
                            Move(Bytes[P+3], _Integer, 4);
                            V:= unassigned;
                            case z[i].VarType of
                              VarByte: V:= Bytes[P+3];
                              VarWord: V:= 256*Bytes[P+3] + Bytes[P+4];
                              VarLongWord: V:= 16777216*Bytes[P+3] + 65536*Bytes[P+4] + 256*Bytes[P+5]+ Bytes[P+6];
                              varShortInt:
                                         begin
                                           _Byte:= Bytes[P+3];
                                           V:= _ShortInt;
                                         end;
                              varSmallInt:
                                         begin
                                           _Word:= 256*Bytes[P+3] + Bytes[P+4];
                                           V:= _SmallInt;
                                         end;
                              varInteger:
                                         begin
                                           _LongWord:= 16777216*Bytes[P+3] + 65536*Bytes[P+4] + 256*Bytes[P+5]+ Bytes[P+6];
                                           V:= _Integer;
                                         end;
                              VarString: begin
                                           V:= '';
                                           for j:=0 to Pred(LL) do V:= V + Char(bytes[P+3+j]);
                                         end;
                            end;
                            if  (-1 < z[i].Bit) and (z[i].VarType in [VarByte, VarWord, VarLongWord]) then
                              if (V and (1 shl z[i].Bit)) = 0 then V:= 0
                                                              else V:= 1;

                            MF.VisualSetValue(z[i].Alias, V);
                          end;
                    end;
                  P:= P + LL + 3;
                end;
              {
              if MF.Q.DeviceVer = '5' then
                for i:=0 to 255 do
                  if z[i].Number = 5 then
                    MF.VisualSetValue(z[i].Alias, MF.Q.UserPassword);
              {}
              for i := Low(z) to High(z) do
                if z[i].WinControl is TControlClass then
                  TControlClass(z[i].WinControl).Colorize;


              MF.Q.HaveSettings:= True;
            end else

            begin
              PacketState:= 1;
            end;

            FInPacketV1[aIndex].State:= PacketState;
          except
            FInPacketV1[aIndex].State:= 1;
          end;
    end;
end;

end.
