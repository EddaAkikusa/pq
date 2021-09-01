program pq;

uses
  Forms,
  Config in 'Config.pas' {K},
  Front in 'Front.pas' {FrontForm},
  Main in 'Main.pas' {MainForm},
  NewGuy in 'NewGuy.pas', Interfaces {NewGuyForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Progress Quest';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TK, K);
  Application.CreateForm(TFrontForm, FrontForm);
  Application.CreateForm(TNewGuyForm, NewGuyForm);
  Application.Run;
end.
