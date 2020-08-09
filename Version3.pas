unit Version3;

interface

uses System.SysUtils, Classes, Variants, Vcl.Graphics, MyTypes;

const
  _SignV3B: Array[0..1] of Byte =  ( 62, 16);

  procedure OnSourceEventV3(const aIndex: Int64);
  procedure OnPacketEventV3(const aIndex: int64);

implementation

uses MForm, Elements, Dictionary;

procedure OnSourceEventV3(const aIndex: Int64);
var CurrentPacket, PBegin: Integer;
    PSize: Word;
    Empty: Boolean;
begin
  if (Length(FInPacketV3) = 0 ) or (0 < FInPacketV3[Pred(Length(FInPacketV3))].State) then
    begin
      CurrentPacket:= Length(FInPacketV3);
      SetLength(FInPacketV3, Succ(CurrentPacket));
      FInPacketV3[CurrentPacket].Time:= FInSource[aIndex].Time;
      FInPacketV3[CurrentPacket].Position:= FInSource[aIndex].Position;
      FInPacketV3[CurrentPacket].Size:= FInSource[aIndex].Size;

      if FInSource[aIndex].State = 255 then
        begin
          FInPacketV3[CurrentPacket].State:= 255;
          Exit;
        end
      else
        begin
          FInPacketV3[CurrentPacket].State:= 0;
        end;
    end
  else
    begin
      CurrentPacket:= Pred(Length(FInPacketV3));
      FInPacketV3[CurrentPacket].Size:= (FInSource[aIndex].Position + FInSource[aIndex].Size) - FInPacketV3[CurrentPacket].Position;
    end;

  PBegin:= MS.ArrayPosition( FInPacketV3[CurrentPacket].Position, FInPacketV3[CurrentPacket].Size, @_SignV3B, SizeOf(_SignV3B) );
  while -1 < PBegin do
    begin
      if PBegin = FInPacketV3[CurrentPacket].Position then
        begin
          // Заголовок полностью еще не начитан, минимальный пакет 4 байта
          if FInSource[aIndex].Position + FInSource[aIndex].Size < PBegin + 3 {+ PSize} + 1 then Break;

          case MS.AsByte(PBegin + 2) of
           $B0: begin
                  PSize:= 6 + 4 + 1 + 4 + 17;
                end;
           $B1: begin
                  PSize:= 3 * 16;
                end;
           $B2: begin
                  PSize:= 1;
                end;
           $B3: begin
                  PSize:= 1 + 1 + 1 + 4 + 16 + 32;
                end;
           $B4: begin
                  PSize:= 32;
                end;
           $B5: begin
                  PSize:= 1;
                end;
           $B6: begin
                  PSize:= 1;
                end;
           $B7: begin
                  PSize:= 2;
                end;
           $B8: begin
                  PSize:= 1 + MS.AsByte(PBegin + 3) * (1 + 6 + 1);
                end;
            else PSize:= 0;
          end;

          // Пакет полностью не начитан
          if MS.Size < PBegin + 3 + PSize + 1 then Break;

          // ЭТОТ !!! Пакет полностью не начитан
          if FInSource[aIndex].Position + FInSource[aIndex].Size < PBegin + 3 + PSize + 1 then Break;


          FInPacketV3[CurrentPacket].Size:= PBegin - FInPacketV3[CurrentPacket].Position + 3 + PSize + 1;
          FInPacketV3[CurrentPacket].State:= 1;

          Empty:= (MS.Size = PBegin + 3 + PSize + 1);

          if FInPacketV3[CurrentPacket].State = 1 then
            OnPacketEventV3(CurrentPacket);

          // Данные во входящем пакете закончились - выходим
          if Empty then
            begin
              MF.Q.InnerSend;
              Break;
            end;

          Inc(CurrentPacket);
          SetLength(FInPacketV3, Succ(CurrentPacket));
          FInPacketV3[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV3[CurrentPacket].Position:= FInPacketV3[Pred(CurrentPacket)].Position + FInPacketV3[Pred(CurrentPacket)].Size;
          FInPacketV3[CurrentPacket].Size:= FInSource[aIndex].Position + FInSource[aIndex].Size - FInPacketV3[CurrentPacket].Position;
          FInPacketV3[CurrentPacket].State:= 0;
        end
      else
        begin
          FInPacketV3[CurrentPacket].Size:= PBegin - FInPacketV3[CurrentPacket].Position;

          CurrentPacket:= Length(FInPacketV3);
          SetLength(FInPacketV3, Succ(CurrentPacket));
          FInPacketV3[CurrentPacket].Time:= FInSource[aIndex].Time;
          FInPacketV3[CurrentPacket].Position:= PBegin;
          FInPacketV3[CurrentPacket].Size:= FInSource[aIndex].Size - PBegin;
          FInPacketV3[CurrentPacket].State:= 0;
        end;

      PBegin:= MS.ArrayPosition( FInPacketV3[CurrentPacket].Position, FInPacketV3[CurrentPacket].Size, @_SignV3B, SizeOf(_SignV3B) );;
    end;
end;

procedure OnPacketEventV3(const aIndex: int64);
var P: Int64;
    i,N: Byte;
    j: Integer;
    FCardinal: Cardinal;

    aControl: TObject;
    fCaption: TCaptionClass;
    fString: TStringClass;
begin
  P:= MForm.FInPacketV3[aIndex].Position;
  if MForm.FInPacketV3[aIndex].State = 1 then
    begin
      case MS.AsByte( P + 2) of
        $B0: begin
               MForm.FInPacketV3[aIndex].State:= 2;
               MF.Q.DeviceName:= MS.AsHex(P+3, 6);

               MF.VisualSetValue('master_1', MS.AsHex (P + 3, 6, ' ', True));
               MF.VisualSetValue('master_2', MS.AsText(P + 9, 4));
               MF.VisualSetValue('master_3', MS.AsByte(P + 13));

               FCardinal:= MS.AsByte(P + 14)         + MS.AsByte(P + 15)*256 +
                           MS.AsByte(P + 16)*256*256 + MS.AsByte(P + 17)*256*256*256;
               MF.VisualSetValue('master_4', Format('%2.2d:%2.2d:%2.2d',
                                                   [ FCardinal div 3600, (FCardinal div 60) mod 60, FCardinal mod 60]) );
             end;
        $B1: begin
               MForm.FInPacketV3[aIndex].State:= 2;
               MF.VisualSetValue('master_1_1', MS.AsHex(P + 3 + 0*16, 6, ' ', True) );
               MF.VisualSetValue('sensor_1_1', MS.AsHex(P + 3 + 0*16, 6, ' ', True) );
               MF.VisualSetValue('master_2_1', MS.AsHex(P + 3 + 1*16, 6, ' ', True) );
               MF.VisualSetValue('sensor_2_1', MS.AsHex(P + 3 + 1*16, 6, ' ', True) );
               MF.VisualSetValue('master_3_1', MS.AsHex(P + 3 + 2*16, 6, ' ', True) );
               MF.VisualSetValue('sensor_3_1', MS.AsHex(P + 3 + 2*16, 6, ' ', True) );

               MF.VisualSetValue('master_1_2', MS.AsByte(P + 9 + 0*16) );
               MF.VisualSetValue('sensor_1_2', MS.AsByte(P + 9 + 0*16) );
               MF.VisualSetValue('master_2_2', MS.AsByte(P + 9 + 1*16) );
               MF.VisualSetValue('sensor_2_2', MS.AsByte(P + 9 + 1*16) );
               MF.VisualSetValue('master_3_2', MS.AsByte(P + 9 + 2*16) );
               MF.VisualSetValue('sensor_3_2', MS.AsByte(P + 9 + 2*16) );

               MF.VisualSetValue('master_1_3', MS.AsByte(P + 10 + 0*16) );
               MF.VisualSetValue('sensor_1_3', MS.AsByte(P + 10 + 0*16) );
               MF.VisualSetValue('master_2_3', MS.AsByte(P + 10 + 1*16) );
               MF.VisualSetValue('sensor_2_3', MS.AsByte(P + 10 + 1*16) );
               MF.VisualSetValue('master_3_3', MS.AsByte(P + 10 + 2*16) );
               MF.VisualSetValue('sensor_3_3', MS.AsByte(P + 10 + 2*16) );

               MF.Q.SendAnsiString(MasterCRC(#49#16#180#0));
               MF.Q.SendAnsiString(MasterCRC(#49#16#180#1));
               MF.Q.SendAnsiString(MasterCRC(#49#16#180#2));
             end;
    $B2,$B5: begin
               MForm.FInPacketV3[aIndex].State:= 2;
               case MS.AsByte(P + 3) of
                $00: MF.MainHintShow(1, Translate(MF.Language, 'mes_SUCCESS'));
                $FA: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_SUPPROTED'));
                $FB: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_INVALID_HANDLE'));
                $FC: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_INTERNAL'));
                $FD: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_CONNECTED'));
                $FE: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_FOUND'));
                $FF: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_SIZE'));
               end
             end;
        $B4: begin
               if 0 < aIndex then
                 if  MForm.FInPacketV3[aIndex-1].State= 255 then
                   begin
                     N:= MS.AsByte(MForm.FInPacketV3[aIndex-1].Position+3);
                     if (0 <= N) and (N<=3) then
                       begin
                         MForm.FInPacketV3[aIndex].State:= 2;
                         MF.VisualSetValue('sensor_'+IntToStr(N+1)+'_4', MS.AsByte(P + 3) );
                         MF.VisualSetValue('sensor_'+IntToStr(N+1)+'_5', MS.AsWord(P + 4) );
                         MF.VisualSetValue('sensor_'+IntToStr(N+1)+'_6', MS.AsWord(P + 6) );
                         MF.VisualSetValue('sensor_'+IntToStr(N+1)+'_7', MS.AsCardinal(P + 8) );
                         MF.VisualSetValue('sensor_'+IntToStr(N+1)+'_8', MS.AsCardinal(P + 12) );
                       end;
                   end;
             end;
        $B7: begin
               MForm.FInPacketV3[aIndex].State:= 2;
               case MS.AsByte(P + 3) of
                $00: MF.MainHintShow(1, Translate(MF.Language, 'mes_SUCCESS'));
                $FA: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_SUPPROTED'));
                $FB: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_INVALID_HANDLE'));
                $FC: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_INTERNAL'));
                $FD: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_CONNECTED'));
                $FE: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_NOT_FOUND'));
                $FF: MF.MainHintShow(0, Translate(MF.Language, 'mes_ERROR_SIZE'));
               end
             end;
        $B8: begin
               MForm.FInPacketV3[aIndex].State:= 2;
               N:= MS.AsByte(P + 3);
               fCaption:= nil;

               if MF.VisualFind(MF, 'SensorResult', aControl) then
                 if aControl is TCaptionClass then
                   begin
                     fCaption:= TCaptionClass(aControl);
                     for j:= fCaption.Body.ControlCount-1 downto 0 do
                       if fCaption.Body.Controls[j] is TStringClass then
                         fCaption.Body.Controls[j].Destroy;

                     fCaption.UpdateHeight;
                     fCaption.Repaint;
                   end;

               if (0 = N) then
                 MF.MainHintShow(0, Translate(MF.Language, 'mes_sensornotfound'));

               if (0 < N) and (assigned(fCaption)) then
                 begin
                   for i:=0 to Pred(N) do
                     begin
                       fString := TStringClass.Create(MF);
                       fString.Ident:= 'FindResultSensors'+IntToStr(i);
                       FString.Parent:= fCaption.Body;
                       fString.Max:= 255;
                       fString.Min:= -1;

                       case MS.AsByte(P + 4 + i * 8) of
                         1:fString.Caption:= 'LLS';
                         2:fString.Caption:= 'Bridge';
                         3:fString.Caption:= 'Escort';
                         4:fString.Caption:= 'Thermo';
                         else fString.Caption:= 'type #'+IntToStr(MS.AsByte(P + 5 + i * 8 ));
                       end;

                       FString.Value:= MS.AsHex (P +  5 + i * 8, 6, ' ', True);

                       fString.Caption:= fString.Caption + ' / ' +IntToStr( MS.AsShortInt(P + 11 + i * 8)) +' dB';

                       if fCaption.Parent.Parent is TColumnClass then
                         TColumnClass(fCaption.Parent.Parent).UpdateHeight;

                       fCaption.UpdateHeight;
                       FString.UpdateHeight;
                     end;
                 end;
             end;
       else  begin
               MForm.FInPacketV3[aIndex].State:= 1;
             end;
      end;
    end;
end;

end.
