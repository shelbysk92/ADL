unit VgaTxDrv;

interface

uses
  Objects,
  WideStr,
  Collects,
  Utils,
  TextDrv;

type
  PVgaTextDriver = ^TVgaTextDriver;
  TVgaTextDriver = object(TTextDriver)
  private
  public
    procedure WriteText(const txt: string); virtual;
    procedure WriteTextLn(const txt: string); virtual;
    procedure WriteWideText(txt: TWideString); virtual;
    procedure WriteWideTextLn(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: TTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

type
  TTextChar = record
    Character: char;
    Attributes: char;
  end;
  TVga80x25Screen = array[0..24, 0..79] of byte;

var
  _currentScreen: PByte;


procedure TVgaTextDriver.SetMode(newMode: TTextMode);
begin
  Mode.Assign(newMode);
end;

procedure TVgaTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
end;

procedure TVgaTextDriver.WriteText(const txt: string);
begin
end;

procedure TVgaTextDriver.WriteTextLn(const txt: string);
begin
end;

procedure TVgaTextDriver.WriteWideText(txt: TWideString);
begin
end;

procedure TVgaTextDriver.WriteWideTextLn(txt: TWideString);
begin
end;

procedure TVgaTextDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
end;

procedure TVgaTextDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
end;

procedure TVgaTextDriver.Init;
var
  newMode: PTextMode;
begin
  TTextDriver.Init;
  TypeName := 'TVgaTextDriver';
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'Text 80x25 16 color';
    AdditionalData := 0;
    Description := 'VGA Text 80x25x16 color';
    HelpText := '';
    Modes.Add(newMode);
  end;
end;

procedure TVgaTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TVgaTextDriver.VLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TVgaTextDriver.ClrScr;
begin
end;

destructor TVgaTextDriver.Done;
begin
  TTextDriver.Done;
end;

end.