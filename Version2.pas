unit Version2;

interface

uses System.SysUtils, Classes, Variants, Vcl.Graphics,
     MyTypes;

const
  _SignV2B: Array[0..1] of Byte =  ( 85, 170);

  procedure OnSourceEventV2(const aIndex: Int64);
  procedure OnPacketEventV2(const aIndex: int64);

implementation

uses MForm, Elements, Dictionary;

procedure OnSourceEventV2(const aIndex: Int64);
var CurrentPacket, PBegin: Integer;
    PSize: Word;
begin
  if (Length(FInPacketV2) = 0 ) or (0 < FInPacketV2[Pred(Length(FInPacketV2))].State) then
    begin
      CurrentPacket:= Length(FInPacketV2);
      SetLength(FInPacketV2, Succ(CurrentPacket));
      FInPacketV2[CurrentPacket].Time:= FInSource[aIndex].Time;
      FInPacketV2[CurrentPacket].Position:= FInSource[aIndex].Position;
      FInPacketV2[CurrentPacket].Size:= FInSource[aIndex].Size;

      if FInSource[aIndex].State = 255 then
        begin
          FInPacketV2[CurrentPacket].State:= 255;
          Exit;
        end
      else
        begin
          FInPacketV2[CurrentPacket].State:= 0;
        end;
    end
  else
    begin
      CurrentPacket:= Pred(Length(FInPacketV2));
      FInPacketV2[CurrentPacket].Size:= (FInSource[aIndex].Position + FInSource[aIndex].Size) - FInPacketV2[CurrentPacket].Position;
    end;

  PBegin:= MS.ArrayPosition( FInPacketV2[CurrentPacket].Position, FInPacketV2[CurrentPacket].Size, @_SignV2B, SizeOf(_SignV2B) );
  while -1 < PBegin do
    begin
      if PBegin = FInPacketV2[CurrentPacket].Position then
        begin
          if MS.Size < PBegin + 8 then Break; // Заголовок полностью еще не начитан

          PSize:= TByteArray(MS.Memory^)[PBegin + 6] + TByteArray(MS.Memory^)[PBegin + 7] * 256;
          if MS.Size < PBegin + 8 + PSize + 2 then Break;  // Пакет полностью не начитан

          FInPacketV2[CurrentPacket].Size:= PBegin - FInPacketV2[CurrentPacket].Position + 8 + PSize + 2;
          FInPacketV2[CurrentPacket].State:= 1;

          if FInPacketV2[CurrentPacket].State = 1 then
            OnPacketEventV2(CurrentPacket);

          // Данные во входящем пакете закончились - выходим
          if MS.Size = PBegin + 8 + PSize + 2 then
            Break;

          Inc(CurrentPacket);
          SetLength(FInPacketV2, Succ(CurrentPacket));
          FInPacketV2[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV2[CurrentPacket].Position:= FInPacketV2[Pred(CurrentPacket)].Position + FInPacketV2[Pred(CurrentPacket)].Size;
          FInPacketV2[CurrentPacket].Size:= FInSource[aIndex].Position + FInSource[aIndex].Size - FInPacketV2[CurrentPacket].Position;
          FInPacketV2[CurrentPacket].State:= 0;
        end
      else
        begin
          FInPacketV2[CurrentPacket].Size:= PBegin - FInPacketV2[CurrentPacket].Position;

          CurrentPacket:= Length(FInPacketV2);
          SetLength(FInPacketV2, Succ(CurrentPacket));
          FInPacketV2[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV2[CurrentPacket].Position:= PBegin;
          FInPacketV2[CurrentPacket].Size:= FInSource[aIndex].Size - PBegin;
          FInPacketV2[CurrentPacket].State:= 0;
        end;

      PBegin:= MS.ArrayPosition( FInPacketV2[CurrentPacket].Position, FInPacketV2[CurrentPacket].Size, @_SignV2B, SizeOf(_SignV2B) );;
    end;

end;

procedure OnPacketEventV2(const aIndex: int64);
var P: Int64;
    PacketState: Byte;
    FWord: Word;
    FCardinal: Cardinal;
    FDateTime: TDateTime;
    S: String;
begin
  P:= MForm.FInPacketV2[aIndex].Position;
  if MForm.FInPacketV2[aIndex].State = 1 then
    begin
      PacketState:= 2;
      case MS.AsCardinal( P + 2) of
        $00020001: begin
                     FDateTime:= UnixTimeToDateTime(MS.AsCardinal( P + 8), 0);
                     MF.VisualSetValue('_InternalTtime', DateToStr(FDateTime)+' '+TimeToStr(FDateTime));

                     FCardinal:= MS.AsCardinal( P + 12);
                     S:= Format('%.2d',  [FCardinal mod 60]);      FCardinal:= FCardinal div 60;
                     S:= Format('%.2d:', [FCardinal mod 60]) + S;  FCardinal:= FCardinal div 60;
                     S:= Format('%.2d:', [FCardinal mod 60]) + S;  FCardinal:= FCardinal div 24;
                     if 0 < FCardinal then
                     S:= Format('%.2d ', [FCardinal])+S;
                     MF.VisualSetValue('_Uptime', S);
                   end;
        $00030001: begin
                     MF.VisualSetValue('_ExternalVoltage', MS.AsWord( P +  8) / 1000 );
                     MF.VisualSetValue('_BatteryVoltage', MS.AsWord( P + 10) / 1000);
                   end;
        $00020002: begin
                     case MS.AsByte( P +  8) of
                       $00: MF.VisualSetValue('_ModemStatus','Отсутствует');
                       $01: MF.VisualSetValue('_ModemStatus','регистрация в домашней сети');
                       $02: MF.VisualSetValue('_ModemStatus','поиск сети');
                       $03: MF.VisualSetValue('_ModemStatus','регистрация отклонена');
                       $04: MF.VisualSetValue('_ModemStatus','резерв');
                       $05: MF.VisualSetValue('_ModemStatus','регистрация в роуминге');
                       $06: MF.VisualSetValue('_ModemStatus','ошибка ПИН');
                       $07: MF.VisualSetValue('_ModemStatus','резерв');
                       $09: MF.VisualSetValue('_ModemStatus','GPRS активирован в домашней сети');
                       $0d: MF.VisualSetValue('_ModemStatus','GPRS активирован в роуминге');
                     end;
                     MF.VisualSetValue('ML', MS.AsByte( P +  9));
                     MF.VisualSetValue('ML2', MS.AsInteger( P +  10));

                     MF.VisualSetValue('ML1', CountryNameByCode(IntToStr(MS.AsInteger( P + 10) div 100)));
                     MF.VisualSetValue('ML2', OperatorNameByCode(IntToStr(MS.AsInteger( P + 10))));

                     FWord:= MS.AsWord( P +  14);
                     FWord:= MS.AsWord( P +  16);
                     MF.VisualSetValue('_ModemInSMS', MS.AsWord( P +  18));
                     MF.VisualSetValue('_ModemOutSMS', MS.AsWord( P +  20));
                   end;
        $00200009: begin
                     FWord:= MS.AsWord( P +  8);
                     if 0 < (FWord and $01) then MF.VisualSetValue('ID0', 1)
                                            else MF.VisualSetValue('ID0', 0);
                     if 0 < (FWord and $02) then MF.VisualSetValue('ID1', 1)
                                            else MF.VisualSetValue('ID1', 0);
                     if 0 < (FWord and $04) then MF.VisualSetValue('ID2', 1)
                                            else MF.VisualSetValue('ID2', 0);
                     if 0 < (FWord and $08) then MF.VisualSetValue('ID3', 1)
                                            else MF.VisualSetValue('ID3', 0);
                     if 0 < (FWord and $10) then MF.VisualSetValue('ID4', 1)
                                            else MF.VisualSetValue('ID4', 0);
                     if 0 < (FWord and $20) then MF.VisualSetValue('ID5', 1)
                                            else MF.VisualSetValue('ID5', 0);
                     if 0 < (FWord and $40) then MF.VisualSetValue('ID6', 1)
                                            else MF.VisualSetValue('ID6', 0);
                     if 0 < (FWord and $80) then MF.VisualSetValue('ID7', 1)
                                            else MF.VisualSetValue('ID7', 0);

                     FWord:= MS.AsWord( P + 10);
                     if 0 < (FWord and $01) then MF.VisualSetValue('OD0', 1)
                                            else MF.VisualSetValue('OD0', 0);
                     if 0 < (FWord and $02) then MF.VisualSetValue('OD1', 1)
                                            else MF.VisualSetValue('OD1', 0);
                     if 0 < (FWord and $04) then MF.VisualSetValue('OD2', 1)
                                            else MF.VisualSetValue('OD2', 0);
                     if 0 < (FWord and $08) then MF.VisualSetValue('OD3', 1)
                                            else MF.VisualSetValue('OD3', 0);
                     if 0 < (FWord and $10) then MF.VisualSetValue('OD4', 1)
                                            else MF.VisualSetValue('OD4', 0);
                     if 0 < (FWord and $20) then MF.VisualSetValue('OD5', 1)
                                            else MF.VisualSetValue('OD5', 0);
                     if 0 < (FWord and $40) then MF.VisualSetValue('OD6', 1)
                                            else MF.VisualSetValue('OD6', 0);
                     if 0 < (FWord and $80) then MF.VisualSetValue('OD7', 1)
                                            else MF.VisualSetValue('OD7', 0);
                   end;
        $00010010: begin
                     FCardinal:= MS.AsCardinal(P + 12);

//                     FDouble:= MS.AsDouble(P + 12);
                     MF.VisualSetValue('_Latitude', MS.AsSingle(P + 12));
                     MF.VisualSetValue('_Longitude', MS.AsSingle(P + 16));
                     MF.VisualSetValue('_Altitude', Round(MS.AsSingle(P + 20)));
                     MF.VisualSetValue('_Speed', MS.AsWord(P + 24)/100);
                     MF.VisualSetValue('_Azimuth', MS.AsWord(P + 26)/100);
                     MF.VisualSetValue('_HDOP', MS.AsWord(P + 28)/100);
                     MF.VisualSetValue('_Satellites', MS.AsByte(P + 30));
                   end
             else  begin
                     PacketState:= 1;
                   end;
      end;
      MForm.FInPacketV2[aIndex].State:= PacketState;
    end;
  //
end;

end.
