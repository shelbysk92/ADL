unit DrTxtDrv;

interface

uses
  Objects,
  TextDrv;

type
  PDirectTextDriver = ^TDirectTextDriver;
  TDirectTextDriver = object(TTextDriver)
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



procedure TDirectTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
end;

procedure TDirectTextDriver.WriteText(const txt: string);
begin
end;

procedure TDirectTextDriver.WriteTextLn(const txt: string);
begin
end;

procedure TDirectTextDriver.WriteWideText(txt: TWideString);
begin
end;

procedure TDirectTextDriver.WriteWideTextLn(txt: TWideString);
begin
end;

procedure TDirectTextDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
end;

procedure TDirectTextDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
end;

procedure TDirectTextDriver.Init;
begin
end;

procedure TDirectTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TDirectTextDriver.VLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TDirectTextDriver.ClrScr;
begin
end;

destructor TDirectTextDriver.Done;
begin
  TTextDriver.Done;
end;

end.