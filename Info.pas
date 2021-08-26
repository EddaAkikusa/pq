unit Info;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, IpHtml;

type

  { TForm4 }

  TForm4 = class(TForm)
    WebBrowser1: TIpHtmlPanel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure Go(url: String);
  end;

var
  Form4: TForm4;

implementation

{$R *.lfm}

procedure TForm4.FormCreate(Sender: TObject);
begin

end;

procedure TForm4.Go(url: String);
begin
  WebBrowser1.Navigate(url);
  Show;
end;

end.
