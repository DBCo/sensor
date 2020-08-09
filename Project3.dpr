program Project3;

{$R *.dres}

uses
  Vcl.Forms,
  MForm in 'MForm.pas' {MF},
  Elements in 'Elements.pas',
  Vcl.Themes,
  Vcl.Styles,
  CommDrv in 'CommDrv.pas',
  myTypes in 'myTypes.pas',
  Dictionary in 'Dictionary.pas',
  Version1 in 'Version1.pas',
  Version2 in 'Version2.pas',
  Version3 in 'Version3.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMF, MF);
  Application.Run;
end.
