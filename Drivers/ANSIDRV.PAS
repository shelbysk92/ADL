unit AnsiDrv;

interface

uses
  Objects,
  TextDrv;

type
  PAnsiDriver = ^TAnsiDriver;
  TAnsiDriver = object(TTextDriver)
  private
  public
    procedure WriteText(const txt: string); virtual;
    procedure WriteTextLn(const txt: string); virtual;
    procedure WriteWideText(txt: TWideString); virtual;
    procedure WriteWideTextLn(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure Init; virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

procedure TAnsiDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
end;

procedure TAnsiDriver.WriteText(const txt: string);
begin
end;

procedure TAnsiDriver.WriteTextLn(const txt: string);
begin
end;

procedure TAnsiDriver.WriteWideText(txt: TWideString);
begin
end;

procedure TAnsiDriver.WriteWideTextLn(txt: TWideString);
begin
end;

procedure TAnsiDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
end;

procedure TAnsiDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
end;

procedure TAnsiDriver.Init;
begin
end;

procedure TAnsiDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.VLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.ClrScr;
begin
end;

destructor TAnsiDriver.Done;
begin
  TTextDriver.Done;
end;

end.